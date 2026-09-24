#!/bin/bash
echo "[EMPIRE] Installing dependencies, compiling full ecosystem manifest, and launching master server..."
npm install
npm run compile:empire
npm start
