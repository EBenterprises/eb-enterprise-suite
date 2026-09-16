import json
import time
from core.storage.engine import StorageEngine
from core.security.crypto import CryptoEngine
from core.network.protocol import ProtocolEngine

class Router:
    def __init__(self, storage: StorageEngine):
        self.storage = storage

    def route(self, path: str, method: str, payload: dict) -> tuple:
        if path == "/health" and method == "GET":
            return 200, {"status": "operational", "time": time.time()}
        
        elif path == "/escrow/create" and method == "POST":
            escrow_id = CryptoEngine.generate_token(16)
            record = {
                "escrow_id": escrow_id,
                "buyer": payload.get("buyer"),
                "seller": payload.get("seller"),
                "amount": payload.get("amount"),
                "status": "initialized"
            }
            tx_hash = self.storage.write_wal("CREATE_ESCROW", record)
            return 201, {"escrow_id": escrow_id, "tx_hash": tx_hash}

        elif path == "/escrow/state" and method == "GET":
            records = self.storage.read_wal()
            return 200, {"records": records}

        return 404, {"error": "Endpoint not found"}
