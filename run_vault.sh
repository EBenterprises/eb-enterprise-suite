#!/bin/bash
cd "$(dirname "$0")"

echo "[+] Terminating existing Flask processes..."
pkill -f "python3 src/app.py" 2>/dev/null || true

echo "[+] Ensuring log directory exists..."
mkdir -p logs

echo "[+] Launching Secure Vault application..."
nohup python3 src/app.py > logs/vault.log 2>&1 &

sleep 1
echo "[+] Application active at http://127.0.0.1:5001"
