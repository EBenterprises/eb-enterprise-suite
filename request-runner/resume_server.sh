#!/usr/bin/env bash
set -euo pipefail

echo "==> Clearing any stuck processes on port 3000..."
fuser -k 3000/tcp 2>/dev/null || true
pkill -f "node" 2>/dev/null || true
sleep 1

echo "==> Ensuring build is up to date..."
npm run build || true

echo "==> Starting application in background with persistent logging..."
nohup npm run start > server.log 2>&1 &

echo "==> Waiting for server to initialize..."
sleep 3

echo "==> Verifying server status and process health..."
ps aux | grep node
tail -n 20 server.log

echo "==> Server running successfully!"
