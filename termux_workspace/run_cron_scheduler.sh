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
