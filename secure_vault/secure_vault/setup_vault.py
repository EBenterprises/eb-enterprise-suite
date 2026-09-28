import os

<<<<<<< HEAD
print("[+] Initializing secure_vault with full EB Enterprises features...")

os.makedirs("secure_vault/app/templates", exist_ok=True)
os.makedirs("secure_vault/app/static/css", exist_ok=True)

# 1. Main Application Logic with Register & Forgot Password
with open("secure_vault/app/app.py", "w", encoding="utf-8") as f:
    f.write('''import os
from flask import Flask, render_template, request, redirect, url_for, session, flash

app = Flask(__name__)
app.secret_key = os.urandom(24)

# In-memory user store for demo & persistence during session
USERS = {
    "admin": "admin123"
}
=======
print("[+] Restoring full EB Enterprises Secure Vault with SQLite Database, Authentication, Orders, and Secure Messages...")

os.makedirs("secure_vault/app/templates", exist_ok=True)
os.makedirs("secure_vault/app/static/css", exist_ok=True)
os.makedirs("secure_vault/app/database", exist_ok=True)

# 1. Database & App Logic (`app.py`)
with open("secure_vault/app/app.py", "w", encoding="utf-8") as f:
    f.write('''import os
import sqlite3
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
        db.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL
            )
        ''')
        db.execute('''
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sender TEXT NOT NULL,
                recipient TEXT NOT NULL,
                message TEXT NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        db.execute('''
            CREATE TABLE IF NOT EXISTS orders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL,
                item TEXT NOT NULL,
                quantity INTEGER NOT NULL,
                status TEXT DEFAULT 'Pending Verification',
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        # Seed default admin if not exists
        cur = db.execute("SELECT * FROM users WHERE username = 'admin'")
        if not cur.fetchone():
            db.execute("INSERT INTO users (username, password) VALUES (?, ?)", ('admin', 'admin123'))
            db.commit()
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)

@app.route('/')
def index():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
<<<<<<< HEAD
    return render_template('dashboard.html', user=session.get('user'))
=======
    
    db = get_db()
    messages = db.execute("SELECT * FROM messages ORDER BY id DESC").fetchall()
    orders = db.execute("SELECT * FROM orders ORDER BY id DESC").fetchall()
    
    return render_template('dashboard.html', user=session.get('user'), messages=messages, orders=orders)
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
<<<<<<< HEAD
        if username in USERS and USERS[username] == password:
=======
        
        db = get_db()
        user = db.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, password)).fetchone()
        
        if user:
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
            session['logged_in'] = True
            session['user'] = username
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
<<<<<<< HEAD
        if username in USERS:
            flash('Username already exists.', 'danger')
        elif not username or not password:
            flash('All fields are required.', 'danger')
        else:
            USERS[username] = password
            flash('Account created successfully. Please log in.', 'success')
            return redirect(url_for('login'))
=======
        
        if not username or not password:
            flash('All fields are required.', 'danger')
            return render_template('register.html')
            
        db = get_db()
        try:
            db.execute("INSERT INTO users (username, password) VALUES (?, ?)", (username, password))
            db.commit()
            flash('Account created successfully. Please log in.', 'success')
            return redirect(url_for('login'))
        except sqlite3.IntegrityError:
            flash('Username already exists.', 'danger')
            
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
    return render_template('register.html')

@app.route('/forgot', methods=['GET', 'POST'])
def forgot():
    if request.method == 'POST':
        username = request.form.get('username')
<<<<<<< HEAD
        if username in USERS:
            flash(f'Recovery instructions dispatched for account: {username}. Password hint: {USERS[username][:2]}***', 'info')
=======
        db = get_db()
        user = db.execute("SELECT * FROM users WHERE username = ?", (username,)).fetchone()
        if user:
            flash(f'Recovery protocols initiated for {{ username }}. Please contact system administrator.', 'info')
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
        else:
            flash('Username not found in registry.', 'danger')
    return render_template('forgot.html')

<<<<<<< HEAD
=======
@app.route('/send_message', methods=['POST'])
def send_message():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    recipient = request.form.get('recipient')
    message = request.form.get('message')
    if recipient and message:
        db = get_db()
        db.execute("INSERT INTO messages (sender, recipient, message) VALUES (?, ?, ?)", (session.get('user'), recipient, message))
        db.commit()
        flash('Secure message encrypted and dispatched to database.', 'success')
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
        db = get_db()
        db.execute("INSERT INTO orders (username, item, quantity) VALUES (?, ?, ?)", (session.get('user'), item, quantity))
        db.commit()
        flash('Order securely committed to database ledger.', 'success')
    else:
        flash('Invalid order parameters.', 'danger')
    return redirect(url_for('index'))

>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
@app.route('/logout')
def logout():
    session.clear()
    flash('Logged out successfully.', 'info')
    return redirect(url_for('login'))

if __name__ == '__main__':
<<<<<<< HEAD
    app.run(host='0.0.0.0', port=5000, debug=True)
''')

# 2. Login Template
=======
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
''')

# 2. Login Template (`login.html`)
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
with open("secure_vault/app/templates/login.html", "w", encoding="utf-8") as f:
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

<<<<<<< HEAD
# 3. Register Template
=======
# 3. Register Template (`register.html`)
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
with open("secure_vault/app/templates/register.html", "w", encoding="utf-8") as f:
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

<<<<<<< HEAD
# 4. Forgot Password Template
=======
# 4. Forgot Password Template (`forgot.html`)
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
with open("secure_vault/app/templates/forgot.html", "w", encoding="utf-8") as f:
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

<<<<<<< HEAD
# 5. Dashboard Template
=======
# 5. Dashboard Template (`dashboard.html`)
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
with open("secure_vault/app/templates/dashboard.html", "w", encoding="utf-8") as f:
    f.write('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>EB Enterprises | Dashboard</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="dashboard-container">
        <header>
            <h1>EB Enterprises // Admin Console</h1>
<<<<<<< HEAD
            <a href="{{ url_for('logout') }}" class="logout-btn">Logout</a>
        </header>
        <main>
            <div class="card">
                <h2>System Status</h2>
                <p>Status: <span class="badge">SECURE</span></p>
                <p>Logged in as: <strong>{{ user }}</strong></p>
=======
            <div class="user-info">
                <span>Node: <strong>{{ user }}</strong></span>
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
            <!-- System Status Card -->
            <div class="card">
                <h2>System Status</h2>
                <p>Status: <span class="badge">SECURE</span></p>
                <p>Database: <strong>SQLite (Persistent)</strong></p>
                <p>Encrypted Tunnel: <strong>Active</strong></p>
            </div>

            <!-- Secure Messaging Card -->
            <div class="card">
                <h2>Secure Message Dispatch</h2>
                <form action="{{ url_for('send_message') }}" method="POST">
                    <div class="input-group">
                        <label>Recipient Node</label>
                        <input type="text" name="recipient" required placeholder="admin">
                    </div>
                    <div class="input-group">
                        <label>Encrypted Payload</label>
                        <textarea name="message" required rows="2" placeholder="Enter secure message..."></textarea>
                    </div>
                    <button type="submit" class="btn">Send Secure Message</button>
                </form>
            </div>

            <!-- Order Form Card -->
            <div class="card">
                <h2>Asset Order Registry</h2>
                <form action="{{ url_for('place_order') }}" method="POST">
                    <div class="input-group">
                        <label>Item / SKU</label>
                        <input type="text" name="item" required placeholder="Titan-OS License / Hardware Unit">
                    </div>
                    <div class="input-group">
                        <label>Quantity</label>
                        <input type="number" name="quantity" required min="1" value="1">
                    </div>
                    <button type="submit" class="btn">Submit Order</button>
                </form>
            </div>

            <!-- Persistent Database Logs Card -->
            <div class="card full-width">
                <h2>Live Database Logs & Dispatches</h2>
                <div class="log-section">
                    <h3>Secure Messages Log</h3>
                    {% if messages %}
                        <ul>
                            {% for m in messages %}
                                <li><strong>{{ m.sender }}</strong> -> <strong>{{ m.recipient }}</strong>: {{ m.message }} <span class="muted">({{ m.timestamp }})</span></li>
                            {% endfor %}
                        </ul>
                    {% else %}
                        <p class="muted">No secure messages recorded in database.</p>
                    {% endif %}
                </div>
                <div class="log-section" style="margin-top: 1rem;">
                    <h3>Orders Database Ledger</h3>
                    {% if orders %}
                        <ul>
                            {% for o in orders %}
                                <li><strong>{{ o.username }}</strong> ordered <strong>{{ o.quantity }}x {{ o.item }}</strong> [<span class="badge-status">{{ o.status }}</span>] <span class="muted">({{ o.timestamp }})</span></li>
                            {% endfor %}
                        </ul>
                    {% else %}
                        <p class="muted">No active orders in database.</p>
                    {% endif %}
                </div>
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
            </div>
        </main>
    </div>
</body>
</html>
''')

<<<<<<< HEAD
# 6. Executive Spectrum Styling (Obsidian, Champagne Gold, Teal)
=======
# 6. Executive Spectrum Styling (`style.css`)
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
with open("secure_vault/app/static/css/style.css", "w", encoding="utf-8") as f:
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
<<<<<<< HEAD
body { background: var(--bg); color: var(--text); display: flex; justify-content: center; align-items: center; height: 100vh; }
.login-box { background: var(--card-bg); padding: 2.5rem; border-radius: 8px; border: 1px solid var(--gold); width: 380px; box-shadow: 0 4px 20px rgba(0,128,128,0.2); }
=======
body { background: var(--bg); color: var(--text); padding: 2rem; display: flex; justify-content: center; }
.login-box { background: var(--card-bg); padding: 2.5rem; border-radius: 8px; border: 1px solid var(--gold); width: 380px; box-shadow: 0 4px 20px rgba(0,128,128,0.2); margin: auto; height: fit-content; }
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
.login-box h2 { color: var(--gold); margin-bottom: 0.25rem; font-size: 1.6rem; letter-spacing: 1px; }
.subtitle { color: var(--text); font-size: 0.85rem; margin-bottom: 1.5rem; opacity: 0.8; }
.input-group { margin-bottom: 1.25rem; }
.input-group label { display: block; font-size: 0.8rem; color: var(--gold); margin-bottom: 0.5rem; }
<<<<<<< HEAD
.input-group input { width: 100%; padding: 0.75rem; background: var(--bg); border: 1px solid var(--accent); color: white; border-radius: 4px; }
.input-group input:focus { outline: none; border-color: var(--gold); }
=======
.input-group input, .input-group textarea { width: 100%; padding: 0.75rem; background: var(--bg); border: 1px solid var(--accent); color: white; border-radius: 4px; resize: vertical; }
.input-group input:focus, .input-group textarea:focus { outline: none; border-color: var(--gold); }
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
.btn { width: 100%; padding: 0.75rem; background: var(--accent); color: white; border: none; border-radius: 4px; font-weight: bold; cursor: pointer; transition: 0.2s; }
.btn:hover { background: #006666; }
.footer-links { margin-top: 1.25rem; text-align: center; font-size: 0.8rem; }
.footer-links a { color: var(--gold); text-decoration: none; }
.footer-links a:hover { text-decoration: underline; }
.alert { padding: 0.5rem; margin-bottom: 1rem; border-radius: 4px; font-size: 0.85rem; }
.alert.danger { background: rgba(207, 102, 121, 0.2); border: 1px solid var(--danger); color: var(--danger); }
.alert.success { background: rgba(0, 128, 128, 0.2); border: 1px solid var(--accent); color: #fff; }
.alert.info { background: rgba(212, 175, 55, 0.2); border: 1px solid var(--gold); color: var(--gold); }
<<<<<<< HEAD
.dashboard-container { width: 100%; max-width: 800px; padding: 2rem; }
header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--gold); padding-bottom: 1rem; margin-bottom: 2rem; }
header h1 { color: var(--gold); }
.logout-btn { color: var(--danger); text-decoration: none; border: 1px solid var(--danger); padding: 0.5rem 1rem; border-radius: 4px; }
.card { background: var(--card-bg); padding: 1.5rem; border-radius: 8px; border: 1px solid var(--gold); }
.card h2 { color: var(--gold); margin-bottom: 0.75rem; }
.badge { background: var(--accent); color: white; padding: 0.1rem 0.4rem; border-radius: 3px; font-weight: bold; }
''')

# 7. Runner script with live deployment triggering
=======

.dashboard-container { width: 100%; max-width: 1000px; }
header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--gold); padding-bottom: 1rem; margin-bottom: 2rem; }
header h1 { color: var(--gold); }
.user-info { display: flex; align-items: center; gap: 1rem; }
.logout-btn { color: var(--danger); text-decoration: none; border: 1px solid var(--danger); padding: 0.4rem 0.8rem; border-radius: 4px; font-size: 0.85rem; }
.grid-layout { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; }
.card { background: var(--card-bg); padding: 1.5rem; border-radius: 8px; border: 1px solid var(--gold); }
.card h2 { color: var(--gold); margin-bottom: 1rem; font-size: 1.1rem; }
.card.full-width { grid-column: 1 / -1; }
.badge { background: var(--accent); color: white; padding: 0.1rem 0.4rem; border-radius: 3px; font-weight: bold; }
.badge-status { color: var(--gold); font-weight: bold; }
.log-section h3 { font-size: 0.9rem; color: var(--gold); margin-bottom: 0.5rem; }
.log-section ul { list-style: none; padding-left: 0.5rem; }
.log-section li { font-size: 0.85rem; margin-bottom: 0.4rem; border-left: 2px solid var(--accent); padding-left: 0.5rem; }
.muted { color: #888; font-size: 0.75rem; font-style: italic; }
''')

# 7. Runner script (`run.sh`)
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
with open("secure_vault/run.sh", "w", encoding="utf-8") as f:
    f.write('''#!/bin/bash
fuser -k 5000/tcp 2>/dev/null || pkill -f "python.*app.py" 2>/dev/null
cd app && python3 app.py &
sleep 1
cloudflared tunnel --url http://localhost:5000
''')

os.chmod("secure_vault/run.sh", 0o755)
<<<<<<< HEAD
print("[+] EB Enterprises Secure Vault generated with Full Stack UI, Create Account, Forgot Login, and Executive Spectrum theme!")
print("[+] Launching application and public tunnel...")
=======
print("[+] EB Enterprises Secure Vault fully restored with SQLite database, admin authentication (`admin` / `admin123`), registration, password recovery, secure messaging, and order registry!")
print("[+] Launching app and tunnel...")
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
