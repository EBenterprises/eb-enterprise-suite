#!/bin/bash
echo "[DEPLOY] Installing dependencies, compiling master manifest, and launching ultimate daemon..."
npm install
npm run compile:master
npm start
