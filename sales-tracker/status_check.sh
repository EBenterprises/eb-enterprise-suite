#!/bin/bash
echo "[+] Checking running instances and logs..."
for i in {0..4}; do
    port=$((3000 + i))
    echo -n "Port $port (v$((i+1))): "
    if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$port | grep -q "200"; then
        echo "🟢 ONLINE"
    else
        echo "🔴 OFFLINE - Last 3 log lines:"
        tail -n 3 instances/v$((i+1))/server.log 2>/dev/null || echo "No log found"
    fi
done
