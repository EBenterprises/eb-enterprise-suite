#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Launch All Multi-Versions Script
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")

for v in "${VERSIONS[@]}"; do
    echo "[+] Launching $v..."
    ./launch_multiversion.sh "$v"
done

echo "[+] All versions (v1 - v5) successfully deployed and active."
echo "[+] Ports:"
echo "    - v1: http://localhost:3000"
echo "    - v2: http://localhost:3001"
echo "    - v3: http://localhost:3002"
echo "    - v4: http://localhost:3003"
echo "    - v5: http://localhost:3004"
