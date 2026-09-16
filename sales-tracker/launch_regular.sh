#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Regular Root Instance Launcher
# ==============================================================================
set -e

PORT=3000

echo "[+] Terminating any active Node processes..."
fuser -k "${PORT}/tcp" 2>/dev/null || true
pkill -f "node" 2>/dev/null || true
sleep 1

echo "[+] Ensuring root project dependencies are installed..."
if [ ! -d "node_modules" ]; then
    npm init -y > /dev/null 2>&1 || true
    npm install express sql.js > /dev/null 2>&1 || true
fi

echo "[+] Launching regular root sales-tracker instance on port $PORT..."
nohup node server.js > server.log 2>&1 &

sleep 1
if pgrep -f "node server.js" > /dev/null; then
    echo "[+] SUCCESS: Regular sales-tracker is running live."
    echo "[+] Access URL: http://localhost:$PORT"
    
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:$PORT"
    elif command -v open &> /dev/null; then
        open "http://localhost:$PORT"
    fi
else
    echo "[!] ERROR: Failed to start regular instance. Check server.log:"
    tail -n 15 server.log
fi
