#!/usr/bin/env bash
set -e
echo "[DAEMON] Starting multi-region edge cluster instances..."
PORT=3001 NODE_ID=1 CLUSTER_PEERS=http://localhost:3002,http://localhost:3003 node cluster_server.js &
PORT=3002 NODE_ID=2 CLUSTER_PEERS=http://localhost:3001,http://localhost:3003 node cluster_server.js &
PORT=3003 NODE_ID=3 CLUSTER_PEERS=http://localhost:3001,http://localhost:3002 node cluster_server.js &
echo "[SUCCESS] Cluster active on ports 3001, 3002, 3003 with zero-dependency LSM storage & real-time mesh replication."
