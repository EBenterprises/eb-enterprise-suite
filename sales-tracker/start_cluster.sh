#!/bin/bash
set -e

echo "[+] Starting EB Sales & Payments Tracker cluster (v1 - v5)..."

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

# Kill any existing node instances on these ports
pkill -9 -f "node server.js" 2>/dev/null || true
sleep 1

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    dir="instances/$v"
    
    if [ -d "$dir" ]; then
        cd "$dir"
        PORT="$p" nohup node server.js > server.log 2>&1 &
        echo " -> Started instance $v on port $p (PID $!)"
        cd - > /dev/null
    else
        echo " [!] Warning: Directory $dir not found."
    fi
done

echo "[+] Cluster startup sequence complete!"
sleep 1
./cluster_comprehensive_status.sh
