#!/bin/bash
set -e

VERSION_DIR="v2_archive"

if [ ! -d "$VERSION_DIR" ]; then
    echo "[!] Error: v2_archive directory not found. Please make sure you saved v2 first."
    exit 1
fi

echo "[+] Restoring files from ${VERSION_DIR}/..."
cp -r ${VERSION_DIR}/server.js .
cp -r ${VERSION_DIR}/public .
cp -r ${VERSION_DIR}/run.sh .
[ -f "${VERSION_DIR}/status.sh" ] && cp ${VERSION_DIR}/status.sh .
[ -f "${VERSION_DIR}/deploy.sh" ] && cp ${VERSION_DIR}/deploy.sh .
[ -f "${VERSION_DIR}/summary_report.sh" ] && cp ${VERSION_DIR}/summary_report.sh .
[ -f "${VERSION_DIR}/sales.sqlite" ] && cp ${VERSION_DIR}/sales.sqlite .

echo "[+] Starting application (V2)..."
./run.sh
