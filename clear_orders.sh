#!/usr/bin/env bash
set -e

echo "[+] Clearing all orders associated with client 'EBenterprises' from the database..."

python3 - << 'EOF_CLEAR'
import sqlite3
import os

db_paths = [
    "secure_vault/src/database.db",
    "secure_vault/database.db",
    "database.db"
]

db_found = False
for path in db_paths:
    if os.path.exists(path):
        conn = sqlite3.connect(path)
        cursor = conn.cursor()
        
        # Check if orders table exists
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='orders';")
        if cursor.fetchone():
            cursor.execute("DELETE FROM orders WHERE client = 'EBenterprises';",)
            conn.commit()
            print(f"[+] Successfully deleted EBenterprises orders from {path}. Rows affected: {cursor.rowcount}")
            db_found = True
        conn.close()

if not db_found:
    print("[!] Database not found or orders table missing.")
EOF_CLEAR

echo "[+] Done! All EBenterprises orders have been cleared."
