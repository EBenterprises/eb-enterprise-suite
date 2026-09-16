#!/usr/bin/env bash
set -e

echo "[*] Consolidating Secure Vault directories..."
cd ~

# If nested secure_vault exists, pull contents up
if [ -d "secure_vault/secure_vault" ]; then
    cp -r secure_vault/secure_vault/* secure_vault/ 2>/dev/null || true
    rm -rf secure_vault/secure_vault
fi

mkdir -p secure_vault/core secure_vault/public secure_vault/data

echo "[*] Writing Server Script..."
cat << 'INNER_EOF' > secure_vault/server.py
import os
import json
import base64
import hashlib
from http.server import HTTPServer, SimpleHTTPRequestHandler

STORE_PATH = "data/encrypted_store.enc"

class ProprietaryCryptoEngine:
    @staticmethod
    def _derive_key(passphrase: str, salt: bytes) -> bytes:
        return hashlib.pbkdf2_hmac('sha256', passphrase.encode('utf-8'), salt, 100_000)

    @staticmethod
    def encrypt_data(passphrase: str, plaintext: str) -> dict:
        salt = os.urandom(16)
        key = ProprietaryCryptoEngine._derive_key(passphrase, salt)
        pt_bytes = plaintext.encode('utf-8')
        iv = os.urandom(len(pt_bytes) or 16)
        extended_key = (key * ((len(pt_bytes) // len(key)) + 1))[:len(pt_bytes)]
        ciphertext_bytes = bytes(a ^ b ^ c for a, b, c in zip(pt_bytes, extended_key, iv))
        return {
            "salt": base64.b64encode(salt).decode('utf-8'),
            "iv": base64.b64encode(iv).decode('utf-8'),
            "payload": base64.b64encode(ciphertext_bytes).decode('utf-8')
        }

    @staticmethod
    def decrypt_data(passphrase: str, encrypted_pkg: dict) -> str:
        salt = base64.b64decode(encrypted_pkg["salt"])
        iv = base64.b64decode(encrypted_pkg["iv"])
        ciphertext_bytes = base64.b64decode(encrypted_pkg["payload"])
        key = ProprietaryCryptoEngine._derive_key(passphrase, salt)
        extended_key = (key * ((len(ciphertext_bytes) // len(key)) + 1))[:len(ciphertext_bytes)]
        pt_bytes = bytes(a ^ b ^ c for a, b, c in zip(ciphertext_bytes, extended_key, iv))
        return pt_bytes.decode('utf-8')

class VaultHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self.path = "/public/index.html"
        elif self.path == "/style.css":
            self.path = "/public/style.css"
        return super().do_GET()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        data = json.loads(body.decode('utf-8'))
        action = data.get("action")
        passphrase = data.get("passphrase")
        
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        
        response = {"status": "error", "message": "Invalid action"}
        try:
            if action == "store":
                key_name = data.get("key")
                secret_value = data.get("value")
                store = {}
                if os.path.exists(STORE_PATH):
                    with open(STORE_PATH, "r") as f:
                        store = json.load(f)
                store[key_name] = ProprietaryCryptoEngine.encrypt_data(passphrase, secret_value)
                with open(STORE_PATH, "w") as f:
                    json.dump(store, f, indent=2)
                response = {"status": "success", "message": f"Successfully stored key '{key_name}'."}
            elif action == "retrieve":
                if not os.path.exists(STORE_PATH):
                    response = {"status": "error", "message": "Vault is empty."}
                else:
                    with open(STORE_PATH, "r") as f:
                        store = json.load(f)
                    results = {}
                    for k, enc_pkg in store.items():
                        try:
                            results[k] = ProprietaryCryptoEngine.decrypt_data(passphrase, enc_pkg)
                        except Exception:
                            results[k] = "[DECRYPTION FAILED]"
                    response = {"status": "success", "vault": results}
        except Exception as e:
            response = {"status": "error", "message": str(e)}
        self.wfile.write(json.dumps(response).encode('utf-8'))

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    server = HTTPServer(('127.0.0.1', 8080), VaultHandler)
    print("[+] Secure Vault active at http://127.0.0.1:8080")
    server.serve_forever()
INNER_EOF

echo "[*] Writing Frontend UI..."
cat << 'INNER_EOF' > secure_vault/public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Secure Vault</title>
    <link rel="stylesheet" href="/style.css">
</head>
<body>
    <div class="container">
        <h1>🔒 Secure Vault</h1>
        <div class="card">
            <h2>Master Passphrase</h2>
            <input type="password" id="passphrase" placeholder="Enter key...">
        </div>
        <div class="grid">
            <div class="card">
                <h2>Store Secret</h2>
                <input type="text" id="secretKey" placeholder="Key Name">
                <textarea id="secretValue" placeholder="Secret Value"></textarea>
                <button onclick="storeSecret()">Save</button>
            </div>
            <div class="card">
                <h2>Contents</h2>
                <button onclick="loadVault()">Unlock</button>
                <div id="vaultOutput" class="output-box">Locked.</div>
            </div>
        </div>
    </div>
    <script>
        async function storeSecret() {
            const passphrase = document.getElementById('passphrase').value;
            const key = document.getElementById('secretKey').value;
            const value = document.getElementById('secretValue').value;
            const res = await fetch('/', {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({action: 'store', passphrase, key, value})});
            const data = await res.json();
            alert(data.message);
            if(data.status === 'success') loadVault();
        }
        async function loadVault() {
            const passphrase = document.getElementById('passphrase').value;
            const res = await fetch('/', {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({action: 'retrieve', passphrase})});
            const data = await res.json();
            document.getElementById('vaultOutput').innerHTML = data.status === 'success' ? '<pre>' + JSON.stringify(data.vault, null, 2) + '</pre>' : 'Error: ' + data.message;
        }
    </script>
</body>
</html>
INNER_EOF

cat << 'INNER_EOF' > secure_vault/public/style.css
body { font-family: monospace; background: #0f172a; color: #f8fafc; padding: 20px; }
.container { max-width: 800px; margin: 0 auto; }
.card { background: #1e293b; padding: 15px; margin-bottom: 15px; border-radius: 6px; border: 1px solid #334155; }
input, textarea { width: 100%; padding: 8px; margin-bottom: 10px; background: #0f172a; border: 1px solid #475569; color: #fff; box-sizing: border-box; }
button { background: #0284c7; color: white; border: none; padding: 10px; width: 100%; cursor: pointer; font-weight: bold; }
.output-box { background: #0f172a; padding: 10px; border: 1px solid #334155; color: #34d399; max-height: 150px; overflow-y: auto; }
.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
INNER_EOF

echo "[*] Starting server..."
cd secure_vault
python3 server.py &
echo "[+] Vault is up!"
