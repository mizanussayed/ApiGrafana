#!/bin/bash

# Simple Password Utility for .env file
# This script reads passwords from .env file

set -euo pipefail

readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ENV_FILE="$PROJECT_DIR/.env"

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found at: $ENV_FILE"
    echo "Please create .env file with your passwords"
    exit 1
fi

# Function to read value from .env file
get_env_value() {
    local key="$1"
    grep "^${key}=" "$ENV_FILE" | cut -d'=' -f2 | head -1
}

# Show current passwords
show_passwords() {
    echo
    echo -e "${BLUE}📋 Current Passwords from .env file:${NC}"
    echo -e "${GREEN}===========================================${NC}"
    echo
    echo -e "${YELLOW}Grafana:${NC}"
    echo -e "  Username: $(get_env_value 'GRAFANA_ADMIN_USER')"
    echo -e "  Password: $(get_env_value 'GRAFANA_ADMIN_PASSWORD')"
    echo -e "  URL: http://localhost:$(get_env_value 'GRAFANA_PORT')"
    echo
    echo -e "${YELLOW}InfluxDB:${NC}"
    echo -e "  Username: $(get_env_value 'INFLUXDB_ADMIN_USER')"
    echo -e "  Password: $(get_env_value 'INFLUXDB_ADMIN_PASSWORD')"
    echo -e "  URL: http://localhost:$(get_env_value 'INFLUXDB_PORT')"
    echo
    echo -e "${YELLOW}API:${NC}"
    echo -e "  URL: http://localhost:$(get_env_value 'NGINX_PORT')"
    echo
}

# Show login information
show_login_info() {
    echo
    echo -e "${BLUE}🔑 Login Information:${NC}"
    echo -e "${GREEN}===================${NC}"
    echo
    echo -e "${YELLOW}Grafana Dashboard:${NC}"
    echo -e "  🌐 URL: http://localhost:$(get_env_value 'GRAFANA_PORT')"
    echo -e "  👤 Username: $(get_env_value 'GRAFANA_ADMIN_USER')"
    echo -e "  🔒 Password: $(get_env_value 'GRAFANA_ADMIN_PASSWORD')"
    echo
    echo -e "${YELLOW}InfluxDB UI:${NC}"
    echo -e "  🌐 URL: http://localhost:$(get_env_value 'INFLUXDB_PORT')"
    echo -e "  👤 Username: $(get_env_value 'INFLUXDB_ADMIN_USER')"
    echo -e "  🔒 Password: $(get_env_value 'INFLUXDB_ADMIN_PASSWORD')"
    echo
}

# Show help
show_help() {
    cat << EOF
Simple Password Utility

Usage: $0 <command>

Commands:
  show      Show all passwords
  login     Show login information
  help      Show this help

To change passwords:
  1. Edit the .env file directly
  2. Restart services: make restart

Files:
  .env file: $ENV_FILE

EOF
}

# Main function
main() {
    local command=${1:-show}
    
    case "$command" in
        show)
            show_passwords
            ;;
        login)
            show_login_info
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "❌ Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
