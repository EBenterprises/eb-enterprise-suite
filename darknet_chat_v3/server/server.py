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
from expansions_v3 import cloak_payload, register_zk_drop, unlock_zk_drop, PEER_REGISTRY, ZK_VAULT
>>>>>>> a0ec857 (Automated Termux sync: 2026-09-02 02:55:41)

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../frontend")
ASSETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../assets")

<<<<<<< HEAD
# Ephemeral memory store for zero-trace onion packets
MESSAGE_VAULT = []
ACTIVE_NODES = [
    {"node_id": "TOR_RELAY_0x9A", "latency": "42ms", "status": "SECURE"},
    {"node_id": "I2P_TUNNEL_0x4F", "latency": "88ms", "status": "ENCRYPTED"},
    {"node_id": "DARK_HOP_0x11", "latency": "15ms", "status": "ACTIVE"}
=======
MESSAGE_VAULT = []
ACTIVE_NODES = [
    {"node_id": "TOR_V3_0x9A", "latency": "28ms", "status": "SECURE"},
    {"node_id": "I2P_V3_0x4F", "latency": "55ms", "status": "ENCRYPTED"}
>>>>>>> a0ec857 (Automated Termux sync: 2026-09-02 02:55:41)
]

class DarkNetHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
<<<<<<< HEAD
=======
        global ACTIVE_NODES, MESSAGE_VAULT
>>>>>>> a0ec857 (Automated Termux sync: 2026-09-02 02:55:41)
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
=======
        try:
            data = json.loads(body) if body else {}
        except:
            data = {}

        if parsed_path.path == '/api/send':
            try:
                recipient = data.get('recipient', 'ANONYMOUS')
                raw_payload = data.get('payload', '')
                steg_mode = data.get('steg_mode', 'NONE')
                burn_timer = int(data.get('burn_timer', 10))

                cloaked = cloak_payload(raw_payload, steg_mode)

                packet = {
                    "id": base64.b32encode(os.urandom(5)).decode('utf-8').strip('='),
                    "recipient": recipient,
                    "payload": cloaked,
                    "timestamp": time.time(),
                    "expires_at": time.time() + burn_timer,
                    "hops": ACTIVE_NODES
>>>>>>> a0ec857 (Automated Termux sync: 2026-09-02 02:55:41)
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

        elif parsed_path.path == '/api/zk/create':
            res = register_zk_drop(data)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(res).encode('utf-8'))

        elif parsed_path.path == '/api/zk/unlock':
            res = unlock_zk_drop(data.get('drop_id'), data.get('passphrase', ''))
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(res).encode('utf-8'))

>>>>>>> a0ec857 (Automated Termux sync: 2026-09-02 02:55:41)
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
>>>>>>> a0ec857 (Automated Termux sync: 2026-09-02 02:55:41)
            MESSAGE_VAULT = [m for m in MESSAGE_VAULT if m["expires_at"] > current_time]

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(MESSAGE_VAULT).encode('utf-8'))
<<<<<<< HEAD
=======

>>>>>>> a0ec857 (Automated Termux sync: 2026-09-02 02:55:41)
        elif parsed_path.path == '/api/nodes':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
<<<<<<< HEAD
            self.wfile.write(json.dumps(ACTIVE_NODES).encode('utf-8'))
=======
            self.wfile.write(json.dumps(PEER_REGISTRY).encode('utf-8'))

        elif parsed_path.path == '/api/zk/list':
            summary = [{"drop_id": d["drop_id"], "recipient": d["recipient"], "locked": d["locked"]} for d in ZK_VAULT]
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(summary).encode('utf-8'))

>>>>>>> a0ec857 (Automated Termux sync: 2026-09-02 02:55:41)
        else:
            super().do_GET()

if __name__ == "__main__":
    os.makedirs(DIRECTORY, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)
    with socketserver.TCPServer(("", PORT), DarkNetHandler) as httpd:
<<<<<<< HEAD
        print(f"[*] DarkNet Node operational on http://localhost:{PORT}")
=======
        print(f"[*] DarkNet V3 Node operational on http://localhost:{PORT}")
>>>>>>> a0ec857 (Automated Termux sync: 2026-09-02 02:55:41)
        httpd.serve_forever()
