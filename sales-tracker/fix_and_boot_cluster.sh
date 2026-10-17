#!/usr/bin/env bash
set -euo pipefail

echo "=== 1. Killing any stale Node processes on ports 3100-3105 ==="
fuser -k 3100/tcp 3101/tcp 3102/tcp 3103/tcp 3104/tcp 2>/dev/null || true
pkill -f "node server.js" || true

echo "=== 2. Restoring modified/truncated server files from git ==="
git checkout instances/v2/server.js v2/server.js 2>/dev/null || git restore instances/v2/server.js 2>/dev/null || true

echo "=== 3. Launching via existing cluster orchestrator ==="
if [ -f "./start_cluster.sh" ]; then
    ./start_cluster.sh
elif [ -f "./full_cluster_bootstrap.sh" ]; then
    ./full_cluster_bootstrap.sh
elif [ -f "./start_cluster_all.sh" ]; then
    ./start_cluster_all.sh
else
    echo "No standard cluster start script found at root, running manual boot..."
    for v in v1 instances/v2 instances/v3 instances/v4; do
        if [ -d "$v" ] && [ -f "$v/server.js" ]; then
            echo "Starting $v..."
            cd "$v" && node server.js &
            cd - > /dev/null
        fi
    done
fi

echo "=== Cluster boot sequence complete! Check ports 3100-3103. ==="
