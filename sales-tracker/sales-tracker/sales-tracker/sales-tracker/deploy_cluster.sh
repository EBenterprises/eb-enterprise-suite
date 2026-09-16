#!/bin/bash
echo "[+] Terminating existing Node processes..."
pkill -f "node server.js" || true

mkdir -p data

echo "[+] Installing dependencies..."
npm install

echo "[+] Launching cluster instances..."
PORT=3000 node server.js &
PORT=3001 node server.js &
PORT=3002 node server.js &
PORT=3003 node server.js &
PORT=3004 node server.js &

sleep 2

echo "[+] Cluster online. Testing v1 on port 3000..."
curl -i http://localhost:3000
