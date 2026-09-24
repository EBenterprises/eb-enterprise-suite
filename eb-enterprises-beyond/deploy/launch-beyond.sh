#!/bin/bash
echo "[BEYOND] Installing dependencies, compiling horizon manifest, and launching autonomous engine..."
npm install
npm run compile:horizon
npm start
