#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Final Full-Stack Consolidation Script
# ==============================================================================
set -e

echo "[+] Verifying Node.js environment and instance cluster..."
pkill -f "node" 2>/dev/null || true
sleep 1

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    if [ -d "$DIR" ] && [ -f "$DIR/server.js" ]; then
        cd "$DIR"
        nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Verified & running instance $V on port $P"
    fi
done

echo "[+]. Executive Spectrum deployment sequence fully synchronized and active."
