import time
import threading
import random

class RaftNode:
    def __init__(self, node_id, peers=None):
        self.node_id = node_id
        self.peers = peers or []
        self.state = "FOLLOWER"  # FOLLOWER, CANDIDATE, LEADER
        self.current_term = 0
        self.voted_for = None
        self.log = []
        self.commit_index = 0
        self.last_applied = 0
        self.lock = threading.Lock()
        
        # Leader state
        self.next_index = {}
        self.match_index = {}
        
        # Election timeout randomization
        self.election_timeout = random.uniform(1.5, 3.0)
        self.last_heartbeat = time.time()

    def handle_request_vote(self, term, candidate_id, last_log_index, last_log_term):
        with self.lock:
            if term > self.current_term:
                self.current_term = term
                self.state = "FOLLOWER"
                self.voted_for = None

            if term == self.current_term and (self.voted_for is None or self.voted_for == candidate_id):
                # Check log up-to-date (simplified)
                self.voted_for = candidate_id
                self.last_heartbeat = time.time()
                return {"term": self.current_term, "vote_granted": True}
            
            return {"term": self.current_term, "vote_granted": False}

    def handle_append_entries(self, term, leader_id, prev_log_index, prev_log_term, entries, leader_commit):
        with self.lock:
            if term < self.current_term:
                return {"term": self.current_term, "success": False}

            self.current_term = term
            self.state = "FOLLOWER"
            self.voted_for = leader_id
            self.last_heartbeat = time.time()

            # Append entries logic placeholder
            return {"term": self.current_term, "success": True}
