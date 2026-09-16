import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'market_core.db')

def get_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def initialize_storage():
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS identities (
            id TEXT PRIMARY KEY,
            alias TEXT UNIQUE NOT NULL,
            pgp_key TEXT,
            pass_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            clearance TEXT DEFAULT 'vendor',
            registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS inventory (
            id TEXT PRIMARY KEY,
            vendor_id TEXT,
            item_name TEXT NOT NULL,
            specification TEXT,
            price_xmr REAL NOT NULL,
            stock_count INTEGER DEFAULT 0,
            FOREIGN KEY (vendor_id) REFERENCES identities(id)
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS ledger (
            id TEXT PRIMARY KEY,
            inventory_id TEXT,
            buyer_id TEXT,
            vendor_id TEXT,
            status TEXT DEFAULT 'PENDING_ESCROW',
            encrypted_payload TEXT,
            valuation_xmr REAL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (inventory_id) REFERENCES inventory(id),
            FOREIGN KEY (buyer_id) REFERENCES identities(id),
            FOREIGN KEY (vendor_id) REFERENCES identities(id)
        )
    ''')

    conn.commit()
    conn.close()
