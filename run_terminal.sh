#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Automated Terminal Execution
# ==============================================================================
set -e

echo "[+] Executing full-stack deployment validation..."
if [ -f "fix_and_deploy.sh" ]; then
    ./fix_and_deploy.sh
else
    echo "[!] Error: fix_and_deploy.sh not found."
    exit 1
fi
