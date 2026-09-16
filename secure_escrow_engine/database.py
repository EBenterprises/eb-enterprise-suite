import sqlite3

def init_db():
    conn = sqlite3.connect('escrow.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS transactions (
            id TEXT PRIMARY KEY,
            buyer TEXT,
            vendor TEXT,
            amount REAL,
            status TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

def create_transaction(tx_id, buyer, vendor, amount):
    conn = sqlite3.connect('escrow.db')
    cursor = conn.cursor()
    cursor.execute("INSERT INTO transactions (id, buyer, vendor, amount, status) VALUES (?, ?, ?, ?, ?)",
                   (tx_id, buyer, vendor, amount, 'FUNDS_LOCKED'))
    conn.commit()
    conn.close()
