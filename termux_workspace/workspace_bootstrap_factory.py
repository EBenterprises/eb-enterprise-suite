#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Automated Workspace Factory & Scaffolder
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import subprocess

WORKSPACE_DIR = os.path.expanduser("~/termux_workspace")

def create_workspace_structure():
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - WORKSPACE FACTORY SCAFFOLDER")
    print(" EB Enterprises | Automated Terminal Environment")
    print("=============================================================")

    # Ensure base workspace and critical subdirectories exist
    directories = [
        WORKSPACE_DIR,
        os.path.join(WORKSPACE_DIR, ".vault"),
        os.path.join(WORKSPACE_DIR, "plugins"),
        os.path.join(WORKSPACE_DIR, "web_ui"),
        os.path.join(WORKSPACE_DIR, "core_engine"),
        os.path.join(WORKSPACE_DIR, "core_engine", "backend")
    ]

    for d in directories:
        os.makedirs(d, exist_ok=True)
        print(f"  [verified] Directory: {d}")

    # Execute master pipeline to build initial state and verify integrity
    pipeline_script = os.path.join(WORKSPACE_DIR, "workspace_master_pipeline.sh")
    if os.path.exists(pipeline_script):
        print("[+] Executing master pipeline in newly scaffolded workspace...")
        subprocess.run(["bash", pipeline_script], cwd=WORKSPACE_DIR)

    # Run optimizer script
    optimizer_script = os.path.join(WORKSPACE_DIR, "workspace_optimizer.py")
    if os.path.exists(optimizer_script):
        print("[+] Engaging system optimizer...")
        subprocess.run(["python3", optimizer_script], cwd=WORKSPACE_DIR)

    print("=============================================================")
    print("[+] Workspace successfully manufactured, verified, and synchronized.")
    print("=============================================================")

if __name__ == "__main__":
    create_workspace_structure()
