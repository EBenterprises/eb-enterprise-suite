#!/bin/bash
echo "=== Checking Process Status ==="
ps aux | grep "[n]ode server.js"

echo -e "\n=== Checking Instance Logs ==="
for v in v1 v2 v3 v4 v5; do
    echo "--- instances/$v/server.log ---"
    if [ -f "instances/$v/server.log" ]; then
        tail -n 5 "instances/$v/server.log"
    else
        echo "Log file not found."
    fi
done
