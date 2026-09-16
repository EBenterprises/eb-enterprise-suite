#!/bin/bash
echo "[+] Cleaning up existing processes..."
fuser -k 5000/tcp 2>/dev/null
fuser -k 5001/tcp 2>/dev/null
pkill -f "python.*app.py" 2>/dev/null

cd secure_vault_public
rm -f flask_run.log

python3 app.py > flask_run.log 2>&1 &
FLASK_PID=$!

echo "[+] Waiting for Flask to bind..."
PORT=""
for i in {1..10}; do
    if grep -q "Running on http://" flask_run.log 2>/dev/null; then
        PORT=$(grep -oE "http://[^[:space:]]+" flask_run.log | grep -oE "[0-9]+$" | head -n 1)
        break
    fi
    sleep 0.5
done

if [ -z "$PORT" ]; then
    PORT="5001"
fi

echo "[+] Flask detected running on port $PORT. Launching Cloudflare Tunnel..."
cloudflared tunnel --url http://localhost:$PORT &
TUNNEL_PID=$!

trap "kill $FLASK_PID $TUNNEL_PID 2>/dev/null; rm -f flask_run.log" EXIT
wait
