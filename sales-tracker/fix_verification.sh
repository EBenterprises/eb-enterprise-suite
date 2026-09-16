#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Accurate Process Verification
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Re-verifying all running instances..."
for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    
    # Check if a node process containing this specific instance directory is running
    if pgrep -f "node.*instances/$V/server.js" > /dev/null; then
        echo "    -> $V (Port $P): [RUNNING SUCCESSFULLY]"
    else
        echo "    -> $V (Port $P): [FAILED] - Log output:"
        tail -n 3 "instances/$V/server.log" 2>/dev/null || echo "No log found"
    fi
done

echo "[+] Testing loopback on port 3000..."
curl -sI "http://localhost:3000" || echo "[!] Loopback test returned no HTTP headers."
