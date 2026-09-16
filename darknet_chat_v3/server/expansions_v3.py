import time
import os
import base64
import hashlib

ZK_VAULT = []
PEER_REGISTRY = [
    {"peer_id": "NODE_ALPHA_0x77", "status": "PEERED", "ping": "12ms"},
    {"peer_id": "NODE_OMEGA_0x88", "status": "LISTENING", "ping": "34ms"}
]

def cloak_payload(raw_text, mode):
    """Wraps payloads in steganographic or camouflage wrappers."""
    encoded = base64.b64encode(raw_text.encode('utf-8')).decode('utf-8')
    if mode == "IMAGE_HEADER":
        return f"data:image/png;base64,iVBORw0KGgoAAAANSUhEUg==#payload:{encoded}"
    elif mode == "METADATA_EXIF":
        return f"EXIF:AUTHOR=ANON;COMMENT={encoded}"
    return encoded

def register_zk_drop(data):
    recipient = data.get('recipient', 'BROADCAST')
    ciphertext = data.get('ciphertext', '')
    passphrase = data.get('passphrase', '')
    
    pass_hash = hashlib.sha256(passphrase.encode('utf-8')).hexdigest() if passphrase else ""
    drop_id = base64.b32encode(os.urandom(4)).decode('utf-8').strip('=')
    
    drop = {
        "drop_id": drop_id,
        "recipient": recipient,
        "ciphertext": ciphertext,
        "pass_hash": pass_hash,
        "locked": bool(pass_hash),
        "timestamp": time.time()
    }
    ZK_VAULT.append(drop)
    return {"status": "ZK_VAULT_ARMED", "drop_id": drop_id}

def unlock_zk_drop(drop_id, passphrase):
    for drop in ZK_VAULT:
        if drop["drop_id"] == drop_id:
            if drop["locked"]:
                p_hash = hashlib.sha256(passphrase.encode('utf-8')).hexdigest()
                if p_hash == drop["pass_hash"]:
                    return {"status": "UNLOCKED", "ciphertext": drop["ciphertext"]}
                else:
                    return {"status": "ERROR", "message": "INVALID_PASSPHRASE"}
            return {"status": "UNLOCKED", "ciphertext": drop["ciphertext"]}
    return {"status": "ERROR", "message": "DROP_NOT_FOUND"}
