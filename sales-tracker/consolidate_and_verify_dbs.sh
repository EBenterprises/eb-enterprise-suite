#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Database Consolidation & Inspection
# ==============================================================================
set -e

echo "[+] Checking records in root ./sales.db and ./sales_tracker.sqlite..."

if [ -f "sales.db" ]; then
    echo "=== Records in sales.db ==="
    sqlite3 sales.db "SELECT id, item_name, tier, weight_grams, price, timestamp FROM sales ORDER BY timestamp DESC;" 2>/dev/null || node -e "
        const initSqlJs = require('sql.js');
        const fs = require('fs');
        initSqlJs().then(SQL => {
            const db = new SQL.Database(fs.readFileSync('sales.db'));
            console.log(db.exec('SELECT * FROM sales;'));
        });
    " 2>/dev/null || echo "Unable to query sales.db directly."
fi

if [ -f "sales_tracker.sqlite" ]; then
    echo "=== Records in sales_tracker.sqlite ==="
    sqlite3 sales_tracker.sqlite "SELECT id, item_name, tier, weight_grams, price, timestamp FROM sales ORDER BY timestamp DESC;" 2>/dev/null || node -e "
        const initSqlJs = require('sql.js');
        const fs = require('fs');
        initSqlJs().then(SQL => {
            const db = new SQL.Database(fs.readFileSync('sales_tracker.sqlite'));
            console.log(db.exec('SELECT * FROM sales;'));
        });
    " 2>/dev/null || echo "Unable to query sales_tracker.sqlite directly."
fi

echo "[+] If your main transactions were in sales_tracker.sqlite or another file, syncing across all instances now..."
TARGET_DB="sales_tracker.sqlite"
if [ ! -f "$TARGET_DB" ]; then
    TARGET_DB="sales.db"
fi

for v in v1 v2 v3 v4 v5; do
    mkdir -p "instances/$v/data"
    cp "$TARGET_DB" "instances/$v/data/sales.db"
    echo "    -> Synchronized $TARGET_DB to instances/$v/data/sales.db"
done

echo "[+] Database consolidation complete."
