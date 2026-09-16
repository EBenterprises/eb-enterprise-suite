#!/usr/bin/env bash
set -euo pipefail
ARCHIVE_DIR="${HOME}/termux_workspace/archives"
mkdir -p "$ARCHIVE_DIR"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
ARCHIVE_NAME="${ARCHIVE_DIR}/workspace_backup_${TIMESTAMP}.tar.gz"

echo "[*] Creating compressed workspace archive..."
tar --exclude="archives" --exclude=".git" -czf "$ARCHIVE_NAME" -C "${HOME}" termux_workspace
echo "[+] Archive successfully created at: $ARCHIVE_NAME"
