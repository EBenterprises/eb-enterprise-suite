#!/bin/bash
echo "[DEPLOY] Triggering automated build, start, and browser opening sequence..."
npm install
npm run compile:orchestration
npm start
