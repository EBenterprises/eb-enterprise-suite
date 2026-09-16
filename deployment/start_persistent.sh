#!/bin/bash
cd "$(dirname "$0")/.."
pkill -f "python3 src/app.py"
pkill -f "python3 src/app_v2.py"

echo "[*] Initializing Database & Daemons..."
python3 src/db_setup.py

nohup python3 src/app.py > deployment/flask_v1.log 2>&1 &
nohup python3 src/app_v2.py > deployment/flask_v2.log 2>&1 &

echo "[*] Secure Vault v1 (Port 5001) & v2 (Port 5002) running in background."
