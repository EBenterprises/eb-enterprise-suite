#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Database Recovery & Consolidation Utility
# ==============================================================================
set -e

echo "[+] Searching for any backup or historical sales databases..."
find . -name "*.db" -o -name "*.sqlite" -o -name "*.bak"

echo "[+] Checking if any original database exists at root..."
if [ -f "data/sales.db" ]; then
    echo "[+] Found root database! Copying to instances..."
    for v in v1 v2 v3 v4 v5; do
        mkdir -p "instances/$v/data"
        cp "data/sales.db" "instances/$v/data/sales.db"
    echo "[+] Restored root database into instances/$v/data/sales.db"
    done
else
    echo "[!] No root database found. Inspecting git history or backups..."
    git status || true
fi
