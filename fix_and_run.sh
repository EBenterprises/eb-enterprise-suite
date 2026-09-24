#!/bin/bash
cd /data/data/com.termux/files/home/plug-monolith || { echo "Plug-monolith folder missing!"; exit 1; }

echo "==> Ensuring package.json exists..."
cat << 'INNER_EOF' > package.json
{
  "name": "plug-monolith",
  "version": "1.0.0",
  "description": "All-in-one monolithic secure plug messenger",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "jsonwebtoken": "^9.0.2",
    "mongoose": "^8.3.1",
    "socket.io": "^4.7.5"
  }
}
INNER_EOF

echo "==> Installing dependencies..."
npm install

echo "==> Moving server.js into place..."
mv /data/data/com.termux/files/home/server.js ./server.js 2>/dev/null || true

echo "==> Starting server..."
npm start
