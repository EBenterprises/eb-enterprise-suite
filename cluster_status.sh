#!/bin/bash
set -e

echo "[+] Checking active node cluster processes..."
ps aux | grep node | grep -v grep || echo "No node processes found."

echo "[+] Testing all cluster ports (3000-3004)..."
for port in {3000..3004}; do
    echo -n "Port $port: "
    curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$port && echo " [OK]" || echo " [FAILED]"
done
