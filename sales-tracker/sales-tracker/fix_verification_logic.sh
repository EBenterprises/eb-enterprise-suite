#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Accurate Process Check
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Verifying running instances via HTTP health check..."
for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$P" || echo "000")
    
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 304 ]; then
        echo "    -> $V (Port $P): [RUNNING & HEALTHY - HTTP $HTTP_CODE]"
    else
        echo "    -> $V (Port $P): [OFFLINE/UNREACHABLE - HTTP $HTTP_CODE]"
    fi
done
