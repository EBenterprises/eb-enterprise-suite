import os
from flask import Flask, render_template, request, jsonify
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.hazmat.primitives import hashes

# Resolve template folder relative to this file's location
basedir = os.path.abspath(os.path.dirname(__file__))
app = Flask(__name__, template_folder=os.path.join(basedir, 'templates'))

PRIVATE_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
PUBLIC_KEY = PRIVATE_KEY.public_key()

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/encrypt", methods=["POST"])
def encrypt_payload():
    data = request.get_json() or {}
    payload = data.get("payload", "")
    
    if not payload:
        return jsonify({"error": "Payload cannot be empty"}), 400

    encrypted = PUBLIC_KEY.encrypt(
        payload.encode('utf-8'),
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None
        )
    )
    return jsonify({"status": "success", "encrypted_hex": encrypted.hex()})

@app.route("/api/decrypt", methods=["POST"])
def decrypt_payload():
    data = request.get_json() or {}
    hex_payload = data.get("encrypted_hex", "")
    
    try:
        encrypted_bytes = bytes.fromhex(hex_payload)
        decrypted = PRIVATE_KEY.decrypt(
            encrypted_bytes,
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )
        return jsonify({"status": "success", "decrypted_payload": decrypted.decode('utf-8')})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
