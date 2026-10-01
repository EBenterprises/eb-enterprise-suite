#!/bin/bash
echo "[+] Starting EB Sales & Payments Tracker cluster (v1 - v5) on ports 3100-3104..."
cd "$(dirname "$0")"

for i in {1..5}; do
    port=$((3100 + i - 1))
    dir="v$i"
    if [ -d "$dir" ]; then
        cd "$dir"
        PORT=$port node server.js > ../server_v$i.log 2>&1 &
        echo " -> Started instance v$i on port $port (PID $!)"
        cd ..
    fi
done
echo "[+] Cluster startup complete!"
