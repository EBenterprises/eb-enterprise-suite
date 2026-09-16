#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Force Start v1 Utility
# ==============================================================================
set -e

PORT=3000
DIR="instances/v1"

echo "[+] Forcefully freeing port $PORT..."
fuser -k "${PORT}/tcp" 2>/dev/null || true
pkill -f "node.*server.js" 2>/dev/null || true
sleep 1

echo "[+] Launching v1 on port $PORT..."
cd "$DIR"
nohup node server.js > server.log 2>&1 &
cd - > /dev/null

sleep 1
if pgrep -f "node.*instances/v1/server.js" > /dev/null; then
    echo "[+] SUCCESS: v1 is running live on http://localhost:$PORT"
else
    echo "[!] ERROR: Failed to start. Log output:"
    tail -n 15 "$DIR/server.log"
fi
