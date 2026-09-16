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
