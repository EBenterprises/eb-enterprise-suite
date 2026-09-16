#!/bin/bash
set -e

echo "[+] Diagnosing loopback resolution..."
ping -c 1 127.0.0.1 || echo "Loopback ping failed"

echo "[+] Restarting single foreground instance on port 3000 to inspect real-time logs..."
pkill -f "node" 2>/dev/null || true
sleep 1

cd ~/sales-tracker/instances/v1
node server.js
