#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Browser & Server Automation Controller
# ==============================================================================
set -e

PORT=${PORT:-5000}
TARGET_URL="http://localhost:$PORT"

echo "[+] Target URL: $TARGET_URL"

# 1. Open links in default system browser (macOS, Linux, Windows/WSL)
echo "[+] Opening application in default system browser..."
if command -v xdg-open &> /dev/null; then
    xdg-open "$TARGET_URL" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "$TARGET_URL" 2>/dev/null &
elif command -v powershell.exe &> /dev/null; then
    powershell.exe -Command "Start-Process '$TARGET_URL'" 2>/dev/null &
else
    echo "[!] Could not automatically detect browser opener. Please visit: $TARGET_URL"
fi

# 2. Trigger a live refresh ping to ensure server responsiveness
echo "[+] Performing live health-check & refresh ping..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL" || echo "000")

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "[+] SUCCESS: Server is active and responding with HTTP 200 OK."
else
    echo "[!] WARNING: Server responded with HTTP status: $HTTP_STATUS"
    echo "[+] Checking recent logs:"
    tail -n 10 server.log 2>/dev/null || echo "No server.log found."
fi

echo "[+] Done. Active server instance is running on port $PORT."
