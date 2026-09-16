#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Health & Deployment Status Check
# ==============================================================================
echo "=== Checking Node Processes ==="
ps aux | grep node | grep -v grep

echo "=== Checking Root Server Log ==="
if [ -f "server.log" ]; then
    tail -n 20 server.log
else
    echo "No root server.log found."
fi

echo "=== Checking Instance Server Logs ==="
for d in instances/v*; do
    if [ -d "$d" ] && [ -f "$d/server.log" ]; then
        echo "--- $d/server.log ---"
        tail -n 10 "$d/server.log"
    fi
done

echo "=== Checking Ports & Listeners ==="
netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null
