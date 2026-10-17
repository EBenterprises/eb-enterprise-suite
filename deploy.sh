#!/usr/bin/env bash
set -e

echo "[EGG-FINDER DEPLOYMENT] Initializing zero-dependency cluster environment..."

mkdir -p data/lsm storage public

if [ ! -f package.json ]; then
    npm init -y > /dev/null
    npm install express > /dev/null
fi

echo "[DEPLOYMENT] Starting cluster server..."
node cluster_server.js &
SERVER_PID=$!

echo "[DEPLOYMENT] Waiting for edge nodes to bind to port 3000..."
until nc -z localhost 3000 2>/dev/null || node -e "fetch('http://localhost:3000/api/farms').then(() => process.exit(0)).catch(() => process.exit(1))" 2>/dev/null; do
    sleep 0.2
done

echo "[DEPLOYMENT] Executing cluster stress test & warm-up..."
node loadtest.js

echo "[DEPLOYMENT] Cluster successfully operational and verified."
kill $SERVER_PID
