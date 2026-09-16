#!/bin/bash
echo "[+] Clearing any lingering python instances..."
pkill -9 -f python3 2>/dev/null
sleep 1
echo "[+] Starting Secure Vault on port 5001..."
python3 secure_vault/src/app.py
