#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Server Startup & Status Verification
# ==============================================================================
set -e

cd "$(dirname "$0")/eb-sales-tracker"

echo "[+] Terminating any lingering processes on port 3000..."
fuser -k 3000/tcp || true

echo "[+] Launching EB Sales Tracker live server..."
node server.js
