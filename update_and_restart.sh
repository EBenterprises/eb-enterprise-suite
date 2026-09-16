#!/bin/bash

echo "[+] Stopping any running Flask servers gracefully..."
pkill -f "app.py" || true
sleep 1

# Ensure directories exist
mkdir -p secure_vault/src/static secure_vault/src/templates

# 1. Restore Original Green Theme & Full Layout CSS
cat << 'CSS' > secure_vault/src/static/style.css
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    word-break: break-word;
    overflow-wrap: break-word;
}

html, body {
    width: 100%;
    min-height: 100vh;
    background-color: #064e3b; /* Deep Forest Green */
    color: #ecfdf5;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    padding: 1rem;
    margin: 0;
}

.container {
    width: 100%;
    max-width: 100%;
    background: #065f46; /* Rich Emerald */
    padding: 1.5rem;
    border-radius: 12px;
    box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4);
    display: flex;
    flex-direction: column;
    gap: 1rem;
    border: 1px solid #047857;
}

@media (min-width: 480px) {
    .container {
        max-width: 440px;
    }
}

form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    width: 100%;
}

input, button {
    width: 100%;
    padding: 1rem;
    border: 1px solid #047857;
    border-radius: 8px;
    background: #064e3b;
    color: #ecfdf5;
    font-size: 1rem;
    outline: none;
}

input:focus {
    border-color: #34d399;
}

button {
    background: #059669;
    border: none;
    font-weight: 600;
    cursor: pointer;
    min-height: 50px;
    color: #ffffff;
    transition: background 0.2s;
}

button:hover {
    background: #047857;
}

button:active {
    background: #065f46;
}

h2 {
    font-size: 1.5rem;
    text-align: center;
    color: #f1f5f9;
}

label {
    color: #a7f3d0;
    font-size: 0.95rem;
}
CSS

# 2. Restore Template with Viewport and Green Theme Styling
cat << 'HTML' > secure_vault/src/templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Secure Vault</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}">
</head>
<body>
    <div class="container">
        <h2>Secure Vault Portal</h2>
        {% if error %}
            <p style="color: #fca5a5; text-align: center; font-size: 0.9rem;">{{ error }}</p>
        {% endif %}
        <form method="POST">
            <label for="passcode">Enter Passcode / Key:</label>
            <input type="password" id="passcode" name="passcode" required placeholder="Enter key...">
            <button type="submit">Access Vault</button>
        </form>
    </div>
</body>
</html>
HTML

# 3. Configure App with 'easton' Auth and Vault Dashboard
cat << 'PYTHON' > secure_vault/src/app.py
from flask import Flask, render_template, request, session, redirect, url_for

app = Flask(__name__)
app.secret_key = 'secure_vault_super_secret_key'

@app.route('/', methods=['GET', 'POST'])
def index():
    error = None
    if request.method == 'POST':
        passcode = request.form.get('passcode')
        if passcode == 'easton':
            session['authenticated'] = True
            return redirect(url_for('vault'))
        else:
            error = 'Invalid passcode. Access denied.'
    return render_template('index.html', error=error)

@app.route('/vault')
def vault():
    if not session.get('authenticated'):
        return redirect(url_for('index'))
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Secure Vault - Dashboard</title>
        <link rel="stylesheet" href="/static/style.css">
    </head>
    <body>
        <div class="container">
            <h2>Welcome, Easton!</h2>
            <p style="color: #a7f3d0; text-align: center;">Vault Access Granted Successfully.</p>
            <a href="/" style="display: block; text-align: center; margin-top: 1rem; color: #34d399; text-decoration: none; font-weight: 600;">Lock Vault</a>
        </div>
    </body>
    </html>
    """

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
PYTHON

echo "[+] Starting Flask server..."
python3 secure_vault/src/app.py &

echo "[+] Server successfully restarted with green theme and 'easton' authentication!"
