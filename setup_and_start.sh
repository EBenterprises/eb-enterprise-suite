#!/bin/bash

echo "[+] Setting up Secure Vault project structure..."

# Create necessary directories
mkdir -p secure_vault/src/static secure_vault/src/templates

# 1. Create Flask Application
cat << 'PYTHON' > secure_vault/src/app.py
from flask import Flask, render_template

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
PYTHON

# 2. Create Mobile-First Responsive Stylesheet
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
    background-color: #0f172a;
    color: #f8fafc;
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
    background: #1e293b;
    padding: 1.5rem;
    border-radius: 12px;
    box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4);
    display: flex;
    flex-direction: column;
    gap: 1rem;
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
    border: 1px solid #334155;
    border-radius: 8px;
    background: #0f172a;
    color: #f8fafc;
    font-size: 1rem;
    outline: none;
}

button {
    background: #3b82f6;
    border: none;
    font-weight: 600;
    cursor: pointer;
    min-height: 50px;
}

button:active {
    background: #2563eb;
}

h2 {
    font-size: 1.5rem;
    text-align: center;
    color: #f1f5f9;
}

label {
    color: #cbd5e1;
    font-size: 0.95rem;
}
CSS

# 3. Create HTML Template
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
        <form method="POST">
            <label for="passcode">Enter Passcode / Key:</label>
            <input type="password" id="passcode" name="passcode" required placeholder="Enter key...">
            <button type="submit">Access Vault</button>
        </form>
    </div>
</body>
</html>
HTML

# 4. Create and run start script
cat << 'START' > start.sh
#!/bin/bash
echo "[+] Stopping any running Flask servers..."
pkill -f "app.py" || true
sleep 1

echo "[+] Starting Flask application..."
python3 secure_vault/src/app.py &
echo "[+] Server started successfully!"
START

chmod +x start.sh
./start.sh

echo "[+] Setup and server restart complete!"
