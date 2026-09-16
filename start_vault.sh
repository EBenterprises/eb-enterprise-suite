#!/bin/bash

APP_FILE="app.py"
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/vault_app.log"

mkdir -p "$LOG_DIR"

if [ ! -f "$APP_FILE" ]; then
    echo "Error: $APP_FILE not found in the current directory."
    exit 1
fi

# Extract the port number directly from app.py
PORT=$(grep -oE 'port=[0-9]+' "$APP_FILE" | head -n 1 | cut -d'=' -f2)
if [ -z "$PORT" ]; then
    PORT=5001
fi

# Cleanly kill any process currently hogging this specific port or app instance
echo "Checking for existing instances on port $PORT..."
fuser -k "${PORT}/tcp" 2>/dev/null || true
pkill -f "python3 $APP_FILE" 2>/dev/null || true
sleep 1

echo "Starting Secure Vault application on port $PORT..."
nohup python3 "$APP_FILE" > "$LOG_FILE" 2>&1 &
PID=$!

sleep 1
if ps -p $PID > /dev/null; then
    echo "Success! Application running with PID $PID."
    URL="http://127.0.0.1:$PORT"
    echo "Access your vault login at: $URL"
    
    if command -v termux-open-url >/dev/null 2>&1; then
        termux-open-url "$URL"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$URL"
    elif command -v open >/dev/null 2>&1; then
        open "$URL"
    fi
else
    echo "Error: Application failed to start. Check logs below:"
    cat "$LOG_FILE"
fi
