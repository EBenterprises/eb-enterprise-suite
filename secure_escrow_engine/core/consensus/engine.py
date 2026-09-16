import time
import threading

class ConsensusEngine:
    def __init__(self, node_id, quorum=2):
        self.node_id = node_id
        self.quorum = quorum
        self.term = 0
        self.is_leader = False
        self.lock = threading.Lock()
        self.peers = {}

    def register_peer(self, peer_id, endpoint):
        with self.lock:
            self.peers[peer_id] = {"endpoint": endpoint, "last_seen": time.time()}

    def heartbeat(self):
        with self.lock:
            return {"node_id": self.node_id, "term": self.term, "is_leader": self.is_leader}
