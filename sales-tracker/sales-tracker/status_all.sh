#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Fleet Status Summary
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "=== EB ENTERPRISES: FLEET HEALTH STATUS ==="
for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$P" || echo "000")
    
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 304 ]; then
        echo "[ACTIVE] Instance $V -> http://localhost:$P (HTTP $HTTP_CODE)"
    else
        echo "[DOWN]   Instance $V -> http://localhost:$P (HTTP $HTTP_CODE)"
    fi
done
echo "============================================"
