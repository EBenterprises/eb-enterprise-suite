#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - System State Inspection Utility
# ==============================================================================
echo "[+] Inspecting current multi-version deployment status..."

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    echo "--------------------------------------------------"
    echo "Instance: $V | Port: $P"
    if pgrep -f "node.*instances/$V/server.js" > /dev/null; then
        echo "Status: [ACTIVE] (PID: $(pgrep -f "node.*instances/$V/server.js"))"
    else
        echo "Status: [INACTIVE]"
    fi
    
    if [ -f "$DIR/public/index.html" ]; then
        echo "UI Source: Verified (File size: $(wc -c < "$DIR/public/index.html") bytes)"
    else
        echo "UI Source: [MISSING]"
    fi
    
    if [ -f "$DIR/data/sales.db" ]; then
        echo "Database: Initialized ($(wc -c < "$DIR/data/sales.db") bytes)"
    else
        echo "Database: No records yet"
    fi
done
echo "--------------------------------------------------"
