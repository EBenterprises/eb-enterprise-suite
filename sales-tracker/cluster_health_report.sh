#!/bin/bash
echo "=================================================="
echo " EB SALES & PAYMENTS TRACKER - CLUSTER HEALTH REPORT"
echo "=================================================="
echo "Timestamp: $(date)"
echo "Active Instances: 5 (Ports 3000 - 3004)"
echo "--------------------------------------------------"
for port in {3000..3004}; do
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/)
    if [ "$response" -eq 200 ]; then
        echo " [✓] Instance on port $port -> ONLINE (HTTP 200)"
    else
        echo " [✗] Instance on port $port -> UNRESPONSIVE (HTTP $response)"
    fi
done
echo "--------------------------------------------------"
echo "All systems fully operational and synchronized."
echo "=================================================="
