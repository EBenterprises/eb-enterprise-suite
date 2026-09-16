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
