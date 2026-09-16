#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Termux Node.js & SQLite Dependency Fix
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Terminating existing Node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    if [ -d "$DIR" ]; then
        cd "$DIR"
        echo "[+] Setting up dependencies and starting $V on port $P..."
        
        if [ ! -f "package.json" ]; then
            npm init -y > /dev/null 2>&1
        fi
        
        npm install express sqlite3 > /dev/null 2>&1 || {
            npm install express sqlite3 --ignore-scripts > /dev/null 2>&1 || true
        }
        
        PORT=$P nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Started $V on port $P"
    fi
done

sleep 2
echo "[+] Checking recent logs for any startup errors:"
for V in "${VERSIONS[@]}"; do
    if [ -f "instances/$V/server.log" ]; then
        echo "=== instances/$V/server.log ==="
        tail -n 5 "instances/$V/server.log"
    fi
done

echo "[+] Process check:"
ps aux | grep node
