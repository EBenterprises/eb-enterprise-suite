import os
import sqlite3
import hashlib
from flask import Flask, render_template, request, redirect, url_for, session, flash

app = Flask(__name__)
app.secret_key = os.urandom(24)
DB_NAME = "vault_auth.db"

def init_db():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            recovery_phrase TEXT
        )
    ''')
    conn.commit()
    conn.close()

def log_audit(action, username):
    print(f"[AUDIT] Action: {action} | User: {username}")

@app.route('/')
def index():
    if 'user' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        hashed_password = hashlib.sha256(password.encode()).hexdigest()
        
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, hashed_password))
        user = cursor.fetchone()
        conn.close()
        
        if user:
            session['user'] = username
            log_audit("LOGIN_SUCCESS", username)
            return redirect(url_for('dashboard'))
        else:
            log_audit("LOGIN_FAILED", username)
            flash("Invalid username or password.")
            
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        recovery = request.form.get('recovery')
        hashed_password = hashlib.sha256(password.encode()).hexdigest()
        hashed_recovery = hashlib.sha256(recovery.encode()).hexdigest() if recovery else ""
        
        try:
            conn = sqlite3.connect(DB_NAME)
            cursor = conn.cursor()
            cursor.execute("INSERT INTO users (username, password, recovery_phrase) VALUES (?, ?, ?)", (username, hashed_password, hashed_recovery))
            conn.commit()
            conn.close()
            log_audit("REGISTER_SUCCESS", username)
            flash("Registration successful. Please log in.")
            return redirect(url_for('login'))
        except sqlite3.IntegrityError:
            log_audit("REGISTER_FAILED_EXISTS", username)
            flash("Username already exists.")
            
    return render_template('register.html')

@app.route('/forgot', methods=['GET', 'POST'])
def forgot():
    if request.method == 'POST':
        username = request.form.get('username')
        recovery = request.form.get('recovery')
        new_password = request.form.get('new_password')
        
        hashed_recovery = hashlib.sha256(recovery.encode()).hexdigest() if recovery else ""
        hashed_new_password = hashlib.sha256(new_password.encode()).hexdigest()
        
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ? AND recovery_phrase = ?", (username, hashed_recovery))
        user = cursor.fetchone()
        
        if user:
            cursor.execute("UPDATE users SET password = ? WHERE username = ?", (hashed_new_password, username))
            conn.commit()
            conn.close()
            log_audit("PASSWORD_RESET_SUCCESS", username)
            flash("Password updated successfully. Please log in.")
            return redirect(url_for('login'))
        else:
            conn.close()
            log_audit("PASSWORD_RESET_FAILED", username)
            flash("Invalid username or recovery phrase.")
            
    return render_template('forgot.html')

@app.route('/dashboard')
def dashboard():
    if 'user' not in session:
        return redirect(url_for('login'))
    return render_template('dashboard.html', username=session['user'])

@app.route('/logout')
def logout():
    user = session.get('user')
    log_audit("LOGOUT", user if user else "UNKNOWN")
    session.pop('user', None)
    return redirect(url_for('login'))

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5001, debug=True)
