#!/usr/bin/env bash
set -e

echo "[SCALING] Terminating existing node processes..."
pkill -f cluster_server.js || true
sleep 1

mkdir -p logs

echo "[SCALING] Spawning distributed mesh cluster across 5 edge nodes..."
PORT=3001 NODE_ID=1 node cluster_server.js > logs/node1.log 2>&1 &
PORT=3002 NODE_ID=2 node cluster_server.js > logs/node2.log 2>&1 &
PORT=3003 NODE_ID=3 node cluster_server.js > logs/node3.log 2>&1 &
PORT=3004 NODE_ID=4 node cluster_server.js > logs/node4.log 2>&1 &
PORT=3005 NODE_ID=5 node cluster_server.js > logs/node5.log 2>&1 &

# Start main proxy/gateway on port 3000
PORT=3000 NODE_ID=GATEWAY node cluster_server.js > logs/gateway.log 2>&1 &

sleep 2
echo "[SUCCESS] All edge nodes and load balancer online."
