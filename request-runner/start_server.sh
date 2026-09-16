#!/usr/bin/env bash
set -euo pipefail

echo "==> Freeing up port 3000 if occupied..."
fuser -k 3000/tcp 2>/dev/null || true
pkill -f "node server.js" 2>/dev/null || true
sleep 1

echo "==> Starting application server..."
npm run start
