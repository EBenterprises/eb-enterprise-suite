import os
import hashlib
import hmac

class PGTVault:
    @staticmethod
    def generate_nonce():
        return os.urandom(32).hex()

    @staticmethod
    def hash_secret(secret, salt=None):
        if not salt:
            salt = os.urandom(16).hex()
        dk = hashlib.pbkdf2_hmac('sha256', secret.encode('utf-8'), salt.encode('utf-8'), 100000)
        return salt, dk.hex()

    @staticmethod
    def verify_secret(secret, salt, expected_hash):
        _, new_hash = PGTVault.hash_secret(secret, salt)
        return hmac.compare_digest(new_hash, expected_hash)
