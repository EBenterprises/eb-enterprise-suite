#!/bin/bash
echo "[DEPLOY] Installing dependencies, compiling action manifest, and executing live daemon..."
npm install
npm run build:manifest
npm start
