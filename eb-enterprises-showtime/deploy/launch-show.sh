#!/bin/bash
echo "[SHOWTIME] Installing dependencies, compiling show manifest, and going live..."
npm install
npm run compile:show
npm start
