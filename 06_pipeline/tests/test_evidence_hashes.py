import csv
import importlib.util
from pathlib import Path
import tempfile
import unittest

p = Path(__file__).resolve().parents[1] / 'LO_EVIDENCE_HASHES.py'
spec = importlib.util.spec_from_file_location('evidence_hashes', p)
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)


class EvidenceHashes(unittest.TestCase):
    def test_parallel_fresh_bytes_and_same_count_are_not_interchangeable(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); entries = []
            for n in range(130):
                f = root / f'proof_{n}.txt'; f.write_bytes(str(n).encode())
                entries.append(dict(path=str(f), sha256=m.sha(f)))
            table = root / 'files.csv'
            with table.open('w', encoding='utf-8', newline='') as f:
                w = csv.DictWriter(f, ['path', 'sha256']); w.writeheader(); w.writerows(entries)
            first = m.verify(table)
            self.assertEqual(first, m.verify(table))
            (root / 'proof_18.txt').write_bytes(b'19')
            with self.assertRaisesRegex(ValueError, 'changed'):
                m.verify(table)
            (root / 'proof_18.txt').write_bytes(b'18')
            (root / 'proof_19.txt').unlink()
            with self.assertRaisesRegex(ValueError, 'missing'):
                m.verify(table)


if __name__ == '__main__': unittest.main()
