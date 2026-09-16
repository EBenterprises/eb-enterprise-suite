#!/bin/bash
echo "[+] Terminating existing Node processes..."
<<<<<<< HEAD
pkill -f "node server/cluster.js" || true

echo "[+] Navigating to server directory..."
cd server || exit 1
=======
pkill -f "node server.js" || true

mkdir -p data
>>>>>>> 7678fca (Automated Termux sync: 2026-09-02 02:59:41)

echo "[+] Installing dependencies..."
npm install

echo "[+] Launching cluster instances..."
<<<<<<< HEAD
PORT=3000 node cluster.js &
PORT=3001 node cluster.js &
PORT=3002 node cluster.js &
PORT=3003 node cluster.js &
PORT=3004 node cluster.js &

cd ..
=======
PORT=3000 node server.js &
PORT=3001 node server.js &
PORT=3002 node server.js &
PORT=3003 node server.js &
PORT=3004 node server.js &

>>>>>>> 7678fca (Automated Termux sync: 2026-09-02 02:59:41)
sleep 2

echo "[+] Cluster online. Testing v1 on port 3000..."
curl -i http://localhost:3000
