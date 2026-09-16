import unittest
import os
import shutil
from core.security.vault import SecurityVault
from core.storage.index import IndexManager
from core.consensus.raft import RaftNode

class TestAdvancedEnterpriseComponents(unittest.TestCase):
    def setUp(self):
        self.test_dir = "./test_advanced_data"
        os.makedirs(self.test_dir, exist_ok=True)

    def tearDown(self):
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)

    def test_security_vault(self):
        vault = SecurityVault("enterprise_master_passphrase")
        secret = b"sensitive_escrow_private_key"
        encrypted = vault.encrypt(secret)
        decrypted = vault.decrypt(encrypted)
        self.assertEqual(secret, decrypted)

    def test_index_manager(self):
        idx = IndexManager(self.test_dir)
        idx.update_index("escrows", "esc_12345", {"status": "funded", "amount": 1000})
        result = idx.query_index("escrows", "esc_12345")
        self.assertIsNotNone(result)
        self.assertEqual(result["status"], "funded")

    def test_raft_node_initialization(self):
        node = RaftNode("node_1", ["node_2", "node_3"])
        self.assertEqual(node.state, "FOLLOWER")
        vote_res = node.handle_request_vote(1, "node_2", 0, 0)
        self.assertTrue(vote_res["vote_granted"])

if __name__ == "__main__":
    unittest.main()
