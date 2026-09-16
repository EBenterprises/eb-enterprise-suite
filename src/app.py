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
