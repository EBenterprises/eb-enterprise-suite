import http.server
import socketserver
import json
import os
import time
import base64
<<<<<<< HEAD
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
>>>>>>> eac6c53 (Automated Termux sync: 2026-09-02 02:55:54)
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
<<<<<<< HEAD
=======
        global USERS, SESSIONS, MESSAGES, PENDING_OTPS
>>>>>>> eac6c53 (Automated Termux sync: 2026-09-02 02:55:54)
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
=======
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
>>>>>>> eac6c53 (Automated Termux sync: 2026-09-02 02:55:54)
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
<<<<<<< HEAD
        parsed_path = urlparse(self.path)
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
>>>>>>> eac6c53 (Automated Termux sync: 2026-09-02 02:55:54)
