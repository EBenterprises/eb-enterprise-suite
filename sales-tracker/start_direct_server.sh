#!/usr/bin/env bash
set -euo pipefail

echo "=== Killing all port 3103 processes ==="
fuser -k 3103/tcp 2>/dev/null || true
pkill -f "node server.js" || true

# Find where public/index.html or index.html is located
TARGET_DIR=""
for d in "instances/v4" "v4" "public" "."; do
    if [ -f "$d/index.html" ] || [ -f "$d/public/index.html" ]; then
        TARGET_DIR="$d"
        break
    fi
done

echo "Serving from directory: $TARGET_DIR"
cd "$TARGET_DIR"

# If there's a public folder, cd into it for python serving
if [ -d "public" ]; then
    cd public
fi

echo "=== Launching direct Python server on port 3103 ==="
python3 -m http.server 3103 &
echo "Direct server started!"
