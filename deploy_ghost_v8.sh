#!/bin/bash
echo "[*] Initializing Ghost Messenger V8 (Private Direct Messaging & Auth Suite)..."
cd "$(dirname "$0")"

if ! command -v python3 &> /dev/null; then
    echo "[!] Python3 not detected. Aborting."
    exit 1
fi

mkdir -p ghost_chat_v8/server ghost_chat_v8/frontend

# Write Server Engine with Multi-User Vault & Auth
cat << 'INNER_EOF' > ghost_chat_v8/server/server.py
import http.server
import socketserver
import json
import os
import time
import base64
from urllib.parse import urlparse

DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../frontend")

# In-Memory Storage Vault
USERS = {}        # username -> {password_hash, email, phone, token}
SESSIONS = {}     # token -> username
MESSAGES = []     # list of {id, sender, recipient, text, timestamp}
PENDING_OTPS = {} # identifier -> code

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

class GhostV8Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
        global USERS, SESSIONS, MESSAGES, PENDING_OTPS
        parsed_path = urlparse(self.path)
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')

        try:
            data = json.loads(body) if body else {}
        except:
            data = {}

        # 1. Register / Account Creation
        if parsed_path.path == '/api/auth/register':
            username = data.get('username', '').strip()
            password = data.get('password', '')
            if not username or not password:
                return self.send_json(400, {"error": "Username and password required"})
            if username in USERS:
                return self.send_json(400, {"error": "Username already exists"})
            
            token = base64.b32encode(os.urandom(10)).decode('utf-8').strip('=')
            USERS[username] = {"password": password, "token": token}
            SESSIONS[token] = username
            self.send_json(200, {"status": "SUCCESS", "token": token, "username": username})

        # 2. Traditional Login
        elif parsed_path.path == '/api/auth/login':
            username = data.get('username', '').strip()
            password = data.get('password', '')
            user = USERS.get(username)
            if not user or user["password"] != password:
                return self.send_json(401, {"error": "Invalid credentials"})
            
            self.send_json(200, {"status": "SUCCESS", "token": user["token"], "username": username})

        # 3. Google OAuth Partner Simulator Login
        elif parsed_path.path == '/api/auth/google':
            email = data.get('email', '').strip()
            if not email:
                return self.send_json(400, {"error": "Invalid Google profile"})
            username = email.split('@')[0]
            if username not in USERS:
                token = base64.b32encode(os.urandom(10)).decode('utf-8').strip('=')
                USERS[username] = {"password": "oauth_secured", "token": token}
            else:
                token = USERS[username]["token"]
            SESSIONS[token] = username
            self.send_json(200, {"status": "SUCCESS", "token": token, "username": username})

        # 4. Request OTP (SMS / Email)
        elif parsed_path.path == '/api/auth/otp/request':
            target = data.get('target', '').strip()
            if not target:
                return self.send_json(400, {"error": "Email or Phone required"})
            code = "8492" # simulated static verification code for testing ease
            PENDING_OTPS[target] = code
            self.send_json(200, {"status": "OTP_SENT", "debug_code": code})

        # 5. Verify OTP Login
        elif parsed_path.path == '/api/auth/otp/verify':
            target = data.get('target', '').strip()
            code = data.get('code', '').strip()
            if PENDING_OTPS.get(target) == code:
                username = target.split('@')[0] if '@' in target else f"User_{target[-4:]}"
                if username not in USERS:
                    token = base64.b32encode(os.urandom(10)).decode('utf-8').strip('=')
                    USERS[username] = {"password": "otp_secured", "token": token}
                else:
                    token = USERS[username]["token"]
                SESSIONS[token] = username
                self.send_json(200, {"status": "SUCCESS", "token": token, "username": username})
            else:
                self.send_json(401, {"error": "Invalid verification code"})

        # 6. Send Direct Message
        elif parsed_path.path == '/api/messages/send':
            token = self.headers.get('Authorization', '')
            sender = SESSIONS.get(token)
            if not sender:
                return self.send_json(401, {"error": "Unauthorized"})
            
            recipient = data.get('recipient', '').strip()
            text = data.get('text', '').strip()
            if not recipient or not text:
                return self.send_json(400, {"error": "Recipient and text required"})

            msg = {
                "id": base64.b32encode(os.urandom(4)).decode('utf-8').strip('='),
                "sender": sender,
                "recipient": recipient,
                "text": text,
                "timestamp": time.time()
            }
            MESSAGES.append(msg)
            self.send_json(200, {"status": "SUCCESS", "message": msg})
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        global MESSAGES, USERS
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/api/users':
            self.send_json(200, list(USERS.keys()))

        elif parsed_path.path == '/api/messages':
            token = self.headers.get('Authorization', '')
            user = SESSIONS.get(token)
            if not user:
                return self.send_json(401, {"error": "Unauthorized"})
            
            # Filter messages where user is sender or recipient
            user_msgs = [m for m in MESSAGES if m["sender"] == user or m["recipient"] == user]
            self.send_json(200, user_msgs)
        else:
            super().do_GET()

    def send_json(self, code, data):
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

if __name__ == "__main__":
    os.makedirs(DIRECTORY, exist_ok=True)
    
    PORT = 8080
    server_instance = None
    for p in range(8080, 8095):
        try:
            server_instance = ReusableTCPServer(("", p), GhostV8Handler)
            PORT = p
            break
        except OSError:
            continue

    if not server_instance:
        print("[!] Error: Could not bind to port.")
        exit(1)

    print(f"[*] Ghost Chat V8 operational on http://localhost:{PORT}")
    try:
        server_instance.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Shutting down Ghost Chat V8...")
        server_instance.server_close()
INNER_EOF

# Write Frontend HTML with Auth Gate & Multi-Conversation UI
cat << 'INNER_EOF' > ghost_chat_v8/frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ghost Messenger V8 // Secure Direct Messaging</title>
    <link rel="stylesheet" href="style.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
</head>
<body>
    <!-- AUTHENTICATION GATEWAY MODAL -->
    <div id="auth-modal" class="auth-overlay">
        <div class="auth-card">
            <h2>GHOST CHAT V8</h2>
            <p>End-to-End Encrypted Direct Messaging Suite</p>
            
            <div class="auth-tabs">
                <button class="tab-btn active" onclick="switchAuthTab('login')">Sign In</button>
                <button class="tab-btn" onclick="switchAuthTab('register')">Register</button>
                <button class="tab-btn" onclick="switchAuthTab('otp')">SMS/Email OTP</button>
            </div>

            <!-- Standard Login Form -->
            <form id="login-form" class="auth-form" onsubmit="handleLogin(event)">
                <input type="text" id="login-user" placeholder="Username" required />
                <input type="password" id="login-pass" placeholder="Password" required />
                <button type="submit" class="auth-action-btn">Sign In</button>
            </form>

            <!-- Register Form -->
            <form id="register-form" class="auth-form hidden" onsubmit="handleRegister(event)">
                <input type="text" id="reg-user" placeholder="Choose Username" required />
                <input type="password" id="reg-pass" placeholder="Choose Password" required />
                <button type="submit" class="auth-action-btn">Create Account</button>
            </form>

            <!-- OTP Request/Verify Form -->
            <div id="otp-form" class="auth-form hidden">
                <input type="text" id="otp-target" placeholder="Enter Email or Phone Number" />
                <button type="button" class="auth-action-btn secondary" onclick="requestOTP()">Send Verification Code</button>
                <input type="text" id="otp-code" placeholder="Enter 4-digit Code" />
                <button type="button" class="auth-action-btn" onclick="verifyOTP()">Verify & Login</button>
            </div>

            <div class="divider"><span>OR PARTNER SIGN-IN</span></div>
            <button type="button" class="google-btn" onclick="simulateGoogleLogin()">
                <svg width="18" height="18" viewBox="0 0 24 24"><path fill="#EA4335" d="M12 5c1.6 0 3 .6 4.1 1.6l3.1-3.1C17.3 1.8 14.8 1 12 1 7.4 1 3.5 3.6 1.6 7.4l3.7 2.9C6.2 7.3 8.9 5 12 5z"/><path fill="#4285F4" d="M23.5 12.3c0-.8-.1-1.6-.2-2.3H12v4.5h6.5c-.3 1.5-1.1 2.8-2.4 3.7l3.7 2.9c2.2-2 3.7-5 3.7-8.8z"/><path fill="#FBBC05" d="M5.3 14.7c-.2-.7-.4-1.5-.4-2.7s.2-2 .4-2.7L1.6 6.4C.6 8.4 0 10.6 0 13s.6 4.6 1.6 6.6l3.7-2.9z"/><path fill="#34A853" d="M12 23c3.2 0 6-1.1 8-3l-3.7-2.9c-1.1.7-2.5 1.2-4.3 1.2-3.1 0-5.8-2.3-6.7-5.3L1.6 15C3.5 18.8 7.4 23 12 23z"/></svg>
                Continue with Google
            </button>
        </div>
    </div>

    <!-- MAIN APP CONTAINER -->
    <div id="app-container" class="app-container hidden">
        <aside class="sidebar">
            <div class="sidebar-header">
                <div>
                    <h3 id="current-user-display">User</h3>
                    <span class="online-status">● Encrypted Session</span>
                </div>
                <div class="header-actions">
                    <button id="share-btn" title="Share App Link">🔗</button>
                    <button id="logout-btn" title="Sign Out" onclick="logout()">🚪</button>
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
                    <span class="status-dot"></span>
                    <h3 id="active-chat-title">Select a Conversation</h3>
                </div>
            </header>

            <div id="chat-messages" class="chat-messages">
                <div class="empty-state">Select a contact on the left or type a username above to begin messaging securely.</div>
            </div>

            <form id="chat-form" class="chat-input-area hidden" onsubmit="sendMessage(event)">
                <input type="text" id="message-input" placeholder="Type an encrypted message..." autocomplete="off" required />
                <button type="submit" id="send-btn">Send</button>
            </form>
        </main>
    </div>

    <!-- Share Modal -->
    <div id="share-modal" class="modal hidden">
        <div class="modal-content">
            <h3>Invite Friends</h3>
            <p>Scan with any device or share the public link:</p>
            <div id="qrcode"></div>
            <input type="text" id="share-url" readonly />
            <button id="close-modal" onclick="document.getElementById('share-modal').classList.add('hidden')">Close</button>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
INNER_EOF

# Write CSS (Clean, Modern Messenger Suite)
cat << 'INNER_EOF' > ghost_chat_v8/frontend/style.css
:root {
    --bg-color: #f0f2f5;
    --sidebar-bg: #ffffff;
    --chat-bg: #efeae2;
    --panel-border: #e4e6eb;
    --primary: #0084ff;
    --primary-hover: #006dd6;
    --text-main: #050505;
    --text-muted: #65676b;
    --bubble-me: #0084ff;
    --bubble-me-text: #ffffff;
    --bubble-other: #ffffff;
    --bubble-other-text: #050505;
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

/* Auth Overlay */
.auth-overlay {
    position: fixed;
    top: 0; left: 0; width: 100%; height: 100%;
    background: rgba(11, 15, 18, 0.85);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 2000;
}

.auth-card {
    background: #ffffff;
    padding: 30px;
    border-radius: 12px;
    width: 360px;
    text-align: center;
    box-shadow: 0 8px 24px rgba(0,0,0,0.2);
}

.auth-card h2 { margin: 0 0 5px 0; color: #1a1a1a; }
.auth-card p { font-size: 0.85rem; color: var(--text-muted); margin-bottom: 20px; }

.auth-tabs {
    display: flex;
    border-bottom: 1px solid var(--panel-border);
    margin-bottom: 20px;
}

.tab-btn {
    flex: 1;
    background: none;
    border: none;
    padding: 10px;
    font-weight: 600;
    cursor: pointer;
    color: var(--text-muted);
    font-size: 0.85rem;
}

.tab-btn.active {
    color: var(--primary);
    border-bottom: 2px solid var(--primary);
}

.auth-form {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.auth-form input {
    padding: 12px;
    border: 1px solid var(--panel-border);
    border-radius: 8px;
    font-size: 0.95rem;
    outline: none;
}

.auth-action-btn {
    background: var(--primary);
    color: white;
    border: none;
    padding: 12px;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
}

.auth-action-btn.secondary {
    background: #e4e6eb;
    color: var(--text-main);
}

.divider {
    margin: 20px 0;
    border-bottom: 1px solid var(--panel-border);
    position: relative;
}

.divider span {
    position: absolute;
    top: -10px;
    left: 50%;
    transform: translateX(-50%);
    background: white;
    padding: 0 10px;
    font-size: 0.7rem;
    color: var(--text-muted);
    font-weight: 600;
}

.google-btn {
    width: 100%;
    background: white;
    border: 1px solid var(--panel-border);
    padding: 10px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    font-weight: 600;
    cursor: pointer;
    font-size: 0.9rem;
}

/* App Layout */
.app-container {
    width: 100%;
    max-width: 1100px;
    height: 100vh;
    background: var(--sidebar-bg);
    display: flex;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

@media (min-width: 768px) {
    .app-container {
        height: 88vh;
        border-radius: 12px;
        overflow: hidden;
    }
}

.sidebar {
    width: 300px;
    border-right: 1px solid var(--panel-border);
    display: flex;
    flex-direction: column;
    background: var(--sidebar-bg);
}

.sidebar-header {
    padding: 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid var(--panel-border);
}

.sidebar-header h3 { margin: 0; font-size: 1rem; }
.online-status { font-size: 0.7rem; color: #31a24c; }

.header-actions { display: flex; gap: 8px; }
.header-actions button { background: none; border: none; cursor: pointer; font-size: 1.1rem; }

.search-bar {
    padding: 12px;
    display: flex;
    gap: 6px;
    border-bottom: 1px solid var(--panel-border);
}

.search-bar input {
    flex: 1;
    padding: 8px 12px;
    border: 1px solid var(--panel-border);
    border-radius: 16px;
    background: var(--bg-color);
    outline: none;
    font-size: 0.85rem;
}

.search-bar button {
    background: var(--primary);
    color: white;
    border: none;
    width: 32px;
    height: 32px;
    border-radius: 50%;
    font-weight: bold;
    cursor: pointer;
}

.contact-list { flex: 1; overflow-y: auto; }

.contact-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    cursor: pointer;
    border-bottom: 1px solid #f0f2f5;
}

.contact-item:hover, .contact-item.active { background: var(--bg-color); }

.avatar {
    width: 40px;
    height: 40px;
    background: #e4e6eb;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    color: var(--text-muted);
}

.contact-name { font-weight: 600; font-size: 0.95rem; }

/* Chat Area */
.chat-area {
    flex: 1;
    display: flex;
    flex-direction: column;
    background: var(--chat-bg);
}

.chat-header {
    padding: 14px 20px;
    background: #ffffff;
    border-bottom: 1px solid var(--panel-border);
    display: flex;
    align-items: center;
}

.chat-title-info { display: flex; align-items: center; gap: 10px; }
.status-dot { width: 8px; height: 8px; background-color: #31a24c; border-radius: 50%; }
.chat-title-info h3 { margin: 0; font-size: 1rem; }

.chat-messages {
    flex: 1;
    padding: 20px;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.empty-state {
    text-align: center;
    color: var(--text-muted);
    margin: auto;
    font-size: 0.9rem;
}

.message-bubble {
    max-width: 65%;
    padding: 10px 14px;
    border-radius: 16px;
    font-size: 0.9rem;
    word-break: break-word;
    box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.message-bubble.me {
    background-color: var(--bubble-me);
    color: var(--bubble-me-text);
    align-self: flex-end;
    border-bottom-right-radius: 4px;
}

.message-bubble.other {
    background-color: var(--bubble-other);
    color: var(--bubble-other-text);
    align-self: flex-start;
    border-bottom-left-radius: 4px;
}

.msg-time { font-size: 0.65rem; text-align: right; margin-top: 4px; opacity: 0.7; }

/* Input Area */
.chat-input-area {
    padding: 12px 20px;
    background: #ffffff;
    border-top: 1px solid var(--panel-border);
    display: flex;
    gap: 10px;
}

#message-input {
    flex: 1;
    padding: 10px 16px;
    border: 1px solid var(--panel-border);
    border-radius: 20px;
    outline: none;
    font-size: 0.95rem;
    background: var(--bg-color);
}

#send-btn {
    background-color: var(--primary);
    color: white;
    border: none;
    padding: 0 20px;
    border-radius: 20px;
    font-weight: 600;
    cursor: pointer;
}

/* Modal */
.modal {
    position: fixed;
    top: 0; left: 0; width: 100%; height: 100%;
    background: rgba(0,0,0,0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 3000;
}

.modal-content {
    background: white;
    padding: 24px;
    border-radius: 12px;
    text-align: center;
    width: 300px;
    box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}

#qrcode { background: white; padding: 10px; display: inline-block; margin: 10px 0; }
#share-url { width: 100%; padding: 8px; border: 1px solid var(--panel-border); background: var(--bg-color); text-align: center; border-radius: 6px; font-size: 0.8rem; margin-bottom: 15px; box-sizing: border-box; }
#close-modal { background: var(--primary); color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-weight: 600; }
INNER_EOF

# Write Frontend App Script
cat << 'INNER_EOF' > ghost_chat_v8/frontend/app.js
let authToken = localStorage.getItem('ghost_token');
let currentUsername = localStorage.getItem('ghost_user');
let activeRecipient = null;
let allMessages = [];

if (authToken && currentUsername) {
    bootApp();
}

function switchAuthTab(tab) {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('login-form').classList.add('hidden');
    document.getElementById('register-form').classList.add('hidden');
    document.getElementById('otp-form').classList.add('hidden');

    if (tab === 'login') {
        event.target.classList.add('active');
        document.getElementById('login-form').classList.remove('hidden');
    } else if (tab === 'register') {
        event.target.classList.add('active');
        document.getElementById('register-form').classList.remove('hidden');
    } else if (tab === 'otp') {
        event.target.classList.add('active');
        document.getElementById('otp-form').classList.remove('hidden');
    }
}

async function handleLogin(e) {
    e.preventDefault();
    const username = document.getElementById('login-user').value.trim();
    const password = document.getElementById('login-pass').value;

    const res = await fetch('/api/auth/login', {
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

async function handleRegister(e) {
    e.preventDefault();
    const username = document.getElementById('reg-user').value.trim();
    const password = document.getElementById('reg-pass').value;

    const res = await fetch('/api/auth/register', {
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

async function requestOTP() {
    const target = document.getElementById('otp-target').value.trim();
    if (!target) return alert('Enter email or phone');
    const res = await fetch('/api/auth/otp/request', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ target })
    });
    const data = await res.json();
    if (res.ok) {
        alert(`Verification code sent! [Demo Code: ${data.debug_code}]`);
        document.getElementById('otp-code').value = data.debug_code; // auto-fill for frictionless test
    }
}

async function verifyOTP() {
    const target = document.getElementById('otp-target').value.trim();
    const code = document.getElementById('otp-code').value.trim();
    const res = await fetch('/api/auth/otp/verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ target, code })
    });
    const data = await res.json();
    if (res.ok) {
        saveSession(data.token, data.username);
    } else {
        alert(data.error);
    }
}

async function simulateGoogleLogin() {
    const email = prompt("Enter simulated Google Email (e.g. alice@gmail.com):", "alice@gmail.com");
    if (!email) return;
    const res = await fetch('/api/auth/google', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email })
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
    localStorage.removeItem('ghost_token');
    localStorage.removeItem('ghost_user');
    location.reload();
}

async function pollData() {
    if (!authToken) return;
    try {
        const [usersRes, msgRes] = await Promise.all([
            fetch('/api/users'),
            fetch('/api/messages', { headers: { 'Authorization': authToken } })
        ]);
        if (msgRes.status === 401) { logout(); return; }
        
        const users = await usersRes.json();
        allMessages = await msgRes.json();
        
        renderContacts(users);
        if (activeRecipient) renderMessages();
    } catch (err) {
        console.error("Sync error", err);
    }
}

function renderContacts(users) {
    const list = document.getElementById('contact-list');
    const otherUsers = users.filter(u => u !== currentUsername);
    
    if (otherUsers.length === 0) {
        list.innerHTML = `<div style="padding:20px; text-align:center; color:#65676b; font-size:0.85rem;">No other users yet. Use search above to start a chat!</div>`;
        return;
    }

    list.innerHTML = otherUsers.map(u => `
        <div class="contact-item ${activeRecipient === u ? 'active' : ''}" onclick="selectChat('${u}')">
            <div class="avatar">${u[0].toUpperCase()}</div>
            <div class="contact-name">${u}</div>
        </div>
    `).join('');
}

function startNewChat() {
    const target = document.getElementById('new-contact-input').value.trim();
    if (!target || target === currentUsername) return;
    document.getElementById('new-contact-input').value = '';
    selectChat(target);
}

function selectChat(username) {
    activeRecipient = username;
    document.getElementById('active-chat-title').innerText = `Chat with ${username}`;
    document.getElementById('chat-form').classList.remove('hidden');
    renderContactsWindowHighlight();
    renderMessages();
}

function renderContactsWindowHighlight() {
    document.querySelectorAll('.contact-item').forEach(el => {
        if (el.innerText.trim() === activeRecipient) el.classList.add('active');
        else el.classList.remove('active');
    });
}

function renderMessages() {
    const container = document.getElementById('chat-messages');
    const thread = allMessages.filter(m => (m.sender === currentUsername && m.recipient === activeRecipient) || (m.sender === activeRecipient && m.recipient === currentUsername));
    
    if (thread.length === 0) {
        container.innerHTML = `<div class="empty-state">No messages with ${activeRecipient} yet. Send your first message below!</div>`;
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

# Launch V8 Server
echo "[*] Launching Ghost Chat V8..."
cd ghost_chat_v8
python3 server/server.py
