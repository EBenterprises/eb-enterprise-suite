# Create directory structure
mkdir -p secure_vault/templates
mkdir -p secure_vault/static/css
mkdir -p secure_vault/static/js

# Create backend application logic
cat << 'INNER_EOF' > secure_vault/app.py
from flask import Flask, render_template, request, jsonify, session, redirect, url_for
import os
import sqlite3

app = Flask(__name__)
app.secret_key = os.urandom(24)
DB_PATH = 'vault.db'

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            payload TEXT NOT NULL,
            classification TEXT NOT NULL
        )
    ''')
    conn.commit()
    conn.close()

@app.route('/')
def index():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT id, title, classification FROM records')
    records = cursor.fetchall()
    conn.close()
    return render_template('index.html', records=records)

@app.route('/api/add', methods=['POST'])
def add_record():
    data = request.json
    title = data.get('title')
    payload = data.get('payload')
    classification = data.get('classification', 'CONFIDENTIAL')
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('INSERT INTO records (title, payload, classification) VALUES (?, ?, ?)',
                   (title, payload, classification))
    conn.commit()
    conn.close()
    return jsonify({"status": "success", "message": "Record stored securely."})

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5001, debug=True)
INNER_EOF

# Create HTML Template
cat << 'INNER_EOF' > secure_vault/templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Vault Interface</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="vault-container">
        <h1>Secure Vault Terminal</h1>
        <div class="vault-panel">
            <h3>Stored Dossiers</h3>
            <ul id="record-list">
                {% for record in records %}
                    <li><strong>{{ record[1] }}</strong> [{{ record[2] }}]</li>
                {% endfor %}
            </ul>
        </div>
    </div>
</body>
</html>
INNER_EOF

# Create CSS Stylesheet
cat << 'INNER_EOF' > secure_vault/static/css/style.css
body {
    background-color: #0b0f19;
    color: #00ffcc;
    font-family: 'Courier New', Courier, monospace;
    margin: 0;
    padding: 20px;
}
.vault-container {
    max-width: 800px;
    margin: auto;
    border: 1px solid #00ffcc;
    padding: 20px;
    box-shadow: 0 0 15px rgba(0, 255, 204, 0.2);
}
h1 {
    text-align: center;
    border-bottom: 1px dashed #00ffcc;
    padding-bottom: 10px;
}
.vault-panel {
    margin-top: 20px;
}
INNER_EOF

# Create startup script
cat << 'INNER_EOF' > secure_vault/start.sh
#!/bin/bash
cd "$(dirname "$0")"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install flask > /dev/null 2>&1
python app.py
INNER_EOF

chmod +x secure_vault/start.sh
echo "Secure Vault successfully restored in ./secure_vault"
