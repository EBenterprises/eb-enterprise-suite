#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Multi-Instance Dependency & Startup Fixer
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Terminating any lingering node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

echo "[+] Checking shared node_modules or installing locally in each instance..."
for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    if [ -d "$DIR" ]; then
        echo "[+] Setting up dependencies and starting $V on port $P..."
        cd "$DIR"
        if [ ! -f "package.json" ]; then
            npm init -y > /dev/null 2>&1
        fi
        npm install express sql.js > /dev/null 2>&1
        
        nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
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
        echo "    -> $V (Port $P): [FAILED] - Last log entries:"
        tail -n 3 "instances/$V/server.log" 2>/dev/null || echo "No log found"
    fi
done
