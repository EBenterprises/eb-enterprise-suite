#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Network & Localhost Diagnostics
# ==============================================================================
set -e

PORT=3000

echo "[+] Checking if port $PORT is actively listening..."
ss -tlnp 2>/dev/null || netstat -an 2>/dev/null || true

echo "[+] Testing loopback connectivity with curl..."
if command -v curl &> /dev/null; then
    curl -I "http://127.0.0.1:$PORT" || curl -I "http://localhost:$PORT" || echo "[!] Curl failed to reach local endpoint."
else
    echo "[!] curl not found."
fi

echo "[+] Checking running node server logs for instance v1..."
tail -n 20 instances/v1/server.log 2>/dev/null || tail -n 20 server.log 2>/dev/null || echo "[!] No log found."
