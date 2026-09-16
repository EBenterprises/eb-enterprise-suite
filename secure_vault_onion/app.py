from flask import Flask, render_template_string, jsonify, request, redirect, url_for, session, flash
import os
import sqlite3
import hashlib
from datetime import datetime

app = Flask(__name__)
app.secret_key = os.environ.get('VAULT_SECRET_KEY') or 'eb-enterprises-monolith-secure-vault-2026'

DATABASE_DIR = os.path.abspath(os.path.dirname(__file__)) + '/data'
os.makedirs(DATABASE_DIR, exist_ok=True)

def init_db():
    orders_db = os.path.join(DATABASE_DIR, 'encrypted_orders.db')
    messages_db = os.path.join(DATABASE_DIR, 'encrypted_messages.db')
    audit_db = os.path.join(DATABASE_DIR, 'audit_logs.db')
    users_db = os.path.join(DATABASE_DIR, 'users.db')
    
    with sqlite3.connect(orders_db) as conn:
        conn.execute('CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_username TEXT, payload TEXT, status TEXT, notes TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)')
    with sqlite3.connect(messages_db) as conn:
        conn.execute('CREATE TABLE IF NOT EXISTS messages (id INTEGER PRIMARY KEY AUTOINCREMENT, sender TEXT, recipient TEXT, payload TEXT, status TEXT DEFAULT "UNREAD", timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)')
    with sqlite3.connect(audit_db) as conn:
        conn.execute('CREATE TABLE IF NOT EXISTS logs (id INTEGER PRIMARY KEY AUTOINCREMENT, event TEXT, ip_address TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)')
    with sqlite3.connect(users_db) as conn:
        conn.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, password_hash TEXT, recovery_phrase TEXT, role TEXT, status TEXT DEFAULT "ACTIVE")')
        
        cursor = conn.cursor()
        # Seed Administrator
        cursor.execute('SELECT * FROM users WHERE username = ?', ('easton',))
        if not cursor.fetchone():
            pw_hash = hashlib.sha256('vaultsecure2026'.encode()).hexdigest()
            cursor.execute('INSERT INTO users (username, password_hash, recovery_phrase, role) VALUES (?, ?, ?, ?)', 
                           ('easton', pw_hash, 'eb-enterprises-recovery-alpha', 'Administrator'))
            conn.commit()

        # Seed Client Node
        cursor.execute('SELECT * FROM users WHERE username = ?', ('client_node',))
        if not cursor.fetchone():
            pw_hash = hashlib.sha256('clientpass2026'.encode()).hexdigest()
            cursor.execute('INSERT INTO users (username, password_hash, recovery_phrase, role) VALUES (?, ?, ?, ?)', 
                           ('client_node', pw_hash, 'eb-client-recovery', 'Client'))
            conn.commit()

        # Seed Customer Node
        cursor.execute('SELECT * FROM users WHERE username = ?', ('customer_alpha',))
        if not cursor.fetchone():
            pw_hash = hashlib.sha256('customerpass2026'.encode()).hexdigest()
            cursor.execute('INSERT INTO users (username, password_hash, recovery_phrase, role) VALUES (?, ?, ?, ?)', 
                           ('customer_alpha', pw_hash, 'eb-customer-recovery', 'Customer'))
            conn.commit()
            
        with sqlite3.connect(orders_db) as o_conn:
            o_cursor = o_conn.cursor()
            o_cursor.execute('SELECT COUNT(*) FROM orders')
            if o_cursor.fetchone()[0] == 0:
                o_cursor.execute('INSERT INTO orders (customer_username, payload, status, notes) VALUES (?, ?, ?, ?)', 
                                 ('customer_alpha', 'TAP Membership Tier 1 - $30.00/mo Referral Dividend Active', 'PENDING', 'Initial onboarding ingestion payload.'))
                o_conn.commit()

        with sqlite3.connect(messages_db) as m_conn:
            m_cursor = m_conn.cursor()
            m_cursor.execute('SELECT COUNT(*) FROM messages')
            if m_cursor.fetchone()[0] == 0:
                m_cursor.execute('INSERT INTO messages (sender, recipient, payload, status) VALUES (?, ?, ?, ?)', 
                                 ('easton', 'client_node', 'Encrypted monolith sync vector verified. Secure tunnel active.', 'UNREAD'))
                m_conn.commit()

init_db()

def log_audit(event):
    audit_db = os.path.join(DATABASE_DIR, 'audit_logs.db')
    ip = request.remote_addr or '127.0.0.1'
    with sqlite3.connect(audit_db) as conn:
        conn.execute('INSERT INTO logs (event, ip_address) VALUES (?, ?)', (event, ip))
        conn.commit()

# --- EMBEDDED STYLESHEET ---
CSS_STYLE = """
body { background: #07090e; color: #f3f4f6; font-family: monospace; margin: 0; padding: 2rem; }
.vault-container { max-width: 1150px; margin: auto; background: #0d1117; border: 1px solid #30363d; padding: 2rem; border-radius: 6px; box-shadow: 0 8px 24px rgba(0,0,0,0.5); }
h1 { color: #58a6ff; font-size: 1.5rem; border-bottom: 1px solid #30363d; padding-bottom: 0.5rem; margin-top: 0; }
.badge { background: #1f6feb; color: #ffffff; padding: 0.2rem 0.6rem; font-size: 0.75rem; border-radius: 4px; display: inline-block; margin-bottom: 1rem; }
.badge.warning { background: #d29922; color: #0d1117; }
.nav-bar { display: flex; gap: 1rem; margin-bottom: 1.5rem; border-bottom: 1px solid #30363d; padding-bottom: 0.75rem; flex-wrap: wrap; }
.nav-bar a { color: #8b949e; text-decoration: none; padding: 0.3rem 0.6rem; border-radius: 4px; font-size: 0.85rem; }
.nav-bar a:hover, .nav-bar a.active { background: #161b22; color: #58a6ff; border: 1px solid #30363d; }
.nav-bar .admin-link { color: #d29922; }
.nav-bar .logout-link { color: #f85149; }
.section { margin-top: 1.5rem; }
.terminal-box { background: #161b22; border: 1px solid #30363d; padding: 1rem; border-radius: 4px; color: #7ee787; white-space: pre-wrap; overflow-x: auto; }
.form-group { margin-bottom: 1rem; }
label { display: block; margin-bottom: 0.5rem; color: #8b949e; font-size: 0.85rem; }
input[type="text"], input[type="password"], select { width: 100%; padding: 0.5rem; background: #161b22; border: 1px solid #30363d; color: #f3f4f6; border-radius: 4px; font-family: monospace; box-sizing: border-box; }
.btn-submit { background: #238636; color: #ffffff; border: none; padding: 0.75rem 1.5rem; border-radius: 4px; cursor: pointer; font-family: monospace; font-weight: bold; }
.btn-submit:hover { background: #2ea043; }
.inline-form { display: flex; gap: 0.4rem; margin: 0; align-items: center; }
.btn-accept { background: #238636; color: #fff; border: none; padding: 0.3rem 0.6rem; border-radius: 3px; cursor: pointer; font-family: monospace; font-size: 0.75rem; }
.btn-accept:hover { background: #2ea043; }
.btn-reject { background: #da3633; color: #fff; border: none; padding: 0.3rem 0.6rem; border-radius: 3px; cursor: pointer; font-family: monospace; font-size: 0.75rem; }
.btn-reject:hover { background: #e5534b; }
.alert { padding: 0.75rem; border-radius: 4px; margin-bottom: 1rem; font-size: 0.9rem; }
.alert.success { background: #1f883d; color: #ffffff; }
.alert.error { background: #da3633; color: #ffffff; }
.data-table { width: 100%; border-collapse: collapse; margin-top: 0.5rem; font-size: 0.85rem; }
.data-table th, .data-table td { border: 1px solid #30363d; padding: 0.75rem; text-align: left; vertical-align: middle; }
.data-table th { background: #161b22; color: #58a6ff; }
.data-table tr:nth-child(even) { background: #0b0f19; }
.status-badge { padding: 0.2rem 0.5rem; border-radius: 3px; font-size: 0.75rem; font-weight: bold; display: inline-block; }
.status-badge.accepted { background: #1f883d; color: #fff; }
.status-badge.rejected { background: #da3633; color: #fff; }
.status-badge.processing { background: #1f6feb; color: #fff; }
.status-badge.pending { background: #d29922; color: #0d1117; }
.nav-links { margin-top: 1rem; font-size: 0.85rem; }
.nav-links a { color: #58a6ff; text-decoration: none; }
"""

# --- EMBEDDED TEMPLATES ---
BASE_LAYOUT = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Enterprises Secure Vault - Monolith</title>
    <style>""" + CSS_STYLE + """</style>
</head>
<body>
    <div class="vault-container">
        <h1>EB Enterprises Monolithic Vault</h1>
        <div class="badge">SECURE MONOLITH ARCHITECTURE [Operator: {{ username }} | Role: {{ role }}]</div>
        
        <div class="nav-bar">
            {% if role == 'Administrator' %}
            <a href="{{ url_for('index') }}">Dashboard</a>
            <a href="{{ url_for('admin_orders_page') }}">Admin Order Review</a>
            <a href="{{ url_for('orders_page') }}">Orders Registry</a>
            {% elif role == 'Client' %}
            <a href="{{ url_for('client_dashboard') }}">Client Dashboard</a>
            {% elif role == 'Customer' %}
            <a href="{{ url_for('customer_portal') }}">Customer Portal</a>
            {% endif %}
            <a href="{{ url_for('messages_page') }}">Secure Messages</a>
            <a href="{{ url_for('audit_logs_page') }}">Audit Logs</a>
            <a href="{{ url_for('settings_page') }}">Settings</a>
            <a href="{{ url_for('logout') }}" class="logout-link">Logout</a>
        </div>

        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                    <div class="alert {{ category }}">{{ message }}</div>
                {% endfor %}
            {% endif %}
        {% endwith %}

        {% block content %}{% endblock %}
    </div>
</body>
</html>
"""

INDEX_HTML = """
{% extends "base" %}
{% block content %}
<div class="section">
    <h3>Live Encrypted Orders Stream</h3>
    <table class="data-table">
        <thead>
            <tr><th>ID</th><th>Customer</th><th>Payload</th><th>Status</th><th>Timestamp</th></tr>
        </thead>
        <tbody>
            {% for o in orders %}
            <tr>
                <td>#{{ o.id }}</td>
                <td><code>{{ o.customer }}</code></td>
                <td><code>{{ o.payload }}</code></td>
                <td><span class="status-badge {{ o.status | lower }}">{{ o.status }}</span></td>
                <td>{{ o.timestamp }}</td>
            </tr>
            {% else %}
            <tr><td colspan="5">No records in registry.</td></tr>
            {% endfor %}
        </tbody>
    </table>
</div>
{% endblock %}
"""

LOGIN_HTML = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><title>Vault Login</title>
    <style>""" + CSS_STYLE + """</style>
</head>
<body>
    <div class="vault-container" style="max-width: 450px; margin-top: 5rem;">
        <h1>Vault Access Portal</h1>
        <div class="badge warning">AUTHENTICATION REQUIRED</div>
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}{% for cat, msg in messages %}<div class="alert {{ cat }}">{{ msg }}</div>{% endfor %}{% endif %}
        {% endwith %}
        <form method="POST">
            <div class="form-group"><label>Username</label><input type="text" name="username" required></div>
            <div class="form-group"><label>Passphrase</label><input type="password" name="password" required></div>
            <button type="submit" class="btn-submit">Authenticate Node</button>
        </form>
        <div class="nav-links">
            <a href="{{ url_for('register') }}">Register New Node</a> | 
            <a href="{{ url_for('forgot_password') }}">Recover Passphrase</a>
        </div>
    </div>
</body>
</html>
"""

REGISTER_HTML = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><title>Node Registration</title>
    <style>""" + CSS_STYLE + """</style>
</head>
<body>
    <div class="vault-container" style="max-width: 450px; margin-top: 5rem;">
        <h1>Node Registration Portal</h1>
        <div class="badge warning">NEW SECURE ACCOUNT</div>
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}{% for cat, msg in messages %}<div class="alert {{ cat }}">{{ msg }}</div>{% endfor %}{% endif %}
        {% endwith %}
        <form method="POST">
            <div class="form-group"><label>Username</label><input type="text" name="username" required></div>
            <div class="form-group"><label>Passphrase</label><input type="password" name="password" required></div>
            <div class="form-group"><label>Recovery Phrase</label><input type="text" name="recovery_phrase" required></div>
            <div class="form-group"><label>Role Portal</label>
                <select name="role"><option value="Customer">Customer</option><option value="Client">Client</option></select>
            </div>
            <button type="submit" class="btn-submit">Initialize Node</button>
        </form>
        <div class="nav-links"><a href="{{ url_for('login') }}">Return to Login</a></div>
    </div>
</body>
</html>
"""

FORGOT_PASSWORD_HTML = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><title>Passphrase Recovery</title>
    <style>""" + CSS_STYLE + """</style>
</head>
<body>
    <div class="vault-container" style="max-width: 450px; margin-top: 5rem;">
        <h1>Passphrase Recovery</h1>
        <div class="badge warning">SECURE RECOVERY GATEWAY</div>
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}{% for cat, msg in messages %}<div class="alert {{ cat }}">{{ msg }}</div>{% endfor %}{% endif %}
        {% endwith %}
        <form method="POST">
            <div class="form-group"><label>Username</label><input type="text" name="username" required></div>
            <div class="form-group"><label>Recovery Phrase</label><input type="text" name="recovery_phrase" required></div>
            <div class="form-group"><label>New Passphrase</label><input type="password" name="new_password" required></div>
            <button type="submit" class="btn-submit">Execute Recovery</button>
        </form>
        <div class="nav-links"><a href="{{ url_for('login') }}">Return to Login</a></div>
    </div>
</body>
</html>
"""

ADMIN_ORDERS_HTML = """
{% extends "base" %}
{% block content %}
<div class="section">
    <h3>Administrator Order Review Console</h3>
    <table class="data-table">
        <thead>
            <tr><th>ID</th><th>Customer</th><th>Payload</th><th>Status</th><th>Notes</th><th>Action</th></tr>
        </thead>
        <tbody>
            {% for o in orders %}
            <tr>
                <td>#{{ o.id }}</td>
                <td><code>{{ o.customer }}</code></td>
                <td><code>{{ o.payload }}</code></td>
                <td><span class="status-badge {{ o.status | lower }}">{{ o.status }}</span></td>
                <td>{{ o.notes }}</td>
                <td>
                    <form method="POST" class="inline-form">
                        <input type="hidden" name="order_id" value="{{ o.id }}">
                        <input type="text" name="admin_note" placeholder="Note..." style="font-size:0.7rem; width:80px; padding:0.2rem;">
                        <button type="submit" name="action" value="ACCEPTED" class="btn-accept">Accept</button>
                        <button type="submit" name="action" value="PROCESSING" style="background:#1f6feb; color:#fff; border:none; padding:0.3rem 0.5rem; border-radius:3px; cursor:pointer; font-size:0.7rem;">Process</button>
                        <button type="submit" name="action" value="REJECTED" class="btn-reject">Reject</button>
                    </form>
                </td>
            </tr>
            {% else %}
            <tr><td colspan="6">No orders pending review.</td></tr>
            {% endfor %}
        </tbody>
    </table>
</div>
{% endblock %}
"""

CLIENT_DASHBOARD_HTML = """
{% extends "base" %}
{% block content %}
<div class="section">
    <h3>Client Operations Dashboard</h3>
    <table class="data-table">
        <thead>
            <tr><th>ID</th><th>Customer</th><th>Payload</th><th>Status</th><th>Telemetry Notes</th><th>Update</th></tr>
        </thead>
        <tbody>
            {% for o in orders %}
            <tr>
                <td>#{{ o.id }}</td>
                <td><code>{{ o.customer }}</code></td>
                <td><code>{{ o.payload }}</code></td>
                <td><span class="status-badge {{ o.status | lower }}">{{ o.status }}</span></td>
                <td>{{ o.notes }}</td>
                <td>
                    <form method="POST" class="inline-form">
                        <input type="hidden" name="order_id" value="{{ o.id }}">
                        <input type="text" name="client_note" placeholder="Telemetry note..." required style="font-size:0.75rem; padding:0.3rem;">
                        <button type="submit" class="btn-accept" style="font-size:0.75rem; padding:0.3rem 0.6rem;">Save</button>
                    </form>
                </td>
            </tr>
            {% else %}
            <tr><td colspan="6">No orders in client feed.</td></tr>
            {% endfor %}
        </tbody>
    </table>
</div>
{% endblock %}
"""

CUSTOMER_PORTAL_HTML = """
{% extends "base" %}
{% block content %}
<div class="section">
    <h3>Submit New Order / Membership Spec</h3>
    <form method="POST" class="recovery-form">
        <div class="form-group"><label>Order Payload Signature</label><input type="text" name="payload" placeholder="e.g., TAP Membership Tier 1 - $30.00/mo Referral Dividend Active" required></div>
        <div class="form-group"><label>Submission Notes</label><input type="text" name="notes" placeholder="Urgent verification requested." required></div>
        <button type="submit" class="btn-submit">Dispatch Encrypted Order</button>
    </form>
</div>
<div class="section">
    <h3>Your Submissions</h3>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Payload</th><th>Status</th><th>Notes</th><th>Timestamp</th></tr></thead>
        <tbody>
            {% for o in orders %}
            <tr>
                <td>#{{ o.id }}</td>
                <td><code>{{ o.payload }}</code></td>
                <td><span class="status-badge {{ o.status | lower }}">{{ o.status }}</span></td>
                <td>{{ o.notes }}</td>
                <td>{{ o.timestamp }}</td>
            </tr>
            {% else %}
            <tr><td colspan="5">No submissions found.</td></tr>
            {% endfor %}
        </tbody>
    </table>
</div>
{% endblock %}
"""

MESSAGES_HTML = """
{% extends "base" %}
{% block content %}
<div class="section">
    <h3>Secure Messaging Console</h3>
    <form method="POST" class="recovery-form" style="margin-bottom: 2rem;">
        <div class="form-group"><label>Recipient Node</label>
            <select name="recipient" required>
                {% for u in users %}<option value="{{ u }}">{{ u }}</option>{% endfor %}
            </select>
        </div>
        <div class="form-group"><label>Encrypted Payload</label><input type="text" name="payload" required></div>
        <button type="submit" class="btn-submit">Transmit Message</button>
    </form>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Sender</th><th>Recipient</th><th>Payload</th><th>Status</th><th>Timestamp</th></tr></thead>
        <tbody>
            {% for m in messages %}
            <tr>
                <td>#{{ m.id }}</td>
                <td>{{ m.sender }}</td>
                <td>{{ m.recipient }}</td>
                <td><code>{{ m.payload }}</code></td>
                <td>{{ m.status }}</td>
                <td>{{ m.timestamp }}</td>
            </tr>
            {% else %}
            <tr><td colspan="6">No messages found.</td></tr>
            {% endfor %}
        </tbody>
    </table>
</div>
{% endblock %}
"""

AUDIT_LOGS_HTML = """
{% extends "base" %}
{% block content %}
<div class="section">
    <h3>System Audit Trail</h3>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Event Telemetry</th><th>IP Address</th><th>Timestamp</th></tr></thead>
        <tbody>
            {% for l in logs %}
            <tr><td>#{{ l.id }}</td><td>{{ l.event }}</td><td><code>{{ l.ip }}</code></td><td>{{ l.timestamp }}</td></tr>
            {% else %}
            <tr><td colspan="4">No logs recorded.</td></tr>
            {% endfor %}
        </tbody>
    </table>
</div>
{% endblock %}
"""

SETTINGS_HTML = """
{% extends "base" %}
{% block content %}
<div class="section">
    <h3>Vault Configuration & Node Settings</h3>
    <p>Connected Operator: <strong>{{ username }}</strong> [Role: {{ role }}]</p>
    {% if role == 'Administrator' %}
    <h4>Active Vault Nodes Registry</h4>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Username</th><th>Role</th><th>Status</th></tr></thead>
        <tbody>
            {% for u in all_users %}
            <tr><td>#{{ u.id }}</td><td>{{ u.username }}</td><td>{{ u.role }}</td><td>{{ u.status }}</td></tr>
            {% endfor %}
        </tbody>
    </table>
    {% endif %}
</div>
{% endblock %}
"""

ORDERS_HTML = """
{% extends "base" %}
{% block content %}
<div class="section">
    <h3>Global Orders Registry</h3>
    <table class="data-table">
        <thead><tr><th>ID</th><th>Customer</th><th>Payload</th><th>Status</th><th>Notes</th><th>Timestamp</th></tr></thead>
        <tbody>
            {% for o in orders %}
            <tr>
                <td>#{{ o.id }}</td>
                <td><code>{{ o.customer }}</code></td>
                <td><code>{{ o.payload }}</code></td>
                <td><span class="status-badge {{ o.status | lower }}">{{ o.status }}</span></td>
                <td>{{ o.notes }}</td>
                <td>{{ o.timestamp }}</td>
            </tr>
            {% else %}
            <tr><td colspan="6">No orders found.</td></tr>
            {% endfor %}
        </tbody>
    </table>
</div>
{% endblock %}
"""

def render_template_monolith(template_name, **context):
    templates = {
        'base': BASE_LAYOUT,
        'index.html': INDEX_HTML,
        'login.html': LOGIN_HTML,
        'register.html': REGISTER_HTML,
        'forgot_password.html': FORGOT_PASSWORD_HTML,
        'admin_orders.html': ADMIN_ORDERS_HTML,
        'client_dashboard.html': CLIENT_DASHBOARD_HTML,
        'customer_portal.html': CUSTOMER_PORTAL_HTML,
        'messages.html': MESSAGES_HTML,
        'audit_logs.html': AUDIT_LOGS_HTML,
        'settings.html': SETTINGS_HTML,
        'orders.html': ORDERS_HTML
    }
    app.jinja_env.loader = jinja2.DictLoader(templates)
    return render_template_string(templates[template_name], **context)

import jinja2

# --- APPLICATION ROUTES ---

@app.route('/')
def index():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    role = session.get('role')
    if role == 'Administrator':
        orders_db = os.path.join(DATABASE_DIR, 'encrypted_orders.db')
        with sqlite3.connect(orders_db) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT id, customer_username, payload, status, notes, timestamp FROM orders ORDER BY id DESC')
            orders = [{'id': r[0], 'customer': r[1], 'payload': r[2], 'status': r[3], 'notes': r[4], 'timestamp': r[5]} for r in cursor.fetchall()]
        return render_template_monolith('index.html', orders=orders, username=session.get('username'), role=role)
    elif role == 'Client':
        return redirect(url_for('client_dashboard'))
    elif role == 'Customer':
        return redirect(url_for('customer_portal'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        pw_hash = hashlib.sha256(password.encode()).hexdigest()
        
        users_db = os.path.join(DATABASE_DIR, 'users.db')
        with sqlite3.connect(users_db) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT username, role, status FROM users WHERE username = ? AND password_hash = ?', (username, pw_hash))
            user = cursor.fetchone()
            
            if user:
                if user[2] == 'SUSPENDED':
                    flash('Access Denied: Node is suspended.', 'error')
                    return redirect(url_for('login'))
                session['logged_in'] = True
                session['username'] = user[0]
                session['role'] = user[1]
                log_audit(f"Successful authentication for {user[1].lower()} node: {username}")
                flash('Vault session authorized.', 'success')
                return redirect(url_for('index'))
            else:
                log_audit(f"Failed authentication attempt for username: {username}")
                flash('Access Denied: Invalid credentials.', 'error')
    return render_template_monolith('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        recovery_phrase = request.form.get('recovery_phrase')
        role = request.form.get('role', 'Customer')
        pw_hash = hashlib.sha256(password.encode()).hexdigest()
        
        users_db = os.path.join(DATABASE_DIR, 'users.db')
        try:
            with sqlite3.connect(users_db) as conn:
                conn.execute('INSERT INTO users (username, password_hash, recovery_phrase, role) VALUES (?, ?, ?, ?)',
                             (username, pw_hash, recovery_phrase, role))
                conn.commit()
                log_audit(f"New node registered: {username}")
                flash('Node registered successfully.', 'success')
                return redirect(url_for('login'))
        except sqlite3.IntegrityError:
            flash('Registration failed: Username already exists.', 'error')
    return render_template_monolith('register.html')

@app.route('/logout')
def logout():
    log_audit(f"Session terminated for node: {session.get('username')}")
    session.clear()
    flash('Vault session terminated.', 'success')
    return redirect(url_for('login'))

@app.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    if request.method == 'POST':
        username = request.form.get('username')
        recovery_phrase = request.form.get('recovery_phrase')
        new_password = request.form.get('new_password')
        
        users_db = os.path.join(DATABASE_DIR, 'users.db')
        with sqlite3.connect(users_db) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM users WHERE username = ? AND recovery_phrase = ?', (username, recovery_phrase))
            user = cursor.fetchone()
            
            if user:
                new_pw_hash = hashlib.sha256(new_password.encode()).hexdigest()
                cursor.execute('UPDATE users SET password_hash = ? WHERE username = ?', (new_pw_hash, username))
                conn.commit()
                log_audit(f"Passphrase recovery executed for: {username}")
                flash('Passphrase updated successfully.', 'success')
                return redirect(url_for('login'))
            else:
                flash('Recovery Failed: Invalid credentials.', 'error')
    return render_template_monolith('forgot_password.html')

@app.route('/client/dashboard', methods=['GET', 'POST'])
def client_dashboard():
    if not session.get('logged_in') or session.get('role') != 'Client':
        flash('Access Denied.', 'error')
        return redirect(url_for('login'))
    
    orders_db = os.path.join(DATABASE_DIR, 'encrypted_orders.db')
    if request.method == 'POST':
        order_id = request.form.get('order_id')
        client_note = request.form.get('client_note')
        if order_id and client_note:
            with sqlite3.connect(orders_db) as conn:
                conn.execute('UPDATE orders SET notes = ? WHERE id = ?', (client_note, order_id))
                conn.commit()
            log_audit(f"Client updated telemetry on Order #{order_id}")
            flash('Telemetry updated.', 'success')
            return redirect(url_for('client_dashboard'))

    with sqlite3.connect(orders_db) as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT id, customer_username, payload, status, notes, timestamp FROM orders ORDER BY id DESC')
        orders = [{'id': r[0], 'customer': r[1], 'payload': r[2], 'status': r[3], 'notes': r[4], 'timestamp': r[5]} for r in cursor.fetchall()]
    return render_template_monolith('client_dashboard.html', orders=orders, username=session.get('username'), role='Client')

@app.route('/customer/portal', methods=['GET', 'POST'])
def customer_portal():
    if not session.get('logged_in') or session.get('role') != 'Customer':
        flash('Access Denied.', 'error')
        return redirect(url_for('login'))
        
    orders_db = os.path.join(DATABASE_DIR, 'encrypted_orders.db')
    if request.method == 'POST':
        payload = request.form.get('payload')
        notes = request.form.get('notes', 'Standard submission.')
        if payload:
            with sqlite3.connect(orders_db) as conn:
                conn.execute('INSERT INTO orders (customer_username, payload, status, notes) VALUES (?, ?, ?, ?)',
                             (session.get('username'), payload, 'PENDING', notes))
                conn.commit()
            log_audit(f"Customer submitted order: {session.get('username')}")
            flash('Order dispatched successfully.', 'success')
            return redirect(url_for('customer_portal'))

    with sqlite3.connect(orders_db) as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT id, payload, status, notes, timestamp FROM orders WHERE customer_username = ? ORDER BY id DESC', (session.get('username'),))
        orders = [{'id': r[0], 'payload': r[1], 'status': r[2], 'notes': r[3], 'timestamp': r[4]} for r in cursor.fetchall()]
    return render_template_monolith('customer_portal.html', orders=orders, username=session.get('username'), role='Customer')

@app.route('/admin/orders', methods=['GET', 'POST'])
def admin_orders_page():
    if not session.get('logged_in') or session.get('role') != 'Administrator':
        flash('Access Denied.', 'error')
        return redirect(url_for('index'))
    
    orders_db = os.path.join(DATABASE_DIR, 'encrypted_orders.db')
    if request.method == 'POST':
        order_id = request.form.get('order_id')
        action = request.form.get('action')
        admin_note = request.form.get('admin_note')
        if order_id and action in ['ACCEPTED', 'REJECTED', 'PROCESSING']:
            with sqlite3.connect(orders_db) as conn:
                if admin_note:
                    conn.execute('UPDATE orders SET status = ?, notes = ? WHERE id = ?', (action, admin_note, order_id))
                else:
                    conn.execute('UPDATE orders SET status = ? WHERE id = ?', (action, order_id))
                conn.commit()
            log_audit(f"Order #{order_id} marked as {action}")
            flash(f"Order #{order_id} status updated to {action.lower()}.", 'success')
            return redirect(url_for('admin_orders_page'))

    with sqlite3.connect(orders_db) as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT id, customer_username, payload, status, notes, timestamp FROM orders ORDER BY id DESC')
        orders = [{'id': r[0], 'customer': r[1], 'payload': r[2], 'status': r[3], 'notes': r[4], 'timestamp': r[5]} for r in cursor.fetchall()]
    return render_template_monolith('admin_orders.html', orders=orders, username=session.get('username'), role='Administrator')

@app.route('/orders')
def orders_page():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    orders_db = os.path.join(DATABASE_DIR, 'encrypted_orders.db')
    with sqlite3.connect(orders_db) as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT id, customer_username, payload, status, notes, timestamp FROM orders ORDER BY id DESC')
        orders = [{'id': r[0], 'customer': r[1], 'payload': r[2], 'status': r[3], 'notes': r[4], 'timestamp': r[5]} for r in cursor.fetchall()]
    return render_template_monolith('orders.html', orders=orders, username=session.get('username'), role=session.get('role'))

@app.route('/messages', methods=['GET', 'POST'])
def messages_page():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    messages_db = os.path.join(DATABASE_DIR, 'encrypted_messages.db')
    users_db = os.path.join(DATABASE_DIR, 'users.db')
    
    if request.method == 'POST':
        recipient = request.form.get('recipient')
        payload = request.form.get('payload')
        if recipient and payload:
            with sqlite3.connect(messages_db) as conn:
                conn.execute('INSERT INTO messages (sender, recipient, payload, status) VALUES (?, ?, ?, ?)',
                             (session.get('username'), recipient, payload, 'UNREAD'))
                conn.commit()
            log_audit(f"Message dispatched from {session.get('username')} to {recipient}")
            flash('Message transmitted.', 'success')
            return redirect(url_for('messages_page'))

    with sqlite3.connect(users_db) as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT username FROM users WHERE username != ?', (session.get('username'),))
        users = [r[0] for r in cursor.fetchall()]

    with sqlite3.connect(messages_db) as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT id, sender, recipient, payload, status, timestamp FROM messages WHERE sender = ? OR recipient = ? ORDER BY id DESC', 
                       (session.get('username'), session.get('username')))
        messages = [{'id': r[0], 'sender': r[1], 'recipient': r[2], 'payload': r[3], 'status': r[4], 'timestamp': r[5]} for r in cursor.fetchall()]
    return render_template_monolith('messages.html', messages=messages, users=users, username=session.get('username'), role=session.get('role'))

@app.route('/audit-logs')
def audit_logs_page():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    audit_db = os.path.join(DATABASE_DIR, 'audit_logs.db')
    with sqlite3.connect(audit_db) as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT id, event, ip_address, timestamp FROM logs ORDER BY id DESC LIMIT 100')
        logs = [{'id': r[0], 'event': r[1], 'ip': r[2], 'timestamp': r[3]} for r in cursor.fetchall()]
    return render_template_monolith('audit_logs.html', logs=logs, username=session.get('username'), role=session.get('role'))

@app.route('/settings')
def settings_page():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    all_users = []
    if session.get('role') == 'Administrator':
        users_db = os.path.join(DATABASE_DIR, 'users.db')
        with sqlite3.connect(users_db) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT id, username, role, status FROM users')
            all_users = [{'id': r[0], 'username': r[1], 'role': r[2], 'status': r[3]} for r in cursor.fetchall()]
    return render_template_monolith('settings.html', username=session.get('username'), role=session.get('role'), all_users=all_users)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
