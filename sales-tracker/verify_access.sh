#!/bin/bash
echo "[+] Testing local connectivity to cluster ports 3000-3004..."
for port in {3000..3004}; do
    response=$(curl -s -I http://127.0.0.1:$port/ | head -n 1)
    echo "    Port $port -> $response"
done
echo "[+] Verification complete."
