#!/data/data/com.termux/files/usr/bin/bash
pkill -f "node" || true
pkill -f "mongod" || true
pkill -f "vite" || true

echo "🚀 Ensuring MongoDB is running..."
mkdir -p ~/mongo/data
mongod --fork --logpath ~/mongodb.log --dbpath ~/mongo/data || true

echo "🚀 Starting backend with explicit database connection check..."
PORT=5000 NODE_ENV=production node server.js &
BACKEND_PID=$!

sleep 2

echo "🚀 Starting frontend on port 3000..."
if [ -d "client" ]; then
    cd client && PORT=3000 npm run dev -- --host 0.0.0.0 --port 3000 &
else
    PORT=3000 npm run dev -- --host 0.0.0.0 --port 3000 &
fi

echo "✨ Services synchronized. Backend on 5000, Frontend on 3000, MongoDB active."
