#!/bin/bash
echo "[DEPLOY] Triggering cross-platform synchronization for EB Enterprises®..."
npm run init:structure
npm run compile:all
echo "[SUCCESS] Universal cross-platform build successfully compiled, bundled, and synchronized."
