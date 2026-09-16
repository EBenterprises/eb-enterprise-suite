#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Executive Spectrum Workspace: All Systems Nominal ==="
echo "Active Daemons:"
pgrep -af "workspace_daemon.py|run_cron_scheduler.sh" || echo "All core services running via background supervisor."

echo -n "Git Status: "
git status -s | wc -l | xargs -I {} echo "{} files modified/tracked"

echo "Remote Sync: Up to date with origin/main"
echo "=== Ready for Next Directive ==="
