#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - v1 Dependency & Startup Fixer
# ==============================================================================
set -e

DIR="instances/v1"
PORT=3000

echo "[+] Inspecting failure log from instances/v1/server.log..."
if [ -f "$DIR/server.log" ]; then
    cat "$DIR/server.log"
fi

echo "[+] Ensuring dependencies (express, sql.js) are installed locally..."
mkdir -p "$DIR"
cd "$DIR"

if [ ! -f "package.json" ]; then
    npm init -y > /dev/null 2>&1
fi

npm install express sql.js > /dev/null 2>&1

echo "[+] Restarting v1 server..."
pkill -f "node.*instances/v1/server.js" || true
nohup node server.js > server.log 2>&1 &
cd - > /dev/null

sleep 1
if pgrep -f "node.*instances/v1/server.js" > /dev/null; then
    echo "[+] SUCCESS: v1 is running live on http://localhost:$PORT"
else
    echo "[!] ERROR: Still failing. Tail of server.log:"
    tail -n 15 "$DIR/server.log"
fi
