#!/bin/bash
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE="eb-sales-tracker-deployment-$TIMESTAMP.tar.gz"
echo "[+] Packaging application state..."
tar -czf "$ARCHIVE" --exclude="node_modules" --exclude="*.tar.gz" .
echo "[+] Archive created: $ARCHIVE"
