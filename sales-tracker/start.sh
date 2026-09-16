#!/bin/bash
pkill -f "node server.js" || true
echo "[+] Starting EB Sales Tracker..."
nohup node server.js > server.log 2>&1 &
echo "[+] Server running in background. Logs redirected to server.log."
echo "[+] Live at: http://localhost:3000"
