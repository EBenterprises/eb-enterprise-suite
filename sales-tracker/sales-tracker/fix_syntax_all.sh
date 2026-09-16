#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Syntax Repair & Startup Utility
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

echo "[+] Terminating all node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    if [ -f "$DIR/server.js" ]; then
        echo "[+] Fixing syntax error in $V/server.js (port $P)..."
        # Fix any malformed port concatenation like 3000PORT
        sed -i "s/[0-9]*PORT/$P/g" "$DIR/server.js"
        sed -i "s/app.listen([0-9]*,/app.listen($P,/g" "$DIR/server.js"
        sed -i "s/app.listen([0-9]*PORT/app.listen($P/g" "$DIR/server.js"
        
        # Ensure correct listen syntax
        if ! grep -q "app.listen($P" "$DIR/server.js"; then
            sed -i "s/app.listen(.*;/app.listen($P, '0.0.0.0', () => { console.log('Running on port $P'); });/g" "$DIR/server.js"
        fi
    fi
done

echo "[+] Starting all fixed instances..."
for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    
    if [ -d "$DIR" ]; then
        cd "$DIR"
        nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
    fi
done

sleep 2
echo "[+] Verification check:"
for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    if pgrep -f "node.*$V/server.js" > /dev/null || ss -tln | grep -q ":$P "; then
        echo "    -> $V (Port $P): [RUNNING]"
    else
        echo "    -> $V (Port $P): [FAILED]"
        tail -n 2 "instances/$V/server.log" 2>/dev/null || true
    fi
done
