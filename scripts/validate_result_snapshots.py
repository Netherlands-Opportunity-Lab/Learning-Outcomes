"""Verify committed national aggregate snapshots and historical code copies."""
from pathlib import Path
import csv
import hashlib
import json
import math
import re

ROOT = Path(__file__).resolve().parents[1]

def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))

snapshots = sorted((ROOT / "04_results/review").glob("*/manifest.json"))
for path in snapshots:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    for entry in manifest["files"]:
        target = (path.parent / entry["file"]).resolve()
        assert target.parent == path.parent.resolve(), "Manifest path escapes snapshot"
        data = target.read_bytes()
        assert len(data) == entry["bytes"], f"Byte mismatch: {target.name}"
        assert hashlib.sha256(data).hexdigest() == entry["sha256"], f"Hash mismatch: {target.name}"
    results = rows(path.parent / "results.csv")
    statuses = rows(path.parent / "target_status.csv")
    assert len(results) == manifest["validated_rows"]
    assert len(statuses) == manifest["target_rows"]
    certified = {row["cell_id"] for row in statuses if row["status"] == "SCIENTIFICALLY_VALIDATED"}
    assert len(certified) == len(results) == len({r["cell_id"] for r in results})
    assert {r["cell_id"] for r in results} == certified
    for row in results:
        assert math.isfinite(float(row["estimate"]))
        assert math.isfinite(float(row["standard_error"])) and float(row["standard_error"]) >= 0
        assert float(row["n_unweighted"]) > 0
        for key in ("input_fingerprint", "producer_fingerprint", "source_edition_sha256", "certification_sha256"):
            assert re.fullmatch(r"[0-9a-f]{64}", row[key]), f"Missing fingerprint: {key}"

archive = ROOT / "06_pipeline/archive_or_superseded/LO05_CODE_LOCK_20261010"
code_manifest = archive / "SOURCE_CODE_ORIGINAL_VS_PUBLIC_SHA256.csv"
if code_manifest.exists():
    for row in rows(code_manifest):
        target = (archive / row["relative_path"]).resolve()
        assert target.is_relative_to(archive.resolve()), "Code path escapes archive"
        assert hashlib.sha256(target.read_bytes()).hexdigest() == row["git_copy_sha256"], target.name
print(f"PASS {len(snapshots)} certified result snapshot(s), exact bytes and archived producer code")
