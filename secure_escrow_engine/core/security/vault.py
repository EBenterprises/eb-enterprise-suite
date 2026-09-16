import os
import hashlib
from cryptography.hazmat.primitives.ciphers.gcm import AESGCM

class SecurityVault:
    def __init__(self, master_secret: str = None):
        # Derive a 256-bit key from master secret or generate secure random
        if master_secret:
            self.key = hashlib.sha256(master_secret.encode()).digest()
        else:
            self.key = AESGCM.generate_key(bit_length=256)
        self.aesgcm = AESGCM(self.key)

    def encrypt(self, plaintext: bytes, associated_data: bytes = b"secure_escrow") -> dict:
        nonce = os.urandom(12)
        ciphertext = self.aesgcm.encrypt(nonce, plaintext, associated_data)
        return {
            "nonce": nonce.hex(),
            "ciphertext": ciphertext.hex()
        }

    def decrypt(self, encrypted_data: dict, associated_data: bytes = b"secure_escrow") -> bytes:
        nonce = bytes.fromhex(encrypted_data["nonce"])
        ciphertext = bytes.fromhex(encrypted_data["ciphertext"])
        return self.aesgcm.decrypt(nonce, ciphertext, associated_data)
