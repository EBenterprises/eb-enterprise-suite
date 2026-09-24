#!/bin/bash
echo "[DEPLOY] Installing dependencies, compiling expansion modules, and launching daemon..."
npm install
npm run compile:expansion
npm start
