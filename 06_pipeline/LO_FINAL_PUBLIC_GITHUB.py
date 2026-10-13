#!/usr/bin/env python3
"""Rights-gated immutable GitHub staging for a NEW 42-system dashboard.
No raw source, old bulk masters or unaudited current results ever go public.
"""
import argparse, hashlib, json, os, shutil, subprocess
from pathlib import Path

BLOCKED={".sav",".zsav",".dta",".rdata",".rds",".sqlite",".db",
         ".parquet",".sas7bdat",".xls",".xlsx",".zip"}
REQUIRED_CERT={"scientific_status":"PASS","rights_status":"PASS",
 "Q01_Q08":"PASS","dashboard_42":"PASS","slides_21":"PASS",
 "replication":"PASS","static_site_QA":"PASS"}

def reject(msg): raise ValueError("PUBLIC_RELEASE_HOLD: "+msg)
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def stage(repo,preview,certificate,push=False):
    if not preview.is_dir() or not certificate.is_file():
        reject("missing dashboard preview or release certification")
    cert=json.loads(certificate.read_text(encoding="utf-8"))
    for key,value in REQUIRED_CERT.items():
        if cert.get(key)!=value:reject("required certification missing: "+key)
    manifest_file=preview/"BUILD_SHA256_MANIFEST.json"
    if not manifest_file.exists():reject("candidate manifest missing")
    entries=json.loads(manifest_file.read_text(encoding="utf-8"))
    if not entries or len(entries)<50:reject("incomplete dashboard files")
    declared=set()
    for item in entries:
        rel=Path(item["path"])
        if rel.is_absolute() or ".." in rel.parts or rel.as_posix() in declared:
            reject("unsafe duplicate/publication path")
        declared.add(rel.as_posix())
        p=preview/rel
        if not p.is_file() or p.suffix.lower() in BLOCKED:
            reject("missing or forbidden public file "+str(rel))
        if digest(p)!=item["sha256"] or p.stat().st_size!=int(item["bytes"]):
            reject("unverified dashboard file "+str(rel))
    if len(list((preview/"product_data"/"countries").glob("*.json")))!=42:
        reject("dashboard must contain exactly 42 countries")
    meta=json.loads((preview/"product_data"/"metadata.json").read_text())
    if len(meta.get("countries",[]))!=42 or not meta.get("panels"):
        reject("country or fixed-comparator panel contract missing")
    ranks=json.loads((preview/"product_data"/"ranks.json").read_text())
    curated=json.loads((preview/"product_data"/"curated.json").read_text())
    if not ranks or len(curated.get("slides",[]))!=21:
        reject("rank and 21-slide narrative review not complete")
    gate=json.loads((preview/"DASHBOARD_GATE.json").read_text())
    if gate.get("dashboard_systems")!=42:
        reject("preview figure-country scope mismatch")
    if cert.get("candidate_manifest_sha256")!=digest(manifest_file):
        reject("certificate not pinned to exact dashboard candidate")
    release_id=digest(manifest_file)[:20]
    target=repo/"05_publication"/"new_release_candidates"/release_id
    if target.exists():reject("immutable public release candidate already exists")
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copytree(preview,target)
    receipt=dict(release_id=release_id,
      status="STAGED_NOT_PUBLISHED",certificate_sha256=digest(certificate),
      manifest_sha256=digest(manifest_file),
      rights_status="PASS",scientific_status="PASS")
    (target/"PUBLICATION_RECEIPT.json").write_text(
        json.dumps(receipt,indent=2),encoding="utf-8")
    if push:
        if os.environ.get("LO_PUBLIC_GITHUB_FINAL_RELEASE")!="YES":
            reject("explicit GitHub publication confirmation not set")
        branch=subprocess.check_output(["git","-C",str(repo),
            "branch","--show-current"],text=True).strip()
        if branch!="feat/reproducible-storage-and-cleanup-20261010":
            reject("unexpected Git branch for protected publication")
        dirty=subprocess.check_output(["git","-C",str(repo),
            "status","--porcelain"],text=True)
        if any(not line.endswith(str(target.relative_to(repo).as_posix()))
               for line in dirty.splitlines()):
            reject("unreviewed dirty repository files")
        subprocess.check_call(["git","-C",str(repo),"add",
                               str(target.relative_to(repo))])
        subprocess.check_call(["git","-C",str(repo),"commit","-m",
          "Stage validated 42-system scientific dashboard "+release_id])
        subprocess.check_call(["git","-C",str(repo),"push","origin",branch])
    return receipt

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--repo",type=Path,required=True)
    p.add_argument("--candidate",type=Path,required=True)
    p.add_argument("--certificate",type=Path,required=True)
    p.add_argument("--push",action="store_true")
    args=p.parse_args()
    print(json.dumps(stage(args.repo,args.candidate,args.certificate,args.push)))
if __name__=="__main__":main()
