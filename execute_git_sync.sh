#!/bin/bash

# ==============================================================================
# E&B ENTERPRISES - AUTOMATED GITHUB AUTHENTICATION & FORCE PUSH SCRIPT
# Organization: EBenterprises
# ==============================================================================

set -e

echo "[*] Verifying git remote and current branch status..."
git remote -v
git branch

echo "[*] Executing enterprise forced push to origin main..."
git push -u origin main --force || {
    echo "[!] Push failed due to authentication. Please ensure your GitHub Personal Access Token"
    echo "    or SSH key is loaded in your environment, then execute:"
    echo "    git push -u origin main --force"
    exit 1
}

echo "=========================================================================="
echo "SUCCESS: Enterprise suite successfully synchronized with GitHub!"
echo "=========================================================================="
