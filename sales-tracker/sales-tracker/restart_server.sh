#!/bin/bash
set -e

echo "[+] Checking running processes and ports..."
pkill -f node || true
pkill -f server.js || true

echo "[+] Starting local server via run.sh..."
if [ -f "./run.sh" ]; then
    ./run.sh &
else
    echo "[!] run.sh not found, starting server.js directly..."
    node server.js &
fi

sleep 2
echo "[+] Server restarted. Check http://localhost:3000 (or the designated local port)."
