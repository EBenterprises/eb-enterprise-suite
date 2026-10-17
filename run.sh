#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Safe Server Launcher
# ==============================================================================
set -e

cd "$(dirname "$0")/eb-sales-tracker"

echo "[+] Starting EB Sales Tracker..."
node server.js
