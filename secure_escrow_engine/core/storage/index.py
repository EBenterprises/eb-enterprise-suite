import os
import json
import fcntl

class IndexManager:
    def __init__(self, data_dir="./data"):
        self.index_path = os.path.join(data_dir, "indexes.json")
        os.makedirs(data_dir, exist_ok=True)
        self._init_index()

    def _init_index(self):
        if not os.path.exists(self.index_path):
            with open(self.index_path, "w") as f:
                json.dump({"escrows": {}, "wallets": {}}, f)

    def update_index(self, key_type, primary_key, metadata):
        with open(self.index_path, "r+") as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_EX)
            data = json.load(f)
            if key_type not in data:
                data[key_type] = {}
            data[key_type][primary_key] = metadata
            f.seek(0)
            json.dump(data, f, indent=2)
            f.truncate()
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)

    def query_index(self, key_type, primary_key):
        with open(self.index_path, "r") as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_SH)
            data = json.load(f)
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)
            return data.get(key_type, {}).get(primary_key)
