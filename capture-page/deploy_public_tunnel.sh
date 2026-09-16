#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Public Tunnel & Live Link Deployment
# ==============================================================================
set -e

PORT=${PORT:-5000}

echo "[+] Preparing public tunnel infrastructure for port $PORT..."

# Check if local app is running, start if not
if ! curl -s "http://localhost:$PORT" > /dev/null; then
    echo "[+] Starting local server instance..."
    node server.js > server.log 2>&1 &
    sleep 2
fi

echo "[+] Executing direct npx localtunnel invocation..."
rm -f public_url.log
npx -y localtunnel --port "$PORT" > public_url.log 2>&1 &
TUNNEL_PID=$!

# Wait for localtunnel to output URL
PUBLIC_URL=""
for i in {1..10}; do
    sleep 1
    if [ -f public_url.log ]; then
        PUBLIC_URL=$(grep -o 'https://[a-z0-9.-]*localtunnel\.me' public_url.log || true)
        if [ -n "$PUBLIC_URL" ]; then
            break
        fi
    fi
done

echo ""
echo "=================================================="
if [ -n "$PUBLIC_URL" ]; then
    echo "🌍 [SUCCESS] PUBLIC LINK GENERATED:"
    echo "    $PUBLIC_URL"
    echo ""
    echo "    (Tunnel PID: $TUNNEL_PID - keep terminal active)"
else
    echo "[!] Tunnel failed to initialize within time limit."
    echo "[+] Run manually: npx localtunnel --port $PORT"
    PUBLIC_URL="http://localhost:$PORT"
fi
echo "=================================================="
echo ""

# Open link in browser
if command -v xdg-open &> /dev/null; then
    xdg-open "$PUBLIC_URL" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "$PUBLIC_URL" 2>/dev/null &
elif command -v powershell.exe &> /dev/null; then
    powershell.exe -Command "Start-Process '$PUBLIC_URL'" 2>/dev/null &
fi

echo "[+] Done."
