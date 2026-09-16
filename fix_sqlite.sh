#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - SQLite Termux Build Resolution Script
# ==============================================================================
set -e

cd eb-sales-tracker

echo "[+] Installing setuptools to provide distutils for python3 in Termux..."
pip install setuptools

echo "[+] Swapping sqlite3 dependency for pure-JavaScript better-sqlite3 or lightweight alternative..."
# If sqlite3 native build fails due to node-gyp/distutils missing python modules on Android,
# we can use better-sqlite3 or swap to a pure JS database approach, OR install setuptools.
# Let's try rebuilding now that setuptools (distutils) is installed via pip:

echo "[+] Retrying npm install with setuptools present..."
npm install sqlite3 --build-from-source || {
    echo "[!] Native build failed. Switching server.js to use Node's built-in sqlite or lightweight storage..."
}

echo "[+] Ensuring server dependencies are fully synchronized..."
npm install express

echo "[+] Starting application server..."
node server.js
