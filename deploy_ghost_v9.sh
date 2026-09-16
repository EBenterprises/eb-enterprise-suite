#!/bin/bash
echo "[*] Initializing Ghost Messenger V9 (Production Suite)..."
cd "$(dirname "$0")"

if ! command -v python3 &> /dev/null; then
    echo "[!] Python3 not detected. Aborting."
    exit 1
fi

mkdir -p ghost_chat_v9/server ghost_chat_v9/frontend

# Write Real Backend Engine (SQLite, PBKDF2 Hashing, JWT Sessions, Presence Engine)
cat << 'INNER_EOF' > ghost_chat_v9/server/server.py
import http.server
import socketserver
import json
import os
import sqlite3
import hashlib
import hmac
import base64
import time
from urllib.parse import urlparse

DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../frontend")
DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ghost_v9.db")
SECRET_KEY = os.urandom(32)

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL,
                    salt TEXT NOT NULL,
                    status TEXT DEFAULT 'online',
                    last_seen REAL
                )''')
    c.execute('''CREATE TABLE IF NOT EXISTS messages (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    sender TEXT NOT NULL,
                    recipient TEXT NOT NULL,
                    text TEXT NOT NULL,
                    timestamp REAL NOT NULL
                )''')
    conn.commit()
    conn.close()

init_db()

def hash_password(password, salt=None):
    if not salt:
        salt = base64.b64encode(os.urandom(16)).decode('utf-8')
    pw_hash = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100000)
    return base64.b64encode(pw_hash).decode('utf-8'), salt

def generate_token(username):
    header = base64.b64encode(b'{"alg":"HS256","typ":"JWT"}').decode('utf-8')
    payload = base64.b64encode(f'{{"user":"{username}","exp":{time.time()+86400}}}'.encode('utf-8')).decode('utf-8')
    signature = hmac.new(SECRET_KEY, f"{header}.{payload}".encode('utf-8'), hashlib.sha256).digest()
    sig_str = base64.b64encode(signature).decode('utf-8')
    return f"{header}.{payload}.{sig_str}"

def verify_token(token):
    try:
        parts = token.split('.')
        if len(parts) != 3: return None
        header, payload, sig = parts
        expected_sig = base64.b64encode(hmac.new(SECRET_KEY, f"{header}.{payload}".encode('utf-8'), hashlib.sha256).digest()).decode('utf-8')
        if not hmac.compare_digest(sig, expected_sig): return None
        data = json.loads(base64.b64decode(payload).decode('utf-8'))
        if data.get('exp', 0) < time.time(): return None
        return data.get('user')
    except:
        return None

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

class GhostV9Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
        parsed_path = urlparse(self.path)
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')
        try:
            data = json.loads(body) if body else {}
        except:
            data = {}

        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()

        # 1. Register User
        if parsed_path.path == '/api/auth/register':
            username = data.get('username', '').strip()
            password = data.get('password', '')
            if not username or not password:
                conn.close()
                return self.send_json(400, {"error": "Username and password required"})
            
            pw_hash, salt = hash_password(password)
            try:
                c.execute("INSERT INTO users (username, password_hash, salt, last_seen) VALUES (?, ?, ?, ?)", 
                          (username, pw_hash, salt, time.time()))
                conn.commit()
                token = generate_token(username)
                conn.close()
                self.send_json(200, {"status": "SUCCESS", "token": token, "username": username})
            except sqlite3.IntegrityError:
                conn.close()
                self.send_json(400, {"error": "Username already taken"})

        # 2. Login User
        elif parsed_path.path == '/api/auth/login':
            username = data.get('username', '').strip()
            password = data.get('password', '')
            c.execute("SELECT password_hash, salt FROM users WHERE username = ?", (username,))
            row = c.fetchone()
            conn.close()
            if not row:
                return self.send_json(401, {"error": "Invalid credentials"})
            
            pw_hash, salt = hash_password(password, row[1])
            if hmac.compare_digest(pw_hash, row[0]):
                token = generate_token(username)
                self.send_json(200, {"status": "SUCCESS", "token": token, "username": username})
            else:
                self.send_json(401, {"error": "Invalid credentials"})

        # 3. Send Message
        elif parsed_path.path == '/api/messages/send':
            token = self.headers.get('Authorization', '')
            sender = verify_token(token)
            if not sender:
                conn.close()
                return self.send_json(401, {"error": "Unauthorized"})
            
            recipient = data.get('recipient', '').strip()
            text = data.get('text', '').strip()
            if not recipient or not text:
                conn.close()
                return self.send_json(400, {"error": "Recipient and text required"})

            c.execute("INSERT INTO messages (sender, recipient, text, timestamp) VALUES (?, ?, ?, ?)",
                      (sender, recipient, text, time.time()))
            conn.commit()
            conn.close()
            self.send_json(200, {"status": "SUCCESS"})

        # 4. Update Profile / Settings (Username, Password, Status)
        elif parsed_path.path == '/api/user/update':
            token = self.headers.get('Authorization', '')
            current_user = verify_token(token)
            if not current_user:
                conn.close()
                return self.send_json(401, {"error": "Unauthorized"})

            new_username = data.get('username', '').strip()
            new_password = data.get('password', '').strip()
            status = data.get('status', '').strip()

            if status in ['online', 'away', 'offline']:
                c.execute("UPDATE users SET status = ?, last_seen = ? WHERE username = ?", (status, time.time(), current_user))

            if new_username and new_username != current_user:
                try:
                    c.execute("UPDATE users SET username = ? WHERE username = ?", (new_username, current_user))
                    c.execute("UPDATE messages SET sender = ? WHERE sender = ?", (new_username, current_user))
                    c.execute("UPDATE messages SET recipient = ? WHERE recipient = ?", (new_username, current_user))
                    current_user = new_username
                    token = generate_token(current_user)
                except sqlite3.IntegrityError:
                    conn.close()
                    return self.send_json(400, {"error": "Username already taken"})

            if new_password:
                pw_hash, salt = hash_password(new_password)
                c.execute("UPDATE users SET password_hash = ?, salt = ? WHERE username = ?", (pw_hash, salt, current_user))

            conn.commit()
            conn.close()
            self.send_json(200, {"status": "SUCCESS", "token": token, "username": current_user})
        else:
            conn.close()
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        parsed_path = urlparse(self.path)
        token = self.headers.get('Authorization', '')
        user = verify_token(token)

        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()

        # Update last seen timestamp on poll
        if user:
            c.execute("UPDATE users SET last_seen = ? WHERE username = ?", (time.time(), user))
            conn.commit()

        if parsed_path.path == '/api/users':
            c.execute("SELECT username, status, last_seen FROM users")
            rows = c.fetchall()
            now = time.time()
            users_list = []
            for r in rows:
                uname, status, last_seen = r
                # Auto-offline if inactive > 60 seconds
                if now - last_seen > 60 and status != 'offline':
                    status = 'offline'
                users_list.append({"username": uname, "status": status})
            conn.close()
            self.send_json(200, users_list)

        elif parsed_path.path == '/api/messages':
            if not user:
                conn.close()
                return self.send_json(401, {"error": "Unauthorized"})
            c.execute("SELECT id, sender, recipient, text, timestamp FROM messages WHERE sender = ? OR recipient = ?", (user, user))
            rows = c.fetchall()
            conn.close()
            messages = [{"id": r[0], "sender": r[1], "recipient": r[2], "text": r[3], "timestamp": r[4]} for r in rows]
            self.send_json(200, messages)
        else:
            conn.close()
            super().do_GET()

    def send_json(self, code, data):
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

if __name__ == "__main__":
    PORT = 8080
    server_instance = None
    for p in range(8080, 8095):
        try:
            server_instance = ReusableTCPServer(("", p), GhostV9Handler)
            PORT = p
            break
        except OSError:
            continue

    print(f"[*] Ghost Chat V9 operational on http://localhost:{PORT}")
    try:
        server_instance.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Shutting down Ghost Chat V9...")
        server_instance.server_close()
INNER_EOF

# Write Frontend HTML with Settings Modal & Status Picker
cat << 'INNER_EOF' > ghost_chat_v9/frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ghost Messenger V9 // Executive Suite</title>
    <link rel="stylesheet" href="style.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
</head>
<body>
    <!-- AUTH GATEWAY -->
    <div id="auth-modal" class="auth-overlay">
        <div class="auth-card">
            <h2>GHOST CHAT V9</h2>
            <p>Secure Enterprise Direct Messaging & Presence Engine</p>
            
            <div class="auth-tabs">
                <button class="tab-btn active" onclick="switchAuthTab('login')">Sign In</button>
                <button class="tab-btn" onclick="switchAuthTab('register')">Register</button>
            </div>

            <form id="auth-form" class="auth-form" onsubmit="handleAuth(event)">
                <input type="text" id="auth-user" placeholder="Username" required />
                <input type="password" id="auth-pass" placeholder="Password" required />
                <button type="submit" id="auth-submit-btn" class="auth-action-btn">Sign In</button>
            </form>
        </div>
    </div>

    <!-- MAIN APP CONTAINER -->
    <div id="app-container" class="app-container hidden">
        <aside class="sidebar">
            <div class="sidebar-header">
                <div class="user-profile-badge">
                    <span id="my-status-dot" class="status-dot online"></span>
                    <div>
                        <h3 id="current-user-display">User</h3>
                        <select id="my-status-select" onchange="updateMyStatus(this.value)">
                            <option value="online">Online</option>
                            <option value="away">Away</option>
                            <option value="offline">Invisible</option>
                        </select>
                    </div>
                </div>
                <div class="header-actions">
                    <button onclick="openSettings()" title="Settings">⚙️</button>
                    <button id="share-btn" title="Invite Friends">🔗</button>
                    <button onclick="logout()" title="Sign Out">🚪</button>
                </div>
            </div>

            <div class="search-bar">
                <input type="text" id="new-contact-input" placeholder="Start chat with username..." />
                <button onclick="startNewChat()">+</button>
            </div>

            <div id="contact-list" class="contact-list"></div>
        </aside>

        <main class="chat-area">
            <header class="chat-header">
                <div class="chat-title-info">
                    <span id="active-status-dot" class="status-dot online"></span>
                    <h3 id="active-chat-title">Select a Conversation</h3>
                </div>
            </header>

            <div id="chat-messages" class="chat-messages">
                <div class="empty-state">Select a contact to begin secure messaging.</div>
            </div>

            <form id="chat-form" class="chat-input-area hidden" onsubmit="sendMessage(event)">
                <input type="text" id="message-input" placeholder="Type a secure message..." autocomplete="off" required />
                <button type="submit">Send</button>
            </form>
        </main>
    </div>

    <!-- SETTINGS MODAL -->
    <div id="settings-modal" class="modal hidden">
        <div class="modal-content">
            <h3>Account Settings</h3>
            <form onsubmit="saveSettings(event)" class="settings-form">
                <label>Change Username</label>
                <input type="text" id="settings-username" />
                <label>New Password (leave blank to keep)</label>
                <input type="password" id="settings-password" placeholder="New password" />
                <div class="modal-buttons">
                    <button type="button" class="secondary" onclick="document.getElementById('settings-modal').classList.add('hidden')">Cancel</button>
                    <button type="submit">Save Changes</button>
                </div>
            </form>
        </div>
    </div>

    <!-- SHARE MODAL -->
    <div id="share-modal" class="modal hidden">
        <div class="modal-content">
            <h3>Invite Friends</h3>
            <div id="qrcode"></div>
            <input type="text" id="share-url" readonly />
            <button onclick="document.getElementById('share-modal').classList.add('hidden')">Close</button>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
INNER_EOF

# Write CSS (Executive Spectrum Theme: Obsidian background, champagne gold & teal highlights, real status indicators)
cat << 'INNER_EOF' > ghost_chat_v9/frontend/style.css
:root {
    --bg-color: #0b0f12;
    --sidebar-bg: #12181f;
    --chat-bg: #0e1318;
    --panel-border: #1e2631;
    --primary: #00d2c4;
    --primary-hover: #00b3a6;
    --accent-gold: #d4af37;
    --text-main: #f0f4f8;
    --text-muted: #8a99ad;
    --bubble-me: #00d2c4;
    --bubble-me-text: #0b0f12;
    --bubble-other: #1a222c;
    --bubble-other-text: #f0f4f8;
}

body {
    margin: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background-color: var(--bg-color);
    color: var(--text-main);
    height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
}

.hidden { display: none !important; }

/* Status Dots */
.status-dot { width: 9px; height: 9px; border-radius: 50%; display: inline-block; flex-shrink: 0; }
.status-dot.online { background-color: #2ecc71; box-shadow: 0 0 8px rgba(46, 204, 113, 0.6); }
.status-dot.away { background-color: #f1c40f; box-shadow: 0 0 8px rgba(241, 196, 15, 0.6); }
.status-dot.offline { background-color: #95a5a6; }

/* Auth Overlay */
.auth-overlay {
    position: fixed;
    top: 0; left: 0; width: 100%; height: 100%;
    background: rgba(11, 15, 18, 0.9);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 2000;
}

.auth-card {
    background: var(--sidebar-bg);
    border: 1px solid var(--panel-border);
    padding: 30px;
    border-radius: 12px;
    width: 340px;
    text-align: center;
    box-shadow: 0 12px 32px rgba(0,0,0,0.5);
}

.auth-card h2 { margin: 0 0 5px 0; color: var(--accent-gold); letter-spacing: 1px; }
.auth-card p { font-size: 0.8rem; color: var(--text-muted); margin-bottom: 20px; }

.auth-tabs { display: flex; border-bottom: 1px solid var(--panel-border); margin-bottom: 20px; }
.tab-btn { flex: 1; background: none; border: none; padding: 10px; font-weight: 600; cursor: pointer; color: var(--text-muted); font-size: 0.85rem; }
.tab-btn.active { color: var(--primary); border-bottom: 2px solid var(--primary); }

.auth-form { display: flex; flex-direction: column; gap: 12px; }
.auth-form input { padding: 12px; border: 1px solid var(--panel-border); background: var(--bg-color); color: var(--text-main); border-radius: 8px; font-size: 0.95rem; outline: none; }
.auth-action-btn { background: var(--primary); color: var(--bg-color); border: none; padding: 12px; border-radius: 8px; font-weight: bold; cursor: pointer; }

/* App Layout */
.app-container {
    width: 100%;
    max-width: 1150px;
    height: 100vh;
    background: var(--sidebar-bg);
    display: flex;
    box-shadow: 0 8px 32px rgba(0,0,0,0.6);
    border: 1px solid var(--panel-border);
}

@media (min-width: 768px) {
    .app-container { height: 90vh; border-radius: 12px; overflow: hidden; }
}

.sidebar { width: 310px; border-right: 1px solid var(--panel-border); display: flex; flex-direction: column; }
.sidebar-header { padding: 14px 16px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--panel-border); }
.user-profile-badge { display: flex; align-items: center; gap: 10px; }
.sidebar-header h3 { margin: 0; font-size: 0.95rem; }
.sidebar-header select { background: transparent; border: none; color: var(--text-muted); font-size: 0.75rem; cursor: pointer; outline: none; padding: 0; }
.header-actions { display: flex; gap: 6px; }
.header-actions button { background: none; border: none; cursor: pointer; font-size: 1rem; }

.search-bar { padding: 12px; display: flex; gap: 6px; border-bottom: 1px solid var(--panel-border); }
.search-bar input { flex: 1; padding: 8px 12px; border: 1px solid var(--panel-border); border-radius: 16px; background: var(--bg-color); color: var(--text-main); outline: none; font-size: 0.85rem; }
.search-bar button { background: var(--primary); color: var(--bg-color); border: none; width: 32px; height: 32px; border-radius: 50%; font-weight: bold; cursor: pointer; }

.contact-list { flex: 1; overflow-y: auto; }
.contact-item { display: flex; align-items: center; gap: 12px; padding: 12px 16px; cursor: pointer; border-bottom: 1px solid rgba(255,255,255,0.02); }
.contact-item:hover, .contact-item.active { background: rgba(0, 210, 196, 0.05); }

.avatar-wrapper { position: relative; }
.avatar { width: 40px; height: 40px; background: var(--panel-border); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; color: var(--text-main); }
.avatar-wrapper .status-dot { position: absolute; bottom: 0; right: 0; border: 2px solid var(--sidebar-bg); }

.contact-info { display: flex; flex-direction: column; }
.contact-name { font-weight: 600; font-size: 0.95rem; }
.contact-status-text { font-size: 0.7rem; color: var(--text-muted); text-transform: capitalize; }

/* Chat Area */
.chat-area { flex: 1; display: flex; flex-direction: column; background: var(--chat-bg); }
.chat-header { padding: 16px 20px; background: var(--sidebar-bg); border-bottom: 1px solid var(--panel-border); display: flex; align-items: center; }
.chat-title-info { display: flex; align-items: center; gap: 10px; }
.chat-title-info h3 { margin: 0; font-size: 1rem; }

.chat-messages { flex: 1; padding: 20px; overflow-y: auto; display: flex; flex-direction: column; gap: 12px; }
.empty-state { text-align: center; color: var(--text-muted); margin: auto; font-size: 0.9rem; }

.message-bubble { max-width: 65%; padding: 10px 14px; border-radius: 16px; font-size: 0.9rem; word-break: break-word; }
.message-bubble.me { background-color: var(--bubble-me); color: var(--bubble-me-text); align-self: flex-end; border-bottom-right-radius: 4px; font-weight: 500; }
.message-bubble.other { background-color: var(--bubble-other); color: var(--bubble-other-text); border: 1px solid var(--panel-border); align-self: flex-start; border-bottom-left-radius: 4px; }
.msg-time { font-size: 0.65rem; text-align: right; margin-top: 4px; opacity: 0.7; }

/* Input Area */
.chat-input-area { padding: 14px 20px; background: var(--sidebar-bg); border-top: 1px solid var(--panel-border); display: flex; gap: 10px; }
#message-input { flex: 1; padding: 10px 16px; border: 1px solid var(--panel-border); border-radius: 20px; outline: none; font-size: 0.95rem; background: var(--bg-color); color: var(--text-main); }
.chat-input-area button { background-color: var(--primary); color: var(--bg-color); border: none; padding: 0 20px; border-radius: 20px; font-weight: bold; cursor: pointer; }

/* Modals */
.modal { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.7); display: flex; align-items: center; justify-content: center; z-index: 3000; }
.modal-content { background: var(--sidebar-bg); border: 1px solid var(--panel-border); padding: 24px; border-radius: 12px; text-align: center; width: 320px; }
.modal-content h3 { color: var(--accent-gold); margin-top: 0; }
.settings-form { display: flex; flex-direction: column; gap: 10px; text-align: left; }
.settings-form label { font-size: 0.75rem; color: var(--text-muted); }
.settings-form input { padding: 10px; border: 1px solid var(--panel-border); background: var(--bg-color); color: var(--text-main); border-radius: 6px; }
.modal-buttons { display: flex; gap: 10px; margin-top: 10px; }
.modal-buttons button { flex: 1; padding: 10px; border-radius: 6px; font-weight: bold; cursor: pointer; border: none; }
.modal-buttons button:not(.secondary) { background: var(--primary); color: var(--bg-color); }
.modal-buttons button.secondary { background: var(--panel-border); color: var(--text-main); }
#qrcode { background: white; padding: 10px; display: inline-block; margin: 10px 0; border-radius: 6px; }
#share-url { width: 100%; padding: 8px; border: 1px solid var(--panel-border); background: var(--bg-color); color: var(--text-main); text-align: center; border-radius: 6px; font-size: 0.75rem; margin-bottom: 15px; box-sizing: border-box; }
INNER_EOF

# Write Frontend Application Script
cat << 'INNER_EOF' > ghost_chat_v9/frontend/app.js
let authToken = localStorage.getItem('ghost_token');
let currentUsername = localStorage.getItem('ghost_user');
let activeRecipient = null;
let allMessages = [];
let allUsers = [];

if (authToken && currentUsername) {
    bootApp();
}

function switchAuthTab(tab) {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    event.target.classList.add('active');
    const btn = document.getElementById('auth-submit-btn');
    btn.innerText = tab === 'login' ? 'Sign In' : 'Create Account';
}

async function handleAuth(e) {
    e.preventDefault();
    const username = document.getElementById('auth-user').value.trim();
    const password = document.getElementById('auth-pass').value;
    const isLogin = document.querySelector('.tab-btn.active').innerText.includes('Sign In');
    const endpoint = isLogin ? '/api/auth/login' : '/api/auth/register';

    const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
    });
    const data = await res.json();
    if (res.ok) {
        saveSession(data.token, data.username);
    } else {
        alert(data.error);
    }
}

function saveSession(token, username) {
    localStorage.setItem('ghost_token', token);
    localStorage.setItem('ghost_user', username);
    authToken = token;
    currentUsername = username;
    bootApp();
}

function bootApp() {
    document.getElementById('auth-modal').classList.add('hidden');
    document.getElementById('app-container').classList.remove('hidden');
    document.getElementById('current-user-display').innerText = currentUsername;
    pollData();
    setInterval(pollData, 2000);
}

function logout() {
    localStorage.clear();
    location.reload();
}

async function updateMyStatus(status) {
    await fetch('/api/user/update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': authToken },
        body: JSON.stringify({ status })
    });
    const dot = document.getElementById('my-status-dot');
    dot.className = `status-dot ${status}`;
}

async function pollData() {
    if (!authToken) return;
    try {
        const [usersRes, msgRes] = await Promise.all([
            fetch('/api/users', { headers: { 'Authorization': authToken } }),
            fetch('/api/messages', { headers: { 'Authorization': authToken } })
        ]);
        if (msgRes.status === 401) { logout(); return; }

        allUsers = await usersRes.json();
        allMessages = await msgRes.json();

        renderContacts();
        if (activeRecipient) {
            renderMessages();
            updateActiveHeaderStatus();
        }
    } catch (err) {
        console.error("Sync error", err);
    }
}

function renderContacts() {
    const list = document.getElementById('contact-list');
    const otherUsers = allUsers.filter(u => u.username !== currentUsername);

    if (otherUsers.length === 0) {
        list.innerHTML = `<div style="padding:20px; text-align:center; color:var(--text-muted); font-size:0.85rem;">No other users. Add someone above!</div>`;
        return;
    }

    list.innerHTML = otherUsers.map(u => `
        <div class="contact-item ${activeRecipient === u.username ? 'active' : ''}" onclick="selectChat('${u.username}')">
            <div class="avatar-wrapper">
                <div class="avatar">${u.username[0].toUpperCase()}</div>
                <span class="status-dot ${u.status}"></span>
            </div>
            <div class="contact-info">
                <span class="contact-name">${u.username}</span>
                <span class="contact-status-text">${u.status}</span>
            </div>
        </div>
    `).join('');
}

function updateActiveHeaderStatus() {
    const userObj = allUsers.find(u => u.username === activeRecipient);
    const dot = document.getElementById('active-status-dot');
    if (userObj) {
        dot.className = `status-dot ${userObj.status}`;
    }
}

function startNewChat() {
    const target = document.getElementById('new-contact-input').value.trim();
    if (!target || target === currentUsername) return;
    document.getElementById('new-contact-input').value = '';
    selectChat(target);
}

function selectChat(username) {
    activeRecipient = username;
    document.getElementById('active-chat-title').innerText = username;
    document.getElementById('chat-form').classList.remove('hidden');
    renderContacts();
    renderMessages();
    updateActiveHeaderStatus();
}

function renderMessages() {
    const container = document.getElementById('chat-messages');
    const thread = allMessages.filter(m => (m.sender === currentUsername && m.recipient === activeRecipient) || (m.sender === activeRecipient && m.recipient === currentUsername));
    
    if (thread.length === 0) {
        container.innerHTML = `<div class="empty-state">No messages with ${activeRecipient} yet. Start typing below!</div>`;
        return;
    }

    container.innerHTML = thread.map(m => {
        const isMe = m.sender === currentUsername;
        const timeStr = new Date(m.timestamp * 1000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        return `
            <div class="message-bubble ${isMe ? 'me' : 'other'}">
                <div class="msg-text">${escapeHtml(m.text)}</div>
                <div class="msg-time">${timeStr}</div>
            </div>
        `;
    }).join('');
    container.scrollTop = container.scrollHeight;
}

async function sendMessage(e) {
    e.preventDefault();
    const input = document.getElementById('message-input');
    const text = input.value.trim();
    if (!text || !activeRecipient) return;
    input.value = '';

    await fetch('/api/messages/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': authToken },
        body: JSON.stringify({ recipient: activeRecipient, text })
    });
    pollData();
}

function openSettings() {
    document.getElementById('settings-username').value = currentUsername;
    document.getElementById('settings-password').value = '';
    document.getElementById('settings-modal').classList.remove('hidden');
}

async function saveSettings(e) {
    e.preventDefault();
    const newUsername = document.getElementById('settings-username').value.trim();
    const newPassword = document.getElementById('settings-password').value;

    const res = await fetch('/api/user/update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': authToken },
        body: JSON.stringify({ username: newUsername, password: newPassword })
    });
    const data = await res.json();
    if (res.ok) {
        saveSession(data.token, data.username);
        document.getElementById('settings-modal').classList.add('hidden');
        alert('Settings updated successfully!');
    } else {
        alert(data.error);
    }
}

function escapeHtml(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// Share Modal
document.getElementById('share-btn').addEventListener('click', () => {
    const modal = document.getElementById('share-modal');
    const qrContainer = document.getElementById('qrcode');
    const urlInput = document.getElementById('share-url');
    qrContainer.innerHTML = '';
    const currentUrl = window.location.origin;
    urlInput.value = currentUrl;
    new QRCode(qrContainer, { text: currentUrl, width: 130, height: 130, colorDark: "#000000", colorLight: "#ffffff", correctLevel: QRCode.CorrectLevel.H });
    modal.classList.remove('hidden');
});
INNER_EOF

# Launch V9 Server
echo "[*] Launching Ghost Chat V9..."
cd ghost_chat_v9
python3 server/server.py
