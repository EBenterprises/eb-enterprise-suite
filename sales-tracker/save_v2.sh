#!/bin/bash
set -e

VERSION_DIR="v2_archive"
echo "[+] Creating archive directory: ${VERSION_DIR}..."
mkdir -p "${VERSION_DIR}"

echo "[+] Backing up current application state and files to ${VERSION_DIR}/..."
cp -r server.js public run.sh status.sh deploy.sh summary_report.sh "${VERSION_DIR}/"
[ -f "sales.sqlite" ] && cp sales.sqlite "${VERSION_DIR}/"

echo "[+] V2 archive created and saved successfully."
