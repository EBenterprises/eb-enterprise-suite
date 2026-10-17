<<<<<<< HEAD
import os
from flask import Flask, render_template, request, redirect, url_for, session

app = Flask(__name__)
app.secret_key = os.urandom(24)

USERS = {
    "admin": "password123"
}

MESSAGES = [
    {"sender": "admin", "text": "System encrypted communication channel established.", "timestamp": "2026-08-28 09:00:00"}
]
ORDERS = []

@app.route('/')
def index():
    if 'authenticated' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '')
        matched_user = next((u for u in USERS if u.lower() == username.lower()), None)
        if matched_user and USERS[matched_user] == password:
            session['authenticated'] = True
            session['user'] = matched_user
            return redirect(url_for('dashboard'))
        else:
            error = "Invalid Access Identifier or Decryption Key."
    return render_template('login.html', error=error)

@app.route('/register', methods=['GET', 'POST'])
def register():
    error = None
    success = None
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '')
        if not username or not password:
            error = "All fields are required."
        elif username.lower() in [u.lower() for u in USERS]:
            error = "Access identifier already exists in secure ledger."
        else:
            USERS[username] = password
            success = "Account provisioned successfully. Proceed to authentication."
    return render_template('register.html', error=error, success=success)

@app.route('/forgot', methods=['GET', 'POST'])
def forgot():
    message = None
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        if any(u.lower() == username.lower() for u in USERS):
            message = "Recovery vector dispatched. Check your registered communication channel."
        else:
            message = "Identifier not found in registry."
    return render_template('forgot.html', message=message)

@app.route('/dashboard')
def dashboard():
    if not session.get('authenticated'):
        return redirect(url_for('login'))
    return render_template('dashboard.html', user=session.get('user'))

@app.route('/secrets')
def secrets():
    if not session.get('authenticated'):
        return redirect(url_for('login'))
    stored_secrets = [
        {"id": 1, "title": "Master Node SSH Key", "category": "Infrastructure", "updated": "2026-08-28"},
        {"id": 2, "title": "Porkbun API Bearer Token", "category": "Domain Management", "updated": "2026-08-25"},
        {"id": 3, "title": "Database Root Password", "category": "Database", "updated": "2026-08-20"}
    ]
    return render_template('secrets.html', secrets=stored_secrets)

@app.route('/messaging', methods=['GET', 'POST'])
def messaging():
    if not session.get('authenticated'):
        return redirect(url_for('login'))
    if request.method == 'POST':
        msg = request.form.get('message')
        if msg:
            MESSAGES.append({"sender": session.get('user'), "text": msg, "timestamp": "2026-08-28 09:15:00"})
    return render_template('messaging.html', messages=MESSAGES)

@app.route('/order', methods=['GET', 'POST'])
def order():
    if not session.get('authenticated'):
        return redirect(url_for('login'))
    status = None
    if request.method == 'POST':
        item = request.form.get('item')
        lat = request.form.get('lat')
        lng = request.form.get('lng')
        ORDERS.append({"item": item, "lat": lat, "lng": lng, "user": session.get('user')})
        status = "Order and precise coordinate vector transmitted successfully."
    return render_template('order.html', status=status, orders=ORDERS)

@app.route('/encryption', methods=['GET', 'POST'])
def encryption():
    if not session.get('authenticated'):
        return redirect(url_for('login'))
    result = None
    action = request.form.get('action')
    text = request.form.get('text')
    if request.method == 'POST' and text:
        if action == 'encrypt':
            import base64
            result = base64.b64encode(text.encode()).decode()
        elif action == 'decrypt':
            import base64
            try:
                result = base64.b64decode(text.encode()).decode()
            except Exception:
                result = "Decryption failed: Malformed cipher block."
    return render_template('encryption.html', result=result)

@app.route('/logs')
def logs():
    if not session.get('authenticated'):
        return redirect(url_for('login'))
    system_logs = [
        {"timestamp": "2026-08-28 08:32:34", "level": "INFO", "message": "Vault initialization sequence completed successfully."},
        {"timestamp": "2026-08-28 08:33:53", "level": "WARN", "message": "Authentication attempt processed for user: admin."},
        {"timestamp": "2026-08-28 09:00:00", "level": "INFO", "message": "Secure messaging tunnel active."}
    ]
    return render_template('logs.html', logs=system_logs)

@app.route('/settings')
def settings():
    if not session.get('authenticated'):
        return redirect(url_for('login'))
    return render_template('settings.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5001, debug=True)
=======
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
    if order["encrypted_payload"] and os.path.exists(PRIVATE_KEY_PATH) and session.get("is_admin"):
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
    elif not session.get("is_admin"):
        decrypted_text = "[Client View: Securely encrypted and pending manager review]"
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
    app.run(host="127.0.0.1", port=5001, debug=True)
>>>>>>> origin/main
