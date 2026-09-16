import os
import json
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

class SecureVault:
    def __init__(self, key: bytes = None):
        self.key = key or AESGCM.generate_key(bit_length=256)
        self.aesgcm = AESGCM(self.key)

    def encrypt_payload(self, data: dict) -> dict:
        nonce = os.urandom(12)
        plaintext = json.dumps(data).encode('utf-8')
        ciphertext = self.aesgcm.encrypt(nonce, plaintext, None)
        return {
            "nonce": nonce.hex(),
            "ciphertext": ciphertext.hex()
        }

    def decrypt_payload(self, encrypted_data: dict) -> dict:
        nonce = bytes.fromhex(encrypted_data["nonce"])
        ciphertext = bytes.fromhex(encrypted_data["ciphertext"])
        plaintext = self.aesgcm.decrypt(nonce, ciphertext, None)
        return json.loads(plaintext.decode('utf-8'))

if __name__ == "__main__":
    vault = SecureVault()
    sample = {"destination": "encrypted_endpoint", "payload": "confidential_data"}
    encrypted = vault.encrypt_payload(sample)
    print("Encrypted:", encrypted)
    decrypted = vault.decrypt_payload(encrypted)
    print("Decrypted:", decrypted)
