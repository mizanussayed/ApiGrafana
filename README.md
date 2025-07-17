# API Monitoring Stack with Grafana

This project sets up a complete monitoring stack with:
- **.NET 8 Minimal API** - A sample API with multiple endpoints
- **nginx** - Reverse proxy with access and error logging
- **InfluxDB** - Time-series database for metrics storage
- **Grafana** - Dashboard for visualization with auto-refresh every 30 seconds

## Architecture

```
Internet → nginx (port 8080) → .NET API (port 5001) 
                     ↓
               nginx access logs → Log Collector → InfluxDB (port 8086)
                                                      ↓
                                                 Grafana (port 3000)
```

## Components

1. **📊 .NET 8 Minimal API** - Independent API with no external dependencies
2. **🔧 nginx** - Reverse proxy with comprehensive logging
3. **📝 Log Collector** - Python service that parses nginx logs and sends metrics to InfluxDB
4. **🗄️ InfluxDB** - Time-series database with 2-day data retention
5. **📈 Grafana** - Dashboard with auto-refresh every 30 seconds

## Quick Start

1. **Prerequisites**
   - Docker and Docker Compose installed
   - Git (optional, for cloning)

2. **Start the stack**
   ```bash
   docker-compose up -d
   ```

3. **Access the services**
   - **API**: http://localhost:8080 (via nginx)
   - **API Direct**: http://localhost:5001
   - **Grafana**: http://localhost:3000 (admin/admin)
   - **InfluxDB**: http://localhost:8086 (admin/password123)

4. **View the dashboard**
   - Open Grafana at http://localhost:3000
   - Login with admin/admin
   - The "API Monitoring Dashboard" will be automatically provisioned
   - Dashboard auto-refreshes every 2 minutes

## API Endpoints

The API includes several endpoints for testing:

- `GET /` - Hello World
- `GET /health` - Health check
- `GET /api/users` - List users
- `GET /api/users/{id}` - Get user by ID
- `POST /api/users` - Create user
- `GET /api/slow` - Slow endpoint (2s delay)
- `GET /api/error` - Error endpoint (500 status)

## Testing the API

Generate some traffic to see metrics:

```bash
# Basic requests
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/api/users

# Test slow endpoint
curl http://localhost:8080/api/slow

# Test error endpoint
curl http://localhost:8080/api/error

# Generate load
for i in {1..100}; do curl http://localhost:8080/api/users; done
```

## Grafana Dashboard

The dashboard includes:
- **API Response Time** - Time series of response times
- **Request Rate** - Requests per second
- **Total Requests** - Counter of total requests
- **Average Response Time** - Average response time stat
- **Requests by Status Code** - Table showing request counts by HTTP status
- **Requests by Endpoint** - Time series showing requests per endpoint

### Dashboard Features
- **Auto-refresh**: Every 2 minutes
- **Time range**: Last 1 hour by default
- **Real-time metrics**: Updated as requests are made

## Nginx Logs

Nginx logs are stored in `./nginx/logs/`:
- `access.log` - All HTTP requests with response times
- `error.log` - Error messages and warnings

View logs in real-time:
```bash
tail -f nginx/logs/access.log
tail -f nginx/logs/error.log
```

## InfluxDB Configuration

- **Organization**: my-org
- **Bucket**: api-metrics
- **Token**: my-super-secret-auth-token
- **Data Retention**: 2 days (automatic cleanup)
- **Database**: Stores API request metrics collected from nginx logs

## Monitoring Metrics

The log collector parses nginx logs and sends metrics to InfluxDB:
- **Measurement**: `api_requests`
- **Tags**: `method`, `endpoint`, `status_code`, `remote_addr`
- **Fields**: `response_time` (ms), `request_count`, `body_bytes_sent`
- **Fields**: `response_time` (ms), `request_count`
- **Timestamp**: Request start time

## Development

To modify the API:
1. Edit `src/Program.cs`
2. Rebuild with `docker-compose up --build api`

To modify nginx configuration:
1. Edit `nginx/nginx.conf`
2. Restart with `docker-compose restart nginx`

To modify Grafana dashboard:
1. Edit `grafana/dashboards/api-monitoring.json`
2. Restart with `docker-compose restart grafana`

## Stopping the Stack

```bash
docker-compose down
```

To remove volumes (will delete all data):
```bash
docker-compose down -v
```

## Troubleshooting

1. **Check service status**
   ```bash
   docker-compose ps
   ```

2. **View logs**
   ```bash
   docker-compose logs api
   docker-compose logs nginx
   docker-compose logs grafana
   docker-compose logs influxdb
   ```

3. **Access services directly**
   - API health: http://localhost:5000/health
   - InfluxDB UI: http://localhost:8086
   - Grafana: http://localhost:3000

4. **Common issues**
   - Port conflicts: Change ports in docker-compose.yml
   - Permission issues: Check file permissions for nginx logs directory
   - Memory issues: Increase Docker memory limits

## Environment Variables

Key environment variables in docker-compose.yml:
- `INFLUXDB_URL`, `INFLUXDB_TOKEN`, `INFLUXDB_ORG`, `INFLUXDB_BUCKET`
- `DOCKER_INFLUXDB_INIT_*` variables for InfluxDB setup
- `GF_SECURITY_ADMIN_PASSWORD` for Grafana admin password

## Current Setup

The stack is configured with these ports:
- **nginx**: 8080 (proxy to API)
- **API**: 5001 (direct access)
- **Grafana**: 3000 (dashboard)
- **InfluxDB**: 8086 (database)
