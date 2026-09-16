#!/data/data/com.termux/files/usr/bin/bash
pkill -f "node server.js" || true
pkill -f "vite" || true

echo "🚀 Starting Backend Server on port 5000..."
PORT=5000 NODE_ENV=production node server.js &

echo "🚀 Starting Frontend Vite Dev Server..."
if [ -d "client" ]; then
    cd client && npm run dev -- --host 0.0.0.0 &
else
    npm run dev -- --host 0.0.0.0 &
fi

echo "✨ All services initialized and proxies aligned!"
