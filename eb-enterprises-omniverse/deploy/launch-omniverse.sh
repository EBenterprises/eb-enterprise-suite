#!/bin/bash
echo "[OMNIVERSE] Installing dependencies, compiling omniverse manifest, and launching all systems..."
npm install
npm run compile:omniverse
npm start
