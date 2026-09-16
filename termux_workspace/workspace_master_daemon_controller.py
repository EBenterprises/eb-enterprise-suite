#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Master Daemon & Continuous Loop Controller
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import time
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
CONTROLLER_LOG = os.path.join(WORKSPACE_DIR, "master_controller.log")

def log_controller(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(CONTROLLER_LOG, "a") as f:
        f.write(entry + "\n")

def run_loop():
    log_controller("Initiating Master Continuous Control Loop...")
    
    while True:
        log_controller("--- Starting Autonomous Executive Cycle ---")
        
        # 1. Self-healing pass
        subprocess.run(["python3", "workspace_auto_recovery.py"], cwd=WORKSPACE_DIR, capture_output=True)
        log_controller("[+] Self-healing and recovery pass complete.")
        
        # 2. Optimization pass
        subprocess.run(["python3", "workspace_optimizer.py"], cwd=WORKSPACE_DIR, capture_output=True)
        log_controller("[+] System optimization sweep complete.")
        
        # 3. Health check dashboard update
        subprocess.run(["python3", "workspace_health_dashboard.py"], cwd=WORKSPACE_DIR, capture_output=True)
        log_controller("[+] Health dashboard refreshed.")
        
        # 4. Git sync state push
        subprocess.run(["git", "add", "."], cwd=WORKSPACE_DIR)
        subprocess.run(["git", "commit", "-m", f"sync: master automated control cycle checkpoint ({datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')})"], cwd=WORKSPACE_DIR, capture_output=True)
        
        pull_res = subprocess.run(["git", "pull", "--rebase", "origin", "main"], cwd=WORKSPACE_DIR, capture_output=True)
        if pull_res.returncode != 0:
            subprocess.run(["git", "rebase", "--abort"], cwd=WORKSPACE_DIR, capture_output=True)
            
        subprocess.run(["git", "push", "origin", "main"], cwd=WORKSPACE_DIR, capture_output=True)
        log_controller("[+] Remote repository state synchronized.")
        
        log_controller("--- Cycle complete. Sleeping for 300 seconds ---")
        time.sleep(300)

if __name__ == "__main__":
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - MASTER DAEMON CONTROLLER")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")
    
    # Run once interactively or spawn
    run_loop()
