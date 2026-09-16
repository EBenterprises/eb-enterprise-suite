#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Continuous Daemon Health & Activity Monitor
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import time
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
PID_FILE = os.path.expanduser("~/termux_workspace/.vault/orchestrator.pid")
LOG_FILE = os.path.expanduser("~/termux_workspace/daemon_activity.log")

def log_activity(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(LOG_FILE, "a") as f:
        f.write(entry + "\n")

def check_daemons():
    if os.path.exists(PID_FILE):
        with open(PID_FILE, "r") as f:
            pid = f.read().strip()
        if pid.isdigit():
            try:
                os.kill(int(pid), 0)
                return True
            except OSError:
                return False
    return False

def main():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - DAEMON HEALTH & ACTIVITY MONITOR")
    print("=============================================================")
    
    running = check_daemons()
    if running:
        log_activity("Daemon check: OPERATIONAL [Active PID detected]")
    else:
        log_activity("Daemon check: STOPPED [Initializing master orchestrator...]")
        subprocess.run(["./workspace_master_orchestrator.sh", "start"], cwd=WORKSPACE_DIR)
        
    # Run comprehensive verification & version snapshot
    subprocess.run(["python3", "workspace_verify.py"], cwd=WORKSPACE_DIR)
    subprocess.run(["python3", "workspace_version_control.py"], cwd=WORKSPACE_DIR)
    
    log_activity("Monitor cycle completed successfully.")
    print("=============================================================")

if __name__ == "__main__":
    main()
