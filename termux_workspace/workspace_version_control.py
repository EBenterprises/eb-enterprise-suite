#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Comprehensive Version Control & Snapshot Utility
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import subprocess
import datetime

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")

def run_git_command(args):
    result = subprocess.run(["git"] + args, cwd=WORKSPACE_DIR, capture_output=True, text=True)
    return result.returncode, result.stdout.strip(), result.stderr.strip()

def snapshot_workspace():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - COMPREHENSIVE VERSION CONTROL SNAPSHOT")
    print("=============================================================")

    # Run cleanup first to eliminate stray cache files
    cleanup_script = os.path.join(WORKSPACE_DIR, "workspace_cleanup.py")
    if os.path.exists(cleanup_script):
        print("[+] Running workspace cleanup pre-snapshot...")
        subprocess.run(["python3", cleanup_script], cwd=WORKSPACE_DIR)

    # Stage all changes
    code, out, err = run_git_command(["add", "-A"])
    if code != 0:
        print(f"[-] Git add failed: {err}")
        return

    # Check status
    code, status_out, err = run_git_command(["status", "--porcelain"])
    if not status_out:
        print("[+] Workspace is already fully version-controlled and clean.")
        print("=============================================================")
        return

    # Commit with timestamp
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    commit_msg = f"snapshot: comprehensive automated state backup ({timestamp})"
    code, out, err = run_git_command(["commit", "-m", commit_msg])
    
    if code == 0:
        print(f"[+] Successfully committed changes: {commit_msg}")
    else:
        print(f"[-] Commit note: {out or err}")

    # Push to origin main
    print("[+] Pushing snapshots to remote repository (origin main)...")
    code, out, err = run_git_command(["push", "origin", "main"])
    if code == 0:
        print("[+] Remote repository successfully synchronized.")
    else:
        print(f"[-] Push warning/error: {err or out}")

    print("=============================================================")

if __name__ == "__main__":
    snapshot_workspace()
