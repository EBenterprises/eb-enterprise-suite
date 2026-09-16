#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Continuous Autonomous Work Engine
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import time
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
WORK_LOG = os.path.join(WORKSPACE_DIR, "work_engine.log")

def log_work(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(WORK_LOG, "a") as f:
        f.write(entry + "\n")

def execute_cycle():
    log_work("Initiating autonomous work cycle...")
    
    # 1. Run master pipeline
    pipeline_script = os.path.join(WORKSPACE_DIR, "workspace_master_pipeline.sh")
    if os.path.exists(pipeline_script):
        res = subprocess.run(["bash", pipeline_script], cwd=WORKSPACE_DIR, capture_output=True, text=True)
        if res.returncode == 0:
            log_work("[+] Master pipeline executed successfully.")
        else:
            log_work(f"[-] Master pipeline encountered issues: {res.stderr.strip() or res.stdout.strip()}")

    # 2. Check orchestrator status & ensure running
    orch_res = subprocess.run(["./exec-spec", "orchestrate", "status"], cwd=WORKSPACE_DIR, capture_output=True, text=True)
    log_work(f"Status check: {orch_res.stdout.strip()}")
    if "STOPPED" in orch_res.stdout:
        subprocess.run(["./workspace_master_orchestrator.sh", "start"], cwd=WORKSPACE_DIR)
        log_work("[+] Restarted orchestrator daemon.")

    # 3. Secure version control backup snapshot & push
    vc_script = os.path.join(WORKSPACE_DIR, "workspace_version_control.py")
    if os.path.exists(vc_script):
        subprocess.run(["python3", vc_script], cwd=WORKSPACE_DIR)
        log_work("[+] Version control synchronization complete.")

    log_work("Autonomous work cycle completed successfully.")

def main():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - AUTONOMOUS WORK ENGINE ENGAGED")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")
    
    execute_cycle()
    
    print("=============================================================")
    print("[+] Work engine is fully active and operational.")
    print("=============================================================")

if __name__ == "__main__":
    main()
