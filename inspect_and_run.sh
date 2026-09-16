#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Foreground Diagnostics & Execution
# ==============================================================================
set -e

echo "[+] Killing existing node processes..."
pkill -f "node" 2>/dev/null || true
sleep 1

echo "[+] Inspecting server.js mongoose connection lines..."
grep -n "mongoose.connect" server.js || true

echo "[+] Running server in foreground to capture exact error/output..."
PORT=5000 MONGO_URI="mongodb://localhost:27017/eb_sales_root" node server.js
