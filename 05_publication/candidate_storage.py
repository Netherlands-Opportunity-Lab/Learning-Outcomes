"""Lossless Git storage for large, already-certified publication evidence.

Browser payloads are unchanged. Only large non-runtime evidence is compressed
in Git; the Pages build restores the exact certified bytes before verification.
"""
import gzip
import hashlib
import json
import shutil
from pathlib import Path

INDEX = "CANDIDATE_STORAGE.json"


def sha(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def member(root, name):
    p = Path(name)
    if p.is_absolute() or ".." in p.parts or ":" in name or "\\" in name:
        raise ValueError("Unsafe candidate storage member")
    target = root / p
    if target.is_symlink() or not target.resolve().is_relative_to(root.resolve()):
        raise ValueError("Candidate storage member escapes its root")
    return target


def materialize(site, output):
    """Restore only manifested files to a new directory and check every byte."""
    if output.exists():
        raise ValueError("Candidate materialization needs a new directory")
    entries = json.loads((site / "BUILD_SHA256_MANIFEST.json").read_text(encoding="utf-8"))
    storage_path = site / INDEX
    storage = json.loads(storage_path.read_text(encoding="utf-8")) if storage_path.exists() else {}
    compressed = storage.get("compressed", {})
    if set(compressed) - {e["path"] for e in entries}:
        raise ValueError("Unmanifested compressed member")
    output.mkdir(parents=True)
    seen = set()
    for entry in entries:
        name = entry["path"]
        if name in seen or not isinstance(entry["bytes"], int) or entry["bytes"] < 0:
            raise ValueError("Duplicate or invalid manifest member")
        seen.add(name)
        dest = member(output, name)
        source = member(site, name)
        dest.parent.mkdir(parents=True, exist_ok=True)
        if name in compressed:
            meta = compressed[name]
            if source.exists():
                raise ValueError("Ambiguous compressed/uncompressed candidate member")
            packed = member(site, meta["path"])
            if sha(packed) != meta["sha256"]:
                raise ValueError("Compressed candidate bytes changed")
            count = 0
            with gzip.open(packed, "rb") as src, dest.open("wb") as dst:
                while block := src.read(1024 * 1024):
                    count += len(block)
                    if count > entry["bytes"]:
                        raise ValueError("Expanded candidate exceeds certified size")
                    dst.write(block)
        else:
            shutil.copyfile(source, dest)
        if dest.stat().st_size != entry["bytes"] or sha(dest) != entry["sha256"]:
            raise ValueError("Restored candidate differs from certification: " + name)
    shutil.copyfile(site / "BUILD_SHA256_MANIFEST.json", output / "BUILD_SHA256_MANIFEST.json")
    return dict(restored_files=len(entries), compressed_files=len(compressed),
                exact_certified_bytes=True)


def store(site, destination):
    """Store an already-verified site without changing its original manifest."""
    if destination.exists():
        raise ValueError("Immutable stored candidate already exists")
    destination.mkdir(parents=True)
    entries = json.loads((site / "BUILD_SHA256_MANIFEST.json").read_text(encoding="utf-8"))
    compressed = {}
    for entry in entries:
        source = member(site, entry["path"])
        if sha(source) != entry["sha256"] or source.stat().st_size != entry["bytes"]:
            raise ValueError("Changed source candidate")
        # Only the large proof is compressed; browser JSON stays directly usable.
        if entry["path"] == "data/balanced_references.json" and entry["bytes"] > 20_000_000:
            name = "_compressed/balanced_references.json.gz"
            dest = member(destination, name)
            dest.parent.mkdir(parents=True, exist_ok=True)
            with source.open("rb") as src, dest.open("wb") as dst:
                with gzip.GzipFile(filename="", fileobj=dst, mode="wb", mtime=0, compresslevel=6) as packed:
                    shutil.copyfileobj(src, packed, 1024*1024)
            compressed[entry["path"]] = dict(path=name, sha256=sha(dest))
        else:
            dest = member(destination, entry["path"])
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, dest)
    shutil.copyfile(site / "BUILD_SHA256_MANIFEST.json", destination / "BUILD_SHA256_MANIFEST.json")
    (destination / INDEX).write_text(json.dumps(dict(schema_version=1, compressed=compressed),
                                              indent=2) + "\n", encoding="utf-8")
    return dict(status="EXACT_CANDIDATE_STORED_LOSSLESSLY", compressed_files=len(compressed),
                candidate_manifest_sha256=sha(destination / "BUILD_SHA256_MANIFEST.json"))
