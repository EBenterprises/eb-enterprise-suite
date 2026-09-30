#!/bin/bash
set -e

echo "[+] Terminating existing Node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

echo "[+] Booting multi-instance Node.js cluster (ports 3000-3004)..."

PORTS=(3000 3001 3002 3003 3004)
VERSIONS=("v1" "v2" "v3" "v4" "v5")

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    dir="instances/$v"
    
    if [ -d "$dir" ]; then
        cd "$dir"
        PORT=$p nohup node server.js > server.log 2>&1 &
        echo "    -> Started instance $v on port $p"
        cd - > /dev/null
    fi
done

sleep 2
echo "[+] All cluster nodes started successfully. Verifying port 3000..."
curl -I http://127.0.0.1:3000
