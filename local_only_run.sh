#!/bin/bash
PROJECT_NAME="secure_vault"
echo "[+] Disconnecting from GitHub pipelines and restoring pure local-first operation..."

# 1. Clean up local git remotes if desired, or keep them locally unlinked
git remote remove origin-a 2>/dev/null || true
git remote remove origin-b 2>/dev/null || true
git remote remove origin 2>/dev/null || true

# 2. Revert any temporary placeholder files and restore original working state
git checkout HEAD -- . 2>/dev/null || true
rm -f index.html 2>/dev/null

echo "[+] Local environment reset to original project state."
echo "[+] To run your app locally without any remote interference, start your application entry point directly."
