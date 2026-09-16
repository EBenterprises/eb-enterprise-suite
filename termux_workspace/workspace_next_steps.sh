#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Planning Next Development & Automation Milestones ==="

# 1. Prune redundant fix scripts from working directory
echo "[*] Cleaning up redundant temporary fix scripts..."
rm -f fix_web_ui*.sh continue_workspace.sh

# 2. Ensure cron scheduler and log rotation are tightly bound
echo "[*] Verifying log maintenance and cron scheduling status..."
if ! pgrep -f "run_cron_scheduler.sh" > /dev/null; then
    nohup "${WORKSPACE_DIR}/run_cron_scheduler.sh" > /dev/null 2>&1 &
    echo "[+] Restarted cron scheduler daemon."
else
    echo "[+] Cron scheduler daemon is running cleanly."
fi

# 3. Commit clean state
git add .
if ! git diff --cached --quiet; then
    git commit -m "Milestone cleanup: Pruned temporary scripts and verified daemon stack $(date '+%Y-%m-%d')"
    git push origin main || true
fi

echo "=== Next Milestones Ready ==="
echo "1. Expand Web UI features (add live log tailing viewer via API)."
echo "2. Implement zero-dependency SQLite local store for snippet tagging."
echo "3. Configure automated backup triggers on terminal session exit."
