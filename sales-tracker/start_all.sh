#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Fleet Startup Utility
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Starting all EB Sales Tracker server instances..."
for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    if [ -d "$DIR" ] && [ -f "$DIR/server.js" ]; then
        cd "$DIR"
        nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Started Instance $V on port $P"
    else
        echo "    -> Skipping $V (missing directory or server.js)"
    fi
done

sleep 2
echo "[+] Fleet startup complete. Run ./status_all.sh to verify health."
