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

MESSAGES = [
    {"id": "msg_01", "sender": "System", "text": "Welcome to Ghost Chat. End-to-end encrypted local session active.", "timestamp": time.time() - 60}
]

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

class GhostHandler(http.server.SimpleHTTPRequestHandler):
>>>>>>> 9f45eed (Automated Termux sync: 2026-09-02 02:55:50)
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
<<<<<<< HEAD
=======
        global MESSAGES
>>>>>>> 9f45eed (Automated Termux sync: 2026-09-02 02:55:50)
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

        if parsed_path.path == '/api/messages/send':
            sender = data.get('sender', 'You')
            text = data.get('text', '').strip()
            
            if text:
                msg = {
                    "id": base64.b32encode(os.urandom(4)).decode('utf-8').strip('='),
                    "sender": sender,
                    "text": text,
                    "timestamp": time.time()
                }
                MESSAGES.append(msg)
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "SUCCESS", "message": msg}).encode('utf-8'))
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(json.dumps({"error": "Empty message"}).encode('utf-8'))
>>>>>>> 9f45eed (Automated Termux sync: 2026-09-02 02:55:50)
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        parsed_path = urlparse(self.path)
        if parsed_path.path == '/api/messages':
<<<<<<< HEAD
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
=======
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(MESSAGES).encode('utf-8'))
>>>>>>> 9f45eed (Automated Termux sync: 2026-09-02 02:55:50)
        else:
            super().do_GET()

if __name__ == "__main__":
    os.makedirs(DIRECTORY, exist_ok=True)
<<<<<<< HEAD
    os.makedirs(ASSETS_DIR, exist_ok=True)
    with socketserver.TCPServer(("", PORT), DarkNetHandler) as httpd:
        print(f"[*] DarkNet Node operational on http://localhost:{PORT}")
        httpd.serve_forever()
=======
    
    PORT = 8080
    server_instance = None
    for p in range(8080, 8095):
        try:
            server_instance = ReusableTCPServer(("", p), GhostHandler)
            PORT = p
            break
        except OSError:
            continue

    if not server_instance:
        print("[!] Error: Could not bind to port.")
        exit(1)

    print(f"[*] Ghost Chat operational on http://localhost:{PORT}")
    try:
        server_instance.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Shutting down Ghost Chat...")
        server_instance.server_close()
>>>>>>> 9f45eed (Automated Termux sync: 2026-09-02 02:55:50)
