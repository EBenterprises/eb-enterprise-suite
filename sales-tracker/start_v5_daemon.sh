#!/usr/bin/env bash
set -e

PORT=51205
SCRIPT="server_v5.js"

echo "[*] Checking if process on port $PORT is running..."
PID=$(pgrep -f "node $SCRIPT" || true)

if [ -n "$PID" ]; then
    echo "[+] $SCRIPT already running under PID $PID"
else
    echo "[*] Launching $SCRIPT on port $PORT..."
    nohup node $SCRIPT > server_v5.log 2>&1 &
    sleep 1
    NEW_PID=$!
    echo "[+] $SCRIPT started with PID $NEW_PID"
fi

echo "[*] Verifying endpoint response..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$PORT/api/data)

if [ "$STATUS" -eq 200 ]; then
    echo "[✔] Success: V5 endpoint returning HTTP 200"
else
    echo "[✘] Error: V5 endpoint returned HTTP $STATUS"
    exit 1
fi
