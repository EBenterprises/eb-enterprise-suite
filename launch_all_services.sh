#!/usr/bin/env bash

echo "=== 1. CHECKING FULL WORKSPACE DIRECTORIES ==="
ls -la

echo "=== 2. FINDING ALL ACTIVE SERVER & UI ENTRY POINTS ==="
find . -maxdepth 3 \( -name "server.js" -o -name "app.js" -o -name "app.py" -o -name "index.html" \) | grep -v "node_modules"

echo "=== 3. LAUNCHING MAIN ECOSYSTEM & SALES TRACKER CLUSTER ==="
if [ -f "sales-tracker/cluster_server.js" ]; then
    node sales-tracker/cluster_server.js
elif [ -f "cluster_server.js" ]; then
    node cluster_server.js
elif [ -f "server.js" ]; then
    node server.js
else
    node sales-tracker/server.js
fi
