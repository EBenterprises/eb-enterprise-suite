#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Git Tracker & Integrity Verification
# ==============================================================================
set -e

cd "$(dirname "$0")/eb-sales-tracker"

if [ ! -d ".git" ]; then
    echo "[+] Initializing Git repository to track file history and prevent unexpected overwrites..."
    git init
    git add .
    git commit -m "Initial baseline commit of EB Sales Tracker"
else
    echo "[+] Git repository already active."
    git status
fi
