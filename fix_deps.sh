#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Dependency & SQLite Resolution Script
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Installing missing Node.js dependencies (sqlite3 & express)..."
npm install sqlite3 express

echo "[+] Restarting server..."
node server.js
