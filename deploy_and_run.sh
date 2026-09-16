#!/usr/bin/env bash
set -e

echo "[+] Ensuring Secure Vault directory layout..."
mkdir -p secure_vault/src secure_vault/templates secure_vault/data secure_vault/keys

echo "[+] Stopping any lingering Python/Flask processes..."
pkill -f "app.py" || true
sleep 1

echo "[+] Starting Secure Vault Server..."
cd secure_vault/src
python3 app.py &

echo "[+] Secure Vault is live and running unblocked!"
