"""Private Google Drive sync for completed Learning Outcomes R outputs.

Requires rclone OAuth configured by the user. Does not use a ChatGPT credential.
Source tree: LO05_RESULTATEN. Remote destination: private project Drive folder.
No microdata, logs with credentials, private SQLite DB, or local absolute paths
appear in the export manifest. Fails closed on a failed remote checksum check.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone

ALLOWED_TOP_LEVEL = {"runs", "candidate_checkpoints"}
ALLOWED_SUFFIXES = {".csv", ".json", ".txt", ".md", ".gz", ".parquet", ".rds"}
DENY_SUFFIXES = {".sav", ".zsav", ".sas7bdat", ".dta", ".por", ".xpt", ".sas", ".sps",
                 ".db", ".sqlite", ".sqlite3", ".pem", ".key"}
DENY_FRAGMENTS = ("password", "secret", "credential", "access_token", "refresh_token",
                  "oauth", "student_microdata", "source_microdata", "private_key")
PARTIAL_FRAGMENTS = (".partial", ".tmp", ".lock", ".sqlite-wal", ".sqlite-shm")
SHA_PATTERN = re.compile(r"^[0-9a-f]{64}$")

class SyncError(RuntimeError):
    pass

def sha256(p):
    h = hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda:f.read(4*1024*1024),b""):
            h.update(b)
    return h.hexdigest()

def safe_relative(p,root):
    path=p.relative_to(root)
    parts=path.parts
    if len(parts)<2 or parts[0] not in ALLOWED_TOP_LEVEL:
        return None
    if any(x.startswith(".") for x in parts):
        return None
    if any(s in p.name.lower() for s in DENY_FRAGMENTS+PARTIAL_FRAGMENTS):
        return None
    if p.suffix.lower() in DENY_SUFFIXES or p.suffix.lower() not in ALLOWED_SUFFIXES:
        return None
    # A filename is not proof of aggregation, but this additional conservative
    # allowlist prevents arbitrary extracts from being uploaded by default.
    if not re.search(r"(result|summary|status|plan|counts|audit|validation|"
                     r"progress|manifest|report|candidate|metrics|figure|"
                     r"reference|coverage|registry|run_log|connection_test)",
                     p.name,flags=re.IGNORECASE):
        return None
    if not p.is_file() or p.is_symlink():
        return None
    return path.as_posix()

def config_load(filename):
    d=json.loads(Path(filename).read_text(encoding="utf-8"))
    needed=("local_results_root","remote")
    if any(not d.get(v) for v in needed):
        raise SyncError("local_results_root and remote are required")
    d["local_results_root"]=Path(os.path.expanduser(os.path.expandvars(d["local_results_root"]))).resolve()
    if not d["local_results_root"].is_dir():
        raise SyncError("Local results root not found")
    remote=d["remote"]
    if not re.match(r"^[a-zA-Z0-9_-]+:[^:]+$",remote):
        raise SyncError("Invalid rclone remote path; must be a private remote:folder")
    if any(x in remote for x in ("\n","\r","..","\\")):
        raise SyncError("Unsafe remote path")
    if d.get("data_visibility")!="PRIVATE_ACCOUNT_ONLY":
        raise SyncError("Refuse publication without explicit private-account-only setting")
    d.setdefault("rclone_binary","rclone")
    d.setdefault("min_age_seconds",30)
    d.setdefault("max_file_bytes",2*1024*1024*1024)
    d.setdefault("max_transfers",4)
    d.setdefault("watch_interval_seconds",180)
    return d

def eligible(root, min_age_seconds, max_file_bytes, now=None):
    now=time.time() if now is None else now
    found=[]
    for top in sorted(ALLOWED_TOP_LEVEL):
        parent=root/top
        if not parent.is_dir():
            continue
        for p in sorted(parent.rglob("*")):
            if not p.is_file():
                continue
            rel=safe_relative(p,root)
            if rel is None:
                continue
            st=p.stat()
            if st.st_size>max_file_bytes or now-st.st_mtime<min_age_seconds:
                continue
            found.append((p,rel,st.st_size,st.st_mtime))
    return found

def run(command):
    process=subprocess.run(command,capture_output=True,text=True,check=False,timeout=3600)
    if process.returncode:
        tail="\n".join((process.stderr or process.stdout).splitlines()[-12:])
        raise SyncError(f"rclone operation failed (exit {process.returncode}): {tail}")
    return process.stdout

def git_commit():
    v=os.environ.get("LO_PRODUCER_GIT_COMMIT","")
    return v if v else "NOT_SET"

def manifest_for(items,root):
    out=[]
    for p,rel,size,mtime in items:
        st1=p.stat()
        digest=sha256(p)
        st2=p.stat()
        if st1.st_size!=st2.st_size or st1.st_mtime_ns!=st2.st_mtime_ns:
            raise SyncError(f"File changed while hashing: {rel}")
        cloud_name=digest[:2]+"/"+digest+p.suffix.lower()
        out.append({"path":rel,"cloud_object":cloud_name,"sha256":digest,"bytes":size,
                    "scientific_status":"NOT_AUTOMATICALLY_VALIDATED",
                    "producer_git_commit":git_commit()})
    return {"schema_version":"learning-outcomes-private-sync-v1",
            "created_utc":datetime.now(timezone.utc).isoformat(),
            "source":"LO05_RESULTATEN/allowlisted_completed_artifacts",
            "visibility":"PRIVATE_ACCOUNT_ONLY",
            "scientific_status":"NOT_AUTOMATICALLY_VALIDATED",
            "files":out}

def stage_immutable_objects(files,items,root):
    """Snapshot only complete files to immutable, content-addressed cloud objects."""
    out=[]
    for item,(source,rel,size,mtime) in zip(files,items):
        digest=item["sha256"]
        obj=root/".cloud_sync"/"objects"/item["cloud_object"]
        obj.parent.mkdir(parents=True,exist_ok=True)
        if obj.is_file():
            if sha256(obj)!=digest:
                raise SyncError("Previously staged object changed: "+str(obj))
        else:
            with tempfile.NamedTemporaryFile(dir=obj.parent,prefix=".snap_",delete=False) as f:
                temp=Path(f.name)
                with source.open("rb") as inp:
                    shutil.copyfileobj(inp,f,length=4*1024*1024)
                f.flush();os.fsync(f.fileno())
            try:
                if sha256(temp)!=digest:
                    raise SyncError("Source changed during immutable snapshot: "+rel)
                os.replace(temp,obj)
            finally:
                temp.unlink(missing_ok=True)
        out.append(item["cloud_object"])
    return out

def write_manifest(data,where):
    where.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.NamedTemporaryFile("w",encoding="utf-8",dir=where.parent,
                                     prefix=".sync_",delete=False) as f:
        temp=Path(f.name)
        json.dump(data,f,sort_keys=True,ensure_ascii=False,indent=2)
        f.write("\n");f.flush();os.fsync(f.fileno())
    os.replace(temp,where)

def publish(cfg, dry_run=False):
    root=cfg["local_results_root"]
    age=float(cfg["min_age_seconds"])
    items=eligible(root,age,int(cfg["max_file_bytes"]))
    data=manifest_for(items,root)
    manifest_root=root/".cloud_sync"
    latest=manifest_root/"LATEST.json"
    if not dry_run:
        write_manifest(data,latest)
    summary={"files_selected":len(items),"bytes_selected":sum(x[2] for x in items),
             "manifest_sha256":(sha256(latest) if not dry_run else
                  hashlib.sha256(json.dumps(data,sort_keys=True).encode("utf-8")).hexdigest()),
             "scientific_status":"NOT_AUTOMATICALLY_VALIDATED",
             "dry_run":bool(dry_run)}
    if dry_run:
        return summary
    if not items:
        return summary
    stage_immutable_objects(data["files"],items,root)
    binary=cfg["rclone_binary"]
    remote=cfg["remote"].rstrip("/")
    with tempfile.NamedTemporaryFile(mode="w",encoding="utf-8",prefix="lo-files-",
                                     suffix=".txt",delete=False) as f:
        paths=Path(f.name)
        for item in data["files"]:
            f.write(item["cloud_object"]+"\n")
    try:
        root_arg=str(manifest_root/"objects")
        files_arg=str(paths)
        cloud=remote+"/objects"
        options=["--files-from",files_arg]
        transfers=["--transfers",str(int(cfg["max_transfers"])),"--checkers","8"]
        # copy, not sync: never delete remote history because local files were pruned.
        run([binary,"copy",root_arg,cloud,"--checksum"]+options+transfers)
        # Mandatory remote checksum check on every candidate selected this pass.
        run([binary,"check",root_arg,cloud,"--checksum","--one-way"]+options)
        manifest_id=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")+"_"+sha256(latest)[:16]
        remote_manifest=remote+"/manifests/"+manifest_id+".json"
        run([binary,"copyto",str(latest),remote_manifest])
        # Google Drive native files have an MD5 checksum (not SHA-256).
        local_md5=hashlib.md5(latest.read_bytes()).hexdigest()
        returned=run([binary,"md5sum",remote_manifest]).strip().split()
        if not returned or returned[0].lower()!=local_md5:
            raise SyncError("Remote manifest MD5 verification failed")
        summary.update({"verified_remote_manifest":remote_manifest,
                        "checksum_check":"PASS","manifest_id":manifest_id})
        write_manifest({"latest_verified_manifest":manifest_id,
                        "remote_manifest_md5":local_md5,
                        "verified_file_count":len(items),
                        "created_utc":data["created_utc"]},manifest_root/"SYNC_STATUS.json")
        # LATEST pointer is written ONLY after the complete remote check passes.
        pointer=manifest_root/"REMOTE_LATEST.json"
        write_manifest({"manifest":manifest_id+".json",
                        "sha256":sha256(latest),
                        "created_utc":data["created_utc"]},pointer)
        run([binary,"copyto",str(pointer),remote+"/LATEST.json"])
        return summary
    finally:
        paths.unlink(missing_ok=True)

def main():
    p=argparse.ArgumentParser()
    p.add_argument("action",choices=["publish","watch","preview"])
    p.add_argument("--config",required=True)
    args=p.parse_args()
    cfg=config_load(args.config)
    if args.action=="watch":
        while True:
            try:
                print(json.dumps(publish(cfg),sort_keys=True),flush=True)
            except Exception as e:
                print("Drive sync HOLD: "+str(e),file=sys.stderr,flush=True)
            time.sleep(max(60,int(cfg["watch_interval_seconds"])))
    else:
        print(json.dumps(publish(cfg,dry_run=args.action=="preview"),sort_keys=True))

if __name__=="__main__":
    main()
