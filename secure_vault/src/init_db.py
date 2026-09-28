import sqlite3
import hashlib
import os
import rsa

db_path = "../data/vault_ledger.db"
os.makedirs(os.path.dirname(db_path), exist_ok=True)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Create tables
cursor.execute('''
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    is_admin INTEGER DEFAULT 0
)
''')

cursor.execute('''
CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    encrypted_payload TEXT,
    status TEXT DEFAULT 'PENDING',
    FOREIGN KEY(user_id) REFERENCES users(id)
)
''')

# Create default Admin account (id=1, is_admin=1)
admin_pass = hashlib.sha256("admin123".encode()).hexdigest()
cursor.execute("INSERT OR IGNORE INTO users (id, username, password_hash, is_admin) VALUES (1, 'admin', ?, 1)", (admin_pass,))

# Create default Client account for EBenterprises (id=2, is_admin=0)
client_pass = hashlib.sha256("client123".encode()).hexdigest()
cursor.execute("INSERT OR IGNORE INTO users (id, username, password_hash, is_admin) VALUES (2, 'EBenterprises', ?, 0)", (client_pass,))

conn.commit()
conn.close()

# Generate RSA Keys for the Vault if missing
if not os.path.exists("private_key.pem") or not os.path.exists("public_key.pem"):
    pubkey, privkey = rsa.newkeys(1024)
    with open("private_key.pem", "wb") as f:
        f.write(privkey.save_pkcs1('PEM'))
    with open("public_key.pem", "wb") as f:
        f.write(pubkey.save_pkcs1('PEM'))

print("[+] Database and RSA keys initialized successfully.")
