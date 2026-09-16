#!/usr/bin/env bash
set -e

echo "[+] Scanning all discovered databases and clearing EBenterprises records..."

python3 - << 'EOF_CLEAR_ALL'
import os
import sqlite3

databases = [
    './secure_escrow_engine/escrow.db',
    './dark_market_core/database/marketplace.db',
    './dark_market/data/market_core.db',
    './secure_vault/data/vault_ledger.db',
    './secure_vault/data/encrypted_orders.db',
    './secure_vault/data/encrypted_messages.db',
    './secure_vault/data/audit_logs.db',
    './secure_vault/data/users.db',
    './secure_vault/secure_vault/data/vault_ledger.db',
    './secure_vault/instance/vault.db'
]

for db_path in databases:
    if not os.path.exists(db_path):
        continue
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [row[0] for row in cursor.fetchall()]
        
        for table in tables:
            cursor.execute(f"PRAGMA table_info({table});")
            columns = [col[1] for col in cursor.fetchall()]
            
            # Check for any column that might hold username / client / sender references
            for col in columns:
                if col.lower() in ['client', 'username', 'user', 'sender', 'owner']:
                    try:
                        cursor.execute(f"DELETE FROM {table} WHERE {col} = 'EBenterprises' OR {col} COLLATE NOCASE = 'ebenterprises';")
                        if cursor.rowcount > 0:
                            conn.commit()
                            print(f"[+] Cleared {cursor.rowcount} row(s) from {db_path} ({table}.{col})")
                    except Exception as ex:
                        pass
        conn.close()
    except Exception as e:
        print(f"[!] Skipped {db_path}: {e}")

print("[+] Database scan & cleanup complete.")
EOF_CLEAR_ALL

echo "[+] Done!"
