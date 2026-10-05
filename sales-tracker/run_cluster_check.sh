#!/usr/bin/env bash
set -uo pipefail

echo "=== Running Cluster Status & Health Check ==="
if [ -f "./cluster_comprehensive_status.sh" ]; then
    ./cluster_comprehensive_status.sh
elif [ -f "./sales-tracker/cluster_comprehensive_status.sh" ]; then
    ./sales-tracker/cluster_comprehensive_status.sh
else
    echo "Checking active Node processes:"
    ps -ef | grep '[n]ode' || echo "No node processes running."
    
    echo -e "\nChecking Ports 3100-3103:"
    for port in 3100 3101 3102 3103; do
        if nc -z localhost "$port" 2>/dev/null || (echo >/dev/tcp/127.0.0.1/"$port") 2>/dev/null; then
            echo "Port $port: ACTIVE"
        else
            echo "Port $port: DOWN/INACCESSIBLE"
        fi
    done
fi
