import os
import sqlite3
import hashlib
from datetime import datetime
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
            birthday TEXT,
            gender TEXT,
            recovery_phrase TEXT
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS secrets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp TEXT NOT NULL
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
    session.pop('reg_username', None)
    session.pop('reg_password', None)
    session.pop('reg_birthday', None)
    
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
            flash("Invalid username or password.", "error")
            
    return render_template('login.html')

@app.route('/register/step1', methods=['GET', 'POST'])
def register_step1():
    if request.method == 'POST':
        session['reg_username'] = request.form.get('username')
        password = request.form.get('password')
        session['reg_password'] = hashlib.sha256(password.encode()).hexdigest()
        return redirect(url_for('register_step2'))
    return render_template('register_step1.html')

@app.route('/register/step2', methods=['GET', 'POST'])
def register_step2():
    if 'reg_username' not in session:
        return redirect(url_for('register_step1'))
    if request.method == 'POST':
        session['reg_birthday'] = request.form.get('birthday')
        return redirect(url_for('register_step3'))
    return render_template('register_step2.html')

@app.route('/register/step3', methods=['GET', 'POST'])
def register_step3():
    if 'reg_username' not in session or 'reg_birthday' not in session:
        return redirect(url_for('register_step1'))
    
    if request.method == 'POST':
        username = session.get('reg_username')
        password = session.get('reg_password')
        birthday = session.get('reg_birthday')
        gender = request.form.get('gender')
        recovery = request.form.get('recovery')
        hashed_recovery = hashlib.sha256(recovery.encode()).hexdigest() if recovery else ""
        
        try:
            conn = sqlite3.connect(DB_NAME)
            cursor = conn.cursor()
            cursor.execute("INSERT INTO users (username, password, birthday, gender, recovery_phrase) VALUES (?, ?, ?, ?, ?)", 
                           (username, password, birthday, gender, hashed_recovery))
            conn.commit()
            conn.close()
            
            session.pop('reg_username', None)
            session.pop('reg_password', None)
            session.pop('reg_birthday', None)
            
            log_audit("REGISTER_SUCCESS", username)
            flash("Registration successful. Please log in.", "success")
            return redirect(url_for('login'))
        except sqlite3.IntegrityError:
            log_audit("REGISTER_FAILED_EXISTS", username)
            flash("Username already exists.", "error")
            return redirect(url_for('register_step1'))
            
    return render_template('register_step3.html')

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
            flash("Password updated successfully. Please log in.", "success")
            return redirect(url_for('login'))
        else:
            conn.close()
            log_audit("PASSWORD_RESET_FAILED", username)
            flash("Invalid username or recovery phrase.", "error")
            
    return render_template('forgot.html')

@app.route('/dashboard')
def dashboard():
    if 'user' not in session:
        return redirect(url_for('login'))
    return render_template('dashboard.html', username=session['user'])

@app.route('/secrets', methods=['GET', 'POST'])
def secrets():
    if 'user' not in session:
        return redirect(url_for('login'))
    
    username = session['user']
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    
    if request.method == 'POST':
        content = request.form.get('secret_content')
        if content:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            cursor.execute("INSERT INTO secrets (username, content, timestamp) VALUES (?, ?, ?)", (username, content, timestamp))
            conn.commit()
            log_audit("SECRET_ADDED", username)
            flash("Secret note saved securely.", "success")
        return redirect(url_for('secrets'))
        
    cursor.execute("SELECT id, content, timestamp FROM secrets WHERE username = ? ORDER BY id DESC", (username,))
    secrets_list = cursor.fetchall()
    conn.close()
    
    return render_template('secrets.html', secrets=secrets_list)

@app.route('/settings', methods=['GET', 'POST'])
def settings():
    if 'user' not in session:
        return redirect(url_for('login'))
        
    if request.method == 'POST':
        username = session['user']
        current_password = request.form.get('current_password')
        new_password = request.form.get('new_password')
        
        hashed_current = hashlib.sha256(current_password.encode()).hexdigest()
        hashed_new = hashlib.sha256(new_password.encode()).hexdigest()
        
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, hashed_current))
        user = cursor.fetchone()
        
        if user:
            cursor.execute("UPDATE users SET password = ? WHERE username = ?", (hashed_new, username))
            conn.commit()
            conn.close()
            log_audit("PASSWORD_CHANGE_SUCCESS", username)
            flash("Password changed successfully.", "success")
            return redirect(url_for('dashboard'))
        else:
            conn.close()
            log_audit("PASSWORD_CHANGE_FAILED", username)
            flash("Incorrect current password.", "error")
            
    return render_template('settings.html')

@app.route('/logout')
def logout():
    user = session.get('user')
    log_audit("LOGOUT", user if user else "UNKNOWN")
    session.pop('user', None)
    return redirect(url_for('login'))

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5001, debug=True)
