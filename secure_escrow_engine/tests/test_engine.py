import unittest
import os
import shutil
from core.storage.engine import StorageEngine
from core.security.crypto import CryptoEngine

class TestSecureEscrowEngine(unittest.TestCase):
    def setUp(self):
        self.test_dir = "./test_data"
        self.storage = StorageEngine(self.test_dir)

    def tearDown(self):
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)

    def test_wal_append_and_read(self):
        tx_hash = self.storage.write_wal("TEST_OP", {"key": "value"})
        self.assertTrue(len(tx_hash) > 0)
        records = self.storage.read_wal()
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]["op"], "TEST_OP")

    def test_crypto_token(self):
        token1 = CryptoEngine.generate_token()
        token2 = CryptoEngine.generate_token()
        self.assertNotEqual(token1, token2)

if __name__ == "__main__":
    unittest.main()
