#!/usr/bin/env python3
"""Restore the exact tested private dashboard snapshot from two Git-safe parts."""
from pathlib import Path
import hashlib,zipfile,io
ROOT=Path(__file__).resolve().parent
expected='72eb4d337019274cc3a1faf29972c81170541e21f75cd8026f2c1f059ad8482b'
raw=b''.join((ROOT/f'PISA_PIRLS_DASHBOARD_STEP4_PRIVATE.zip.part{i:02}').read_bytes() for i in [1,2])
actual=hashlib.sha256(raw).hexdigest()
if actual!=expected:raise SystemExit(f'Archive checksum mismatch: {actual}')
with zipfile.ZipFile(io.BytesIO(raw)) as z:
 bad=z.testzip()
 if bad:raise SystemExit(f'Invalid member: {bad}')
 for name in z.namelist():
  p=Path(name)
  if p.is_absolute() or '..' in p.parts:raise SystemExit('Unsafe archive path')
 z.extractall(ROOT)
print('Restored PISA_PIRLS_DASHBOARD_STEP4_PRIVATE; 404 manifest-listed files. No public deployment.')
print('Run: python -m http.server 8000 --directory PISA_PIRLS_DASHBOARD_STEP4_PRIVATE')
