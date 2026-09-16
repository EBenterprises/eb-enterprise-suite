#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Transaction History Inspector
# ==============================================================================
set -e

VERSIONS=("v1" "v2" "v3" "v4" "v5")

echo "[+] Inspecting database records across all version instances..."
for V in "${VERSIONS[@]}"; do
    DB_PATH="instances/$V/data/sales.db"
    if [ -f "$DB_PATH" ]; then
        echo "=== $V Database Records ($DB_PATH) ==="
        if command -v sqlite3 &> /dev/null; then
            sqlite3 "$DB_PATH" "SELECT id, item_name, tier, weight_grams, price, timestamp FROM sales ORDER BY timestamp DESC;" || echo "Query failed."
        else
            node -e "
                const initSqlJs = require('sql.js');
                const fs = require('fs');
                initSqlJs().then(SQL => {
                    const buffer = fs.readFileSync('$DB_PATH');
                    const db = new SQL.Database(buffer);
                    const res = db.exec('SELECT * FROM sales;');
                    console.log(JSON.stringify(res, null, 2));
                });
            " 2>/dev/null || echo "Unable to read SQLite DB via node."
        fi
    else
        echo "=== $V: No database file found at $DB_PATH ==="
    fi
    echo ""
done
