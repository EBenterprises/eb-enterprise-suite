#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
LOG_CLEANUP_SCRIPT="${WORKSPACE_DIR}/clean_logs.sh"
CRON_SCHEDULER_SCRIPT="${WORKSPACE_DIR}/run_cron_scheduler.sh"

cat << 'INNER_EOF' > "$LOG_CLEANUP_SCRIPT"
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
INNER_EOF

chmod +x "$LOG_CLEANUP_SCRIPT"

cat << 'INNER_EOF' > "$CRON_SCHEDULER_SCRIPT"
#!/usr/bin/env bash
LOG_CLEANUP_SCRIPT="${HOME}/termux_workspace/clean_logs.sh"

while true; do
    "$LOG_CLEANUP_SCRIPT"
    sleep 86400
done
INNER_EOF

chmod +x "$CRON_SCHEDULER_SCRIPT"

if ! pgrep -f "run_cron_scheduler.sh" > /dev/null; then
    nohup "$CRON_SCHEDULER_SCRIPT" > /dev/null 2>&1 &
    echo "Termux-compatible background log maintenance scheduler started successfully."
else
    echo "Log maintenance scheduler is already running."
fi
