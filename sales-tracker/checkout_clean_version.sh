#!/usr/bin/env bash
set -euo pipefail

echo "=== Stashing any current local terminal edits ==="
git stash || true

echo "=== Checking out clean commit f375e77 ==="
git checkout f375e77

echo "=== Killing any running node processes ==="
fuser -k 3100/tcp 3101/tcp 3102/tcp 3103/tcp 3104/tcp 2>/dev/null || true
pkill -f "node server.js" || true

echo "=== Booting clean v1-v4 cluster from f375e77 ==="
declare -A ports=( ["v1"]=3100 ["v2"]=3101 ["v3"]=3102 ["v4"]=3103 )

for v in v1 v2 v3 v4; do
    target_dir=""
    if [ -d "instances/$v" ] && [ -f "instances/$v/server.js" ]; then
        target_dir="instances/$v"
    elif [ -d "$v" ] && [ -f "$v/server.js" ]; then
        target_dir="$v"
    fi

    if [ -n "$target_dir" ]; then
        echo "Starting $target_dir on port ${ports[$v]}..."
        cd "$target_dir"
        
        # Ensure 0.0.0.0 binding
        if ! grep -q "0.0.0.0" server.js; then
            sed -i "s/app.listen(PORT/app.listen(PORT, '0.0.0.0'/g" server.js 2>/dev/null || true
        fi
        
        PORT="${ports[$v]}" node server.js > "../../${v}_clean.log" 2>&1 &
        cd - > /dev/null
    fi
done

echo "=== Successfully rolled back and booted! ==="
echo "Version 4 is now running at: http://localhost:3103"
