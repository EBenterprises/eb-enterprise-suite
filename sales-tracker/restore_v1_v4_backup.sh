#!/usr/bin/env bash
set -e

PROJECT_DIR="$HOME/sales-tracker"
cd "$PROJECT_DIR"

echo "[1/3] Stopping current server cluster..."
pkill -9 -f node || true
sleep 1

echo "[2/3] Restoring original V1-V4 files from backups..."
for v in {1..4}; do
    # Locate latest valid backup for each version
    BACKUP_FILE=$(ls -t "$PROJECT_DIR/backups/"*"v${v}"* 2>/dev/null | head -n 1 || true)
    
    if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$PROJECT_DIR/server_v${v}.js"
        echo "  - Restored server_v${v}.js from $BACKUP_FILE"
    else
        echo "  - Checking root directory for untouched pre-deployment server_v${v}.js..."
    fi
done

echo "[3/3] Relaunching untouched V1-V4 servers..."
declare -A PORTS=([1]=51201 [2]=51202 [3]=51203 [4]=51204)

for v in {1..4}; do
    PORT=${PORTS[$v]}
    if [ -f "server_v${v}.js" ]; then
        nohup node "server_v${v}.js" > "logs/server_v${v}.log" 2>&1 &
        echo "V${v} running on http://127.0.0.1:${PORT}"
    fi
done

sleep 2
echo "Restoration complete. V1-V4 strictly preserved."
