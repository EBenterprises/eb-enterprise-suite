#!/bin/bash
cd ~/sales-tracker

echo "[*] Killing all Node processes and removing unwanted scripts..."
pkill -f node || true
pkill -f "v5_server.js" || true

# Let's locate where your classic v1-v4 server or index.js files are, or check if server.js needs to be your v1-v4 runner
if [ -f "server.js" ]; then
    # Ensure it's not a symlink to v5 or contains executive spectrum
    if grep -q "EXECUTIVE SPECTRUM" server.js; then
        echo "[-] server.js contains Executive Spectrum. Resetting or searching for classic runner..."
        if [ -f "server_classic.js" ]; then
            cp server_classic.js server.js
        elif [ -f "server_v4.js" ]; then
            cp server_v4.js server.js
        fi
    fi
fi

echo "[*] Starting the V1-V4 cluster or server..."
if [ -f "run_cluster.sh" ]; then
    # Check if run_cluster.sh references v5_server.js and strip it if needed
    sed -i '/v5_server.js/d' run_cluster.sh
    chmod +x run_cluster.sh
    ./run_cluster.sh &
else
    node server.js &
fi

echo "[+] Done! V1-V4 environment initialized."
