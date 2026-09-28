import os

<<<<<<< HEAD
print("[+] Initializing secure_vault with EB Enterprises & Admin Authentication...")
=======
print("[+] Initializing secure_vault with full EB Enterprises features...")
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)

os.makedirs("secure_vault/app/templates", exist_ok=True)
os.makedirs("secure_vault/app/static/css", exist_ok=True)

<<<<<<< HEAD
# 1. Main Application Logic
=======
# 1. Main Application Logic with Register & Forgot Password
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
with open("secure_vault/app/app.py", "w", encoding="utf-8") as f:
    f.write('''import os
from flask import Flask, render_template, request, redirect, url_for, session, flash

app = Flask(__name__)
app.secret_key = os.urandom(24)

<<<<<<< HEAD
ADMIN_USER = "admin"
ADMIN_PASS = "admin123"
=======
# In-memory user store for demo & persistence during session
USERS = {
    "admin": "admin123"
}
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)

@app.route('/')
def index():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    return render_template('dashboard.html', user=session.get('user'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
<<<<<<< HEAD
        if username == ADMIN_USER and password == ADMIN_PASS:
=======
        if username in USERS and USERS[username] == password:
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
            session['logged_in'] = True
            session['user'] = username
            flash('Successfully authenticated into EB Enterprises vault.', 'success')
            return redirect(url_for('index'))
        else:
            flash('Invalid credentials. Access denied.', 'danger')
    return render_template('login.html')

<<<<<<< HEAD
=======
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        if username in USERS:
            flash('Username already exists.', 'danger')
        elif not username or not password:
            flash('All fields are required.', 'danger')
        else:
            USERS[username] = password
            flash('Account created successfully. Please log in.', 'success')
            return redirect(url_for('login'))
    return render_template('register.html')

@app.route('/forgot', methods=['GET', 'POST'])
def forgot():
    if request.method == 'POST':
        username = request.form.get('username')
        if username in USERS:
            flash(f'Recovery instructions dispatched for account: {username}. Password hint: {USERS[username][:2]}***', 'info')
        else:
            flash('Username not found in registry.', 'danger')
    return render_template('forgot.html')

>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
@app.route('/logout')
def logout():
    session.clear()
    flash('Logged out successfully.', 'info')
    return redirect(url_for('login'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
''')

# 2. Login Template
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
<<<<<<< HEAD
=======
        <div class="footer-links">
            <a href="{{ url_for('register') }}">Create Account</a> | 
            <a href="{{ url_for('forgot') }}">Forgot Login?</a>
        </div>
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
    </div>
</body>
</html>
''')

<<<<<<< HEAD
# 3. Dashboard Template
=======
# 3. Register Template
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

# 4. Forgot Password Template
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

# 5. Dashboard Template
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
            <a href="{{ url_for('logout') }}" class="logout-btn">Logout</a>
        </header>
        <main>
            <div class="card">
                <h2>System Status</h2>
                <p>Status: <span class="badge">SECURE</span></p>
                <p>Logged in as: <strong>{{ user }}</strong></p>
            </div>
        </main>
    </div>
</body>
</html>
''')

<<<<<<< HEAD
# 4. Styling
with open("secure_vault/app/static/css/style.css", "w", encoding="utf-8") as f:
    f.write('''
:root {
    --bg: #0b0f19;
    --card-bg: #111827;
    --accent: #3b82f6;
    --text: #f3f4f6;
    --danger: #ef4444;
    --success: #22c55e;
}
* { box-sizing: border-box; margin: 0; padding: 0; font-family: monospace, sans-serif; }
body { background: var(--bg); color: var(--text); display: flex; justify-content: center; align-items: center; height: 100vh; }
.login-box { background: var(--card-bg); padding: 2.5rem; border-radius: 8px; border: 1px solid #1f2937; width: 350px; box-shadow: 0 4px 20px rgba(0,0,0,0.5); }
.login-box h2 { color: var(--accent); margin-bottom: 0.25rem; font-size: 1.5rem; }
.subtitle { color: #9ca3af; font-size: 0.85rem; margin-bottom: 1.5rem; }
.input-group { margin-bottom: 1.25rem; }
.input-group label { display: block; font-size: 0.8rem; color: #9ca3af; margin-bottom: 0.5rem; }
.input-group input { width: 100%; padding: 0.75rem; background: #1f2937; border: 1px solid #374151; color: white; border-radius: 4px; }
.btn { width: 100%; padding: 0.75rem; background: var(--accent); color: white; border: none; border-radius: 4px; font-weight: bold; cursor: pointer; }
.btn:hover { background: #2563eb; }
.alert { padding: 0.5rem; margin-bottom: 1rem; border-radius: 4px; font-size: 0.85rem; }
.alert.danger { background: rgba(239, 68, 68, 0.2); border: 1px solid var(--danger); color: var(--danger); }
.alert.success { background: rgba(34, 197, 94, 0.2); border: 1px solid var(--success); color: var(--success); }
.dashboard-container { width: 100%; max-width: 800px; padding: 2rem; }
header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #1f2937; padding-bottom: 1rem; margin-bottom: 2rem; }
.logout-btn { color: var(--danger); text-decoration: none; border: 1px solid var(--danger); padding: 0.5rem 1rem; border-radius: 4px; }
.card { background: var(--card-bg); padding: 1.5rem; border-radius: 8px; border: 1px solid #1f2937; }
.badge { background: var(--success); color: black; padding: 0.1rem 0.4rem; border-radius: 3px; font-weight: bold; }
''')

# 5. Automation runner script
=======
# 6. Executive Spectrum Styling (Obsidian, Champagne Gold, Teal)
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
body { background: var(--bg); color: var(--text); display: flex; justify-content: center; align-items: center; height: 100vh; }
.login-box { background: var(--card-bg); padding: 2.5rem; border-radius: 8px; border: 1px solid var(--gold); width: 380px; box-shadow: 0 4px 20px rgba(0,128,128,0.2); }
.login-box h2 { color: var(--gold); margin-bottom: 0.25rem; font-size: 1.6rem; letter-spacing: 1px; }
.subtitle { color: var(--text); font-size: 0.85rem; margin-bottom: 1.5rem; opacity: 0.8; }
.input-group { margin-bottom: 1.25rem; }
.input-group label { display: block; font-size: 0.8rem; color: var(--gold); margin-bottom: 0.5rem; }
.input-group input { width: 100%; padding: 0.75rem; background: var(--bg); border: 1px solid var(--accent); color: white; border-radius: 4px; }
.input-group input:focus { outline: none; border-color: var(--gold); }
.btn { width: 100%; padding: 0.75rem; background: var(--accent); color: white; border: none; border-radius: 4px; font-weight: bold; cursor: pointer; transition: 0.2s; }
.btn:hover { background: #006666; }
.footer-links { margin-top: 1.25rem; text-align: center; font-size: 0.8rem; }
.footer-links a { color: var(--gold); text-decoration: none; }
.footer-links a:hover { text-decoration: underline; }
.alert { padding: 0.5rem; margin-bottom: 1rem; border-radius: 4px; font-size: 0.85rem; }
.alert.danger { background: rgba(207, 102, 121, 0.2); border: 1px solid var(--danger); color: var(--danger); }
.alert.success { background: rgba(0, 128, 128, 0.2); border: 1px solid var(--accent); color: #fff; }
.alert.info { background: rgba(212, 175, 55, 0.2); border: 1px solid var(--gold); color: var(--gold); }
.dashboard-container { width: 100%; max-width: 800px; padding: 2rem; }
header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--gold); padding-bottom: 1rem; margin-bottom: 2rem; }
header h1 { color: var(--gold); }
.logout-btn { color: var(--danger); text-decoration: none; border: 1px solid var(--danger); padding: 0.5rem 1rem; border-radius: 4px; }
.card { background: var(--card-bg); padding: 1.5rem; border-radius: 8px; border: 1px solid var(--gold); }
.card h2 { color: var(--gold); margin-bottom: 0.75rem; }
.badge { background: var(--accent); color: white; padding: 0.1rem 0.4rem; border-radius: 3px; font-weight: bold; }
''')

# 7. Runner script with live deployment triggering
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
print("[+] EB Enterprises Secure Vault generated successfully!")
print("[+] To execute and launch your public tunnel:")
print("    cd secure_vault && ./run.sh")
=======
print("[+] EB Enterprises Secure Vault generated with Full Stack UI, Create Account, Forgot Login, and Executive Spectrum theme!")
print("[+] Launching application and public tunnel...")
>>>>>>> 326a216 (Automated Termux sync: 2026-09-02 02:51:48)
