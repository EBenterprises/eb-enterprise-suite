import http.server
import socketserver
import json
import uuid
import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from crypto_engine import NativeCryptoEngine
from storage_engine import initialize_storage, get_db

PORT = 8080

class MarketDaemonHandler(http.server.BaseHTTPRequestHandler):
    def _send_json(self, status_code, payload):
        response = json.dumps(payload).encode('utf-8')
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(response)))
        self.end_headers()
        self.wfile.write(response)

    def do_GET(self):
        if self.path == '/api/v1/health':
            self._send_json(200, {"status": "active", "engine": "native_zero_dependency"})
        elif self.path == '/api/v1/inventory':
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute("SELECT id, vendor_id, item_name, specification, price_xmr, stock_count FROM inventory")
            rows = [dict(r) for r in cursor.fetchall()]
            conn.close()
            self._send_json(200, {"inventory": rows})
        else:
            self._send_json(404, {"error": "endpoint_not_found"})

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        raw_body = self.rfile.read(content_length)
        
        try:
            data = json.loads(raw_body.decode('utf-8')) if raw_body else {}
        except json.JSONDecodeError:
            self._send_json(400, {"error": "malformed_json"})
            return

        if self.path == '/api/v1/auth/register':
            uid = str(uuid.uuid4())
            salt, phash = NativeCryptoEngine.derive_key(data.get('password', ''))
            try:
                conn = get_db()
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO identities (id, alias, pgp_key, pass_hash, salt, clearance) VALUES (?, ?, ?, ?, ?, ?)",
                    (uid, data.get('alias'), data.get('pgp_key', ''), phash, salt, data.get('clearance', 'vendor'))
                )
                conn.commit()
                conn.close()
                self._send_json(201, {"status": "success", "identity_id": uid})
            except Exception as e:
                self._send_json(400, {"error": str(e)})

        elif self.path == '/api/v1/ledger/commit':
            tx_id = str(uuid.uuid4())
            try:
                conn = get_db()
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO ledger (id, inventory_id, buyer_id, vendor_id, status, encrypted_payload, valuation_xmr) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    (tx_id, data.get('inventory_id'), data.get('buyer_id'), data.get('vendor_id'), 'ESCROW_LOCKED', data.get('encrypted_payload'), data.get('valuation_xmr'))
                )
                conn.commit()
                conn.close()
                self._send_json(201, {"status": "success", "transaction_id": tx_id, "escrow_state": "ESCROW_LOCKED"})
            except Exception as e:
                self._send_json(400, {"error": str(e)})
        else:
            self._send_json(404, {"error": "endpoint_not_found"})

if __name__ == '__main__':
    initialize_storage()
    with socketserver.TCPServer(("", PORT), MarketDaemonHandler) as httpd:
        print(f"[*] Dark Market Daemon running on loopback port {PORT}")
        httpd.serve_forever()
