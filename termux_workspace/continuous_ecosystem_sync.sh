#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Initializing Continuous Ecosystem Sync & Cron Automation ==="

# 1. Create Cron Auto-Scheduler Script
cat << 'CRONPY' > run_cron_scheduler.sh
#!/usr/bin/env python3
import time
import subprocess
import os

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')

def run_tasks():
    while True:
        try:
            # Run health matrix generation
            subprocess.run(['python3', 'system_health_matrix.py'], cwd=WORKSPACE_DIR, check=True)
            # Run git auto-sync
            subprocess.run(['git', 'add', '.'], cwd=WORKSPACE_DIR, check=True)
            result = subprocess.run(['git', 'diff', '--cached', '--quiet'], cwd=WORKSPACE_DIR)
            if result.returncode != 0:
                subprocess.run(['git', 'commit', '-m', 'Cron auto-sync: health report and log rotation'], cwd=WORKSPACE_DIR, check=True)
                subprocess.run(['git', 'push', 'origin', 'main'], cwd=WORKSPACE_DIR, check=True)
        except Exception as e:
            print(f"[!] Cron task error: {e}")
        time.sleep(600) # Every 10 minutes

if __name__ == '__main__':
    run_tasks()
CRONPY

chmod +x run_cron_scheduler.sh

# 2. Ensure cron scheduler runs in background
if ! pgrep -f "run_cron_scheduler.sh" > /dev/null; then
    nohup python3 run_cron_scheduler.sh > /dev/null 2>&1 &
    echo "[+] Cron scheduler daemon started successfully."
else
    echo "[!] Cron scheduler daemon is already active."
fi

# 3. Final Sync & Commit
git add .
if ! git diff --cached --quiet; then
    git commit -m "Ecosystem continuation: Deployed cron auto-scheduler and background supervisor $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Continuous Ecosystem Automation Fully Synchronized ==="
