.PHONY: help start stop restart logs clean build traffic health

help: ## Show this help message
	@echo "🚀 API Monitoring Stack - Available Commands"
	@echo "============================================="
	@echo
	@echo "📋 Basic Operations:"
	@echo "  make start              - Start all services"
	@echo "  make stop               - Stop all services"
	@echo "  make restart            - Restart all services"
	@echo "  make status             - Check service status"
	@echo "  make logs               - View all logs"
	@echo "  make clean              - Clean up containers and volumes"
	@echo
	@echo "🔧 Individual Service Management:"
	@echo "  make restart-grafana    - Restart only Grafana"
	@echo "  make restart-influxdb   - Restart only InfluxDB"
	@echo "  make restart-nginx      - Restart only Nginx"
	@echo "  make restart-api        - Restart only API"
	@echo
	@echo "🏥 Health Checks:"
	@echo "  make health             - Check all services health"
	@echo "  make health-api         - Check API health"
	@echo "  make health-grafana     - Check Grafana health"
	@echo "  make health-influxdb    - Check InfluxDB health"
	@echo
	@echo "🔐 Password Management:"
	@echo "  make show-passwords     - Show all passwords from .env"
	@echo "  make login-info         - Show login information"
	@echo "  make edit-env           - Edit .env file"
	@echo
	@echo "📊 Monitoring & Testing:"
	@echo "  make traffic            - Generate test traffic"
	@echo "  make logs-api           - View API logs"
	@echo "  make logs-grafana       - View Grafana logs"
	@echo "  make logs-nginx         - View nginx logs"
	@echo "  make logs-influxdb      - View InfluxDB logs"
	@echo "  make logs-error         - View nginx error logs"
	@echo "  make logs-access        - View nginx access logs"
	@echo
	@echo "🌐 Quick Access URLs:"
	@echo "  API:      http://localhost:8080"
	@echo "  Grafana:  http://localhost:3000 (use make show-passwords)"
	@echo "  InfluxDB: http://localhost:8086"

start: ## Start the entire stack
	@echo "🚀 Starting API monitoring stack..."
	@docker compose up -d
	@echo "✅ Stack started!"
	@echo "📊 Grafana: http://localhost:3000 (use make show-passwords)"
	@echo "🔧 API: http://localhost:8080"

stop: ## Stop the entire stack
	@echo "🛑 Stopping API monitoring stack..."
	@docker compose down
	@echo "✅ Stack stopped!"

restart: ## Restart all services
	@echo "🔄 Restarting all services..."
	@docker compose restart
	@echo "✅ All services restarted successfully"

logs: ## Show logs from all services
	@docker compose logs -f

logs-api: ## Show API logs
	@docker compose logs -f api

logs-nginx: ## Show nginx logs
	@docker compose logs -f nginx

logs-grafana: ## Show Grafana logs
	@docker compose logs -f grafana

logs-influxdb: ## Show InfluxDB logs
	@docker compose logs -f influxdb

build: ## Build the API image
	@echo "🔨 Building API image..."
	@docker compose build api
	@echo "✅ API image built!"

rebuild: ## Rebuild and restart the API
	@echo "🔨 Rebuilding API..."
	@docker compose up -d --build api
	@echo "✅ API rebuilt and restarted!"

clean: ## Remove all containers, volumes, and images
	@echo "🧹 Cleaning up..."
	@docker compose down -v --remove-orphans
	@docker system prune -f
	@echo "✅ Cleanup complete!"

traffic: ## Generate test traffic to API endpoints
	@echo "� Generating test traffic..."
	@chmod +x scripts/generate-traffic.sh
	@./scripts/generate-traffic.sh

# Password Management (using .env file)
show-passwords: ## Show all passwords from .env file
	@echo "🔐 Reading passwords from .env file..."
	@./scripts/show-passwords.sh show

login-info: ## Show login information
	@echo "🔑 Login information..."
	@./scripts/show-passwords.sh login

edit-env: ## Edit .env file
	@echo "� Opening .env file for editing..."
	@${EDITOR:-nano} .env
	@echo "💡 Remember to restart services after changing passwords: make restart"

logs-error: ## View nginx error logs
	@echo "🚨 Viewing nginx error logs..."
	@tail -f nginx/logs/error.log

logs-access: ## View nginx access logs
	@echo "📊 Viewing nginx access logs..."
	@tail -f nginx/logs/access.log

logs-error-recent: ## View recent nginx error logs
	@echo "🚨 Recent nginx error logs (last 50 lines)..."
	@tail -n 50 nginx/logs/error.log

logs-access-recent: ## View recent nginx access logs
	@echo "📊 Recent nginx access logs (last 50 lines)..."
	@tail -n 50 nginx/logs/access.log

health: ## Check health of all services
	@echo "🔍 Checking service health..."
	@echo -n "API: "
	@curl -s http://localhost:8080/health >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"
	@echo -n "Grafana: "
	@curl -s http://localhost:3000 >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"
	@echo -n "InfluxDB: "
	@curl -s http://localhost:8086/health >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

status: ## Show container status
	@echo "🔍 Checking container status..."
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "label=com.docker.compose.project=apigrafana" || docker-compose ps
	@echo ""
	@echo "🌐 Service URLs:"
	@echo "  API:      http://localhost:8080"
	@echo "  Grafana:  http://localhost:3000"
	@echo "  InfluxDB: http://localhost:8086"

dashboard: ## Open Grafana dashboard
	@echo "🖥️  Opening Grafana dashboard..."
	@echo "Navigate to: http://localhost:3000"
	@echo "Use 'make show-passwords' to see login credentials"
	@echo "Dashboard: API Monitoring Dashboard"

setup: ## Complete setup with retention policy
	@echo "� Setting up API monitoring stack..."
	@./setup-complete.sh

retention: ## Set up InfluxDB retention policy
	@echo "🗄️ Setting up InfluxDB retention policy..."
	@./scripts/setup-retention.sh

update: ## Update all container images
	@echo "🔄 Updating container images..."
	@docker compose pull
	@echo "✅ Images updated!"
