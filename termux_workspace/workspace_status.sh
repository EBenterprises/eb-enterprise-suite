#!/usr/bin/env bash
WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

while true; do
    if [ -n "$(git status --porcelain)" ]; then
        git add .
        git commit -m "Daemon auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
        git push origin main >/dev/null 2>&1 || true
    fi
    sleep 300
done
