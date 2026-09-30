#!/bin/bash
echo "[+] Active Node processes:"
ps aux | grep node | grep -v grep

echo -e "\n[+] Checking server logs..."
for v in v1 v2 v3 v4 v5; do
    echo "=== instances/$v/server.log ==="
    if [ -f "instances/$v/server.log" ]; then
        tail -n 3 "instances/$v/server.log"
    else
        echo "No log found."
    fi
done
