#!/bin/bash
cd ~/sales-tracker

echo "[*] Killing any running node instances..."
pkill -f node || true

# If server.js is pointing to the wrong wrapper or theme, let's restore the classic multi-version runner or server_v4.js as the main focus
if [ -f "server_v4.js" ]; then
    echo "[*] Restoring classic server implementation..."
    cp server_v4.js server.js
fi

echo "[*] Launching cluster using classic script..."
if [ -f "./run_cluster.sh" ]; then
    ./run_cluster.sh &
else
    node server.js &
fi

echo "[+] Done! Classic V1-V4 environment restored."
