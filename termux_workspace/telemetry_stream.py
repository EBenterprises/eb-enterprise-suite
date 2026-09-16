#!/usr/bin/env python3
import os
import time
import json
import datetime
import subprocess

WORKSPACE_DIR = os.path.expanduser('~/termux_workspace')
TELEMETRY_LOG = os.path.join(WORKSPACE_DIR, 'telemetry_stream.jsonl')

def collect_metric():
    load1, load5, load15 = os.getloadavg() if hasattr(os, 'getloadavg') else (0.0, 0.0, 0.0)
    
    # Active process count
    active_procs = len(subprocess.check_output(['ps', 'aux'], text=True).splitlines())
    
    # Git uncommitted changes
    git_status = subprocess.run(['git', 'status', '--porcelain'], cwd=WORKSPACE_DIR, capture_output=True, text=True).stdout.strip()
    dirty_files = len(git_status.splitlines()) if git_status else 0

    metric = {
        "timestamp": datetime.datetime.now().isoformat(),
        "load_avg": [load1, load5, load15],
        "active_processes": active_procs,
        "dirty_git_files": dirty_files
    }
    return metric

def main():
    print("[*] Telemetry stream daemon active. Logging metrics every 60 seconds.")
    while True:
        metric = collect_metric()
        with open(TELEMETRY_LOG, 'a') as f:
            f.write(json.dumps(metric) + '\n')
        time.sleep(60)

if __name__ == '__main__':
    main()
