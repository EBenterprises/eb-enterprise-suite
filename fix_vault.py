import os

os.makedirs('templates', exist_ok=True)

with open('templates/base.html', 'w') as f:
    f.write('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Secure Vault V4{% endblock %}</title>
    <style>
        :root {
            --bg-color: #0b0f19; --card-bg: #111827; --border-color: #1f2937;
            --input-bg: #1f2937; --text-main: #e2e8f0; --accent: #0d9488;
            --accent-hover: #0f766e; --error: #f87171; --link: #2dd4bf;
            --danger: #ef4444; --danger-hover: #dc2626;
        }
        body {
            background-color: var(--bg-color); color: var(--text-main);
            font-family: ui-monospace, monospace; display: flex;
            justify-content: center; align-items: center; min-height: 100vh; margin: 0;
        }
        .card {
            background: var(--card-bg); padding: 2.5rem 2.0rem;
            border: 1px solid var(--border-color); border-radius: 12px;
            width: 360px; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.4); box-sizing: border-box;
        }
        h2 { margin-top: 0; margin-bottom: 1.5rem; font-size: 1.25rem; text-align: center; }
        .input-group { margin-bottom: 1rem; }
        input, select, textarea {
            width: 100%; padding: 12px; background: var(--input-bg);
            border: 1px solid #374151; color: #fff; border-radius: 6px;
            box-sizing: border-box; font-family: inherit; font-size: 0.9rem;
        }
        input:focus, select:focus, textarea:focus { outline: none; border-color: var(--accent); }
        button, .btn {
            display: inline-block; width: 100%; padding: 12px; background: var(--accent);
            color: white; border: none; border-radius: 6px; cursor: pointer;
            font-weight: bold; font-family: inherit; font-size: 0.95rem; margin-top: 0.5rem;
            text-align: center; text-decoration: none; box-sizing: border-box;
        }
        button:hover, .btn:hover { background: var(--accent-hover); }
        .btn-danger { background: var(--danger); }
        .btn-danger:hover { background: var(--danger-hover); }
        .msg {
            color: var(--error); font-size: 0.85rem; text-align: center; margin-bottom: 1rem;
            background: rgba(248,113,113,0.1); padding: 8px; border-radius: 4px;
            border: 1px solid rgba(248,113,113,0.2);
        }
        .success-msg {
            color: #2dd4bf; font-size: 0.85rem; text-align: center; margin-bottom: 1rem;
            background: rgba(45,212,191,0.1); padding: 8px; border-radius: 4px;
            border: 1px solid rgba(45,212,191,0.2);
        }
        .links {
            display: flex; justify-content: space-between; margin-top: 1.5rem;
            font-size: 0.8rem; border-top: 1px solid var(--border-color); padding-top: 1rem;
        }
        a { color: var(--link); text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="card">
        {% with messages = get_flashed_messages(with_categories=true) %}
          {% if messages %}
            {% for cat, msg in messages %}
              <div class="{{ 'success-msg' if cat == 'success' else 'msg' }}">{{ msg }}</div>
            {% endfor %}
          {% endif %}
        {% endwith %}
        {% block content %}{% endblock %}
    </div>
</body>
</html>
''')

with open('templates/login.html', 'w') as f:
    f.write('''{% extends "base.html" %}
{% block content %}
<h2>🔒 Vault V4 Login</h2>
<form method="POST">
    <div class="input-group"><input type="text" name="username" placeholder="Username / Email" required autocomplete="off"></div>
    <div class="input-group"><input type="password" name="password" placeholder="Password" required></div>
    <button type="submit">Authenticate</button>
</form>
<div class="links"><a href="/register/step1">Create Account</a><a href="/forgot">Forgot Password?</a></div>
{% endblock %}''')

with open('templates/register_step1.html', 'w') as f:
    f.write('''{% extends "base.html" %}
{% block content %}
<h2>📝 Step 1: Credentials</h2>
<form method="POST">
    <div class="input-group"><input type="text" name="fullname" placeholder="Full Name" required></div>
    <div class="input-group"><input type="email" name="username" placeholder="Email Address" required></div>
    <div class="input-group"><input type="password" name="password" placeholder="Password" required></div>
    <button type="submit">Next</button>
</form>
<div class="links" style="justify-content: center;"><a href="/login">Back to Login</a></div>
{% endblock %}''')

with open('templates/register_step2.html', 'w') as f:
    f.write('''{% extends "base.html" %}
{% block content %}
<h2>🎂 Step 2: Birthday</h2>
<form method="POST">
    <div class="input-group"><input type="date" name="birthday" max="{{ max_date }}" required></div>
    <button type="submit">Next</button>
</form>
<div class="links" style="justify-content: center;"><a href="/login">Cancel</a></div>
{% endblock %}''')

with open('templates/register_step3.html', 'w') as f:
    f.write('''{% extends "base.html" %}
{% block content %}
<h2>👤 Step 3: Gender</h2>
<form method="POST">
    <div class="input-group">
        <select name="gender" required>
            <option value="" disabled selected>Select Gender</option>
            <option value="Male">Male</option>
            <option value="Female">Female</option>
            <option value="Non-binary">Non-binary</option>
            <option value="Prefer not to say">Prefer not to say</option>
        </select>
    </div>
    <button type="submit">Next</button>
</form>
<div class="links" style="justify-content: center;"><a href="/login">Cancel</a></div>
{% endblock %}''')

with open('templates/register_step4.html', 'w') as f:
    f.write('''{% extends "base.html" %}
{% block content %}
<h2>🔑 Step 4: Recovery</h2>
<form method="POST">
    <div class="input-group"><input type="text" name="recovery_phrase" placeholder="Recovery Phrase" required></div>
    <div class="input-group"><input type="text" name="recovery_answer" placeholder="Recovery Answer" required></div>
    <button type="submit">Complete</button>
</form>
<div class="links" style="justify-content: center;"><a href="/login">Cancel</a></div>
{% endblock %}''')

with open('templates/forgot.html', 'w') as f:
    f.write('''{% extends "base.html" %}
{% block content %}
<h2>🔑 Vault Recovery</h2>
<form method="POST">
    <div class="input-group"><input type="text" name="username" placeholder="Email" required></div>
    <div class="input-group"><input type="text" name="recovery_phrase" placeholder="Recovery Phrase" required></div>
    <div class="input-group"><input type="text" name="recovery_answer" placeholder="Recovery Answer" required></div>
    <div class="input-group"><input type="password" name="new_password" placeholder="New Password" required></div>
    <button type="submit" style="background: #d97706;">Reset Password</button>
</form>
<div class="links" style="justify-content: center;"><a href="/login">Back</a></div>
{% endblock %}''')

with open('templates/dashboard.html', 'w') as f:
    f.write('''{% extends "base.html" %}
{% block content %}
<h2 style="color: #2dd4bf;">Welcome, {{ fullname }}</h2>
<p style="color: #9ca3af; font-size: 0.85rem; text-align: center; margin-bottom: 1.5rem;">Secure Vault V4 Active</p>
<a class="btn" href="/secrets">Manage Secrets</a>
<a class="btn" href="/settings" style="background: #374151; margin-top: 10px;">Settings</a>
<a class="btn btn-danger" href="/logout" style="margin-top: 10px;">Logout</a>
{% endblock %}''')

with open('templates/secrets.html', 'w') as f:
    f.write('''{% extends "base.html" %}
{% block content %}
<h2>🔐 Encrypted Notes</h2>
<form method="POST">
    <div class="input-group"><textarea name="secret_content" rows="4" placeholder="Store notes..." required></textarea></div>
    <button type="submit">Save</button>
</form>
<div style="margin-top: 1.5rem; max-height: 150px; overflow-y: auto; font-size: 0.8rem;">
    {% if secrets %}{% for s in secrets %}
        <div style="background: #1f2937; padding: 8px; margin-bottom: 6px; border-radius: 4px; word-break: break-all;">
            <span>{{ s[1] }}</span><span style="color: #6b7280; font-size: 0.7rem; display: block;">{{ s[2] }}</span>
        </div>
    {% endfor %}{% else %}<p style="color: #6b7280; text-align: center;">No secrets yet.</p>{% endif %}
</div>
<div class="links" style="justify-content: center;"><a href="/dashboard">Dashboard</a></div>
{% endblock %}''')

with open('templates/settings.html', 'w') as f:
    f.write('''{% extends "base.html" %}
{% block content %}
<h2>⚙️ Settings</h2>
<form method="POST">
    <div class="input-group"><input type="password" name="current_password" placeholder="Current Password" required></div>
    <div class="input-group"><input type="password" name="new_password" placeholder="New Password" required></div>
    <button type="submit" style="background: #4f46e5;">Update Password</button>
</form>
<div class="links" style="justify-content: center;"><a href="/dashboard">Dashboard</a></div>
{% endblock %}''')

with open('app.py', 'w') as f:
    f.write('''import os, sqlite3, hashlib
from datetime import datetime, date
from flask import Flask, render_template, request, redirect, url_for, session, flash

app = Flask(__name__)
app.secret_key = os.urandom(24)
DB = "vault_auth_v4.db"

def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, fullname TEXT NOT NULL, username TEXT UNIQUE NOT NULL, password TEXT NOT NULL, birthday TEXT, gender TEXT, recovery_phrase TEXT, recovery_answer TEXT)')
    c.execute('CREATE TABLE IF NOT EXISTS secrets (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, content TEXT NOT NULL, timestamp TEXT NOT NULL)')
    conn.commit(); conn.close()

@app.route('/')
def index():
    return redirect(url_for('dashboard' if 'user' in session else 'login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    session.clear()
    if request.method == 'POST':
        u, p = request.form.get('username'), hashlib.sha256(request.form.get('password').encode()).hexdigest()
        conn = sqlite3.connect(DB); c = conn.cursor()
        c.execute("SELECT * FROM users WHERE username = ? AND password = ?", (u, p))
        user = c.fetchone(); conn.close()
        if user:
            session['user'], session['fullname'] = u, user[1]
            return redirect(url_for('dashboard'))
        flash("Invalid credentials.", "error")
    return render_template('login.html')

@app.route('/register/step1', methods=['GET', 'POST'])
def register_step1():
    if request.method == 'POST':
        session['reg_fullname'] = request.form.get('fullname')
        session['reg_username'] = request.form.get('username')
        session['reg_password'] = hashlib.sha256(request.form.get('password').encode()).hexdigest()
        return redirect(url_for('register_step2'))
    return render_template('register_step1.html')

@app.route('/register/step2', methods=['GET', 'POST'])
def register_step2():
    if 'reg_username' not in session: return redirect(url_for('register_step1'))
    today = date.today().strftime('%Y-%m-%d')
    if request.method == 'POST':
        bday = request.form.get('birthday')
        if datetime.strptime(bday, '%Y-%m-%d').date() > date.today():
            flash("Birthday cannot be in the future.", "error")
            return render_template('register_step2.html', max_date=today)
        session['reg_birthday'] = bday
        return redirect(url_for('register_step3'))
    return render_template('register_step2.html', max_date=today)

@app.route('/register/step3', methods=['GET', 'POST'])
def register_step3():
    if 'reg_birthday' not in session: return redirect(url_for('register_step1'))
    if request.method == 'POST':
        session['reg_gender'] = request.form.get('gender')
        return redirect(url_for('register_step4'))
    return render_template('register_step3.html')

@app.route('/register/step4', methods=['GET', 'POST'])
def register_step4():
    if 'reg_gender' not in session: return redirect(url_for('register_step1'))
    if request.method == 'POST':
        fn, u, p, b, g = session['reg_fullname'], session['reg_username'], session['reg_password'], session['reg_birthday'], session['reg_gender']
        rp = hashlib.sha256(request.form.get('recovery_phrase').encode()).hexdigest()
        ra = hashlib.sha256(request.form.get('recovery_answer').encode()).hexdigest()
        try:
            conn = sqlite3.connect(DB); c = conn.cursor()
            c.execute("INSERT INTO users (fullname, username, password, birthday, gender, recovery_phrase, recovery_answer) VALUES (?, ?, ?, ?, ?, ?, ?)", (fn, u, p, b, g, rp, ra))
            conn.commit(); conn.close()
            session.clear()
            flash("Registration successful. Please log in.", "success")
            return redirect(url_for('login'))
        except sqlite3.IntegrityError:
            flash("Username already exists.", "error")
            return redirect(url_for('register_step1'))
    return render_template('register_step4.html')

@app.route('/forgot', methods=['GET', 'POST'])
def forgot():
    if request.method == 'POST':
        u = request.form.get('username')
        rp = hashlib.sha256(request.form.get('recovery_phrase').encode()).hexdigest()
        ra = hashlib.sha256(request.form.get('recovery_answer').encode()).hexdigest()
        np = hashlib.sha256(request.form.get('new_password').encode()).hexdigest()
        conn = sqlite3.connect(DB); c = conn.cursor()
        c.execute("SELECT * FROM users WHERE username = ? AND recovery_phrase = ? AND recovery_answer = ?", (u, rp, ra))
        if c.fetchone():
            c.execute("UPDATE users SET password = ? WHERE username = ?", (np, u))
            conn.commit(); conn.close()
            flash("Password updated successfully.", "success")
            return redirect(url_for('login'))
        conn.close()
        flash("Invalid recovery details.", "error")
    return render_template('forgot.html')

@app.route('/dashboard')
def dashboard():
    if 'user' not in session: return redirect(url_for('login'))
    return render_template('dashboard.html', fullname=session.get('fullname'))

@app.route('/secrets', methods=['GET', 'POST'])
def secrets():
    if 'user' not in session: return redirect(url_for('login'))
    u = session['user']
    conn = sqlite3.connect(DB); c = conn.cursor()
    if request.method == 'POST':
        content = request.form.get('secret_content')
        if content:
            c.execute("INSERT INTO secrets (username, content, timestamp) VALUES (?, ?, ?)", (u, content, datetime.now().strftime("%Y-%m-%d %H:%M:%S")))
            conn.commit()
        conn.close()
        return redirect(url_for('secrets'))
    c.execute("SELECT id, content, timestamp FROM secrets WHERE username = ? ORDER BY id DESC", (u,))
    s_list = c.fetchall(); conn.close()
    return render_template('secrets.html', secrets=s_list)

@app.route('/settings', methods=['GET', 'POST'])
def settings():
    if 'user' not in session: return redirect(url_for('login'))
    if request.method == 'POST':
        u = session['user']
        cp = hashlib.sha256(request.form.get('current_password').encode()).hexdigest()
        np = hashlib.sha256(request.form.get('new_password').encode()).hexdigest()
        conn = sqlite3.connect(DB); c = conn.cursor()
        c.execute("SELECT * FROM users WHERE username = ? AND password = ?", (u, cp))
        if c.fetchone():
            c.execute("UPDATE users SET password = ? WHERE username = ?", (np, u))
            conn.commit(); conn.close()
            flash("Password changed.", "success")
            return redirect(url_for('dashboard'))
        conn.close()
        flash("Incorrect current password.", "error")
    return render_template('settings.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5001, debug=True)
''')

print("Files generated successfully!")
