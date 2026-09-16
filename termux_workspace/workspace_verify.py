#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Comprehensive System Verification Suite
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import subprocess

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")

COMPONENTS = [
    ("Master CLI Wrapper", "exec-spec"),
    ("Status Dashboard", "workspace_status.py"),
    ("Advanced Curses TUI", "executive_tui.py"),
    ("Snippet Manager", "workspace_snippets.py"),
    ("Secure Credential Vault", "workspace_vault.py"),
    ("Master Orchestrator", "workspace_master_orchestrator.sh"),
    ("Module Scaffolder", "new_module.sh"),
    ("Plugin Manager", "workspace_plugins.py"),
    ("Telemetry Analyzer", "workspace_telemetry_analyzer.py"),
    ("Backup & Sync Utility", "workspace_backup_sync.sh"),
]

def run_checks():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - SYSTEM VERIFICATION SUITE")
    print("=============================================================")
    
    all_passed = True
    for name, filename in COMPONENTS:
        filepath = os.path.join(WORKSPACE_DIR, filename)
        exists = os.path.exists(filepath)
        executable = os.access(filepath, os.X_OK) if exists else False
        
        status = "[PASSED]"
        details = "OK"
        
        if not exists:
            status = "[FAILED]"
            details = "File missing"
            all_passed = False
        elif not executable and filename.endswith((".py", ".sh", "exec-spec")):
            status = "[WARNING]"
            details = "Not marked executable"
            
        print(f"  {status:<10} {name} ({filename}) - {details}")

    print("=============================================================")
    if all_passed:
        print("[+] All core workspace components verified successfully.")
    else:
        print("[-] Verification completed with errors. Check missing files.")
        sys.exit(1)

if __name__ == "__main__":
    run_checks()
