<<<<<<< HEAD
#!/bin/bash
cd "$(dirname "$0")"

echo "[+] Terminating existing Flask processes..."
pkill -f "python3 src/app.py" 2>/dev/null || true
=======
#!/usr/bin/env bash
set -e

echo "[+] Terminating existing Flask processes..."
pkill -9 -f "python3 src/app.py" 2>/dev/null || true
fuser -k 5001/tcp 2>/dev/null || true
>>>>>>> origin/main

echo "[+] Ensuring log directory exists..."
mkdir -p logs

echo "[+] Launching Secure Vault application..."
<<<<<<< HEAD
nohup python3 src/app.py > logs/vault.log 2>&1 &
=======
nohup python3 -u src/app.py > logs/vault_runtime.log 2>&1 &
>>>>>>> origin/main

sleep 1
echo "[+] Application active at http://127.0.0.1:5001"
