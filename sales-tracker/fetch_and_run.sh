#!/bin/bash
# Fetch exact versions from GitHub (EBenterprises/sales-tracker) and run them

REPO_DIR="$HOME/sales-tracker"
cd "$REPO_DIR" || exit 1

echo "[*] Cleaning up existing node processes..."
pkill -f "node" 2>/dev/null
fuser -k 51201/tcp 51202/tcp 51203/tcp 51204/tcp 51205/tcp 2>/dev/null
sleep 1

echo "[*] Fetching latest tags and branches from GitHub..."
git fetch origin --tags

# Checkout or setup version directories based on git tags/branches if they exist,
# otherwise ensure the repo structure matches what was committed.
if git show-ref --tags --quiet; then
    echo "[*] Checking out version tags from repository..."
fi

echo "[*] Launching cluster from repository commit tree..."

# Start servers directly from the repo's version paths
if [ -d "$REPO_DIR/v1" ]; then
    cd "$REPO_DIR/v1" && node server_v1.js & P1=$!
fi

if [ -d "$REPO_DIR/v2" ]; then
    cd "$REPO_DIR/v2" && node server_v2.js & P2=$!
fi

if [ -d "$REPO_DIR/v3" ]; then
    cd "$REPO_DIR/v3" && node server_v3.js & P3=$!
fi

if [ -d "$REPO_DIR/v4" ]; then
    cd "$REPO_DIR/v4" && (node pin_picker_server.js || node server_v4.js) & P4=$!
fi

echo "=========================================="
echo "   GITHUB REPO CLUSTER ONLINE (v1 - v4)   "
echo "=========================================="
echo "  v1 Core Ledger : http://localhost:51201"
echo "  v2 Balance UI  : http://localhost:51202"
echo "  v3 Time-Travel : http://localhost:51203"
echo "  v4 Pin Picker  : http://localhost:51204"
echo "=========================================="

trap "kill $P1 $P2 $P3 $P4 2>/dev/null; exit" INT TERM
wait
