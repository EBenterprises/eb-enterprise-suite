#!/usr/bin/env bash
set -e

echo "[MESH DAEMON] Initializing direct single-process node binding..."

mkdir -p data/node1/lsm data/node2/lsm data/node3/lsm logs

pkill -f cluster_server.js || true
sleep 1

export NODE_ENV=production
PORT=3001 NODE_ID=1 CLUSTER_PEERS=http://localhost:3002,http://localhost:3003 node cluster_server.js > logs/node1.log 2>&1 &
PORT=3002 NODE_ID=2 CLUSTER_PEERS=http://localhost:3001,http://localhost:3003 node cluster_server.js > logs/node2.log 2>&1 &
PORT=3003 NODE_ID=3 CLUSTER_PEERS=http://localhost:3001,http://localhost:3002 node cluster_server.js > logs/node3.log 2>&1 &

echo "[MESH DAEMON] Waiting for servers to bind..."
sleep 2

echo "[MESH DAEMON] Edge cluster operational."
