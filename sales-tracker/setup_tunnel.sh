#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - LocalTunnel Setup Utility
# ==============================================================================
set -e

PORT=${1:-3000}

echo "[+] Checking for localtunnel (lt)..."
if ! command -v lt &> /dev/null; then
    echo "[+] Installing localtunnel globally..."
    npm install -g localtunnel > /dev/null 2>&1 || npm install localtunnel > /dev/null 2>&1
fi

echo "[+] Establishing secure tunnel for port $PORT..."
echo "[+] Your public URL will appear below once connected:"
npx localtunnel --port "$PORT"
