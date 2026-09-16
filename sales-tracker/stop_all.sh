#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Fleet Shutdown Utility
# ==============================================================================
set -e

echo "[+] Terminating all running node processes across the fleet..."
pkill -f "node" 2>/dev/null || true
sleep 1

echo "[+] Verifying shutdown status..."
if pgrep -f "node" > /dev/null; then
    echo "[!] Some node processes are still running. Forcing termination..."
    pkill -9 -f "node" 2>/dev/null || true
fi

echo "[+] All EB Sales Tracker instances have been stopped."
