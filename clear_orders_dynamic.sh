#!/usr/bin/env bash
set -e

echo "[+] Scanning filesystem for SQLite databases to clear EBenterprises orders..."

python3 - << 'EOF_SEARCH'
import os
import sqlite3

found_dbs = []
for root, dirs, files in os.walk("."):
    for file in files:
        if file.endswith(".db") or file.endswith(".sqlite") or file.endswith(".sqlite3"):
            found_dbs.append(os.path.join(root, file))

print(f"[+] Discovered database files: {found_dbs}")

cleared_any = False
for db_path in found_dbs:
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [row[0] for row in cursor.fetchall()]
        
        if 'orders' in tables:
            cursor.execute("SELECT id, client FROM orders;")
            rows = cursor.fetchall()
            print(f"    Database {db_path} orders: {rows}")
            
            cursor.execute("DELETE FROM orders WHERE client = 'EBenterprises' OR client COLLATE NOCASE = 'ebenterprises';")
            conn.commit()
            if cursor.rowcount > 0:
                print(f"    [+] Cleared {cursor.rowcount} order(s) matching EBenterprises from {db_path}")
                cleared_any = True
        conn.close()
    except Exception as e:
        print(f"    [!] Error inspecting {db_path}: {e}")

if not cleared_any:
    print("[!] No orders matching EBenterprises found in any discovered database.")
EOF_SEARCH

echo "[+] Done!"
