#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Patched Tunnel Utility for Termux
# ==============================================================================
set -e

PORT=${1:-3000}

echo "[+] Locating localtunnel bin..."
LT_BIN=$(npm root -g)/localtunnel/bin/lt.js
OPENURL_JS=$(npm root -g)/localtunnel/node_modules/openurl/openurl.js

if [ -f "$OPENURL_JS" ]; then
    echo "[+] Patching openurl.js for Android/Termux platform compatibility..."
    sed -i "s/throw new Error('Unsupported platform: ' + process.platform);/console.log('Skipping browser open on Android...'); return;/g" "$OPENURL_JS"
fi

echo "[+] Launching secure tunnel for port $PORT..."
node "$LT_BIN" --port "$PORT"
