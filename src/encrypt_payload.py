#!/usr/bin/env python3
import os
import sys
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.serialization import load_pem_public_key

def encrypt_shipping_data(public_key_path: str, plaintext_message: str) -> bytes:
    """
    Encrypts sensitive string data (e.g., delivery instructions) 
    using a designated public key to ensure end-to-end privacy.
    """
    if not os.path.exists(public_key_path):
        raise FileNotFoundError(f"Public key not found at: {public_key_path}")

    with open(public_key_path, "rb") as key_file:
        public_key = load_pem_public_key(key_file.read())

    encrypted_data = public_key.encrypt(
        plaintext_message.encode('utf-8'),
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None
        )
    )
    return encrypted_data

if __name__ == "__main__":
    sample_payload = "Recipient: Jane Doe, 123 Hidden Lane, Sector 7"
    print(f"[*] Processing payload: {sample_payload}")
    # In production, output is written to file or transmitted securely.
