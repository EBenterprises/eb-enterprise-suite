#!/usr/bin/env python3
import os
import subprocess

def run_script(script_path):
    print(f"\n[*] Executing: {script_path}")
    result = subprocess.run(["python3", script_path], capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(f"[-] Errors:\n{result.stderr}")

if __name__ == "__main__":
    print("========================================")
    print("      SECURE VAULT AUTOMATION PIPELINE   ")
    print("========================================")
    
    # Step 1: Provision vault directories, keys, and DB
    run_script("secure_vault/src/provision_vault.py")
    
    # Step 2: Encrypt sample payload
    run_script("secure_vault/src/encrypt_payload.py")
    
    # Step 3: Log transaction record
    run_script("secure_vault/src/log_transaction.py")
    
    print("========================================")
    print("[+] Pipeline execution complete.")
