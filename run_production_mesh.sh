#!/usr/bin/env bash
set -e

echo "[PRODUCTION MESH] Killing any existing node instances..."
pkill -f cluster_server.js || true
sleep 1

echo "[PRODUCTION MESH] Initializing multi-node distributed mesh nodes..."
PORT=3001 NODE_ID=1 CLUSTER_PEERS=http://localhost:3002 node cluster_server.js &
PORT=3002 NODE_ID=2 CLUSTER_PEERS=http://localhost:3001 node cluster_server.js &

echo "[MESH] Node 1 active on port 3001 | Node 2 active on port 3002."
echo "[PRODUCTION MESH] Distributed edge network operational with live replication."
