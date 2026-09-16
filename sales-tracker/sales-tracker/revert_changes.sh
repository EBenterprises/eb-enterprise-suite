#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Revert Utility
# ==============================================================================
set -e

echo "[+] Checking git status..."
git status || true

echo "[+] Reverting recent changes to public/index.html and server.js..."
git checkout . || echo "No git tracking for some files."

# Alternatively, restore previous instance states if git reset is clean
git reset --hard HEAD || echo "No previous git commit to hard reset to."

echo "[+] Restarting all server instances..."
pkill -f "node" 2>/dev/null || true
sleep 1

VERSIONS=("v1" "v2" "v3" "v4" "v5")
PORTS=(3000 3001 3002 3003 3004)

for i in "${!VERSIONS[@]}"; do
    V="${VERSIONS[$i]}"
    P="${PORTS[$i]}"
    DIR="instances/$V"
    if [ -d "$DIR" ] && [ -f "$DIR/server.js" ]; then
        cd "$DIR"
        nohup node server.js > server.log 2>&1 &
        cd - > /dev/null
        echo "    -> Restarted $V on port $P"
    fi
done

echo "[+] Revert complete."
