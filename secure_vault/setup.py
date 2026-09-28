import os

print("[+] Restoring EB Enterprises Secure Vault with Admin Review Console, Cryptographic Payload Hashing, and Accept/Reject Workflows...")

os.makedirs("app/templates", exist_ok=True)
os.makedirs("app/static/css", exist_ok=True)
os.makedirs("app/database", exist_ok=True)

# 1. Main Application Logic (`app.py`)
with open("app/app.py", "w", encoding="utf-8") as f:
    f.write('''import os
import sqlite3
import hashlib
import base64
from flask import Flask, render_template, request, redirect, url_for, session, g, flash

app = Flask(__name__)
app.secret_key = os.urandom(24)
DATABASE = 'database/vault.db'

def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DATABASE)
        db.row_factory = sqlite3.Row
    return db

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

def init_db():
    with app.app_context():
        db = get_db()
        db.execute(\'''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                role TEXT DEFAULT 'client'
            )
        \''')
        db.execute(\'''
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sender TEXT NOT NULL,
                recipient TEXT NOT NULL,
                payload TEXT NOT NULL,
                payload_hash TEXT NOT NULL,
                status TEXT DEFAULT 'Pending Review',
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        \''')
        db.execute(\'''
            CREATE TABLE IF NOT EXISTS orders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL,
                item TEXT NOT NULL,
                quantity INTEGER NOT NULL,
                payload_hash TEXT NOT NULL,
                status TEXT DEFAULT 'Pending Review',
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        \''')
        
        # Seed default admin
        cur = db.execute("SELECT * FROM users WHERE username = 'admin'")
        if not cur.fetchone():
            db.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)", ('admin', 'admin123', 'admin'))
            db.commit()

@app.route('/')
def index():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    
    db = get_db()
    user_role = session.get('role', 'client')
    username = session.get('user')
    
    if user_role == 'admin':
        messages = db.execute("SELECT * FROM messages ORDER BY id DESC").fetchall()
        orders = db.execute("SELECT * FROM orders ORDER BY id DESC").fetchall()
    else:
        messages = db.execute("SELECT * FROM messages WHERE sender = ? OR recipient = ? ORDER BY id DESC", (username, username)).fetchall()
        orders = db.execute("SELECT * FROM orders WHERE username = ? ORDER BY id DESC", (username,)).fetchall()
        
    return render_template('dashboard.html', user=username, role=user_role, messages=messages, orders=orders)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        db = get_db()
        user = db.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, password)).fetchone()
        
        if user:
            session['logged_in'] = True
            session['user'] = user['username']
            session['role'] = user['role']
            flash('Successfully authenticated into EB Enterprises vault.', 'success')
            return redirect(url_for('index'))
        else:
            flash('Invalid credentials. Access denied.', 'danger')
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if not username or not password:
            flash('All fields are required.', 'danger')
            return render_template('register.html')
            
        db = get_db()
        try:
            db.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)", (username, password, 'client'))
            db.commit()
            flash('Client node registered successfully. Please log in.', 'success')
            return redirect(url_for('login'))
        except sqlite3.IntegrityError:
            flash('Username already exists.', 'danger')
            
    return render_template('register.html')

@app.route('/forgot', methods=['GET', 'POST'])
def forgot():
    if request.method == 'POST':
        username = request.form.get('username')
        db = get_db()
        user = db.execute("SELECT * FROM users WHERE username = ?", (username,)).fetchone()
        if user:
            flash(f'Recovery sequence initialized for node: {username}. Contact system administrator.', 'info')
        else:
            flash('Username not found in registry.', 'danger')
    return render_template('forgot.html')

@app.route('/send_message', methods=['POST'])
def send_message():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
        
    recipient = request.form.get('recipient')
    raw_message = request.form.get('message')
    
    if recipient and raw_message:
        # Encrypt message payload (Base64 wrapper simulating secure vault cipher)
        encrypted_payload = base64.b64encode(raw_message.encode('utf-8')).decode('utf-8')
        payload_hash = hashlib.sha256(raw_message.encode('utf-8')).hexdigest()
        
        db = get_db()
        db.execute("INSERT INTO messages (sender, recipient, payload, payload_hash, status) VALUES (?, ?, ?, ?, ?)",
                   (session.get('user'), recipient, encrypted_payload, payload_hash, 'Pending Review'))
        db.commit()
        flash('Secure message encrypted, hashed, and dispatched for admin review.', 'success')
    else:
        flash('All message fields are required.', 'danger')
    return redirect(url_for('index'))

@app.route('/place_order', methods=['POST'])
def place_order():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
        
    item = request.form.get('item')
    quantity = request.form.get('quantity')
    
    if item and quantity:
        raw_data = f"{session.get('user')}:{item}:{quantity}"
        payload_hash = hashlib.sha256(raw_data.encode('utf-8')).hexdigest()
        
        db = get_db()
        db.execute("INSERT INTO orders (username, item, quantity, payload_hash, status) VALUES (?, ?, ?, ?, ?)",
                   (session.get('user'), item, quantity, payload_hash, 'Pending Review'))
        db.commit()
        flash('Asset order registered with cryptographic checksum for admin review.', 'success')
    else:
        flash('Invalid order parameters.', 'danger')
    return redirect(url_for('index'))

@app.route('/review/<item_type>/<int:item_id>/<action>', methods=['POST'])
def review_item(item_type, item_id, action):
    if session.get('role') != 'admin':
        flash('Unauthorized administrative action.', 'danger')
        return redirect(url_for('index'))
        
    new_status = 'Approved & Accepted' if action == 'accept' else 'Rejected & Terminated'
    table = 'messages' if item_type == 'message' else 'orders'
    
    db = get_db()
    db.execute(f"UPDATE {table} SET status = ? WHERE id = ?", (new_status, item_id))
    db.commit()
    
    flash(f'{item_type.capitalize()} #{item_id} successfully marked as {new_status}.', 'success')
    return redirect(url_for('index'))

@app.route('/logout')
def logout():
    session.clear()
    flash('Logged out successfully.', 'info')
    return redirect(url_for('login'))

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
''')

# 2. Login Template (`login.html`)
with open("app/templates/login.html", "w", encoding="utf-8") as f:
    f.write('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>EB Enterprises | Vault Login</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="login-box">
        <h2>EB Enterprises</h2>
        <p class="subtitle">Secure Vault Control Center</p>
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                    <div class="alert {{ category }}">{{ message }}</div>
                {% endfor %}
            {% endif %}
        {% endwith %}
        <form method="POST">
            <div class="input-group">
                <label>Username</label>
                <input type="text" name="username" required autocomplete="off">
            </div>
            <div class="input-group">
                <label>Password</label>
                <input type="password" name="password" required>
            </div>
            <button type="submit" class="btn">Authenticate</button>
        </form>
        <div class="footer-links">
            <a href="{{ url_for('register') }}">Create Account</a> | 
            <a href="{{ url_for('forgot') }}">Forgot Login?</a>
        </div>
    </div>
</body>
</html>
''')

# 3. Register Template (`register.html`)
with open("app/templates/register.html", "w", encoding="utf-8") as f:
    f.write('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>EB Enterprises | Register</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="login-box">
        <h2>EB Enterprises</h2>
        <p class="subtitle">Register New Node Access</p>
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                    <div class="alert {{ category }}">{{ message }}</div>
                {% endfor %}
            {% endif %}
        {% endwith %}
        <form method="POST">
            <div class="input-group">
                <label>New Username</label>
                <input type="text" name="username" required autocomplete="off">
            </div>
            <div class="input-group">
                <label>New Password</label>
                <input type="password" name="password" required>
            </div>
            <button type="submit" class="btn">Create Account</button>
        </form>
        <div class="footer-links">
            <a href="{{ url_for('login') }}">Back to Login</a>
        </div>
    </div>
</body>
</html>
''')

# 4. Forgot Password Template (`forgot.html`)
with open("app/templates/forgot.html", "w", encoding="utf-8") as f:
    f.write('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>EB Enterprises | Recovery</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="login-box">
        <h2>EB Enterprises</h2>
        <p class="subtitle">Credential Recovery</p>
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                    <div class="alert {{ category }}">{{ message }}</div>
                {% endfor %}
            {% endif %}
        {% endwith %}
        <form method="POST">
            <div class="input-group">
                <label>Registered Username</label>
                <input type="text" name="username" required autocomplete="off">
            </div>
            <button type="submit" class="btn">Recover Access</button>
        </form>
        <div class="footer-links">
            <a href="{{ url_for('login') }}">Back to Login</a>
        </div>
    </div>
</body>
</html>
''')

# 5. Dashboard Template (`dashboard.html`)
with open("app/templates/dashboard.html", "w", encoding="utf-8") as f:
    f.write('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>EB Enterprises | Secure Vault Dashboard</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="dashboard-container">
        <header>
            <h1>EB Enterprises // Secure Vault Console</h1>
            <div class="user-info">
                <span>Node: <strong>{{ user }}</strong> [Role: <span class="badge">{{ role|upper }}</span>]</span>
                <a href="{{ url_for('logout') }}" class="logout-btn">Logout</a>
            </div>
        </header>

        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                    <div class="alert {{ category }}">{{ message }}</div>
                {% endfor %}
            {% endif %}
        {% endwith %}

        <main class="grid-layout">
            <!-- System Status -->
            <div class="card">
                <h2>Vault Status</h2>
                <p>Status: <span class="badge">ONLINE & SECURE</span></p>
                <p>Cipher Engine: <strong>AES / SHA-256 Hashing</strong></p>
                <p>Review Mode: <strong>Active (Accept / Reject)</strong></p>
            </div>

            <!-- Secure Message Dispatch -->
            <div class="card">
                <h2>Encrypted Message Dispatch</h2>
                <form action="{{ url_for('send_message') }}" method="POST">
                    <div class="input-group">
                        <label>Recipient Node</label>
                        <input type="text" name="recipient" required placeholder="admin">
                    </div>
                    <div class="input-group">
                        <label>Message Payload</label>
                        <textarea name="message" required rows="2" placeholder="Enter confidential message..."></textarea>
                    </div>
                    <button type="submit" class="btn">Encrypt & Dispatch</button>
                </form>
            </div>

            <!-- Asset Order Registry -->
            <div class="card">
                <h2>Asset Order Registry</h2>
                <form action="{{ url_for('place_order') }}" method="POST">
                    <div class="input-group">
                        <label>Item / License SKU</label>
                        <input type="text" name="item" required placeholder="Titan-OS Module / Hardware Unit">
                    </div>
                    <div class="input-group">
                        <label>Quantity</label>
                        <input type="number" name="quantity" required min="1" value="1">
                    </div>
                    <button type="submit" class="btn">Commit Order Ledger</button>
                </form>
            </div>

            <!-- Review Queues (Messages & Orders) -->
            <div class="card full-width">
                <h2>Cryptographic Audit Trail & Admin Review Console</h2>
                
                <div class="log-section">
                    <h3>Encrypted Messages Queue</h3>
                    {% if messages %}
                        <ul>
                            {% for m in messages %}
                                <li>
                                    <div>
                                        <strong>{{ m.sender }}</strong> -> <strong>{{ m.recipient }}</strong><br>
                                        <span class="muted">Encrypted Payload (Base64):</span> <code>{{ m.payload }}</code><br>
                                        <span class="muted">SHA-256 Hash:</span> <code class="hash-text">{{ m.payload_hash }}</code><br>
                                        <span class="muted">Timestamp:</span> {{ m.timestamp }} | Status: <span class="badge-status">{{ m.status }}</span>
                                    </div>
                                    {% if role == 'admin' and m.status == 'Pending Review' %}
                                        <div class="action-buttons">
                                            <form action="{{ url_for('review_item', item_type='message', item_id=m.id, action='accept') }}" method="POST" style="display:inline;">
                                                <button type="submit" class="btn-accept">Accept</button>
                                            </form>
                                            <form action="{{ url_for('review_item', item_type='message', item_id=m.id, action='reject') }}" method="POST" style="display:inline;">
                                                <button type="submit" class="btn-reject">Reject</button>
                                            </form>
                                        </div>
                                    {% endif %}
                                </li>
                            {% endfor %}
                        </ul>
                    {% else %}
                        <p class="muted">No secure messages in vault.</p>
                    {% endif %}
                </div>

                <div class="log-section" style="margin-top: 1.5rem;">
                    <h3>Asset Orders Queue</h3>
                    {% if orders %}
                        <ul>
                            {% for o in orders %}
                                <li>
                                    <div>
                                        <strong>Node: {{ o.username }}</strong> requested <strong>{{ o.quantity }}x {{ o.item }}</strong><br>
                                        <span class="muted">SHA-256 Hash Checksum:</span> <code class="hash-text">{{ o.payload_hash }}</code><br>
                                        <span class="muted">Timestamp:</span> {{ o.timestamp }} | Status: <span class="badge-status">{{ o.status }}</span>
                                    </div>
                                    {% if role == 'admin' and o.status == 'Pending Review' %}
                                        <div class="action-buttons">
                                            <form action="{{ url_for('review_item', item_type='order', item_id=o.id, action='accept') }}" method="POST" style="display:inline;">
                                                <button type="submit" class="btn-accept">Accept</button>
                                            </form>
                                            <form action="{{ url_for('review_item', item_type='order', item_id=o.id, action='reject') }}" method="POST" style="display:inline;">
                                                <button type="submit" class="btn-reject">Reject</button>
                                            </form>
                                        </div>
                                    {% endif %}
                                </li>
                            {% endfor %}
                        </ul>
                    {% else %}
                        <p class="muted">No asset orders in vault ledger.</p>
                    {% endif %}
                </div>
            </div>
        </main>
    </div>
</body>
</html>
''')

# 6. Executive Spectrum Styling (`style.css`)
with open("app/static/css/style.css", "w", encoding="utf-8") as f:
    f.write('''
:root {
    --bg: #0B0C10;
    --card-bg: #1F2833;
    --accent: #008080;
    --gold: #D4AF37;
    --text: #C5C6C7;
    --danger: #cf6679;
    --success: #008080;
}
* { box-sizing: border-box; margin: 0; padding: 0; font-family: monospace, sans-serif; }
body { background: var(--bg); color: var(--text); padding: 2rem; display: flex; justify-content: center; }
.login-box { background: var(--card-bg); padding: 2.5rem; border-radius: 8px; border: 1px solid var(--gold); width: 380px; box-shadow: 0 4px 20px rgba(0,128,128,0.2); margin: auto; height: fit-content; }
.login-box h2 { color: var(--gold); margin-bottom: 0.25rem; font-size: 1.6rem; letter-spacing: 1px; }
.subtitle { color: var(--text); font-size: 0.85rem; margin-bottom: 1.5rem; opacity: 0.8; }
.input-group { margin-bottom: 1.25rem; }
.input-group label { display: block; font-size: 0.8rem; color: var(--gold); margin-bottom: 0.5rem; }
.input-group input, .input-group textarea { width: 100%; padding: 0.75rem; background: var(--bg); border: 1px solid var(--accent); color: white; border-radius: 4px; resize: vertical; }
.input-group input:focus, .input-group textarea:focus { outline: none; border-color: var(--gold); }
.btn { width: 100%; padding: 0.75rem; background: var(--accent); color: white; border: none; border-radius: 4px; font-weight: bold; cursor: pointer; transition: 0.2s; }
.btn:hover { background: #006666; }
.footer-links { margin-top: 1.25rem; text-align: center; font-size: 0.8rem; }
.footer-links a { color: var(--gold); text-decoration: none; }
.footer-links a:hover { text-decoration: underline; }
.alert { padding: 0.5rem; margin-bottom: 1rem; border-radius: 4px; font-size: 0.85rem; }
.alert.danger { background: rgba(207, 102, 121, 0.2); border: 1px solid var(--danger); color: var(--danger); }
.alert.success { background: rgba(0, 128, 128, 0.2); border: 1px solid var(--accent); color: #fff; }
.alert.info { background: rgba(212, 175, 55, 0.2); border: 1px solid var(--gold); color: var(--gold); }

.dashboard-container { width: 100%; max-width: 1100px; }
header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--gold); padding-bottom: 1rem; margin-bottom: 2rem; }
header h1 { color: var(--gold); }
.user-info { display: flex; align-items: center; gap: 1rem; }
.logout-btn { color: var(--danger); text-decoration: none; border: 1px solid var(--danger); padding: 0.4rem 0.8rem; border-radius: 4px; font-size: 0.85rem; }
.grid-layout { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 1.5rem; }
.card { background: var(--card-bg); padding: 1.5rem; border-radius: 8px; border: 1px solid var(--gold); }
.card h2 { color: var(--gold); margin-bottom: 1rem; font-size: 1.1rem; }
.card.full-width { grid-column: 1 / -1; }
.badge { background: var(--accent); color: white; padding: 0.1rem 0.4rem; border-radius: 3px; font-weight: bold; }
.badge-status { color: var(--gold); font-weight: bold; }
.log-section h3 { font-size: 0.95rem; color: var(--gold); margin-bottom: 0.75rem; border-bottom: 1px dashed var(--accent); padding-bottom: 0.25rem; }
.log-section ul { list-style: none; padding-left: 0; }
.log-section li { background: rgba(11, 12, 16, 0.5); font-size: 0.85rem; margin-bottom: 0.75rem; border-left: 3px solid var(--gold); padding: 0.75rem; border-radius: 4px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem; }
.hash-text { font-size: 0.75rem; color: var(--gold); word-break: break-all; }
.muted { color: #888; font-size: 0.75rem; }
.action-buttons { display: flex; gap: 0.5rem; }
.btn-accept { background: var(--accent); color: white; border: none; padding: 0.4rem 0.8rem; border-radius: 4px; font-weight: bold; cursor: pointer; }
.btn-accept:hover { background: #006666; }
.btn-reject { background: var(--danger); color: white; border: none; padding: 0.4rem 0.8rem; border-radius: 4px; font-weight: bold; cursor: pointer; }
.btn-reject:hover { background: #b04b5c; }
''')

# 7. Runner script (`run.sh`)
with open("run.sh", "w", encoding="utf-8") as f:
    f.write('''#!/bin/bash
fuser -k 5000/tcp 2>/dev/null || pkill -f "python.*app.py" 2>/dev/null
cd app && python3 app.py &
sleep 1
cloudflared tunnel --url http://localhost:5000
''')

os.chmod("run.sh", 0o755)
print("[+] EB Enterprises Secure Vault successfully restored with encrypted payloads, SHA-256 hashes, and Admin Accept/Reject review workflows!")
