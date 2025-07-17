.PHONY: help start stop restart logs clean build traffic health

help: ## Show this help message
	@echo "API Monitoring Stack - Available commands:"
	@echo
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

start: ## Start the entire stack
	@echo "🚀 Starting API monitoring stack..."
	@docker-compose up -d
	@echo "✅ Stack started!"
	@echo "📊 Grafana: http://localhost:3000 (admin/admin)"
	@echo "🔧 API: http://localhost:8080"

stop: ## Stop the entire stack
	@echo "🛑 Stopping API monitoring stack..."
	@docker-compose down
	@echo "✅ Stack stopped!"

restart: stop start ## Restart the entire stack

logs: ## Show logs from all services
	@docker-compose logs -f

logs-api: ## Show API logs
	@docker-compose logs -f api

logs-nginx: ## Show nginx logs
	@docker-compose logs -f nginx

logs-grafana: ## Show Grafana logs
	@docker-compose logs -f grafana

logs-influxdb: ## Show InfluxDB logs
	@docker-compose logs -f influxdb

build: ## Build the API image
	@echo "🔨 Building API image..."
	@docker-compose build api
	@echo "✅ API image built!"

rebuild: ## Rebuild and restart the API
	@echo "🔨 Rebuilding API..."
	@docker-compose up -d --build api
	@echo "✅ API rebuilt and restarted!"

clean: ## Remove all containers, volumes, and images
	@echo "🧹 Cleaning up..."
	@docker-compose down -v --remove-orphans
	@docker system prune -f
	@echo "✅ Cleanup complete!"

traffic: ## Generate test traffic
	@echo "🚦 Generating API traffic..."
	@./generate-traffic.sh

health: ## Check health of all services
	@echo "🔍 Checking service health..."
	@echo -n "API: "
	@curl -s http://localhost:8080/health >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"
	@echo -n "Grafana: "
	@curl -s http://localhost:3000 >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"
	@echo -n "InfluxDB: "
	@curl -s http://localhost:8086/health >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

status: ## Show container status
	@docker-compose ps

dashboard: ## Open Grafana dashboard
	@echo "🖥️  Opening Grafana dashboard..."
	@echo "Navigate to: http://localhost:3000"
	@echo "Login: admin/admin"
	@echo "Dashboard: API Monitoring Dashboard"

setup: ## Complete setup with retention policy
	@echo "� Setting up API monitoring stack..."
	@./setup-complete.sh

retention: ## Set up InfluxDB retention policy
	@echo "🗄️ Setting up InfluxDB retention policy..."
	@./scripts/setup-retention.sh

update: ## Update all container images
	@echo "🔄 Updating container images..."
	@docker-compose pull
	@echo "✅ Images updated!"
