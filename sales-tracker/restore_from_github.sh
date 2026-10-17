#!/usr/bin/env bash
set -e

PROJECT_DIR="$HOME/sales-tracker"
cd "$PROJECT_DIR"

echo "[1/4] Stopping all running Node processes..."
pkill -9 -f node || true
sleep 1

echo "[2/4] Fetching full commit history and tags from GitHub..."
git fetch origin --tags --force

echo "[3/4] Restoring original server files from remote history..."

# Checkout exact historical files from remote origin
for v in {1..4}; do
    if git cat-file -e "origin/main:server_v${v}.js" 2>/dev/null; then
        git checkout origin/main -- "server_v${v}.js"
        echo "  - Restored server_v${v}.js from origin/main"
    elif git cat-file -e "origin/main:releases/v${v}/server.js" 2>/dev/null; then
        git show "origin/main:releases/v${v}/server.js" > "server_v${v}.js"
        echo "  - Restored server_v${v}.js from origin/main:releases/v${v}/server.js"
    else
        echo "  - Checking git log tags for v${v}..."
        TAG_COMMIT=$(git rev-parse "v${v}" 2>/dev/null || true)
        if [ -n "$TAG_COMMIT" ]; then
            git checkout "$TAG_COMMIT" -- "server_v${v}.js" 2>/dev/null || true
            echo "  - Restored server_v${v}.js from tag v${v}"
        fi
    fi
done

echo "[4/4] Relaunching restored original servers (V1-V4)..."
declare -A PORTS=([1]=51201 [2]=51202 [3]=51203 [4]=51204)

for v in {1..4}; do
    PORT=${PORTS[$v]}
    if [ -f "server_v${v}.js" ]; then
        nohup node "server_v${v}.js" > "logs/server_v${v}.log" 2>&1 &
        echo "  - V${v} running on http://127.0.0.1:${PORT}"
    fi
done

sleep 2
echo "GitHub restoration complete."
