#!/bin/bash
echo "[FINALE] Installing dependencies, compiling grand finale manifest, and going live..."
npm install
npm run compile:finale
npm start
