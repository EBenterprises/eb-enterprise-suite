import os
import hashlib
import hmac

class NativeCryptoEngine:
    @staticmethod
    def generate_secure_token(length=32):
        return os.urandom(length).hex()

    @staticmethod
    def derive_key(secret: str, salt: str = None) -> tuple:
        if not salt:
            salt = os.urandom(16).hex()
        dk = hashlib.pbkdf2_hmac('sha256', secret.encode('utf-8'), salt.encode('utf-8'), 250000)
        return salt, dk.hex()

    @staticmethod
    def verify_key(secret: str, salt: str, expected_hash: str) -> bool:
        _, computed = NativeCryptoEngine.derive_key(secret, salt)
        return hmac.compare_digest(computed, expected_hash)
