#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Initializing Continuous Background Daemon & Supervisor ==="

cat << 'PYDAEMON' > workspace_daemon.py
#!/usr/bin/env python3
import os
import time
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')
LOG_PATH = os.path.join(WORKSPACE_DIR, 'workspace_daemon.log')

def log_event(message):
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    entry = f"[{timestamp}] {message}\n"
    print(entry.strip())
    with open(LOG_PATH, 'a') as f:
        f.write(entry)

def check_git_changes():
    try:
        status_output = subprocess.check_output(['git', 'status', '--porcelain'], cwd=WORKSPACE_DIR, text=True)
        if status_output.strip():
            log_event("Uncommitted changes detected. Auto-staging and syncing...")
            subprocess.run(['git', 'add', '.'], cwd=WORKSPACE_DIR, check=True)
            subprocess.run(['git', 'commit', '-m', f"Auto-daemon sync: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"], cwd=WORKSPACE_DIR, check=True)
            subprocess.run(['git', 'push', 'origin', 'main'], cwd=WORKSPACE_DIR, check=True)
            log_event("Auto-sync completed successfully.")
    except Exception as e:
        log_event(f"Error during git sync check: {e}")

def main():
    log_event("Workspace background supervisor daemon started.")
    while True:
        check_git_changes()
        time.sleep(300) # Check every 5 minutes

if __name__ == '__main__':
    main()
PYDAEMON

chmod +x workspace_daemon.py

# Ensure daemon runs cleanly in background
if ! pgrep -f "workspace_daemon.py" > /dev/null; then
    nohup python3 workspace_daemon.py > /dev/null 2>&1 &
    echo "[+] Continuous workspace daemon launched in background."
else
    echo "[!] Workspace daemon is already active."
fi

git add .
if ! git diff --cached --quiet; then
    git commit -m "Milestone update: Deployed continuous workspace background supervisor daemon $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Continuous Automation Suite Fully Deployed & Operational ==="
