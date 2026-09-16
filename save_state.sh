#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - State Snapshot & Archive Utility
# ==============================================================================
set -e

BACKUP_DIR="../eb-sales-tracker-backup-$(date +%Y%m%d_%H%M%S)"

echo "[+] Creating snapshot backup of eb-sales-tracker..."
cp -r eb-sales-tracker "$BACKUP_DIR"

echo "[+] State successfully saved to $BACKUP_DIR"
