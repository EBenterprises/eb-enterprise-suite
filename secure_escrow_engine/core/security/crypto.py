import os
import hashlib
import hmac
import base64

class CryptoEngine:
    @staticmethod
    def generate_token(length=32):
        return base64.urlsafe_b64encode(os.urandom(length)).decode('utf-8').rstrip('=')

    @staticmethod
    def hash_payload(data: str) -> str:
        return hashlib.sha256(data.encode('utf-8')).hexdigest()

    @staticmethod
    def verify_hmac(secret: bytes, message: bytes, signature: str) -> bool:
        computed = hmac.new(secret, message, hashlib.sha256).hexdigest()
        return hmac.compare_digest(computed, signature)
