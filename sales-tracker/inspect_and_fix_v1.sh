#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - v1 Diagnostic & Process Verification
# ==============================================================================
set -e

echo "=== v1 server.log ==="
cat instances/v1/server.log

echo "=== Checking Node processes ==="
ps aux | grep node

echo "=== Checking listening ports with netstat / lsof ==="
netstat -an 2>/dev/null || ss -an 2>/dev/null || true

echo "[+] Fixing v1 server script syntax or missing dependencies if needed..."
cd instances/v1
node -c server.js
cd - > /dev/null
