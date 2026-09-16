import http.server
import socketserver
import json
import os
<<<<<<< HEAD
import time
import base64
from urllib.parse import parse_qs, urlparse

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../frontend")
ASSETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../assets")

# Ephemeral memory store for zero-trace onion packets
MESSAGE_VAULT = []
ACTIVE_NODES = [
    {"node_id": "TOR_RELAY_0x9A", "latency": "42ms", "status": "SECURE"},
    {"node_id": "I2P_TUNNEL_0x4F", "latency": "88ms", "status": "ENCRYPTED"},
    {"node_id": "DARK_HOP_0x11", "latency": "15ms", "status": "ACTIVE"}
]

class DarkNetHandler(http.server.SimpleHTTPRequestHandler):
=======
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
>>>>>>> 2b1bd96 (Automated Termux sync: 2026-09-02 02:59:18)
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
        parsed_path = urlparse(self.path)
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')
<<<<<<< HEAD

        if parsed_path.path == '/api/send':
            try:
                data = json.loads(body)
                recipient = data.get('recipient', 'ANONYMOUS')
                payload = data.get('payload', '')
                burn_timer = int(data.get('burn_timer', 10))

                packet = {
                    "id": base64.b32encode(os.urandom(5)).decode('utf-8').strip('='),
                    "recipient": recipient,
                    "payload": base64.b64encode(payload.encode('utf-8')).decode('utf-8'),
                    "timestamp": time.time(),
                    "expires_at": time.time() + burn_timer,
                    "hops": ACTIVE_NODes if 'ACTIVE_NODes' in globals() else ACTIVE_NODES
                }
                MESSAGE_VAULT.append(packet)

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "SUCCESS", "packet_id": packet["id"]}).encode('utf-8'))
            except Exception as e:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode('utf-8'))
        else:
=======
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
>>>>>>> 2b1bd96 (Automated Termux sync: 2026-09-02 02:59:18)
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        parsed_path = urlparse(self.path)
<<<<<<< HEAD
        if parsed_path.path == '/api/messages':
            current_time = time.time()
            # Purge expired self-destruct messages
            global MESSAGE_VAULT
            MESSAGE_VAULT = [m for m in MESSAGE_VAULT if m["expires_at"] > current_time]

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(MESSAGE_VAULT).encode('utf-8'))
        elif parsed_path.path == '/api/nodes':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(ACTIVE_NODES).encode('utf-8'))
        else:
            super().do_GET()

if __name__ == "__main__":
    os.makedirs(DIRECTORY, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)
    with socketserver.TCPServer(("", PORT), DarkNetHandler) as httpd:
        print(f"[*] DarkNet Node operational on http://localhost:{PORT}")
        httpd.serve_forever()
=======
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
>>>>>>> 2b1bd96 (Automated Termux sync: 2026-09-02 02:59:18)
