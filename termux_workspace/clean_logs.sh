#!/usr/bin/env bash
WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

find . -name "*.log" -mtime +7 -exec rm -f {} +
find . -name "nohup.out" -size +10M -exec truncate -s 0 {} +

if [ -n "$(git status --porcelain)" ]; then
    git add .
    git commit -m "Log maintenance cleanup: $(date '+%Y-%m-%d')"
    git push origin main >/dev/null 2>&1 || true
fi
