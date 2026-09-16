#!/usr/bin/env bash
# ==============================================================================
# Executive Spectrum - Backup & Git Sync Utility
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

cd "$HOME/termux_workspace" || exit 1

echo "[+] Initiating immediate workspace sync & backup..."
git add -A
git commit -m "auto-sync: automated state checkpoint $(date +'%Y-%m-%d %H:%M:%S')"
git push origin main
echo "[+] Workspace synchronized successfully."
