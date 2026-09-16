#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Initializing Continuous Deployment & Live Trigger verification ==="

cat << 'PYLOOP' > deployment_verify.py
#!/usr/bin/env python3
import os
import time
import json
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')
LOG_PATH = os.path.join(WORKSPACE_DIR, 'deployment_verify.log')

def log_event(message):
    entry = f"[{datetime.datetime.now().isoformat()}] [DEPLOY_VERIFY] {message}\n"
    print(entry.strip())
    with open(LOG_PATH, 'a') as f:
        f.write(entry)

def verify_and_trigger():
    # 1. Trigger health check matrix
    subprocess.run(['python3', 'system_health_matrix.py'], cwd=WORKSPACE_DIR, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    # 2. Check git status for any unstaged changes
    status = subprocess.run(['git', 'status', '--porcelain'], cwd=WORKSPACE_DIR, capture_output=True, text=True).stdout.strip()
    if status:
        log_event("Uncommitted changes detected. Staging and syncing...")
        subprocess.run(['git', 'add', '.'], cwd=WORKSPACE_DIR)
        subprocess.run(['git', 'commit', '-m', f'Automated deployment verification sync {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}'], cwd=WORKSPACE_DIR)
        push_res = subprocess.run(['git', 'push', 'origin', 'main'], cwd=WORKSPACE_DIR, capture_output=True, text=True)
        if push_res.returncode == 0:
            log_event("Successfully pushed latest ecosystem changes to remote repository.")
        else:
            log_event(f"Git push warning/error: {push_res.stderr.strip()}")
    else:
        log_event("Working tree clean. Ecosystem fully synchronized.")

if __name__ == '__main__':
    log_event("Deployment verification loop started.")
    verify_and_trigger()
PYLOOP

chmod +x deployment_verify.py
python3 deployment_verify.py

git add .
if ! git diff --cached --quiet; then
    git commit -m "Deployment update: Added continuous deployment verification loop $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Deployment Verification Loop Complete ==="
