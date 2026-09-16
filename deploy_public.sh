#!/bin/bash

echo "[+] Preparing Secure Vault for public deployment..."

# Stop any existing Flask or cloudflared instances
pkill -f "python3 app.py"
pkill -f "cloudflared tunnel"

# Check if app.py exists
if [ ! -f "app.py" ]; then
    echo "[!] Error: app.py not found in current directory."
    exit 1
fi

# Start Flask application in the background with logging
echo "[+] Starting Flask application..."
nohup python3 app.py > flask.log 2>&1 &

# Wait for Flask to spin up on port 5000
sleep 2

if curl -s http://localhost:5000 > /dev/null; then
    echo "[+] Flask application is running successfully."
else
    echo "[!] Flask failed to start. Check flask.log for details."
    exit 1
fi

# Start Cloudflare Tunnel
echo "[+] Opening Cloudflare Tunnel..."
cloudflared tunnel --url http://localhost:5000
