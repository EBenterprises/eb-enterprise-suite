#!/usr/bin/env bash
set -e

echo "[+] Constructing full-stack production directory tree..."
mkdir -p secure_vault/src
mkdir -p secure_vault/templates
mkdir -p secure_vault/deployment
mkdir -p secure_vault/data
mkdir -p secure_vault/keys

echo "[+] Writing server daemon startup script..."
cat << 'START_EOF' > secure_vault/deployment/start_server.sh
#!/usr/bin/env bash
cd "$(dirname "$0")/.."
python3 src/app.py
START_EOF
chmod +x secure_vault/deployment/start_server.sh

echo "[+] Initializing database migration and cryptographic keys..."
cat << 'INIT_EOF' > secure_vault/src/init_db.py
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
    print("[+] Generating RSA-4096 Master Encryption Keypair...")
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

# Users Table
cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        is_admin INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
''')

# Transactions / Orders Table
cursor.execute('''
    CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        payload_hash TEXT,
        encrypted_payload BLOB,
        status TEXT DEFAULT 'PENDING_APPROVAL',
        FOREIGN KEY(user_id) REFERENCES users(id)
    )
''')

# Create default admin account if missing (Password: AdminSecret99!)
import hashlib
admin_pass_hash = hashlib.sha256("AdminSecret99!".encode()).hexdigest()
cursor.execute("INSERT OR IGNORE INTO users (id, username, password_hash, is_admin) VALUES (1, 'admin', ?, 1)", (admin_pass_hash,))

conn.commit()
conn.close()
print("[+] Database schema, authentication tables, and keys fully provisioned.")
INIT_EOF
python3 secure_vault/src/init_db.py

echo "[+] Writing core full-stack application logic (app.py)..."
cat << 'APP_EOF' > secure_vault/src/app.py
#!/usr/bin/env python3
import os
import sqlite3
import hashlib
import urllib.request
import urllib.parse
from flask import Flask, render_template, request, redirect, url_for, make_response, session
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.serialization import load_pem_public_key, load_pem_private_key

app = Flask(__name__, template_folder="../templates")
app.secret_key = os.urandom(32)

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DB_PATH = os.path.join(BASE_DIR, "data", "vault_ledger.db")
PUBLIC_KEY_PATH = os.path.join(BASE_DIR, "keys", "public_key.pem")
PRIVATE_KEY_PATH = os.path.join(BASE_DIR, "keys", "private_key.pem")

# CONFIGURABLE MOBILE ALERTS (Optional free push via ntfy.sh or Twilio)
# To get instant phone notifications, download the 'ntfy' app on your phone and subscribe to a unique topic name below.
NTFY_TOPIC = "secure_vault_alerts_easton_999"

def send_push_notification(title, message):
    """Fires an instant push alert to your mobile device."""
    try:
        data = message.encode('utf-8')
        req = urllib.request.Request(f"https://ntfy.sh/{NTFY_TOPIC}", data=data, headers={"Title": title})
        urllib.request.urlopen(req, timeout=3)
    except Exception as e:
        print(f"[-] Push notification warning: {e}")

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@app.route("/", methods=["GET"])
def index():
    if not session.get("user_id"):
        return redirect(url_for('login_page'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    if session.get("is_admin"):
        # Admin sees all orders
        cursor.execute("SELECT t.id, u.username, t.timestamp, t.payload_hash, t.status FROM transactions t JOIN users u ON t.user_id = u.id ORDER BY t.id DESC")
    else:
        # Regular clients only see their own orders
        cursor.execute("SELECT t.id, u.username, t.timestamp, t.payload_hash, t.status FROM transactions t JOIN users u ON t.user_id = u.id WHERE t.user_id = ? ORDER BY t.id DESC", (session["user_id"],))
    
    transactions = cursor.fetchall()
    conn.close()
    return render_template("dashboard.html", transactions=transactions, username=session.get("username"), is_admin=session.get("is_admin"))

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")
        if not username or not password:
            return "Username and password required", 400
        
        pass_hash = hashlib.sha256(password.encode()).hexdigest()
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)", (username, pass_hash))
            conn.commit()
            conn.close()
            return redirect(url_for('login_page'))
        except sqlite3.IntegrityError:
            return "Username already taken. Please choose another.", 400

    return render_template("register.html")

@app.route("/login", methods=["GET", "POST"])
def login_page():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")
        pass_hash = hashlib.sha256(password.encode()).hexdigest()

        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, username, is_admin FROM users WHERE username = ? AND password_hash = ?", (username, pass_hash))
        user = cursor.fetchone()
        conn.close()

        if user:
            session["user_id"] = user["id"]
            session["username"] = user["username"]
            session["is_admin"] = user["is_admin"]
            return redirect(url_for('index'))
        return "Invalid username or password", 403

    return render_template("login.html")

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for('login_page'))

@app.route("/submit_order", methods=["POST"])
def submit_order():
    if not session.get("user_id"):
        return redirect(url_for('login_page'))

    payload = request.form.get("payload", "").strip()
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
        "INSERT INTO transactions (user_id, payload_hash, encrypted_payload) VALUES (?, ?, ?)",
        (session["user_id"], payload_hash, encrypted_blob)
    )
    conn.commit()
    conn.close()

    # Trigger instant mobile push alert to your phone
    send_push_notification(f"New Order from {session['username']}", f"Client submitted an encrypted payload. Log in to review.")

    return redirect(url_for('index'))

@app.route("/order/<int:order_id>", methods=["GET"])
def view_order(order_id):
    if not session.get("user_id"):
        return redirect(url_for('login_page'))

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT t.*, u.username FROM transactions t JOIN users u ON t.user_id = u.id WHERE t.id = ?", (order_id,))
    order = cursor.fetchone()
    conn.close()

    if not order:
        return "Order not found", 404

    # Security check: Only admins or the client who created the order can inspect it
    if not session.get("is_admin") and order["user_id"] != session["user_id"]:
        return render_template("unauthorized.html")

    decrypted_text = "[Decryption Failed]"
    if order["encrypted_payload"] and os.path.exists(PRIVATE_KEY_PATH) and session.get("is_admin"):
        try:
            with open(PRIVATE_KEY_PATH, "rb") as key_file:
                private_key = load_pem_private_key(key_file.read(), password=None)
            decrypted_bytes = private_key.decrypt(
                order["encrypted_payload"],
                padding.OAEP(
                    mgf=padding.MGF1(algorithm=hashes.SHA256()),
                    algorithm=hashes.SHA256(),
                    label=None
                )
            )
            decrypted_text = decrypted_bytes.decode('utf-8')
        except Exception as e:
            decrypted_text = f"[Decryption Error: {str(e)}]"
    elif not session.get("is_admin"):
        decrypted_text = "[Client View: Order is securely encrypted and pending manager review]"

    return render_template("order_detail.html", order=order, decrypted_text=decrypted_text, is_admin=session.get("is_admin"))

@app.route("/admin/update/<int:order_id>", methods=["POST"])
def update_status(order_id):
    if not session.get("is_admin"):
        return "Unauthorized", 403

    new_status = request.form.get("status", "APPROVED")
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE transactions SET status = ? WHERE id = ?", (new_status, order_id))
    conn.commit()
    conn.close()
    return redirect(url_for('index'))

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
APP_EOF

echo "[+] Writing client and manager HTML templates..."

cat << 'EOF' > secure_vault/templates/login.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><title>Secure Vault - Login</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap');
        body { font-family: 'JetBrains Mono', monospace; background: #09090b; color: #f4f4f5; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .box { width: 100%; max-width: 400px; background: #121216; padding: 30px; border: 1px solid #27272a; border-radius: 8px; box-shadow: 0 0 30px rgba(0,0,0,0.8); }
        h2 { color: #00ff66; margin-top: 0; }
        input { width: 100%; padding: 12px; margin: 10px 0; background: #09090b; border: 1px solid #27272a; color: #fff; border-radius: 6px; box-sizing: border-box; }
        button { width: 100%; padding: 12px; background: #00ff66; color: #000; font-weight: bold; border: none; border-radius: 6px; cursor: pointer; margin-top: 10px; }
        button:hover { background: #00cc52; }
        .link { font-size: 12px; color: #a1a1aa; margin-top: 15px; text-align: center; display: block; text-decoration: none; }
        .link:hover { color: #00ff66; }
    </style>
</head>
<body>
    <div class="box">
        <h2>Client Portal Login</h2>
        <form method="POST">
            <input type="text" name="username" placeholder="Username" required>
            <input type="password" name="password" placeholder="Password" required>
            <button type="submit">Sign In</button>
        </form>
        <a href="/register" class="link">Don't have an account? Register here</a>
    </div>
</body>
</html>
