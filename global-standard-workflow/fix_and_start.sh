#!/bin/bash
set -e

# Kill any existing node processes occupying ports
pkill -f "node server.js" || true

# Dynamically find an open port starting from 3000
PORT=$(node -e "
const net = require('net');
async function find() {
  for (let p = 3000; p <= 3010; p++) {
    await new Promise(r => {
      const s = net.createServer();
      s.listen(p, '127.0.0.1', () => { s.close(() => r(p)); });
      s.on('error', () => r(null));
    }).then(res => { if (res) { console.log(res); process.exit(0); } });
  }
}
find();
")

echo "================================================================"
echo " SELECTED OPEN PORT: $PORT"
echo "================================================================"

# Update .env with the discovered open port
if [ -f .env ]; then
  sed -i "s/^PORT=.*/PORT=$PORT/" .env
else
  echo "PORT=$PORT" > .env
fi

echo "Starting Global Standard Workflow server on port $PORT..."
node server.js
