#!/usr/bin/env python3
import os
import sys
import sqlite3
import hashlib

def log_payload_entry(payload_text: str, status: str = "PENDING"):
    db_path = "secure_vault/data/vault_ledger.db"
    if not os.path.exists(db_path):
        print("[-] Error: Ledger database not found. Run provision_vault.py first.")
        sys.exit(1)

    payload_hash = hashlib.sha256(payload_text.encode('utf-8')).hexdigest()

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO transactions (payload_hash, status)
        VALUES (?, ?)
    ''', (payload_hash, status))
    conn.commit()
    conn.close()
    
    print(f"[+] Logged entry to ledger.")
    print(f"    - Hash: {payload_hash}")
    print(f"    - Status: {status}")

if __name__ == "__main__":
    sample_entry = "Shipment instruction payload verified."
    log_payload_entry(sample_entry, status="SECURED")
