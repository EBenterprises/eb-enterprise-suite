#!/usr/bin/env bash
set -euo pipefail

echo "=== Killing any running node instances ==="
fuser -k 3100/tcp 3101/tcp 3102/tcp 3103/tcp 3104/tcp 2>/dev/null || true
pkill -f "node server.js" || true

echo "=== Booting top-level v1 - v4 cluster ==="
declare -A ports=( ["v1"]=3100 ["v2"]=3101 ["v3"]=3102 ["v4"]=3103 )

for v in v1 v2 v3 v4; do
    if [ -d "$v" ] && [ -f "$v/server.js" ]; then
        echo "Starting top-level $v on port ${ports[$v]}..."
        cd "$v"
        
        # Ensure server.js binds to 0.0.0.0
        if ! grep -q "0.0.0.0" server.js; then
            sed -i "s/app.listen(PORT/app.listen(PORT, '0.0.0.0'/g" server.js 2>/dev/null || true
        fi
        
        PORT="${ports[$v]}" node server.js > "../${v}_cluster.log" 2>&1 &
        cd ..
    fi
done

echo "=== Cluster Boot Complete! ==="
echo "Version 4 (Map & Timestamp) is running at: http://localhost:3103"
