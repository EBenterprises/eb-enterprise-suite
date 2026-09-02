import os
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
