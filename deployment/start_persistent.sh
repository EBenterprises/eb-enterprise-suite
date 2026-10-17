#!/bin/bash
<<<<<<< HEAD
cd "$(dirname "$0")/.."
pkill -f "python3 src/app.py"
pkill -f "python3 src/app_v2.py"

echo "[*] Initializing Database & Daemons..."
python3 src/db_setup.py

nohup python3 src/app.py > deployment/flask_v1.log 2>&1 &
nohup python3 src/app_v2.py > deployment/flask_v2.log 2>&1 &

echo "[*] Secure Vault v1 (Port 5001) & v2 (Port 5002) running in background."
=======
cd ~/secure_vault

pkill -f "python3 src/app.py" || true
pkill -f "ssh.*serveo.net" || true
pkill -f "tor" || true

# Start Tor
tor &>/dev/null &

# Start Flask App
python3 src/app.py >> ~/secure_vault/deployment/server.log 2>&1 &

# Start Public SSH Tunnel and pipe output directly to tunnel_url.log
while true; do
    ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:127.0.0.1:5001 serveo.net > ~/secure_vault/deployment/tunnel_url.log 2>&1
    sleep 10
done &
>>>>>>> origin/main
