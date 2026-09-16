#!/bin/bash
TARGET_URL="http://localhost:5000/health"
LOG_FILE="/var/log/enterprise-health.log"

response=$(curl -s -o /dev/null -w "%{http_code}" $TARGET_URL)
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ "$response" -eq 200 ]; then
    echo "[$timestamp] [HEALTH] Status: OK (200)" >> $LOG_FILE
else
    echo "[$timestamp] [ALERT] Status: FAILURE ($response)" >> $LOG_FILE
    # Trigger alerting hooks or restart sequence here
fi
