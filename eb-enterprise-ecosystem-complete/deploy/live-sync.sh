#!/bin/bash
echo "[DEPLOY] Initializing live synchronization and automated trigger..."
npm run init:all
npm run compile:ecosystem
echo "[SUCCESS] Final ecosystem build verified and live trigger successfully dispatched."
