"""Content-addressed local result store for Learning Outcomes.

Never uploads data to GitHub. Standard library only; safely indexes historic files,
deduplicates their bytes, and requires two verified independent stores before GC.
Scientific equivalence and publication permission are separate review gates.
"""
from __future__ import annotations
import argparse
import csv
import gzip
import hashlib
import json
import os
from pathlib import Path
import shutil
import sqlite3
import sys
import tempfile
import time

SOURCE_EXT = {".sav", ".zsav", ".sas7bdat", ".dta", ".por", ".xpt", ".dat", ".sas", ".sps"}
CODE_EXT = {".r", ".py", ".sql"}
DATA_EXT = {".csv", ".gz", ".rds", ".parquet", ".sqlite", ".json"}
EXCLUDED_DIRS = {".git", "node_modules", ".Rproj.user", "__pycache__", "microdata"}
PROTECTED_NAMES = {"CURRENT_RESULTS.parquet", "RESULT_HISTORY.parquet",
                   "PROJECT_RESULTS_REGISTRY.sqlite", "FINAL_PRODUCT_BASIS.csv.gz",
                   "RESULTATEN_MASTER.csv.gz"}

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            b = f.read(8 * 1024 * 1024)
            if not b:
                break
            h.update(b)
    return h.hexdigest()

def canonical(path) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(str(path)))).resolve()

def classify(p: Path) -> str:
    name = p.name
    if p.suffix.lower() in SOURCE_EXT:
        return "SOURCE_NO_REDISTRIBUTION"
    if p.suffix.lower() in CODE_EXT:
        return "CODE_PROTECTED"
    if name in PROTECTED_NAMES or "release" in (x.lower() for x in p.parts):
        return "PINNED_CANDIDATE"
    if p.suffix.lower() in DATA_EXT:
        return "INTERMEDIATE_CANDIDATE"
    return "UNCLASSIFIED_PROTECTED"

def independent(a: Path, b: Path) -> bool:
    """Conservative: both stores must be on different filesystems/drives."""
    try:
        if os.name == "nt":
            return a.anchor.lower() != b.anchor.lower()
        return os.stat(a).st_dev != os.stat(b).st_dev
    except OSError:
        return False

def object_path(root: Path, digest: str) -> Path:
    return root / "objects" / digest[:2] / digest

def atomic_verified_copy(src: Path, dst: Path, digest: str) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        if sha256(dst) != digest:
            raise RuntimeError("Content-addressed object has changed: " + str(dst))
        return
    with tempfile.NamedTemporaryFile(dir=dst.parent, prefix=".partial_", delete=False) as f:
        tmp = Path(f.name)
        with src.open("rb") as inp:
            shutil.copyfileobj(inp, f, length=8 * 1024 * 1024)
        f.flush()
        os.fsync(f.fileno())
    try:
        if sha256(tmp) != digest:
            raise RuntimeError("Copied bytes differ from input")
        os.replace(tmp, dst)
        if sha256(dst) != digest:
            raise RuntimeError("Committed bytes failed verification")
    finally:
        tmp.unlink(missing_ok=True)

def load_config(path: Path) -> dict:
    cfg = json.loads(path.read_text(encoding="utf-8"))
    required = ("archive_root", "scan_roots")
    if any(k not in cfg for k in required):
        raise ValueError("Missing archive_root or scan_roots")
    cfg["archive_root"] = canonical(cfg["archive_root"])
    cfg["backup_root"] = canonical(cfg["backup_root"]) if cfg.get("backup_root") else None
    cfg["scan_roots"] = [canonical(p) for p in cfg["scan_roots"]]
    cfg.setdefault("minimum_age_days", 30)
    cfg.setdefault("automatic_cleanup_enabled", False)
    return cfg

def connect(root: Path):
    root.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(str(root / "provenance.sqlite"), timeout=30)
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA foreign_keys=ON")
    db.executescript("""
        CREATE TABLE IF NOT EXISTS artifacts(
          sha256 TEXT PRIMARY KEY, bytes INTEGER NOT NULL, kind TEXT NOT NULL,
          archive_path TEXT NOT NULL, backup_verified_at INTEGER,
          restore_verified_at INTEGER, first_seen_at INTEGER NOT NULL);
        CREATE TABLE IF NOT EXISTS origins(
          path TEXT PRIMARY KEY, sha256 TEXT NOT NULL REFERENCES artifacts(sha256),
          kind TEXT NOT NULL, producer_code_sha256 TEXT, science_status TEXT NOT NULL,
          mtime REAL NOT NULL, deleted_at INTEGER);
        CREATE TABLE IF NOT EXISTS metric_versions(
          metric_key TEXT NOT NULL, artifact_sha256 TEXT NOT NULL REFERENCES artifacts(sha256),
          source_row INTEGER NOT NULL, producer_code_sha256 TEXT,
          science_status TEXT NOT NULL, PRIMARY KEY(metric_key,artifact_sha256,source_row));
        CREATE TABLE IF NOT EXISTS product_pins(
          product TEXT NOT NULL, release_id TEXT NOT NULL,
          artifact_sha256 TEXT NOT NULL REFERENCES artifacts(sha256),
          PRIMARY KEY(product, release_id, artifact_sha256));
        CREATE TABLE IF NOT EXISTS actions(
          at INTEGER NOT NULL, action TEXT NOT NULL, path TEXT, sha256 TEXT,
          outcome TEXT NOT NULL, note TEXT);
        CREATE INDEX IF NOT EXISTS idx_origin_sha ON origins(sha256);
    """)
    return db

def action_log(db, verb, path, digest, outcome, note=""):
    db.execute("INSERT INTO actions VALUES(?,?,?,?,?,?)",
               (int(time.time()), verb, str(path), digest, outcome, note))

def discover(cfg):
    for base in cfg["scan_roots"]:
        if not base.is_dir():
            continue
        for directory, dirs, files in os.walk(base):
            dirs[:] = sorted(d for d in dirs if d not in EXCLUDED_DIRS)
            for name in sorted(files):
                p = Path(directory) / name
                if p.is_file() and not p.is_symlink():
                    yield p.resolve()

def migrate(db, cfg):
    root = cfg["archive_root"]
    scanned = copied = indexed = omitted = 0
    for p in discover(cfg):
        scanned += 1
        kind = classify(p)
        if kind in ("SOURCE_NO_REDISTRIBUTION", "CODE_PROTECTED", "UNCLASSIFIED_PROTECTED"):
            omitted += 1
            continue
        s = p.stat()
        row = db.execute("SELECT sha256,mtime FROM origins WHERE path=? AND deleted_at IS NULL",
                         (str(p),)).fetchone()
        if row and row[1] == s.st_mtime and object_path(root, row[0]).is_file():
            # Validate cached object, not merely the old file modification time.
            if sha256(object_path(root, row[0])) == row[0]:
                indexed += 1
                continue
        digest = sha256(p)
        dst = object_path(root, digest)
        existed = dst.exists()
        atomic_verified_copy(p, dst, digest)
        copied += int(not existed)
        now = int(time.time())
        with db:
            db.execute("""INSERT OR IGNORE INTO artifacts
                (sha256,bytes,kind,archive_path,first_seen_at)
                VALUES(?,?,?,?,?)""", (digest, s.st_size, kind, str(dst), now))
            db.execute("""INSERT INTO origins(path,sha256,kind,producer_code_sha256,
                science_status,mtime,deleted_at) VALUES(?,?,?,?,?,?,NULL)
                ON CONFLICT(path) DO UPDATE SET sha256=excluded.sha256,
                kind=excluded.kind,mtime=excluded.mtime,deleted_at=NULL""",
                (str(p), digest, kind, None, "UNREVIEWED_LEGACY", s.st_mtime))
            action_log(db, "MIGRATE", p, digest, "VERIFIED_OBJECT")
        indexed += 1
    return dict(files_scanned=scanned, origins_indexed=indexed,
                new_unique_objects=copied, excluded_or_protected=omitted)

def index_result_csv(db, input_path: Path):
    p = canonical(input_path)
    row = db.execute("SELECT sha256 FROM origins WHERE path=? AND deleted_at IS NULL",
                     (str(p),)).fetchone()
    if not row:
        raise ValueError("Source not migrated; run migrate first")
    digest = row[0]
    opener = gzip.open if p.name.endswith(".gz") else open
    n = 0
    with opener(p, "rt", encoding="utf-8-sig", errors="replace", newline="") as f, db:
        rows = csv.DictReader(f)
        if "metric_key" not in (rows.fieldnames or []):
            raise ValueError("No metric_key in result file; cannot index individual results")
        for number, item in enumerate(rows, 2):
            k = (item.get("metric_key") or "").strip()
            if not k:
                continue
            # Never infer VALIDATED from a filename or a legacy 'CURRENT' label.
            producer = item.get("producer_code_sha256") or item.get("producer_code_family_sha256")
            status = "REVIEW_REQUIRED"
            db.execute("""INSERT OR IGNORE INTO metric_versions
                (metric_key,artifact_sha256,source_row,producer_code_sha256,science_status)
                VALUES(?,?,?,?,?)""", (k,digest,number,producer,status))
            n += 1
    return {"indexed_metric_rows": n, "scientific_status": "REVIEW_REQUIRED"}

def pin(db, manifest_path: Path):
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if not manifest.get("release_id") or not manifest.get("product"):
        raise ValueError("Pin manifest needs product and release_id")
    hashes = manifest.get("artifact_sha256", [])
    if not hashes:
        raise ValueError("At least one exact artifact SHA256 is required")
    with db:
        for digest in hashes:
            row = db.execute("SELECT 1 FROM artifacts WHERE sha256=?", (digest,)).fetchone()
            if not row:
                raise ValueError("Pin points to unknown artifact " + digest)
            db.execute("INSERT OR IGNORE INTO product_pins VALUES(?,?,?)",
                       (manifest["product"], manifest["release_id"], digest))
    return {"pinned_artifacts": len(hashes)}

def verify_backup(db, cfg):
    a, b = cfg["archive_root"], cfg["backup_root"]
    if b is None or not b.is_dir() or not independent(a, b):
        raise RuntimeError("Independent backup on a different drive/filesystem required")
    passed = 0
    for digest, source in db.execute("SELECT sha256,archive_path FROM artifacts").fetchall():
        src, dst = Path(source), object_path(b, digest)
        if sha256(src) != digest:
            raise RuntimeError("Archive damaged: " + str(src))
        atomic_verified_copy(src, dst, digest)
        # Independently test that the backup can be read and restored.
        with tempfile.TemporaryDirectory() as td:
            recovered = Path(td) / "restored"
            shutil.copyfile(dst, recovered)
            if sha256(recovered) != digest:
                raise RuntimeError("Restore verification failed: " + digest)
        with db:
            now = int(time.time())
            db.execute("""UPDATE artifacts SET backup_verified_at=?,restore_verified_at=?
                WHERE sha256=?""", (now,now,digest))
            action_log(db, "RESTORE_TEST", dst, digest, "PASS")
        passed += 1
    return {"independently_backed_up_and_restored": passed}

def cleanup_plan(db, cfg):
    now = time.time()
    minage = float(cfg["minimum_age_days"]) * 86400
    pins = {r[0] for r in db.execute("SELECT artifact_sha256 FROM product_pins")}
    rows = db.execute("""SELECT o.path,o.sha256,o.kind,o.science_status,o.mtime,
          a.archive_path,a.backup_verified_at,a.restore_verified_at
          FROM origins o JOIN artifacts a USING(sha256) WHERE o.deleted_at IS NULL""").fetchall()
    result = []
    b = cfg["backup_root"]
    independent_backup = b is not None and b.is_dir() and independent(cfg["archive_root"], b)
    for path, digest, kind, science_status, mtime, archive, backed, restored in rows:
        p = Path(path)
        reason = "PROTECTED"
        if p.name in PROTECTED_NAMES or kind != "INTERMEDIATE_CANDIDATE":
            reason = "PROTECTED_CLASS"
        elif digest in pins:
            reason = "PRODUCT_PIN"
        elif now - mtime < minage:
            reason = "RETENTION_WINDOW"
        elif science_status != "UNREVIEWED_LEGACY":
            reason = "REQUIRES_REVIEW"
        elif not independent_backup or not backed or not restored:
            reason = "BACKUP_OR_RESTORE_NOT_VERIFIED"
        elif not p.exists() or sha256(p) != digest:
            reason = "SOURCE_CHANGED_OR_MISSING"
        elif not Path(archive).exists() or sha256(Path(archive)) != digest:
            reason = "ARCHIVE_NOT_VERIFIED"
        elif not object_path(b, digest).exists() or sha256(object_path(b,digest)) != digest:
            reason = "OFFSITE_BACKUP_NOT_VERIFIED"
        else:
            reason = "ELIGIBLE_AFTER_GATES"
        result.append({"path":path,"sha256":digest,"kind":kind,"decision":reason})
    return result

def cleanup(db, cfg, apply=False):
    plan = cleanup_plan(db,cfg)
    if apply and not cfg["automatic_cleanup_enabled"]:
        raise RuntimeError("Cleanup disabled by configuration")
    removed = 0
    if apply:
        for item in plan:
            if item["decision"] != "ELIGIBLE_AFTER_GATES":
                continue
            p = Path(item["path"])
            # Recheck every condition at the moment of deletion.
            current = {x["path"]:x for x in cleanup_plan(db,cfg)}.get(str(p))
            if not current or current["decision"] != "ELIGIBLE_AFTER_GATES":
                raise RuntimeError("Cleanup precondition changed: "+str(p))
            p.unlink()
            with db:
                db.execute("UPDATE origins SET deleted_at=? WHERE path=?",
                           (int(time.time()),str(p)))
                action_log(db,"DELETE",p,item["sha256"],"DELETED_VERIFIED_REDUNDANT")
            removed += 1
    summary={}
    for x in plan:
        summary[x["decision"]]=summary.get(x["decision"],0)+1
    return {"counts":summary,"deleted":removed,"dry_run":not apply}

def status(db):
    return {
        "unique_artifacts":db.execute("SELECT COUNT(*) FROM artifacts").fetchone()[0],
        "active_origin_paths":db.execute("SELECT COUNT(*) FROM origins WHERE deleted_at IS NULL").fetchone()[0],
        "review_required_metric_versions":db.execute("SELECT COUNT(*) FROM metric_versions WHERE science_status='REVIEW_REQUIRED'").fetchone()[0],
        "product_pins":db.execute("SELECT COUNT(*) FROM product_pins").fetchone()[0]
    }

def main(argv=None):
    parser=argparse.ArgumentParser()
    parser.add_argument("action", choices=["inventory","migrate","index-csv","pin",
          "verify-backup","cleanup-plan","cleanup-apply","status"])
    parser.add_argument("--config",required=True)
    parser.add_argument("--input")
    args=parser.parse_args(argv)
    cfg=load_config(canonical(args.config))
    if args.action=="inventory":
        ans={"files_by_class":{}}
        for p in discover(cfg):
            k=classify(p)
            ans["files_by_class"][k]=ans["files_by_class"].get(k,0)+1
    else:
        db=connect(cfg["archive_root"])
        try:
            if args.action=="migrate": ans=migrate(db,cfg)
            elif args.action=="index-csv":
                if not args.input: raise ValueError("--input required")
                ans=index_result_csv(db,Path(args.input))
            elif args.action=="pin":
                if not args.input: raise ValueError("--input required")
                ans=pin(db,Path(args.input))
            elif args.action=="verify-backup": ans=verify_backup(db,cfg)
            elif args.action=="cleanup-plan": ans=cleanup(db,cfg,False)
            elif args.action=="cleanup-apply": ans=cleanup(db,cfg,True)
            else: ans=status(db)
        finally:
            db.close()
    print(json.dumps(ans,sort_keys=True,ensure_ascii=False))
    return 0

if __name__=="__main__":
    sys.exit(main())
