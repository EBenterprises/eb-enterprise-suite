#!/bin/bash
echo "=== Inspecting server.log for v1 ==="
if [ -f "instances/v1/server.log" ]; then
    cat "instances/v1/server.log"
else
    echo "No log file found."
fi

echo -e "\n=== Running v1 directly in foreground to check error ==="
cd instances/v1
PORT=3000 timeout 3 node server.js
