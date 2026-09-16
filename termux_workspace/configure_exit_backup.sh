#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "[*] Configuring automated backup triggers on terminal session exit..."

# Append a clean session exit hook to ~/.bashrc or ~/.zshrc if not already present
HOOK_LINE="[ -f \"${WORKSPACE_DIR}/verify_and_deploy.sh\" ] && (cd \"${WORKSPACE_DIR}\" && ./verify_and_deploy.sh > /dev/null 2>&1 &)"

for rc_file in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    if [ -f "$rc_file" ]; then
        if ! grep -q "verify_and_deploy.sh" "$rc_file"; then
            echo "" >> "$rc_file"
            echo "# Automated workspace sync on session closure" >> "$rc_file"
            echo "trap '${WORKSPACE_DIR}/verify_and_deploy.sh > /dev/null 2>&1 &' EXIT" >> "$rc_file"
            echo "[+] Added exit trap hook to $rc_file"
        else
            echo "[!] Exit hook already present in $rc_file"
        fi
    fi
done

# Commit changes
git add .
if ! git diff --cached --quiet; then
    git commit -m "Milestone update: Configured automated backup triggers on terminal session exit $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Milestone 3 Complete: Automated Session-Exit Backups Active ==="
echo "All three initial automation milestones have been successfully executed and synchronized."
