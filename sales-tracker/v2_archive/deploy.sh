#!/bin/bash
set -e
ARCHIVE_NAME="sales-tracker-$(date +%Y%m%d_%H%M%S).tar.gz"
echo "[+] Packaging application..."
tar -czf "$ARCHIVE_NAME" --exclude="node_modules" --exclude=".git" --exclude="*.tar.gz" .
echo "[+] Created archive: $ARCHIVE_NAME"
