import os
<<<<<<< HEAD
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
        db.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                role TEXT DEFAULT 'client'
            )
        ''')
        db.execute('''
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sender TEXT NOT NULL,
                recipient TEXT NOT NULL,
                payload TEXT NOT NULL,
                payload_hash TEXT NOT NULL,
                status TEXT DEFAULT 'Pending Review',
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        db.execute('''
            CREATE TABLE IF NOT EXISTS orders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL,
                item TEXT NOT NULL,
                quantity INTEGER NOT NULL,
                payload_hash TEXT NOT NULL,
                status TEXT DEFAULT 'Pending Review',
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Seed default admin
        cur = db.execute("SELECT * FROM users WHERE username = 'admin'")
        if not cur.fetchone():
            db.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)", ('admin', 'admin123', 'admin'))
            db.commit()
=======
from flask import Flask, render_template, request, redirect, url_for, session, flash

app = Flask(__name__)
app.secret_key = os.urandom(24)

ADMIN_USER = "admin"
ADMIN_PASS = "admin123"
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)

@app.route('/')
def index():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
<<<<<<< HEAD
    
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
=======
    return render_template('dashboard.html', user=session.get('user'))
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
<<<<<<< HEAD
        
        db = get_db()
        user = db.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, password)).fetchone()
        
        if user:
            session['logged_in'] = True
            session['user'] = user['username']
            session['role'] = user['role']
=======
        if username == ADMIN_USER and password == ADMIN_PASS:
            session['logged_in'] = True
            session['user'] = username
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
            flash('Successfully authenticated into EB Enterprises vault.', 'success')
            return redirect(url_for('index'))
        else:
            flash('Invalid credentials. Access denied.', 'danger')
    return render_template('login.html')

<<<<<<< HEAD
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

=======
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
@app.route('/logout')
def logout():
    session.clear()
    flash('Logged out successfully.', 'info')
    return redirect(url_for('login'))

if __name__ == '__main__':
<<<<<<< HEAD
    init_db()
=======
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
    app.run(host='0.0.0.0', port=5000, debug=True)
