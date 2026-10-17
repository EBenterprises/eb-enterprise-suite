#!/bin/bash
cd ~/sales-tracker

echo "[*] Killing all node processes..."
pkill -f node || true

echo "[*] Restoring classic V1-V4 server file..."
if [ -f "server_v4.js" ]; then
    cp server_v4.js server.js
    echo "[+] Restored from server_v4.js"
elif [ -f "server_classic.js" ]; then
    cp server_classic.js server.js
    echo "[+] Restored from server_classic.js"
else
    # Let's check git status or git checkout if it's a git repo
    if [ -d ".git" ]; then
        echo "[*] Attempting git checkout of classic server..."
        git checkout HEAD -- server.js 2>/dev/null || true
    fi
fi

echo "[*] Starting classic server..."
if [ -f "server.js" ]; then
    node server.js &
    echo "[+] Server started successfully on classic UI!"
else
    echo "[-] Error: Classic server file not found. Please specify where your V1-V4 server code is located."
fi
