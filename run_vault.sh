#!/usr/bin/env bash
set -e

echo "[+] Terminating existing Flask processes..."
pkill -9 -f "python3 src/app.py" 2>/dev/null || true
fuser -k 5001/tcp 2>/dev/null || true

echo "[+] Ensuring log directory exists..."
mkdir -p logs

echo "[+] Launching Secure Vault application..."
nohup python3 -u src/app.py > logs/vault_runtime.log 2>&1 &

sleep 1
echo "[+] Application active at http://127.0.0.1:5001"
