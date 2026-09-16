#!/bin/bash
set -e

VERSION_DIR="v1_archive"
echo "[+] Creating archive directory: ${VERSION_DIR}..."
mkdir -p "${VERSION_DIR}"

echo "[+] Backing up current application files to ${VERSION_DIR}/..."
cp -r server.js public run.sh "${VERSION_DIR}/"

echo "[+] V1 archive created successfully with all current code, assets, and configuration."
