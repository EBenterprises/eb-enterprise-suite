#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"
cd "$APP"

echo "==============================================="
echo " Request Runner®"
echo " Android/ARM64 Webpack + Socket.IO"
echo "==============================================="

pkill -f "$APP/server.js" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
pkill -f "realtime-server.js" 2>/dev/null || true

sleep 1

echo
echo "[1] Starting realtime server..."

node realtime-server.js > "$APP/realtime.log" 2>&1 &
REALTIME_PID=$!

sleep 1

if ! kill -0 "$REALTIME_PID" 2>/dev/null; then
    echo "ERROR: Socket.IO failed to start."
    cat "$APP/realtime.log"
    exit 1
fi

echo "Socket.IO PID: $REALTIME_PID"

cleanup() {
    echo
    echo "Stopping Request Runner®..."
    kill "$REALTIME_PID" 2>/dev/null || true
    pkill -f "next-server" 2>/dev/null || true
    pkill -f "next dev" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

echo
echo "[2] Starting Next.js with Webpack..."
echo
echo "Customer:"
echo "  http://127.0.0.1:3000/request"
echo
echo "Operations:"
echo "  http://127.0.0.1:3000/ops"
echo
echo "Realtime:"
echo "  http://127.0.0.1:3001"
echo
echo "LAN:"
echo "  http://$(ip route 2>/dev/null | awk '/src/ {print $NF; exit}'):3000"
echo

exec npx next dev --webpack
