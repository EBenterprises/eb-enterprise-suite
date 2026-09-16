#!/bin/bash
set -e

echo "[+] Working on v2 application environment (releases/v2 on port 3002)..."

# Ensure releases/v2 is fully up to date and active
cd releases/v2
PORT=3002 npm install || true
pkill -f "node.*releases/v2/server.js" || true
PORT=3002 nohup node server.js > server.log 2>&1 &
cd - > /dev/null

echo "[+] v2 is ready for active development on http://localhost:3002"
