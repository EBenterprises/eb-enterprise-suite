#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Remote Sync Watchdog & Bi-directional Bridge
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")
WATCHDOG_LOG = os.path.join(WORKSPACE_DIR, "watchdog.log")

def log_watchdog(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(WATCHDOG_LOG, "a") as f:
        f.write(entry + "\n")

def check_remote_sync():
    log_watchdog("Initiating bi-directional remote sync verification...")
    
    # Fetch latest remote changes without merging
    fetch_res = subprocess.run(["git", "fetch", "origin", "main"], cwd=WORKSPACE_DIR, capture_output=True, text=True)
    if fetch_res.returncode != 0:
        log_watchdog(f"[-] Git fetch warning: {fetch_res.stderr.strip()}")
        return

    # Check divergence between local and remote
    status_res = subprocess.run(["git", "status", "-sb"], cwd=WORKSPACE_DIR, capture_output=True, text=True)
    output = status_res.stdout.strip()
    log_watchdog(f"Branch status: {output}")

    if "behind" in output:
        log_watchdog("[!] Local workspace is behind remote. Pulling latest updates with rebase...")
        pull_res = subprocess.run(["git", "pull", "--rebase", "origin", "main"], cwd=WORKSPACE_DIR, capture_output=True, text=True)
        if pull_res.returncode == 0:
            log_watchdog("[+] Successfully synchronized remote updates.")
        else:
            log_watchdog(f"[-] Rebase conflict detected: {pull_res.stderr.strip()}")
            subprocess.run(["git", "rebase", "--abort"], cwd=WORKSPACE_DIR)
    elif "ahead" in output:
        log_watchdog("[+] Local workspace has unpushed commits. Pushing to origin main...")
        push_res = subprocess.run(["git", "push", "origin", "main"], cwd=WORKSPACE_DIR, capture_output=True, text=True)
        if push_res.returncode == 0:
            log_watchdog("[+] Remote repository successfully updated.")
        else:
            log_watchdog(f"[-] Push warning: {push_res.stderr.strip()}")
    else:
        log_watchdog("[+] Local and remote repositories are fully synchronized.")

def main():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - REMOTE SYNC WATCHDOG")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")
    
    check_remote_sync()
    
    # Stage log updates and push
    subprocess.run(["git", "add", "watchdog.log"], cwd=WORKSPACE_DIR)
    subprocess.run(["git", "commit", "-m", "chore: update remote sync watchdog telemetry"], cwd=WORKSPACE_DIR, capture_output=True)
    subprocess.run(["git", "push", "origin", "main"], cwd=WORKSPACE_DIR, capture_output=True)
    
    print("=============================================================")
    print("[+] Watchdog telemetry recorded and synchronized.")
    print("=============================================================")

if __name__ == "__main__":
    main()
