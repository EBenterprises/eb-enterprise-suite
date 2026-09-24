#!/bin/bash
echo "[MESH] Cleaning ports 13000-13005, installing dependencies, compiling manifest, and spinning up all services..."
for p in 13000 13001 13002 13003 13004 13005; do
  npx kill-port $p || fuser -k $p/tcp || lsof -ti:$p | xargs kill -9 2>/dev/null || true
done
npm install
npm run compile:mesh
npm start
