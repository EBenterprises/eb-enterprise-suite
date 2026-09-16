#!/bin/bash
set -e
echo "[+] Starting EB Sales Tracker..."
pkill -f "node server.js" || true
nohup node server.js > server.log 2>&1 &
echo "[+] Server running live on http://localhost:3000"
