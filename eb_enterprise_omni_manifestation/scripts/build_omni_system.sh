#!/usr/bin/env bash
set -euo pipefail

echo "================================================================"
echo "      EB ENTERPRISES - OMNI SYSTEM COMPILATION PIPELINE"
echo "================================================================"

WORKSPACE_DIR="$HOME/eb_enterprise_omni_manifestation"
cd "$WORKSPACE_DIR"

echo "[*] Compiling core microkernel & routing modules..."
gcc -O3 src/modules/router.c -o build/omni_router

echo "[*] Executing binary verification..."
./build/omni_router

echo "[*] Triggering automated live asset synchronization..."
if [ -f build/deploy.sh ]; then
    ./build/deploy.sh
fi

echo "================================================================"
echo "      OMNI SYSTEM MANIFESTATION & DEPLOYMENT COMPLETE           "
echo "================================================================"
