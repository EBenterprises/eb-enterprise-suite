#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Process & Port Status Inspection
# ==============================================================================
set -e

echo "[+] Checking if node processes are actually alive..."
ps aux | grep node || echo "    -> No node processes found running!"

echo "[+] Checking recent server logs..."
for dir in instances/v*; do
    if [ -f "$dir/server.log" ]; then
        echo "=== $dir/server.log ==="
        tail -n 5 "$dir/server.log"
    fi
done
