#!/usr/bin/env python3
import os
import re
import time
import logging
from datetime import datetime
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class NginxLogCollector:
    def __init__(self):
        self.influx_url = os.getenv("INFLUXDB_URL", "http://influxdb:8086")
        self.influx_token = os.getenv("INFLUXDB_TOKEN", "my-super-secret-auth-token")
        self.influx_org = os.getenv("INFLUXDB_ORG", "my-org")
        self.influx_bucket = os.getenv("INFLUXDB_BUCKET", "api-metrics")
        self.log_file = "/var/log/nginx/access.log"
        
        # Initialize InfluxDB client
        try:
            self.client = InfluxDBClient(url=self.influx_url, token=self.influx_token, org=self.influx_org)
            self.write_api = self.client.write_api(write_options=SYNCHRONOUS)
            logger.info("InfluxDB client initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize InfluxDB client: {e}")
            raise
        
        # Nginx log format regex
        self.log_pattern = re.compile(
            r'(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] '
            r'"(?P<request>[^"]*)" (?P<status>\d+) (?P<body_bytes_sent>\d+) '
            r'"(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)" '
            r'"(?P<http_x_forwarded_for>[^"]*)" rt=(?P<request_time>[\d.]+) '
            r'uct="(?P<upstream_connect_time>[^"]*)" uht="(?P<upstream_header_time>[^"]*)" '
            r'urt="(?P<upstream_response_time>[^"]*)"'
        )
    
    def parse_log_line(self, line):
        """Parse a single nginx log line"""
        match = self.log_pattern.match(line)
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
            'remote_addr': data['remote_addr'],
            'body_bytes_sent': int(data['body_bytes_sent']),
            'timestamp': datetime.now()
        }
    
    def write_to_influxdb(self, log_data):
        """Write parsed log data to InfluxDB"""
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
            logger.debug(f"Written to InfluxDB: {log_data['method']} {log_data['path']} - {log_data['status_code']}")
        except Exception as e:
            logger.error(f"Failed to write to InfluxDB: {e}")
    
    def tail_log_file(self):
        """Tail the nginx access log file"""
        logger.info(f"Starting to tail log file: {self.log_file}")
        
        # Wait for log file to exist
        while not os.path.exists(self.log_file):
            logger.info("Waiting for log file to exist...")
            time.sleep(1)
        
        # Start tailing
        with open(self.log_file, 'r') as f:
            # Go to end of file
            f.seek(0, 2)
            
            while True:
                line = f.readline()
                if line:
                    log_data = self.parse_log_line(line.strip())
                    if log_data:
                        self.write_to_influxdb(log_data)
                else:
                    time.sleep(0.1)
    
    def run(self):
        """Run the log collector"""
        logger.info("Starting Nginx Log Collector")
        
        # Test InfluxDB connection
        try:
            self.client.ping()
            logger.info("InfluxDB connection successful")
        except Exception as e:
            logger.error(f"InfluxDB connection failed: {e}")
            return
        
        # Start tailing log file
        try:
            self.tail_log_file()
        except KeyboardInterrupt:
            logger.info("Shutting down log collector")
        except Exception as e:
            logger.error(f"Error in log collector: {e}")
        finally:
            self.client.close()

if __name__ == "__main__":
    collector = NginxLogCollector()
    collector.run()
