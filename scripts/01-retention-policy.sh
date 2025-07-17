#!/bin/bash
# This script sets up a retention policy for the api-metrics bucket
# It will be executed when InfluxDB starts for the first time

echo "Setting up retention policy for api-metrics bucket..."

# Wait for InfluxDB to be ready
sleep 5

# Create retention policy for 2 days
influx bucket update \
    --name api-metrics \
    --retention 2d \
    --org my-org \
    --token my-super-secret-auth-token

echo "Retention policy set to 2 days for api-metrics bucket"
