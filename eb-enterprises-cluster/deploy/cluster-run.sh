#!/bin/bash
echo "[DEPLOY] Installing dependencies, compiling cluster, and launching master node..."
npm install
npm run cluster:compile
npm start
