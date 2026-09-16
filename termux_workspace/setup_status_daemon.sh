#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
STATUS_SCRIPT="${WORKSPACE_DIR}/workspace_status.sh"

cat << 'INNER_EOF' > "$STATUS_SCRIPT"
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
INNER_EOF

chmod +x "$STATUS_SCRIPT"

if ! pgrep -f "workspace_status.sh" > /dev/null; then
    nohup "$STATUS_SCRIPT" > /dev/null 2>&1 &
    echo "Background workspace sync daemon started successfully (runs every 5 minutes)."
else
    echo "Background workspace sync daemon is already running."
fi
