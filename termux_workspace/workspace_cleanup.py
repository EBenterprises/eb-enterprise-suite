#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Workspace Cache & Diagnostic Cleanup Utility
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import shutil

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")

def cleanup():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - CLEANUP UTILITY")
    print("=============================================================")
    
    # Remove pycache directories
    for root, dirs, files in os.walk(WORKSPACE_DIR):
        if "__pycache__" in dirs:
            cache_path = os.path.join(root, "__pycache__")
            shutil.rmtree(cache_path)
            print(f"  [removed] {cache_path}")

    # Remove temporary diagnostic/stream files
    temp_files = ["diagnostic_report.json", "telemetry_stream.jsonl"]
    for tf in temp_files:
        tf_path = os.path.join(WORKSPACE_DIR, tf)
        if os.path.exists(tf_path):
            os.remove(tf_path)
            print(f"  [removed] {tf_path}")

    print("=============================================================")
    print("[+] Workspace cleaned successfully.")

if __name__ == "__main__":
    cleanup()
