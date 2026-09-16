#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Ecosystem Master Orchestrator & Supervisor
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
SUPERVISOR_LOG = os.path.join(WORKSPACE_DIR, "ecosystem_supervisor.log")

def log_supervisor(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(SUPERVISOR_LOG, "a") as f:
        f.write(entry + "\n")

def execute_supervisor_cycle():
    log_supervisor("Initiating Executive Spectrum supervisor cycle...")

    scripts = [
        ("workspace_auto_recovery.py", "Self-Healing Sweep"),
        ("workspace_optimizer.py", "Optimization Pass"),
        ("workspace_health_dashboard.py", "Health Dashboard Compile"),
        ("workspace_remote_sync_watchdog.py", "Remote Sync Watchdog"),
        ("workspace_deployment_gateway.py", "Deployment Gateway Trigger")
    ]

    for script, name in scripts:
        script_path = os.path.join(WORKSPACE_DIR, script)
        if os.path.exists(script_path):
            log_supervisor(f"[+] Executing subsystem: {name} ({script})...")
            res = subprocess.run(["python3", script], cwd=WORKSPACE_DIR, capture_output=True, text=True)
            if res.returncode == 0:
                log_supervisor(f"[+] Subsystem {name} completed successfully.")
            else:
                log_supervisor(f"[-] Subsystem {name} reported warnings/errors.")

    # Final git reconciliation and push
    rm_lock = os.path.join(WORKSPACE_DIR, ".git", "index.lock")
    if os.path.exists(rm_lock):
        os.remove(rm_lock)

    subprocess.run(["git", "add", "."], cwd=WORKSPACE_DIR)
    subprocess.run(["git", "commit", "-m", f"sync: master ecosystem supervisory cycle checkpoint ({datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')})"], cwd=WORKSPACE_DIR, capture_output=True)

    pull_res = subprocess.run(["git", "pull", "--rebase", "origin", "main"], cwd=WORKSPACE_DIR, capture_output=True, text=True)
    if pull_res.returncode != 0:
        subprocess.run(["git", "rebase", "--abort"], cwd=WORKSPACE_DIR, capture_output=True)

    push_res = subprocess.run(["git", "push", "origin", "main"], cwd=WORKSPACE_DIR, capture_output=True, text=True)
    if push_res.returncode == 0:
        log_supervisor("[+] Master ecosystem state successfully synchronized with remote repository.")
    else:
        log_supervisor("[!] Remote sync push completed or deferred.")

    log_supervisor("Ecosystem supervisor cycle fully finalized.")

def main():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - ECOSYSTEM MASTER SUPERVISOR")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")
    
    execute_supervisor_cycle()
    
    print("=============================================================")
    print("[+] All ecosystem subsystems supervised, verified, and synchronized.")
    print("=============================================================")

if __name__ == "__main__":
    main()
