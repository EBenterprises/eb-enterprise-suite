import os, sqlite3, hashlib
from datetime import datetime, date
from flask import Flask, render_template, request, redirect, url_for, session, flash

app = Flask(__name__)
app.secret_key = os.urandom(24)
DB = "vault_auth_v5.db"

def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        fullname TEXT NOT NULL, 
        username TEXT UNIQUE NOT NULL, 
        email TEXT NOT NULL,
        password TEXT NOT NULL, 
        birthday TEXT, 
        gender TEXT, 
        recovery_phrase TEXT, 
        recovery_answer TEXT
    )''')
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
        session['reg_email'] = request.form.get('email')
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
        fn = session['reg_fullname']
        u = session['reg_username']
        em = session['reg_email']
        p = session['reg_password']
        b = session['reg_birthday']
        g = session['reg_gender']
        rp = hashlib.sha256(request.form.get('recovery_phrase').encode()).hexdigest()
        ra = hashlib.sha256(request.form.get('recovery_answer').encode()).hexdigest()
        try:
            conn = sqlite3.connect(DB); c = conn.cursor()
            c.execute("INSERT INTO users (fullname, username, email, password, birthday, gender, recovery_phrase, recovery_answer) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", (fn, u, em, p, b, g, rp, ra))
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
    return render_template('dashboard.html', fullname=session.get('fullname'), username=session.get('user'))

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
