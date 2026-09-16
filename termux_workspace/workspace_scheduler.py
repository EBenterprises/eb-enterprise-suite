#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Automated Background Task Scheduler & Cron Bridge
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import time
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
SCHEDULER_LOG = os.path.join(WORKSPACE_DIR, "scheduler.log")

def log_task(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(SCHEDULER_LOG, "a") as f:
        f.write(entry + "\n")

def run_task(name, script):
    log_task(f"Starting scheduled task: {name}")
    script_path = os.path.join(WORKSPACE_DIR, script)
    if not os.path.exists(script_path):
        log_task(f"[-] Task script missing: {script}")
        return
    
    ext = script.split('.')[-1]
    if ext == "py":
        res = subprocess.run(["python3", script_path], cwd=WORKSPACE_DIR, capture_output=True, text=True)
    elif ext == "sh":
        res = subprocess.run(["bash", script_path], cwd=WORKSPACE_DIR, capture_output=True, text=True)
    else:
        log_task(f"[-] Unknown script extension: {ext}")
        return

    if res.returncode == 0:
        log_task(f"[+] Task completed successfully: {name}")
    else:
        log_task(f"[-] Task failed ({name}): {res.stderr.strip() or res.stdout.strip()}")

def main():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - AUTOMATED TASK SCHEDULER")
    print("=============================================================")
    
    # Execute maintenance pipeline
    run_task("System Verification", "workspace_verify.py")
    run_task("Telemetry Matrix", "workspace_status_matrix.py")
    run_task("Daemon Monitor", "workspace_daemon_monitor.py")
    run_task("Version Control Snapshot", "workspace_version_control.py")
    
    log_task("Scheduler execution loop finished.")
    print("=============================================================")

if __name__ == "__main__":
    main()
