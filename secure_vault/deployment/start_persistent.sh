#!/bin/bash
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
