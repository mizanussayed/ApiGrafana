#!/bin/bash

# Script to generate test traffic for the API monitoring dashboard

echo "Starting API traffic generation..."
echo "Press Ctrl+C to stop"

BASE_URL="http://localhost:8080"

# Function to make a request and show status
make_request() {
    local endpoint=$1
    local method=${2:-GET}
    local data=${3:-}
    
    if [ "$method" = "POST" ]; then
        response=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$data" "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "%{http_code}" "$BASE_URL$endpoint")
    fi
    
    echo "$(date '+%H:%M:%S') - $method $endpoint - Status: ${response: -3}"
}

# Main loop
counter=0
while true; do
    counter=$((counter + 1))
    
    # Random endpoint selection
    case $((RANDOM % 7)) in
        0) make_request "/" ;;
        1) make_request "/health" ;;
        2) make_request "/api/users" ;;
        3) make_request "/api/users/$((RANDOM % 10 + 1))" ;;
        4) make_request "/api/users" "POST" '{"name":"Test User","email":"test@example.com"}' ;;
        5) make_request "/api/slow" ;;
        6) make_request "/api/error" ;;
    esac
    
    # Random delay between requests (1 to 3 seconds)
    sleep_time=$((RANDOM % 3 + 1))
    sleep $sleep_time
    
    # Show progress every 10 requests
    if [ $((counter % 10)) -eq 0 ]; then
        echo "--- $counter requests sent ---"
    fi
done
