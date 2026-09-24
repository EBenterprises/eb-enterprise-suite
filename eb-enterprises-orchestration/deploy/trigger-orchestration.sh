#!/bin/bash
echo "[DEPLOY] Triggering automated orchestration & live deployment sync..."
npm run init:dirs
npm run compile:orchestration
echo "[SUCCESS] Subsystem orchestration compiled and deployment hook dispatched."
