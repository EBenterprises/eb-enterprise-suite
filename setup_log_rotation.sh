#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
LOG_CLEANUP_SCRIPT="${WORKSPACE_DIR}/clean_logs.sh"

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

CRON_JOB="0 3 * * * ${LOG_CLEANUP_SCRIPT} >/dev/null 2>&1"
(crontab -l 2>/dev/null | grep -v -F "${LOG_CLEANUP_SCRIPT}"; echo "$CRON_JOB") | crontab -

echo "Log rotation and automated cleanup script created and scheduled via cron."
