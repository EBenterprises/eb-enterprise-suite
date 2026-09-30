#!/bin/bash
echo "[+] Checking cluster processes and ports..."
ps aux | grep node | grep -v grep

echo -e "\n[+] Testing HTTP endpoints across v1-v5..."
for port in {3000..3004}; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/)
    echo "    Port $port -> HTTP Status: $status"
done
