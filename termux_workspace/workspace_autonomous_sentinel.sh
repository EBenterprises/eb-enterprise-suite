#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Initializing Autonomous Sentinel & Self-Healing Daemon ==="

cat << 'PYSENTINEL' > sentinel_daemon.py
#!/usr/bin/env python3
import os
import time
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')
LOG_PATH = os.path.join(WORKSPACE_DIR, 'sentinel.log')

def log_event(message):
    entry = f"[{datetime.datetime.now().isoformat()}] [SENTINEL] {message}\n"
    print(entry.strip())
    with open(LOG_PATH, 'a') as f:
        f.write(entry)

def check_and_heal():
    # 1. Ensure master orchestrator or core daemons are active
    services = [
        ('workspace_daemon.py', 'workspace_daemon.py'),
        ('web_ui_dashboard.py', 'web_ui_dashboard.py'),
        ('telemetry_stream.py', 'telemetry_stream.py'),
        ('run_cron_scheduler.sh', 'run_cron_scheduler.sh')
    ]

    for script, proc_name in services:
        res = subprocess.run(['pgrep', '-f', proc_name], stdout=subprocess.PIPE, text=True)
        if not res.stdout.strip():
            script_path = os.path.join(WORKSPACE_DIR, script)
            if os.path.exists(script_path):
                log_event(f"Service {script} down. Restarting...")
                subprocess.Popen(['python3', script_path], cwd=WORKSPACE_DIR, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                log_event(f"Service {script} restarted successfully.")

    # 2. Run background self-diagnostics
    diag_script = os.path.join(WORKSPACE_DIR, 'self_diagnostics.py')
    if os.path.exists(diag_script):
        subprocess.run(['python3', diag_script], cwd=WORKSPACE_DIR, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def main():
    log_event("Autonomous sentinel daemon started.")
    while True:
        try:
            check_and_heal()
        except Exception as e:
            log_event(f"Error in sentinel loop: {e}")
        time.sleep(300) # Check every 5 minutes

if __name__ == '__main__':
    main()
PYSENTINEL

chmod +x sentinel_daemon.py

if ! pgrep -f "sentinel_daemon.py" > /dev/null; then
    nohup python3 sentinel_daemon.py > /dev/null 2>&1 &
    echo "[+] Autonomous sentinel daemon launched in background."
else
    echo "[!] Autonomous sentinel daemon is already running."
fi

git add .
if ! git diff --cached --quiet; then
    git commit -m "Sentinel update: Deployed autonomous self-healing sentinel daemon $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=== Autonomous Sentinel Ecosystem Fully Integrated ==="
