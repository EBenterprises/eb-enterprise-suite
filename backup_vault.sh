#!/usr/bin/env bash
set -e

BACKUP_DIR="secure_vault_backup_$(date +%Y%m%d_%H%M%S)"
echo "[+] Creating full backup of secure_vault into directory: $BACKUP_DIR..."

mkdir -p "$BACKUP_DIR"
cp -r secure_vault "$BACKUP_DIR/"

echo "[+] Backup complete! All code, templates, static assets, and databases are safely archived in $BACKUP_DIR/"
