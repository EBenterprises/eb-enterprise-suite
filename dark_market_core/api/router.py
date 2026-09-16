import json
import uuid
from database.schema import get_connection
from crypto.pgp_vault import PGTVault

class Router:
    @staticmethod
    def handle_request(path, method, headers, body):
        if path == '/api/health' and method == 'GET':
            return 200, {"status": "operational", "node": "onion_proxied_instance"}

        elif path == '/api/auth/register' and method == 'POST':
            data = json.loads(body.decode('utf-8'))
            uid = str(uuid.uuid4())
            salt, p_hash = PGTVault.hash_secret(data.get('password'))
            
            try:
                conn = get_connection()
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO users (id, username, pgp_public_key, password_hash, salt, role) VALUES (?, ?, ?, ?, ?, ?)",
                    (uid, data.get('username'), data.get('pgp_key', ''), p_hash, salt, data.get('role', 'buyer'))
                )
                conn.commit()
                conn.close()
                return 201, {"status": "success", "user_id": uid}
            except Exception as e:
                return 400, {"error": str(e)}

        elif path == '/api/listings' and method == 'GET':
            conn = get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT id, vendor_id, title, description, price_xmr, stock FROM listings")
            rows = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return 200, {"listings": rows}

        elif path == '/api/order/create' and method == 'POST':
            data = json.loads(body.decode('utf-8'))
            oid = str(uuid.uuid4())
            try:
                conn = get_connection()
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO orders (id, listing_id, buyer_id, vendor_id, encrypted_shipping_memo, amount_xmr) VALUES (?, ?, ?, ?, ?, ?)",
                    (oid, data.get('listing_id'), data.get('buyer_id'), data.get('vendor_id'), data.get('memo'), data.get('amount'))
                )
                conn.commit()
                conn.close()
                return 201, {"status": "success", "order_id": oid, "escrow_state": "FUNDS_LOCKED"}
            except Exception as e:
                return 400, {"error": str(e)}

        return 404, {"error": "Endpoint not found"}
