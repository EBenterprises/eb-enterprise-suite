#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Launch & Focus v1 Utility
# ==============================================================================
set -e

VERSION="v1"
PORT=3000
DIR="instances/$VERSION"

if [ ! -d "$DIR" ]; then
    echo "[!] Instance $VERSION not found. Please run the multi-version generator first."
    exit 1
fi

echo "[+] Terminating any existing processes on port $PORT..."
pkill -f "node.*instances/$VERSION/server.js" || true

echo "[+] Launching $VERSION on http://localhost:$PORT..."
cd "$DIR"
nohup node server.js > server.log 2>&1 &
cd - > /dev/null

sleep 1
if pgrep -f "node.*instances/$VERSION/server.js" > /dev/null; then
    echo "[+] SUCCESS: $VERSION is live and running."
    echo "[+] Access URL: http://localhost:$PORT"
    
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:$PORT"
    elif command -v open &> /dev/null; then
        open "http://localhost:$PORT"
    fi
else
    echo "[!] ERROR: Failed to start $VERSION. Check $DIR/server.log for details."
    tail -n 10 "$DIR/server.log"
fi
