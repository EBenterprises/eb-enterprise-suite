#!/usr/bin/env bash
set -e

echo "[+] Setting up Secure Vault project structure..."
mkdir -p secure_vault/src
mkdir -p secure_vault/templates
mkdir -p secure_vault/deployment
mkdir -p secure_vault/data
mkdir -p secure_vault/keys

echo "[+] Creating server startup script..."
cat << 'START_EOF' > secure_vault/deployment/start_server.sh
#!/usr/bin/env bash
python3 secure_vault/src/app.py
START_EOF
chmod +x secure_vault/deployment/start_server.sh

echo "[+] Generating initialization and database migration script..."
cat << 'INIT_EOF' > secure_vault/src/update_vault.py
import os
import sqlite3
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DB_PATH = os.path.join(BASE_DIR, "data", "vault_ledger.db")
KEYS_DIR = os.path.join(BASE_DIR, "keys")
PRIVATE_KEY_PATH = os.path.join(KEYS_DIR, "private_key.pem")
PUBLIC_KEY_PATH = os.path.join(KEYS_DIR, "public_key.pem")

os.makedirs(KEYS_DIR, exist_ok=True)
os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

if not os.path.exists(PRIVATE_KEY_PATH) or not os.path.exists(PUBLIC_KEY_PATH):
    print("[+] Generating new RSA-4096 Key Pair...")
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=4096)
    public_key = private_key.public_key()

    with open(PRIVATE_KEY_PATH, "wb") as f:
        f.write(private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        ))
    with open(PUBLIC_KEY_PATH, "wb") as f:
        f.write(public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        ))

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()
cursor.execute('''
    CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        payload_hash TEXT,
        encrypted_payload BLOB,
        status TEXT
    )
''')
try:
    cursor.execute("ALTER TABLE transactions ADD COLUMN encrypted_payload BLOB")
except sqlite3.OperationalError:
    pass
conn.commit()
conn.close()
print("[+] Database schema & keys verified successfully.")
INIT_EOF

echo "[+] Writing backend application logic (app.py)..."
cat << 'APP_EOF' > secure_vault/src/app.py
#!/usr/bin/env python3
import os
import sqlite3
import hashlib
from flask import Flask, render_template, request, redirect, url_for, make_response
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.serialization import load_pem_public_key, load_pem_private_key

app = Flask(__name__, template_folder="../templates")

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DB_PATH = os.path.join(BASE_DIR, "data", "vault_ledger.db")
PUBLIC_KEY_PATH = os.path.join(BASE_DIR, "keys", "public_key.pem")
PRIVATE_KEY_PATH = os.path.join(BASE_DIR, "keys", "private_key.pem")

ADMIN_TOKEN = "VAULT_SECURE_ADMIN_KEY_99"

def get_db_connection():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    return sqlite3.connect(DB_PATH)

@app.route("/", methods=["GET"])
def index():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, timestamp, payload_hash, status FROM transactions ORDER BY id DESC LIMIT 10")
    transactions = cursor.fetchall()
    conn.close()
    return render_template("dashboard.html", transactions=transactions)

@app.route("/admin/login", methods=["POST"])
def admin_login():
    passkey = request.form.get("passkey")
    if passkey == ADMIN_TOKEN:
        resp = redirect(url_for('admin_panel'))
        resp.set_cookie("vault_admin_session", ADMIN_TOKEN, httponly=True, samesite="Strict")
        return resp
    return "[-] Unauthorized: Invalid Manager Password", 403

@app.route("/transaction/<int:tx_id>", methods=["GET"])
def transaction_detail(tx_id):
    session_cookie = request.cookies.get("vault_admin_session")
    if session_cookie != ADMIN_TOKEN:
        return render_template("unauthorized.html", tx_id=tx_id)

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, timestamp, payload_hash, encrypted_payload, status FROM transactions WHERE id = ?", (tx_id,))
    tx = cursor.fetchone()
    conn.close()

    if not tx:
        return "Order not found", 404

    decrypted_text = "[Decryption Failed]"
    encrypted_blob = tx[3]

    if encrypted_blob and os.path.exists(PRIVATE_KEY_PATH):
        try:
            with open(PRIVATE_KEY_PATH, "rb") as key_file:
                private_key = load_pem_private_key(key_file.read(), password=None)
            decrypted_bytes = private_key.decrypt(
                encrypted_blob,
                padding.OAEP(
                    mgf=padding.MGF1(algorithm=hashes.SHA256()),
                    algorithm=hashes.SHA256(),
                    label=None
                )
            )
            decrypted_text = decrypted_bytes.decode('utf-8')
        except Exception as e:
            decrypted_text = f"[Decryption Error: {str(e)}]"

    tx_data = (tx[0], tx[1], tx[2], tx[4], decrypted_text)
    return render_template("transaction.html", tx=tx_data)

@app.route("/admin", methods=["GET"])
def admin_panel():
    session_cookie = request.cookies.get("vault_admin_session")
    if session_cookie != ADMIN_TOKEN:
        return render_template("admin_login.html")

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, timestamp, payload_hash, status FROM transactions ORDER BY id DESC")
    transactions = cursor.fetchall()
    conn.close()
    return render_template("admin.html", transactions=transactions)

@app.route("/admin/update/<int:tx_id>", methods=["POST"])
def update_transaction(tx_id):
    session_cookie = request.cookies.get("vault_admin_session")
    if session_cookie != ADMIN_TOKEN:
        return "Unauthorized", 403

    new_status = request.form.get("status", "PENDING_APPROVAL")
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE transactions SET status = ? WHERE id = ?", (new_status, tx_id))
    conn.commit()
    conn.close()
    return redirect(url_for('admin_panel'))

@app.route("/vault", methods=["GET"])
def vault_diagnostics():
    session_cookie = request.cookies.get("vault_admin_session")
    if session_cookie != ADMIN_TOKEN:
        return render_template("admin_login.html")

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM transactions")
    total_records = cursor.fetchone()[0]
    conn.close()

    pub_key_content = "[Public Key Missing]"
    if os.path.exists(PUBLIC_KEY_PATH):
        with open(PUBLIC_KEY_PATH, "r") as f:
            pub_key_content = f.read()

    return render_template("vault.html", db_path=DB_PATH, total_records=total_records, public_key_pem=pub_key_content)

@app.route("/encrypt", methods=["POST"])
def encrypt():
    payload = request.form.get("payload")
    if not payload:
        return redirect(url_for('index'))

    encrypted_blob = b""
    try:
        if os.path.exists(PUBLIC_KEY_PATH):
            with open(PUBLIC_KEY_PATH, "rb") as key_file:
                public_key = load_pem_public_key(key_file.read())
            encrypted_blob = public_key.encrypt(
                payload.encode('utf-8'),
                padding.OAEP(
                    mgf=padding.MGF1(algorithm=hashes.SHA256()),
                    algorithm=hashes.SHA256(),
                    label=None
                )
            )
    except Exception as e:
        print(f"[-] Encryption error: {e}")

    payload_hash = hashlib.sha256(payload.encode('utf-8')).hexdigest()
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO transactions (payload_hash, encrypted_payload, status) VALUES (?, ?, ?)", 
        (payload_hash, encrypted_blob, "PENDING_APPROVAL")
    )
    conn.commit()
    conn.close()

    return redirect(url_for('index'))

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
APP_EOF

echo "[+] Writing HTML templates..."

cat << 'EOF' > secure_vault/templates/dashboard.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Vault - Home</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700;800&display=swap');
        :root {
            --bg: #09090b; --surface: #121216; --surface-border: #27272a;
            --accent: #00ff66; --accent-glow: rgba(0, 255, 102, 0.2);
            --text-main: #f4f4f5; --text-muted: #a1a1aa;
        }
        * { box-sizing: border-box; }
        body { font-family: 'JetBrains Mono', monospace; background: var(--bg); color: var(--text-main); margin: 0; padding: 20px; min-height: 100vh; display: flex; justify-content: center; align-items: flex-start; }
        .container { width: 100%; max-width: 1000px; background: var(--surface); padding: 30px; border: 1px solid var(--surface-border); border-radius: 8px; box-shadow: 0 0 30px rgba(0, 0, 0, 0.8); }
        header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--surface-border); padding-bottom: 15px; margin-bottom: 25px; flex-wrap: wrap; gap: 10px; }
        h2 { font-size: 1.4rem; font-weight: 800; color: var(--accent); margin: 0; }
        .nav-links { display: flex; gap: 15px; font-size: 12px; }
        .nav-links a { color: var(--text-muted); text-decoration: none; transition: color 0.2s; }
        .nav-links a:hover { color: var(--accent); }
        h3 { font-size: 0.95rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; }
        textarea { width: 100%; min-height: 100px; padding: 15px; background: #09090b; color: var(--text-main); border: 1px solid var(--surface-border); font-family: 'JetBrains Mono', monospace; font-size: 13px; border-radius: 6px; resize: vertical; }
        textarea:focus { outline: none; border-color: var(--accent); box-shadow: 0 0 15px var(--accent-glow); }
        button { width: 100%; padding: 14px; background: var(--accent); color: #000; font-family: 'JetBrains Mono', monospace; font-weight: 800; font-size: 13px; letter-spacing: 1px; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; box-shadow: 0 0 15px var(--accent-glow); margin-top: 10px; }
        button:hover { background: #00cc52; box-shadow: 0 0 25px rgba(0, 255, 102, 0.4); }
        .table-container { width: 100%; overflow-x: auto; margin-top: 25px; border: 1px solid var(--surface-border); border-radius: 6px; background: #09090b; }
        table { width: 100%; border-collapse: collapse; white-space: nowrap; }
        th, td { padding: 12px 16px; text-align: left; font-size: 12px; }
        th { background: #121216; color: var(--text-muted); font-weight: 700; border-bottom: 1px solid var(--surface-border); text-transform: uppercase; }
        td { border-bottom: 1px solid #18181b; color: var(--text-main); }
        tr:hover td { background: #121216; }
        .hash-link { color: var(--accent); text-decoration: none; }
        .hash-link:hover { text-decoration: underline; }
        .badge { background: rgba(0, 255, 102, 0.1); color: var(--accent); padding: 3px 8px; border-radius: 4px; font-size: 11px; border: 1px solid rgba(0, 255, 102, 0.2); }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h2>Secure Vault</h2>
            <div class="nav-links">
                <a href="/">Home</a>
                <a href="/admin">Manager Login</a>
                <a href="/vault">System Status</a>
            </div>
        </header>
        
        <h3>Send a Secure Message or Order</h3>
        <form method="POST" action="/encrypt">
            <textarea name="payload" placeholder="Type your private message, shipping details, or order information here..." required></textarea>
            <button type="submit">Submit Securely</button>
        </form>

        <h3>Recent Orders</h3>
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Order #</th>
                        <th>Date & Time</th>
                        <th>Security Code (Reference)</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    {% for row in transactions %}
                    <tr>
                        <td><a href="/transaction/{{ row[0] }}" class="hash-link">#{{ row[0] }}</a></td>
                        <td>{{ row[1] }}</td>
                        <td><a href="/transaction/{{ row[0] }}" class="hash-link">{{ row[2][:24] }}...</a></td>
                        <td><span class="badge">{{ row[3] }}</span></td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
