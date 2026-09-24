#!/bin/bash
echo "[SUPERMESH] Clearing ports 14000-14009, installing dependencies, compiling manifest, and launching all 10 services..."
for p in $(seq 14000 14009); do
  npx kill-port $p || fuser -k $p/tcp || lsof -ti:$p | xargs kill -9 2>/dev/null || true
done
npm install
npm run compile:supermesh
npm start
