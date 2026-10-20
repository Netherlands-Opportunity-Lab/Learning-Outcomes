"""Exercise lossless evidence restoration and reject changed or escaping files."""
import gzip
import hashlib
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("storage", Path(__file__).resolve().parents[1] / "candidate_storage.py")
storage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(storage)


class Storage(unittest.TestCase):
    def fixture(self, root):
        site = root / "site"
        site.mkdir()
        data = b'{"verified":"unchanged scientific proof"}'
        packed = site / "proof.gz"
        packed.write_bytes(gzip.compress(data, mtime=0))
        entry = dict(path="data/balanced_references.json", bytes=len(data),
                     sha256=hashlib.sha256(data).hexdigest())
        (site / "BUILD_SHA256_MANIFEST.json").write_text(json.dumps([entry]))
        (site / storage.INDEX).write_text(json.dumps({"compressed": {
            entry["path"]: {"path": "proof.gz", "sha256": storage.sha(packed)}}}))
        return site, data

    def test_exact_restore_and_tamper(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            site, data = self.fixture(root)
            proof = storage.materialize(site, root / "out")
            self.assertTrue(proof["exact_certified_bytes"])
            self.assertEqual(data, (root / "out/data/balanced_references.json").read_bytes())
            (site / "proof.gz").write_bytes(gzip.compress(b"different"))
            with self.assertRaises(ValueError):
                storage.materialize(site, root / "changed")

    def test_path_and_size_guard(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            site, _ = self.fixture(root)
            with self.assertRaises(ValueError):
                storage.member(site, "../outside")
            entry = json.loads((site / "BUILD_SHA256_MANIFEST.json").read_text())
            entry[0]["bytes"] = 2
            (site / "BUILD_SHA256_MANIFEST.json").write_text(json.dumps(entry))
            with self.assertRaises(ValueError):
                storage.materialize(site, root / "oversized")


if __name__ == "__main__":
    unittest.main()
