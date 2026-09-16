#!/usr/bin/env python3
import os
import sqlite3
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

def initialize_vault_structure():
    directories = [
        "secure_vault/src",
        "secure_vault/keys",
        "secure_vault/data"
    ]
    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        print(f"[+] Verified directory: {directory}")

def generate_key_pair():
    private_key_path = "secure_vault/keys/private_key.pem"
    public_key_path = "secure_vault/keys/public_key.pem"

    if os.path.exists(private_key_path) and os.path.exists(public_key_path):
        print("[*] Key pair already exists. Skipping generation.")
        return

    print("[*] Generating secure RSA 4096-bit key pair...")
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=4096
    )
    public_key = private_key.public_key()

    with open(private_key_path, "wb") as f:
        f.write(private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        ))

    with open(public_key_path, "wb") as f:
        f.write(public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        ))
    print("[+] Key pair successfully generated and secured.")

def initialize_database():
    db_path = "secure_vault/data/vault_ledger.db"
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            payload_hash TEXT,
            status TEXT
        )
    ''')
    conn.commit()
    conn.close()
    print(f"[+] Local SQLite ledger initialized at: {db_path}")

if __name__ == "__main__":
    print("[*] Initializing Secure Vault Architecture...")
    initialize_vault_structure()
    generate_key_pair()
    initialize_database()
    print("[+] Vault provisioning complete.")
