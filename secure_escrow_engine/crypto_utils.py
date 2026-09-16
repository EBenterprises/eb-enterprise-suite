import hashlib
import hmac
import os

def generate_salt():
    return os.urandom(16).hex()

def hash_password(password, salt):
    return hmac.new(salt.encode(), password.encode(), hashlib.sha256).hexdigest()

def verify_hash(password, salt, stored_hash):
    return hmac.compare_digest(hash_password(password, salt), stored_hash)
