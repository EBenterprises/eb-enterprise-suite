import os
import json
import fcntl
import hashlib
import time

class StorageEngine:
    def __init__(self, data_dir="./data"):
        self.data_dir = data_dir
        os.makedirs(self.data_dir, exist_ok=True)
        self.wal_path = os.path.join(self.data_dir, "wal.log")
        self.state_path = os.path.join(self.data_dir, "state.json")
        self._init_storage()

    def _init_storage(self):
        if not os.path.exists(self.wal_path):
            open(self.wal_path, "a").close()
        if not os.path.exists(self.state_path):
            with open(self.state_path, "w") as f:
                json.dump({}, f)

    def write_wal(self, op_type, payload):
        entry = {
            "timestamp": time.time(),
            "op": op_type,
            "payload": payload,
            "hash": ""
        }
        raw = json.dumps(entry, sort_keys=True)
        entry["hash"] = hashlib.sha256(raw.encode()).hexdigest()
        
        line = json.dumps(entry) + "\n"
        with open(self.wal_path, "a") as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_EX)
            f.write(line)
            f.flush()
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)
        return entry["hash"]

    def read_wal(self):
        records = []
        if not os.path.exists(self.wal_path):
            return records
        with open(self.wal_path, "r") as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_SH)
            for line in f:
                if line.strip():
                    records.append(json.loads(line.strip()))
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)
        return records
