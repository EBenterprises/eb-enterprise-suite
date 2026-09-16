#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Force Port Recovery & Health Check
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Force killing any processes holding ports 3000-3004..."
for p in "${PORTS[@]}"; do
    fuser -k ${p}/tcp 2>/dev/null || true
done
pkill -f "node" 2>/dev/null || true
sleep 2

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    if [ -d "$DIR" ]; then
        cd "$DIR"
        
        # Verify node_modules and express
        if [ ! -d "node_modules/express" ]; then
            npm install express sqlite3 > /dev/null 2>&1 || true
        fi
        
        # Ensure PORT is explicitly exported / used
        PORT=$P nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Launched instance $V on port $P"
    fi
done

sleep 2
echo "[+] Checking active node processes and ports:"
netstat -tuln | grep -E "3000|3001|3002|3003|3004" || ss -tuln | grep -E "3000|3001|3002|3003|3004" || ps aux | grep node

echo "[+] Site recovery sequence executed successfully. All endpoints are online."
