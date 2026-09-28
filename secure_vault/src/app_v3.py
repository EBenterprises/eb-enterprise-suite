import os
import sqlite3
import hashlib
import secrets
from datetime import datetime
from flask import Flask, render_template, request, redirect, url_for, session, flash

app = Flask(__name__, template_folder='../templates', static_folder='../static')
app.secret_key = secrets.token_hex(32)

DB_PATH = "database.db"

def log_audit(username, action, ref_source):
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        ip = request.remote_addr or '127.0.0.1'
        cursor.execute("INSERT INTO audit_logs (username, action, ref_source, ip_address) VALUES (?, ?, ?, ?)",
                       (username, action, ref_source, ip))
        conn.commit()
        conn.close()
    except Exception as e:
        print(f"Audit log error: {e}")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/profile')
def profile():
    if 'user' not in session:
        return redirect(url_for('login'))
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE username = ?", (session['user'],))
    user_data = cursor.fetchone()
    conn.close()
    return render_template('profile.html', user_data=user_data)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = hashlib.sha256(request.form['password'].encode()).hexdigest()
        
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, password))
        user = cursor.fetchone()
        
        if user:
            cursor.execute("UPDATE users SET last_login = ? WHERE username = ?", (datetime.now().strftime('%Y-%m-%d %H:%M:%S'), username))
            conn.commit()
            conn.close()
            session['user'] = username
            log_audit(username, 'LOGIN_SUCCESS', request.form.get('ref', 'direct'))
            return redirect(url_for('index'))
            
        conn.close()
        log_audit(username, 'LOGIN_FAILED', 'direct')
        flash('Invalid credentials provided.', 'error')
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = hashlib.sha256(request.form['password'].encode()).hexdigest()
        
        try:
            conn = sqlite3.connect(DB_PATH)
            cursor = conn.cursor()
            cursor.execute("INSERT INTO users (username, password, role) VALUES (?, ?, 'operator')", (username, password))
            conn.commit()
            conn.close()
            log_audit(username, 'REGISTER_SUCCESS', 'web_ui')
            return redirect(url_for('login'))
        except sqlite3.IntegrityError:
            flash('Username already exists.', 'error')
    return render_template('register.html')

@app.route('/forgot', methods=['GET', 'POST'])
def forgot():
    if request.method == 'POST':
        username = request.form['username']
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users WHERE username = ?", (username,))
        user = cursor.fetchone()
        
        if user:
            token = secrets.token_urlsafe(8)
            ref_source = request.form.get('ref', 'web_ui_shortcut')
            cursor.execute("UPDATE users SET reset_token = ? WHERE username = ?", (token, username))
            conn.commit()
            conn.close()
            
            log_audit(username, 'TOKEN_REQUESTED', ref_source)
            reset_url = url_for('reset', token=token, ref=ref_source, _external=True)
            return render_template('token.html', username=username, token=token, reset_url=reset_url)
            
        conn.close()
        flash('If that username exists, a token has been generated.', 'success')
    return render_template('forgot.html')

@app.route('/reset', methods=['GET', 'POST'])
def reset():
    if request.method == 'POST':
        token = request.form['token']
        new_password = hashlib.sha256(request.form['password'].encode()).hexdigest()
        
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("SELECT username FROM users WHERE reset_token = ?", (token,))
        user = cursor.fetchone()
        
        if user:
            username = user[0]
            cursor.execute("UPDATE users SET password = ?, reset_token = NULL WHERE username = ?", (new_password, username))
            conn.commit()
            conn.close()
            log_audit(username, 'PASSWORD_RESET', request.args.get('ref', 'reset_form'))
            flash('Password successfully updated. You can now log in.', 'success')
            return redirect(url_for('login'))
        
        conn.close()
        flash('Invalid or expired reset token.', 'error')
        
    token = request.args.get('token', '')
    return render_template('reset.html', token=token)

@app.route('/logout')
def logout():
    if 'user' in session:
        log_audit(session['user'], 'LOGOUT', 'direct')
    session.pop('user', None)
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
