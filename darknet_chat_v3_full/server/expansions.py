import time
import os
import base64
import hashlib

DEAD_DROP_VAULT = []
CIRCUIT_LOG = []
ZK_VAULT = []
PEER_REGISTRY = [
    {"node_id": "TOR_RELAY_0x9A", "latency": "28ms", "status": "SECURE"},
    {"node_id": "I2P_TUNNEL_0x4F", "latency": "55ms", "status": "ENCRYPTED"},
    {"node_id": "DARK_HOP_0x11", "latency": "15ms", "status": "ACTIVE"},
    {"peer_id": "NODE_ALPHA_0x77", "status": "PEERED", "ping": "12ms"}
]

def handle_dead_drop(body_data):
    recipient = body_data.get('recipient', 'UNKNOWN')
    payload = body_data.get('payload', '')
    passphrase_hash = body_data.get('passphrase_hash', '')
    
    drop_id = base64.b32encode(os.urandom(4)).decode('utf-8').strip('=')
    drop = {
        "drop_id": drop_id,
        "recipient": recipient,
        "payload": base64.b64encode(payload.encode('utf-8')).decode('utf-8'),
        "passphrase_hash": passphrase_hash,
        "retrieved": False,
        "created_at": time.time()
    }
    DEAD_DROP_VAULT.append(drop)
    return {"status": "DEAD_DROP_ARMED", "drop_id": drop_id}

def get_dead_drops():
    return [d for d in DEAD_DROP_VAULT if not d["retrieved"]]

def rotate_circuit():
    nodes = [
        {"node_id": "TOR_EXIT_0x8B", "latency": "31ms", "status": "ROTATED"},
        {"node_id": "I2P_HOP_0x9C", "latency": "64ms", "status": "SECURE"},
        {"node_id": "DARK_RELAY_0x33", "latency": "19ms", "status": "ACTIVE"}
    ]
    CIRCUIT_LOG.append({"timestamp": time.time(), "nodes": nodes})
    return nodes

def cloak_payload(raw_text, mode):
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
