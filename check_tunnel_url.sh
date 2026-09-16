#!/bin/bash
echo "[+] Extracting active public domain URL from tunnel logs..."
sleep 2
if [ -f "tunnel.log" ]; then
    grep -o 'https://[-a-z0-9]*\.trycloudflare\.com' tunnel.log | tail -n 1
else
    echo "[-] tunnel.log not found. Run ./daemon_tunnel.sh first."
fi
