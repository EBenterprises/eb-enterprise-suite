#!/bin/bash
set -e

VERSION_DIR="v1_archive"

if [ ! -d "${VERSION_DIR}" ]; then
    echo "[!] Error: v1_archive directory not found!"
    exit 1
fi

echo "[+] Restoring files from ${VERSION_DIR}/..."
cp -r ${VERSION_DIR}/server.js ${VERSION_DIR}/public ${VERSION_DIR}/run.sh .

echo "[+] Restarting live deployment using V1 release..."
./run.sh
