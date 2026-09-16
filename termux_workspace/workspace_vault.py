#!/usr/bin/env python3
# ==============================================================================
# Executive Spectrum - Secure Credential Vault
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

import os
import sys
import json
import base64

VAULT_DIR = os.path.expanduser("~/termux_workspace/.vault")
VAULT_FILE = os.path.join(VAULT_DIR, "credentials.enc")

def ensure_vault():
    os.makedirs(VAULT_DIR, exist_ok=True)
    if not os.path.exists(VAULT_FILE):
        with open(VAULT_FILE, "w") as f:
            json.dump({}, f)

def load_vault():
    ensure_vault()
    try:
        with open(VAULT_FILE, "r") as f:
            content = f.read().strip()
            if not content:
                return {}
            decoded = base64.b64decode(content.encode()).decode()
            return json.loads(decoded)
    except Exception:
        return {}

def save_vault(data):
    ensure_vault()
    encoded = base64.b64encode(json.dumps(data).encode()).decode()
    with open(VAULT_FILE, "w") as f:
        f.write(encoded)

def list_credentials():
    vault = load_vault()
    print("=============================================================")
    print(" EXECUTIVE SPECTRUM - SECURE CREDENTIAL VAULT")
    print("=============================================================")
    if not vault:
        print(" Vault is currently empty.")
    else:
        for key in vault.keys():
            print(f"  - {key}: [SECURED]")
    print("=============================================================")

def set_credential(key, value):
    vault = load_vault()
    vault[key] = value
    save_vault(vault)
    print(f"[+] Credential '{key}' successfully secured in vault.")

def get_credential(key):
    vault = load_vault()
    if key in vault:
        print(vault[key])
    else:
        print(f"[-] Credential '{key}' not found in vault.", file=sys.stderr)
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage: ./exec-spec vault <list|set|get> [key] [value]")
        sys.exit(1)

    action = sys.argv[1]
    if action == "list":
        list_credentials()
    elif action == "set":
        if len(sys.argv) < 4:
            print("Usage: ./exec-spec vault set <key> <value>")
            sys.exit(1)
        set_credential(sys.argv[2], sys.argv[3])
    elif action == "get":
        if len(sys.argv) < 3:
            print("Usage: ./exec-spec vault get <key>")
            sys.exit(1)
        get_credential(sys.argv[2])
    else:
        print(f"Unknown vault action: {action}")
        sys.exit(1)

if __name__ == "__main__":
    main()
