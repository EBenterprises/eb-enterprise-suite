#!/bin/bash
set -e

echo "[+] Forcibly cleaning up node processes and launching cluster..."
pkill -9 -f "node server.js" 2>/dev/null || true
sleep 1

PORTS=(3000 3001 3002 3003 3004)
VERSIONS=("v1" "v2" "v3" "v4" "v5")

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    cd "instances/$v"
    
    PORT="$p" nohup node server.js > server.log 2>&1 &
    echo "    -> Started instance $v on port $p (PID $!)"
    cd - > /dev/null
done

sleep 2
echo "[+] Verifying endpoints..."
for port in "${PORTS[@]}"; do
    echo -n "Checking port $port: "
    curl -s -I http://127.0.0.1:$port | head -n 1
done
