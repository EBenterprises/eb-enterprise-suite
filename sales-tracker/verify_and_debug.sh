#!/bin/bash
set -e

echo "[+] Terminating any lingering processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

cd instances/v1

echo "[+] Running instance v1 in foreground to check output..."
node server.js &
SERVER_PID=$!
sleep 2

echo "[+] Testing connection to port 3000..."
curl -I http://127.0.0.1:3000 || echo "Connection failed"

kill $SERVER_PID 2>/dev/null || true
