#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Orchestrator Daemon Auto-Start & Service Bridge
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import subprocess

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")

def ensure_daemon_running():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - ORCHESTRATOR DAEMON MANAGER")
    print("=============================================================")
    
    # Check current status
    res = subprocess.run(["./exec-spec", "orchestrate", "status"], cwd=WORKSPACE_DIR, capture_output=True, text=True)
    print(res.stdout.strip())
    
    if "STOPPED" in res.stdout:
        print("[+] Starting orchestrator daemon via master orchestrator...")
        start_res = subprocess.run(["./workspace_master_orchestrator.sh", "start"], cwd=WORKSPACE_DIR, capture_output=True, text=True)
        print(start_res.stdout.strip() or start_res.stderr.strip())
        
        # Verify again
        verify_res = subprocess.run(["./exec-spec", "orchestrate", "status"], cwd=WORKSPACE_DIR, capture_output=True, text=True)
        print(verify_res.stdout.strip())
    else:
        print("[+] Orchestrator daemon is already running.")

    print("=============================================================")

if __name__ == "__main__":
    ensure_daemon_running()
