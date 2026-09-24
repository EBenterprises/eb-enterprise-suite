#!/bin/bash
echo "[DEPLOY] Installing dependencies, compiling all modules, and launching master daemon..."
npm install
npm run compile:all
npm start
