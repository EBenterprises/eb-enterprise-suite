#!/bin/bash
PORT="${1:-8080}"
PROJECT_NAME="secure_vault"

echo "[+] Initializing instant public domain tunnel for $PROJECT_NAME..."

# 1. Start local preview server if port is inactive
if ! nc -z localhost "$PORT" 2>/dev/null; then
    echo "[+] Spinning up local HTTP server on port $PORT..."
    python3 -m http.server "$PORT" &
    sleep 1
fi

# 2. Use Cloudflare Quick Tunnels (generates a free, secure *.trycloudflare.com public domain instantly)
if command -v cloudflared &> /dev/null; then
    echo "[+] Opening live Cloudflare public domain..."
    cloudflared tunnel --url "http://localhost:$PORT"
elif command -v npx &> /dev/null; then
    echo "[+] Using LocalTunnel to generate public URL..."
    npx localtunnel --port "$PORT"
else
    echo "[+] Installing cloudflared for instant public domains..."
    pkg install -y cloudflared 2>/dev/null || npm install -g localtunnel 2>/dev/null
    cloudflared tunnel --url "http://localhost:$PORT" || npx localtunnel --port "$PORT"
fi
