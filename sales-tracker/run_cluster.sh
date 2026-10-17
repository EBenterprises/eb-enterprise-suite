#!/bin/bash
# Clean cluster startup script for V1-V4

echo "[*] Cleaning up existing node processes..."
pkill -f node || true

echo "[*] Starting main server..."
if [ -f "server.js" ]; then
    # Ensure server.js doesn't have stray javascript declarations if it was overwritten
    node server.js &
else
    echo "[-] server.js not found!"
fi

echo "[+] Cluster runner active."
