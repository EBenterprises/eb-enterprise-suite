#!/bin/bash
echo "[DEPLOY] Triggering production execution pipeline for EB Enterprises®..."
npm run init:dirs
npm run compile:next
echo "[SUCCESS] Next steps compilation completed successfully. Ready for daemon start."
