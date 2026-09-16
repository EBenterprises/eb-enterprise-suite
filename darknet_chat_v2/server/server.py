import http.server
import socketserver
import json
import os
import time
import base64
<<<<<<< HEAD
from urllib.parse import parse_qs, urlparse
=======
from urllib.parse import urlparse
from expansions import handle_dead_drop, get_dead_drops, rotate_circuit
>>>>>>> 0e624b8 (Automated Termux sync: 2026-09-02 02:59:00)

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../frontend")
ASSETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../assets")

<<<<<<< HEAD
# Ephemeral memory store for zero-trace onion packets
=======
>>>>>>> 0e624b8 (Automated Termux sync: 2026-09-02 02:59:00)
MESSAGE_VAULT = []
ACTIVE_NODES = [
    {"node_id": "TOR_RELAY_0x9A", "latency": "42ms", "status": "SECURE"},
    {"node_id": "I2P_TUNNEL_0x4F", "latency": "88ms", "status": "ENCRYPTED"},
    {"node_id": "DARK_HOP_0x11", "latency": "15ms", "status": "ACTIVE"}
]

class DarkNetHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
<<<<<<< HEAD
=======
        global ACTIVE_NODES
>>>>>>> 0e624b8 (Automated Termux sync: 2026-09-02 02:59:00)
        parsed_path = urlparse(self.path)
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')

<<<<<<< HEAD
        if parsed_path.path == '/api/send':
            try:
                data = json.loads(body)
=======
        try:
            data = json.loads(body) if body else {}
        except:
            data = {}

        if parsed_path.path == '/api/send':
            try:
>>>>>>> 0e624b8 (Automated Termux sync: 2026-09-02 02:59:00)
                recipient = data.get('recipient', 'ANONYMOUS')
                payload = data.get('payload', '')
                burn_timer = int(data.get('burn_timer', 10))

                packet = {
                    "id": base64.b32encode(os.urandom(5)).decode('utf-8').strip('='),
                    "recipient": recipient,
                    "payload": base64.b64encode(payload.encode('utf-8')).decode('utf-8'),
                    "timestamp": time.time(),
                    "expires_at": time.time() + burn_timer,
<<<<<<< HEAD
                    "hops": ACTIVE_NODes if 'ACTIVE_NODes' in globals() else ACTIVE_NODES
=======
                    "hops": ACTIVE_NODES
>>>>>>> 0e624b8 (Automated Termux sync: 2026-09-02 02:59:00)
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
<<<<<<< HEAD
=======

        elif parsed_path.path == '/api/deaddrop/create':
            response = handle_dead_drop(data)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))

        elif parsed_path.path == '/api/circuit/rotate':
            ACTIVE_NODES = rotate_circuit()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "CIRCUIT_ROTATED", "nodes": ACTIVE_NODES}).encode('utf-8'))

>>>>>>> 0e624b8 (Automated Termux sync: 2026-09-02 02:59:00)
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
=======
        global MESSAGE_VAULT
        parsed_path = urlparse(self.path)
        if parsed_path.path == '/api/messages':
            current_time = time.time()
>>>>>>> 0e624b8 (Automated Termux sync: 2026-09-02 02:59:00)
            MESSAGE_VAULT = [m for m in MESSAGE_VAULT if m["expires_at"] > current_time]

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(MESSAGE_VAULT).encode('utf-8'))
<<<<<<< HEAD
=======

>>>>>>> 0e624b8 (Automated Termux sync: 2026-09-02 02:59:00)
        elif parsed_path.path == '/api/nodes':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(ACTIVE_NODES).encode('utf-8'))
<<<<<<< HEAD
=======

        elif parsed_path.path == '/api/deaddrop/list':
            drops = get_dead_drops()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(drops).encode('utf-8'))

>>>>>>> 0e624b8 (Automated Termux sync: 2026-09-02 02:59:00)
        else:
            super().do_GET()

if __name__ == "__main__":
    os.makedirs(DIRECTORY, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)
    with socketserver.TCPServer(("", PORT), DarkNetHandler) as httpd:
<<<<<<< HEAD
        print(f"[*] DarkNet Node operational on http://localhost:{PORT}")
=======
        print(f"[*] DarkNet V2 Node operational on http://localhost:{PORT}")
>>>>>>> 0e624b8 (Automated Termux sync: 2026-09-02 02:59:00)
        httpd.serve_forever()
