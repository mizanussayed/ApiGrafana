#!/usr/bin/env python3
import os
import re
import time
import logging
import threading
from datetime import datetime
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

class NginxLogCollector:
    def __init__(self):
        self.influx_url = os.getenv("INFLUXDB_URL", "http://influxdb:8086")
        self.influx_token = os.getenv("INFLUXDB_TOKEN", "my-super-secret-auth-token")
        self.influx_org = os.getenv("INFLUXDB_ORG", "my-org")
        self.influx_bucket = os.getenv("INFLUXDB_BUCKET", "api-metrics")
        self.access_log_file = "/var/log/nginx/access.log"
        self.error_log_file = "/var/log/nginx/error.log"
        
        # Initialize InfluxDB client
        try:
            self.client = InfluxDBClient(url=self.influx_url, token=self.influx_token, org=self.influx_org)
            self.write_api = self.client.write_api(write_options=SYNCHRONOUS)
            logger.info("InfluxDB client initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize InfluxDB client: {e}")
            raise
        
        # Nginx access log format regex
        self.access_log_pattern = re.compile(
            r'(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] '
            r'"(?P<request>[^"]*)" (?P<status>\d+) (?P<body_bytes_sent>\d+) '
            r'"(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)" '
            r'"(?P<http_x_forwarded_for>[^"]*)" rt=(?P<request_time>[\d.]+) '
            r'uct="(?P<upstream_connect_time>[^"]*)" uht="(?P<upstream_header_time>[^"]*)" '
            r'urt="(?P<upstream_response_time>[^"]*)"'
        )
        
        # Nginx error log format regex
        self.error_log_pattern = re.compile(
            r'(?P<timestamp>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) '
            r'\[(?P<level>\w+)\] (?P<pid>\d+)#(?P<tid>\d+): '
            r'(?P<message>.*?)(?:, client: (?P<client_ip>\S+))?'
            r'(?:, server: (?P<server>\S+))?'
            r'(?:, request: "(?P<request>[^"]*)")?'
            r'(?:, upstream: "(?P<upstream>[^"]*)")?'
            r'(?:, host: "(?P<host>[^"]*)")?'
            r'(?:\s*$)'
        )
    
    def parse_access_log_line(self, line):
        """Parse a single nginx access log line"""
        match = self.access_log_pattern.match(line)
        if not match:
            return None
        
        data = match.groupdict()
        
        # Extract method and path from request
        request_parts = data['request'].split(' ')
        if len(request_parts) >= 2:
            method = request_parts[0]
            path = request_parts[1]
        else:
            method = "UNKNOWN"
            path = "/"
        
        # Convert response time to milliseconds
        try:
            response_time_ms = float(data['request_time']) * 1000
        except (ValueError, TypeError):
            response_time_ms = 0
        
        return {
            'method': method,
            'path': path,
            'status_code': int(data['status']),
            'response_time': response_time_ms,
            'body_bytes_sent': int(data['body_bytes_sent']),
            'remote_addr': data['remote_addr'],
            'timestamp': datetime.utcnow()
        }
    
    def parse_error_log_line(self, line):
        """Parse a single nginx error log line"""
        match = self.error_log_pattern.match(line)
        if not match:
            return None
        
        data = match.groupdict()
        
        # Parse timestamp
        try:
            timestamp = datetime.strptime(data['timestamp'], '%Y/%m/%d %H:%M:%S')
        except (ValueError, TypeError):
            timestamp = datetime.utcnow()
        
        # Extract path from request if available
        path = "unknown"
        if data['request']:
            request_parts = data['request'].split(' ')
            if len(request_parts) > 1:
                path = request_parts[1]
        
        return {
            'timestamp': timestamp,
            'level': data['level'],
            'message': data['message'],
            'client_ip': data['client_ip'] or 'unknown',
            'server': data['server'] or 'unknown',
            'request': data['request'] or 'unknown',
            'upstream': data['upstream'] or 'unknown',
            'host': data['host'] or 'unknown',
            'path': path
        }
    
    def write_access_log_to_influxdb(self, log_data):
        """Write access log data to InfluxDB"""
        try:
            point = Point("api_requests") \
                .tag("method", log_data['method']) \
                .tag("endpoint", log_data['path']) \
                .tag("status_code", str(log_data['status_code'])) \
                .tag("remote_addr", log_data['remote_addr']) \
                .field("response_time", log_data['response_time']) \
                .field("request_count", 1) \
                .field("body_bytes_sent", log_data['body_bytes_sent']) \
                .time(log_data['timestamp'])
            
            self.write_api.write(bucket=self.influx_bucket, record=point)
            logger.debug(f"Written access log to InfluxDB: {log_data['method']} {log_data['path']} - {log_data['status_code']}")
        except Exception as e:
            logger.error(f"Failed to write access log to InfluxDB: {e}")
    
    def write_error_log_to_influxdb(self, log_data):
        """Write error log data to InfluxDB"""
        try:
            point = Point("api_errors") \
                .tag("level", log_data['level']) \
                .tag("endpoint", log_data['path']) \
                .tag("client_ip", log_data['client_ip']) \
                .tag("server", log_data['server']) \
                .tag("host", log_data['host']) \
                .field("error_count", 1) \
                .field("message", log_data['message']) \
                .field("request", log_data['request']) \
                .field("upstream", log_data['upstream']) \
                .time(log_data['timestamp'])
            
            self.write_api.write(bucket=self.influx_bucket, record=point)
            logger.debug(f"Written error log to InfluxDB: {log_data['level']} - {log_data['message'][:50]}...")
        except Exception as e:
            logger.error(f"Failed to write error log to InfluxDB: {e}")
    
    def tail_access_log_file(self):
        """Tail the nginx access log file"""
        logger.info(f"Starting to tail access log file: {self.access_log_file}")
        
        # Wait for log file to exist
        while not os.path.exists(self.access_log_file):
            logger.info("Waiting for access log file to exist...")
            time.sleep(1)
        
        # Start tailing
        with open(self.access_log_file, 'r') as f:
            # Start from the beginning for testing
            f.seek(0, 0)
            # Skip to the last few lines to test
            lines = f.readlines()
            f.seek(0, 2)  # Go back to end for real-time tailing
            
            # Process last few lines for testing
            for line in lines[-3:]:
                if line.strip():
                    logger.debug(f"Testing with existing log line: {line.strip()}")
                    log_data = self.parse_access_log_line(line.strip())
                    if log_data:
                        logger.debug(f"Successfully parsed: {log_data}")
                        self.write_access_log_to_influxdb(log_data)
                    else:
                        logger.debug("Failed to parse line")
            
            logger.debug(f"Starting to tail access log from position: {f.tell()}")
            
            while True:
                line = f.readline()
                if line:
                    logger.debug(f"Read access log line: {line.strip()}")
                    log_data = self.parse_access_log_line(line.strip())
                    if log_data:
                        logger.debug(f"Parsed access log data: {log_data}")
                        self.write_access_log_to_influxdb(log_data)
                    else:
                        logger.debug("Failed to parse access log line")
                else:
                    time.sleep(0.1)
    
    def tail_error_log_file(self):
        """Tail the nginx error log file"""
        logger.info(f"Starting to tail error log file: {self.error_log_file}")
        
        # Wait for log file to exist
        while not os.path.exists(self.error_log_file):
            logger.info("Waiting for error log file to exist...")
            time.sleep(1)
        
        # Start tailing
        with open(self.error_log_file, 'r') as f:
            # Start from the beginning for testing
            f.seek(0, 0)
            # Skip to the last few lines to test
            lines = f.readlines()
            f.seek(0, 2)  # Go back to end for real-time tailing
            
            # Process last few lines for testing
            for line in lines[-3:]:
                if line.strip():
                    logger.debug(f"Testing with existing error log line: {line.strip()}")
                    log_data = self.parse_error_log_line(line.strip())
                    if log_data:
                        logger.debug(f"Successfully parsed error log: {log_data}")
                        self.write_error_log_to_influxdb(log_data)
                    else:
                        logger.debug("Failed to parse error log line")
            
            logger.debug(f"Starting to tail error log from position: {f.tell()}")
            
            while True:
                line = f.readline()
                if line:
                    logger.debug(f"Read error log line: {line.strip()}")
                    log_data = self.parse_error_log_line(line.strip())
                    if log_data:
                        logger.debug(f"Parsed error log data: {log_data}")
                        self.write_error_log_to_influxdb(log_data)
                    else:
                        logger.debug("Failed to parse error log line")
                else:
                    time.sleep(0.1)
    
    def run(self):
        """Run the log collector"""
        logger.info("Starting Enhanced Nginx Log Collector (Access + Error logs)")
        
        # Test InfluxDB connection
        try:
            self.client.ping()
            logger.info("InfluxDB connection successful")
        except Exception as e:
            logger.error(f"InfluxDB connection failed: {e}")
            return
        
        # Start tailing both log files in separate threads
        try:
            access_thread = threading.Thread(target=self.tail_access_log_file)
            error_thread = threading.Thread(target=self.tail_error_log_file)
            
            access_thread.daemon = True
            error_thread.daemon = True
            
            access_thread.start()
            error_thread.start()
            
            logger.info("Both log collectors started successfully")
            
            # Keep main thread alive
            while True:
                time.sleep(1)
                
        except KeyboardInterrupt:
            logger.info("Shutting down log collector")
        except Exception as e:
            logger.error(f"Error in log collector: {e}")
        finally:
            self.client.close()

if __name__ == "__main__":
    collector = NginxLogCollector()
    collector.run()
