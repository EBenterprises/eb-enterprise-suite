#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Start All Versions Utility
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Terminating any existing node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    if [ -d "$DIR" ]; then
        echo "[+] Starting $V on port $P..."
        cd "$DIR"
        nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
    else
        echo "[!] Directory $DIR not found, skipping."
    fi
done

sleep 2
echo "[+] Verification of running instances:"
for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    if pgrep -f "node.*instances/$V/server.js" > /dev/null; then
        echo "    -> $V (Port $P): [RUNNING]"
    else
        echo "    -> $V (Port $P): [FAILED]"
    fi
done

echo "[+] All versions startup sequence complete."
