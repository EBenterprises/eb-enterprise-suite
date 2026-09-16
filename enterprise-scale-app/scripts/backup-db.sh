#!/bin/bash
set -e

BACKUP_DIR="/var/backups/enterprise"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql"

mkdir -p $BACKUP_DIR

echo "[Backup] Initiating PostgreSQL snapshot..."
docker exec enterprise_postgres pg_dump -U user -d enterprise_db > "$BACKUP_FILE"

echo "[Backup] Compressing database snapshot..."
gzip "$BACKUP_FILE"

echo "[Backup] Complete: $BACKUP_FILE.gz"

# Clean backups older than 7 days
find $BACKUP_DIR -type f -mtime +7 -exec rm {} \;
echo "[Backup] Retention policy applied (removed backups > 7 days old)."
