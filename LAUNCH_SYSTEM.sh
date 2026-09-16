#!/usr/bin/env bash
set -e

echo "[EGG-FINDER® ENTERPRISE MESH] Initializing complete cluster infrastructure..."

# 1. Scale cluster to 5 nodes and start proxy balancer
./scale_mesh.sh 5

# 2. Wait for binding verification
echo "[CLUSTER] Waiting for edge gateways to initialize sockets..."
sleep 2

# 3. Run telemetry audit to confirm synchronization
node cluster_telemetry.js

echo ""
echo "======================================================================"
echo "⚡ EGG-FINDER® DISTRIBUTED MESH ECOSYSTEM ONLINE"
echo "======================================================================"
echo "  • Global Load Balancer Proxy : http://localhost:3000"
echo "  • Executive Command Center   : http://localhost:3000/dashboard.html"
echo "  • Producer Management Portal : http://localhost:3000/admin.html"
echo "  • Consumer Radar View        : http://localhost:3000/index.html"
echo "  • Edge Gateway Nodes         : Ports 3001, 3002, 3003, 3004, 3005"
echo "======================================================================"
