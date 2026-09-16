#!/usr/bin/env bash
set -e

echo "[+] Locating database and clearing EBenterprises orders..."

python3 - << 'EOF_CLEAR'
import sqlite3
import os

# Search across possible database locations in the project workspace
paths_to_check = [
    "secure_vault/src/database.db",
    "secure_vault/database.db",
    "database.db",
    "secure_vault/src/instance/database.db",
    "instance/database.db"
]

cleared = False
for path in paths_to_check:
    if os.path.exists(path):
        print(f"[+] Found database at: {path}")
        conn = sqlite3.connect(path)
        cursor = conn.cursor()
        
        # Check tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [row[0] for row in cursor.fetchall()]
        print(f"    Tables found: {tables}")
        
        if 'orders' in tables:
            # Let's inspect what clients exist in the orders table
            cursor.execute("SELECT DISTINCT client FROM orders;")
            clients = cursor.fetchall()
            print(f"    Clients in orders table: {clients}")
            
            cursor.execute("DELETE FROM orders WHERE client = 'EBenterprises';")
            conn.commit()
            print(f"    [+] Deleted EBenterprises orders. Rows deleted: {cursor.rowcount}")
            cleared = True
            
        conn.close()

if not cleared:
    print("[!] Warning: Could not find an 'orders' table with 'EBenterprises' records in standard paths.")
EOF_CLEAR

echo "[+] Done! EBenterprises orders cleared."
