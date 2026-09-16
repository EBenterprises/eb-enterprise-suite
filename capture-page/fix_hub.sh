#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Hub Diagnostics & Repair Engine
# ==============================================================================
set -e

PORT=5000

echo "[+] Diagnosing current environment and server state..."

# Kill any rogue node processes holding port 5000
pkill -f "node" 2>/dev/null || true
sleep 1

# Ensure package.json exists with express and mongoose dependencies
if [ ! -f package.json ]; then
    echo "[+] Initializing package.json..."
    cat << 'PKG_EOF' > package.json
{
  "name": "eb-multi-capture-hub",
  "version": "1.0.0",
  "description": "EB Enterprises Multi-Template Hub",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^8.0.0"
  }
}
PKG_EOF
fi

echo "[+] Verifying node modules..."
if [ ! -d node_modules ]; then
    npm install --no-audit --no-fund
fi

echo "[+] Restarting server cleanly..."
PORT=$PORT nohup node server.js > server.log 2>&1 &
sleep 2

# Verify server health
if curl -s "http://localhost:$PORT/api/templates" > /dev/null; then
    echo "[+] Server responded successfully on port $PORT."
else
    echo "[!] Server check failed. Displaying server.log:"
    cat server.log
    exit 1
fi

echo "[+] Launching fresh LocalTunnel instance..."
rm -f public_url.log
npx -y localtunnel --port $PORT > public_url.log 2>&1 &

PUBLIC_URL=""
for i in {1..10}; do
    sleep 1
    if [ -f public_url.log ]; then
        PUBLIC_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+(\.loca\.lt|\.localtunnel\.me)' public_url.log || true)
        if [ -n "$PUBLIC_URL" ]; then
            break
        fi
    fi
done

echo ""
echo "=================================================="
if [ -n "$PUBLIC_URL" ]; then
    echo "🌍 [SUCCESS] REPAIRED & ACTIVE PUBLIC LINK:"
    echo "    $PUBLIC_URL"
    echo ""
    echo "    (Keep this terminal active. Switch templates at the top or click gear to customize.)"
else
    echo "[!] Tunnel failed to auto-capture URL. Run manually in another tab:"
    echo "    npx localtunnel --port $PORT"
    echo "    Local URL: http://localhost:$PORT"
fi
echo "=================================================="
echo ""
