"""Bounded, read-only byte verification for existing scientific attachments."""
import argparse
import csv
import hashlib
import json
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


def sha(path):
    with Path(path).open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def verify(path, workers=16):
    table_sha = sha(path)
    with path.open(encoding='utf-8-sig', newline='') as f:
        rows = list(csv.DictReader(f))
    if not rows or any(set(r) != {'path', 'sha256'} for r in rows):
        raise ValueError('Invalid evidence list')
    def check(row):
        try:
            return sha(row['path']) == row['sha256']
        except OSError:
            return False
    with ThreadPoolExecutor(max_workers=max(1, min(16, workers))) as pool:
        good = list(pool.map(check, rows))
    if not all(good) or sha(path) != table_sha:
        raise ValueError('Scientific attachment changed or missing: ' +
                         '; '.join(Path(r['path']).name for r, ok in zip(rows, good) if not ok)[:700])
    return dict(status='EXACT_ATTACHMENT_BYTES_VERIFIED', files=len(rows), table_sha256=table_sha)


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--table', type=Path, required=True)
    a = p.parse_args()
    print(json.dumps(verify(a.table)))
