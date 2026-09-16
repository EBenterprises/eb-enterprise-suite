#!/usr/bin/env bash
set -e

echo "[+] Initializing full-stack restoration of Secure Vault..."

# 1. Create clean directory hierarchy
mkdir -p secure_vault/src/static secure_vault/src/templates secure_vault/data secure_vault/keys secure_vault/deployment

# 2. Install required Python packages silently
pip install --quiet flask cryptography

# 3. Initialize SQLite Database with WAL mode and schema
python3 - << 'DB_INIT'
import sqlite3
import os
import hashlib

db_path = "secure_vault/data/vault_ledger.db"
os.makedirs(os.path.dirname(db_path), exist_ok=True)
conn = sqlite3.connect(db_path, timeout=10.0)
conn.execute("PRAGMA journal_mode=WAL;")
cursor = conn.cursor()

cursor.execute("""
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    is_admin INTEGER DEFAULT 0
)
""")

cursor.execute("""
CREATE TABLE IF NOT EXISTS transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    payload_hash TEXT NOT NULL,
    encrypted_payload BLOB,
    status TEXT DEFAULT 'PENDING',
    FOREIGN KEY (user_id) REFERENCES users (id)
)
""")

# Default admin/manager account
admin_pass = hashlib.sha256("admin123".encode()).hexdigest()
cursor.execute("INSERT OR IGNORE INTO users (id, username, password_hash, is_admin) VALUES (1, 'admin', ?, 1)", (admin_pass,))
cursor.execute("INSERT OR IGNORE INTO users (username, password_hash, is_admin) VALUES ('EBenterprises', ?, 1)", (admin_pass,))
conn.commit()
conn.close()
print("[+] Database initialized successfully.")
DB_INIT

# 4. Generate RSA Cryptographic Keypair
python3 - << 'KEY_INIT'
import os
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

keys_dir = "secure_vault/keys"
os.makedirs(keys_dir, exist_ok=True)
priv_path = os.path.join(keys_dir, "private_key.pem")
pub_path = os.path.join(keys_dir, "public_key.pem")

if not os.path.exists(priv_path):
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    public_key = private_key.public_key()

    with open(priv_path, "wb") as f:
        f.write(private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        ))

    with open(pub_path, "wb") as f:
        f.write(public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        ))
    print("[+] RSA cryptographic keypair generated.")
KEY_INIT

# 5. Create Core Flask Application (app.py)
cat << 'PYTHON_APP' > secure_vault/src/app.py
#!/usr/bin/env python3
import os
import sqlite3
import hashlib
import urllib.request
from flask import Flask, render_template, request, redirect, url_for, session
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.serialization import load_pem_public_key, load_pem_private_key

app = Flask(__name__, template_folder="../templates")
app.secret_key = os.urandom(32)

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DB_PATH = os.path.join(BASE_DIR, "data", "vault_ledger.db")
PUBLIC_KEY_PATH = os.path.join(BASE_DIR, "keys", "public_key.pem")
PRIVATE_KEY_PATH = os.path.join(BASE_DIR, "keys", "private_key.pem")
NTFY_TOPIC = "secure_vault_alerts_easton_999"

def send_push_notification(title, message):
    try:
        data = message.encode('utf-8')
        req = urllib.request.Request(f"https://ntfy.sh/{NTFY_TOPIC}", data=data, headers={"Title": title})
        urllib.request.urlopen(req, timeout=3)
    except Exception as e:
        print(f"[-] Push notification warning: {e}")

def get_db_connection():
    conn = sqlite3.connect(DB_PATH, timeout=10.0)
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.row_factory = sqlite3.Row
    return conn

@app.route("/", methods=["GET", "POST"])
def index():
    if not session.get("user_id"):
        return redirect(url_for('login_page'))

    if request.method == "POST":
        payload = request.form.get("payload", "").strip()
        if payload:
            encrypted_blob = b""
            try:
                if os.path.exists(PUBLIC_KEY_PATH):
                    with open(PUBLIC_KEY_PATH, "rb") as key_file:
                        public_key = load_pem_public_key(key_file.read())
                    encrypted_blob = public_key.encrypt(
                        payload.encode('utf-8'),
                        padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None)
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
            send_push_notification(f"New Order from {session['username']}", "Client submitted an encrypted payload. Log in to review.")
        return redirect(url_for('index'))

    conn = get_db_connection()
    cursor = conn.cursor()
    if session.get("is_admin"):
        cursor.execute("SELECT t.id, u.username, t.timestamp, t.payload_hash, t.status FROM transactions t JOIN users u ON t.user_id = u.id ORDER BY t.id DESC")
    else:
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
            return "Username already taken.", 400
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
        return "Invalid credentials", 403
    return render_template("login.html")

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for('login_page'))

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
    if not session.get("is_admin") and order["user_id"] != session["user_id"]:
        return render_template("unauthorized.html")
    
    decrypted_text = "[Decryption Failed]"
    if order["encrypted_payload"] and os.path.exists(PRIVATE_KEY_PATH):
        try:
            with open(PRIVATE_KEY_PATH, "rb") as key_file:
                private_key = load_pem_private_key(key_file.read(), password=None)
            decrypted_bytes = private_key.decrypt(
                order["encrypted_payload"],
                padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None)
            )
            decrypted_text = decrypted_bytes.decode('utf-8')
        except Exception as e:
            decrypted_text = f"[Decryption Error: {str(e)}]"
            
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
    app.run(host="0.0.0.0", port=5000, debug=True)
PYTHON_APP

# 6. Create Mobile-First Responsive Stylesheet
cat << 'CSS_EOF' > secure_vault/src/static/style.css
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    word-break: break-word;
    overflow-wrap: break-word;
}

html, body {
    width: 100%;
    min-height: 100vh;
    background-color: #064e3b;
    color: #ecfdf5;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    padding: 1rem;
    margin: 0;
}

.container {
    width: 100%;
    max-width: 100%;
    background: #065f46;
    padding: 1.5rem;
    border-radius: 12px;
    box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4);
    display: flex;
    flex-direction: column;
    gap: 1rem;
    border: 1px solid #047857;
}

@media (min-width: 480px) {
    .container {
        max-width: 440px;
    }
}

form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    width: 100%;
}

input, button {
    width: 100%;
    padding: 1rem;
    border: 1px solid #047857;
    border-radius: 8px;
    background: #064e3b;
    color: #ecfdf5;
    font-size: 1rem;
    outline: none;
}

input:focus {
    border-color: #34d399;
}

button {
    background: #059669;
    border: none;
    font-weight: 600;
    cursor: pointer;
    min-height: 50px;
    color: #ffffff;
}

button:hover {
    background: #047857;
}

h2 {
    font-size: 1.5rem;
    text-align: center;
    color: #f1f5f9;
}

label {
    color: #a7f3d0;
    font-size: 0.95rem;
}
CSS_EOF

# 7. Create HTML Templates
cat << 'TEMPLATE_DASH' > secure_vault/templates/dashboard.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Secure Vault - Dashboard</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap');
        body { font-family: 'JetBrains Mono', monospace; background: #064e3b; color: #ecfdf5; margin: 0; padding: 20px; display: flex; justify-content: center; }
        .container { width: 100%; max-width: 1000px; background: #065f46; padding: 25px; border: 1px solid #047857; border-radius: 12px; }
        header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #047857; padding-bottom: 15px; margin-bottom: 25px; flex-wrap: wrap; gap: 10px; }
        h2 { color: #34d399; margin: 0; font-size: 1.3rem; }
        textarea { width: 100%; min-height: 90px; padding: 12px; background: #064e3b; color: #ecfdf5; border: 1px solid #047857; border-radius: 6px; box-sizing: border-box; }
        button { padding: 12px 20px; background: #059669; color: #fff; font-weight: bold; border: none; border-radius: 6px; cursor: pointer; margin-top: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; overflow-x: auto; display: block; white-space: nowrap; }
        th, td { padding: 12px; text-align: left; font-size: 12px; border-bottom: 1px solid #047857; }
        th { background: #064e3b; color: #a7f3d0; text-transform: uppercase; }
        .badge { background: rgba(52,211,153,0.15); color: #34d399; padding: 3px 8px; border-radius: 4px; border: 1px solid rgba(52,211,153,0.3); }
        .btn-action { padding: 5px 10px; font-size: 11px; margin-right: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h2>Welcome, {{ username }} {% if is_admin %}<span style="color:#fca5a5;">[MANAGER]</span>{% endif %}</h2>
            <div>
                <a href="{{ url_for('logout') }}" style="color: #a7f3d0; text-decoration: none; font-size: 12px;">Sign Out</a>
            </div>
        </header>

        <h3>Submit a New Secure Order / Message</h3>
        <form method="POST" action="">
            <textarea name="payload" placeholder="Type your secure order or private instructions here..." required></textarea>
            <button type="submit">Submit Order Securely</button>
        </form>

        <h3 style="margin-top: 30px;">{% if is_admin %}All Client Orders (Manager View){% else %}Your Order History{% endif %}</h3>
        <table>
            <thead>
                <tr>
                    <th>Order #</th>
                    {% if is_admin %}<th>Client</th>{% endif %}
                    <th>Date & Time</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                {% for row in transactions %}
                <tr>
                    <td><a href="{{ url_for('view_order', order_id=row[0]) }}" style="color: #34d399; text-decoration: none;">#{{ row[0] }}</a></td>
                    {% if is_admin %}<td>{{ row[1] }}</td>{% endif %}
                    <td>{{ row[2] }}</td>
                    <td><span class="badge">{{ row[4] }}</span></td>
                    <td>
                        <a href="{{ url_for('view_order', order_id=row[0]) }}" style="background: #047857; color: #fff; padding: 6px 12px; text-decoration: none; border-radius: 4px; font-size: 11px;">View Details</a>
                        {% if is_admin %}
                        <form action="{{ url_for('update_status', order_id=row[0]) }}" method="POST" style="display:inline;">
                            <input type="hidden" name="status" value="APPROVED">
                            <button type="submit" class="btn-action" style="background:rgba(52,211,153,0.2); color:#34d399; border:1px solid #34d399;">Approve</button>
                        </form>
                        <form action="{{ url_for('update_status', order_id=row[0]) }}" method="POST" style="display:inline;">
                            <input type="hidden" name="status" value="REJECTED">
                            <button type="submit" class="btn-action" style="background:rgba(252,165,165,0.2); color:#fca5a5; border:1px solid #fca5a5;">Reject</button>
                        </form>
                        {% endif %}
                    </td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
    </div>
</body>
</html>
TEMPLATE_DASH

cat << 'TEMPLATE_LOGIN' > secure_vault/templates/login.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Secure Vault - Login</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
</head>
<body>
    <div class="container">
        <h2>Secure Vault Sign In</h2>
        <form method="POST">
            <label>Username</label>
            <input type="text" name="username" required placeholder="Enter username...">
            <label>Password</label>
            <input type="password" name="password" required placeholder="Enter password...">
            <button type="submit">Login</button>
        </form>
        <p style="margin-top: 15px; font-size: 12px; text-align: center;">Need an account? <a href="/register" style="color: #34d399;">Register</a></p>
    </div>
</body>
</html>
TEMPLATE_LOGIN

cat << 'TEMPLATE_REG' > secure_vault/templates/register.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Secure Vault - Register</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
</head>
<body>
    <div class="container">
        <h2>Create Account</h2>
        <form method="POST">
            <label>Username</label>
            <input type="text" name="username" required placeholder="Choose username...">
            <label>Password</label>
            <input type="password" name="password" required placeholder="Choose password...">
            <button type="submit">Register</button>
        </form>
        <p style="margin-top: 15px; font-size: 12px; text-align: center;">Already have an account? <a href="/login" style="color: #34d399;">Sign In</a></p>
    </div>
</body>
</html>
TEMPLATE_REG

cat << 'TEMPLATE_DETAIL' > secure_vault/templates/order_detail.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Order #{{ order.id }} - Details</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap');
        body { font-family: 'JetBrains Mono', monospace; background: #064e3b; color: #ecfdf5; padding: 20px; display: flex; justify-content: center; }
        .container { width: 100%; max-width: 800px; background: #065f46; padding: 25px; border: 1px solid #047857; border-radius: 12px; }
        h2 { color: #34d399; margin-top: 0; }
        pre { background: #064e3b; padding: 15px; border: 1px solid #047857; border-radius: 6px; color: #34d399; white-space: pre-wrap; word-break: break-all; }
        a { color: #34d399; text-decoration: none; font-size: 13px; }
    </style>
</head>
<body>
    <div class="container">
        <h2>Order Details: #{{ order.id }}</h2>
        <p><strong>Client:</strong> {{ order.username }}</p>
        <p><strong>Timestamp:</strong> {{ order.timestamp }}</p>
        <p><strong>Status:</strong> {{ order.status }}</p>
        <p><strong>Payload Hash (SHA-256):</strong></p>
        <pre>{{ order.payload_hash }}</pre>
        <p><strong>Decrypted Content Payload:</strong></p>
        <pre>{{ decrypted_text }}</pre>
        <p style="margin-top: 25px;"><a href="/">← Back to Dashboard</a></p>
    </div>
</body>
</html>
TEMPLATE_DETAIL

cat << 'TEMPLATE_UNAUTH' > secure_vault/templates/unauthorized.html
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Unauthorized</title></head>
<body style="background:#064e3b;color:#fca5a5;font-family:monospace;padding:50px;text-align:center;">
    <h2>Access Denied</h2>
    <p>You do not have permission to view this order record.</p>
    <a href="/" style="color:#34d399;">Return to Dashboard</a>
</body>
</html>
TEMPLATE_UNAUTH

# 8. Create Startup Script
cat << 'START_EOF' > secure_vault/deployment/start_server.sh
#!/usr/bin/env bash
cd "$(dirname "$0")/../src"
echo "[*] Starting Secure Vault Web UI Server..."
python3 app.py
START_EOF
chmod +x secure_vault/deployment/start_server.sh

echo "[+] Full-stack restoration complete!"
echo "[+] Starting server now..."
pkill -f "app.py" || true
sleep 1
cd secure_vault/src
python3 app.py &
