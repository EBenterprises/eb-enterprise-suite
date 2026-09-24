#!/bin/bash
echo "[DEPLOY] Installing dependencies, compiling compliance manifest, and launching audit daemon..."
npm install
npm run audit:compile
npm start
