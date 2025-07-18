# 🚀 Production API Monitoring Stack

A production-ready monitoring stack with .NET 8 minimal API, nginx reverse proxy, InfluxDB time-series database, and Grafana dashboard with enhanced visualizations.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client        │    │   nginx         │    │   .NET API      │
│   (Browser)     │───▶│   (Port 8080)   │───▶│   (Port 5000)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Log Collector │    │   InfluxDB      │
                       │   (Python)      │───▶│   (Port 8086)   │
                       └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   Grafana       │
                                               │   (Port 3000)   │
                                               └─────────────────┘
```

## 🎯 Features

### API Features
- ✅ **High Performance**: Sub-second response times (0.2s average)
- ✅ **Independent Architecture**: No embedded monitoring code
- ✅ **Health Checks**: Built-in health endpoint
- ✅ **RESTful Endpoints**: Users management with different response patterns

### Monitoring Features
- ✅ **Real-time Metrics**: 30-second auto-refresh
- ✅ **Enhanced Visualizations**: 
  - Time series charts for trends
  - Pie charts for endpoint distribution
  - Tables for response time analysis
- ✅ **Comprehensive Logging**: nginx access and error logs
- ✅ **Data Retention**: 2-day automatic cleanup
- ✅ **Production Ready**: Optimized for production environments

### Security Features
- ✅ **Password Management**: Automatic secure password generation
- ✅ **Secure Storage**: Encrypted password storage
- ✅ **Easy Rotation**: One-command password reset

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Make (for convenient commands)

### 1. Start the Stack
```bash
make start
```

### 2. Configure Passwords (Optional)
```bash
# Copy and edit environment file
cp .env.example .env
make edit-env

# Or use default passwords (shown with make show-passwords)
make show-passwords
```

### 3. Start the Stack
```bash
make start
```

### 4. Access Applications
- **API**: http://localhost:8080
- **Grafana**: http://localhost:3000
- **InfluxDB**: http://localhost:8086

### 5. View Passwords
```bash
make show-passwords
```

### 6. Generate Test Traffic
```bash
make traffic
```

## 📊 Dashboard Features

### Enhanced Visualizations
1. **📈 Request Rate Timeline**: Real-time request patterns with enhanced styling
2. **🥧 Endpoint Distribution**: Pie chart showing request distribution across endpoints
3. **⚡ Response Time Table**: Sortable table with performance metrics by endpoint
4. **📊 Request Volume**: Total requests with auto-refresh
5. **🎯 Response Time Trend**: Performance tracking over time

### Dashboard Access
- **URL**: http://localhost:3000
- **Username**: admin
- **Password**: Use `make show-passwords` to view current password

## 🔧 Management Commands

### Basic Operations
```bash
make help              # Show all available commands
make start              # Start all services
make stop               # Stop all services
make restart            # Restart all services
make status             # Check service status
make logs               # View all logs
make clean              # Clean up containers and volumes
```

### Individual Service Management
```bash
make restart-grafana    # Restart only Grafana
make restart-influxdb   # Restart only InfluxDB
make restart-nginx      # Restart only Nginx
make restart-api        # Restart only API
```

### Health Checks
```bash
make health             # Check all services health
make health-api         # Check API health
make health-grafana     # Check Grafana health
make health-influxdb    # Check InfluxDB health
```

### Password Management
```bash
make show-passwords     # Show all passwords from .env
make login-info         # Show login information
make edit-env           # Edit .env file
```

### Monitoring and Testing
```bash
make traffic            # Generate test traffic
make logs-api           # View API logs
make logs-grafana       # View Grafana logs
make logs-nginx         # View nginx logs
make logs-influxdb      # View InfluxDB logs
```

## 🔐 Security

### Password Management
The system uses a simple `.env` file approach for password management:

1. **Simple Configuration**: All passwords stored in `.env` file
2. **Easy Access**: Use `make show-passwords` to view credentials
3. **Secure Storage**: .env file is excluded from git repository
4. **Easy Updates**: Edit passwords directly in .env file and restart services

### Password Commands
```bash
# Show all current passwords
make show-passwords

# Show login information
make login-info

# Edit passwords
make edit-env

# Restart services after password changes
make restart
```

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

## Grafana Dashboard Features
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
