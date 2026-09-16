#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Link Opener & Verification Utility
# ==============================================================================
set -e

URLS=(
    "http://localhost:3000"
    "http://localhost:3001"
    "http://localhost:3002"
    "http://localhost:3003"
    "http://localhost:3004"
)

echo "[+] Opening all deployed version links..."

for url in "${URLS[@]}"; do
    echo "[+] Accessing: $url"
    if command -v xdg-open &> /dev/null; then
        xdg-open "$url"
    elif command -v open &> /dev/null; then
        open "$url"
    elif command -v curl &> /dev/null; then
        curl -s -o /dev/null "$url" && echo "    -> Verified reachable via curl."
    else
        echo "    -> Please open $url manually."
    fi
done

echo "[+] Link opening sequence completed."
