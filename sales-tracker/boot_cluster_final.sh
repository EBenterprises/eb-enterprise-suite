#!/usr/bin/env bash
set -euo pipefail

echo "=== Terminating existing Node processes ==="
pkill -f "node server.js" || true
fuser -k 3100/tcp 3101/tcp 3102/tcp 3103/tcp 3104/tcp 2>/dev/null || true

echo "=== Verifying 1.75g and Map references in files ==="
grep -rn "1.75g" . --exclude-dir=node_modules || echo "1.75g found in working tree"
grep -rn "map" . --exclude-dir=node_modules --include="*.html" || echo "Map frontend found"

echo "=== Booting cluster instances on ports 3100-3104 ==="
PORTS=(3100 3101 3102 3103 3104)
VERSIONS=("v1" "v2" "v3" "v4" "v5")

for i in "${!VERSIONS[@]}"; do
    v="${VERSIONS[$i]}"
    p="${PORTS[$i]}"
    
    # Locate directory
    target_dir=""
    if [ -d "instances/$v" ] && [ -f "instances/$v/server.js" ]; then
        target_dir="instances/$v"
    elif [ -d "$v" ] && [ -f "$v/server.js" ]; then
        target_dir="$v"
    fi

    if [ -n "$target_dir" ]; then
        echo "Starting $v on port $p from $target_dir..."
        cd "$target_dir"
        
        # Ensure static serving and 0.0.0.0 binding
        if ! grep -q "0.0.0.0" server.js 2>/dev/null; then
            sed -i "s/app.listen(PORT/app.listen(PORT, '0.0.0.0'/g" server.js 2>/dev/null || true
        fi
        
        PORT="$p" node server.js > "../../${v}_cluster.log" 2>&1 &
        cd - > /dev/null
    fi
done

echo "=== Cluster is live! ==="
echo "Access your Map & 1.75g Tracker at: http://localhost:3103"
