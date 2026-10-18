"""Deterministic public replication ZIP and explicit interim metadata.

Run after the scientific export and static builder, before independent release QA.
The caller supplies already-reviewed product-only inputs, never the private master.
This creates no scientific approval and does not deploy anything.
"""
from __future__ import annotations
import argparse, hashlib, json, re, zipfile
from pathlib import Path

PACKAGE = "replication/learning-outcomes-replication.zip"

def sha(path):
    with path.open("rb") as f:return hashlib.file_digest(f,"sha256").hexdigest()

def put_json(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2,sort_keys=True)+"\n",encoding="utf-8")

def write_manifest(site):
    target=site/"BUILD_SHA256_MANIFEST.json"
    entries=[dict(path=p.relative_to(site).as_posix(),bytes=p.stat().st_size,sha256=sha(p))
             for p in sorted(site.rglob("*")) if p.is_file() and p!=target]
    put_json(target,entries)
    return entries

def make_package(repo,site,inputs,provenance,source_commit):
    if not re.fullmatch("[a-f0-9]{40}",source_commit):raise ValueError("Exact source commit required")
    if (site/PACKAGE).exists():raise ValueError("Immutable package already exists")
    code={}
    def add(path,name=None):
        if not path.is_file():raise ValueError("Missing required package source: "+path.name)
        code[name or path.relative_to(repo).as_posix()]=path.read_bytes()
    for name in ("START.R","renv.lock","LICENSE","DATA_LICENSE.md","CITATION.cff"):
        add(repo/name)
    for pattern in ("*.R","*.py"):
        for path in sorted((repo/"06_pipeline").glob(pattern)):add(path)
    for name in ("REPLICATION_CURRENT.md","RUN_CONFIG.example.json","SCOPE_APPROVALS.csv",
                 "MASTER_GRID_DESIGN_20261013.md"):
        add(repo/"06_pipeline"/name)
    # Static policy/source controls only. No private run inventories or result masters.
    for name in ("international/SOURCE_CATALOG.csv","international/HOME_SOURCE_CATALOG.csv",
                 "RANK_PRODUCT_CONTRACT.json","PAPER_QA_CURRENT.json"):
        add(repo/"06_pipeline/review_20261013"/name)
    archive=repo/"06_pipeline/archive_or_superseded/LO05_CODE_LOCK_20261010"
    for path in sorted(archive.rglob("*")):
        if path.is_file() and path.suffix.lower() in (".r",".md",".csv"):add(path)
    for path in sorted((repo/"05_publication/preview_overlay").rglob("*")):
        if path.is_file():add(path)
    add(repo/"05_publication/reproduce_dashboard.py","reproduce_dashboard.py")
    add(repo/"05_publication/REPLICATION_PACKAGE_README.md","README.md")
    for name in ("dashboard_cells.csv","COUNTRY_SOURCE_ELIGIBILITY.csv","SCOPE_APPROVALS.csv",
                 "FIGURE_SERIES_CONTRACT_20261002.csv"):
        add(inputs/name,"release_inputs/"+name)
    balance=site/'data/balanced_references.json'
    if balance.is_file():add(balance,'release_inputs/BALANCED_REFERENCE_EXPORT.json')
    base=json.loads((site/"BUILD_SHA256_MANIFEST.json").read_text(encoding="utf-8"))
    code["release_inputs/DASHBOARD_REBUILD_MANIFEST.json"]=json.dumps(base,sort_keys=True).encode()
    code["release_inputs/PROVENANCE.json"]=(json.dumps(provenance,sort_keys=True,indent=2)+"\n").encode()
    # Fail on accidentally included user paths; credentials are never inputs.
    private=re.compile(rb"(?:[A-Za-z]:[/\\]+Users[/\\]+(?!<|example|USER|YOUR)[A-Za-z0-9_.-]+|/Users/[A-Za-z0-9_.-]+|-----BEGIN (?:RSA |OPENSSH )?PRIVATE KEY-----)")
    for name,content in code.items():
        if Path(name).suffix.lower() in (".r",".py",".json",".csv",".md",".html",".js",".mjs") and private.search(content):
            raise ValueError("Personal path/private material in public package: "+name)
    manifest=dict(schema_version=1,source_commit=source_commit,
                  pupil_data_included=False,full_scientific_replication_certified=False,
                  files={name:hashlib.sha256(content).hexdigest() for name,content in sorted(code.items())})
    code["PACKAGE_MANIFEST.json"]=(json.dumps(manifest,sort_keys=True,indent=2)+"\n").encode()
    target=site/PACKAGE;target.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(target,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for name,content in sorted(code.items()):
            info=zipfile.ZipInfo(name,date_time=(1980,1,1,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED
            info.external_attr=0o100644<<16;info.create_system=3
            z.writestr(info,content,compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
    put_json(site/"data/snapshot_provenance.json",provenance)
    qa=json.loads((site/"GUIDED_QA.json").read_text(encoding="utf-8"))
    qa["review_release"]=dict(kind="PARTIAL_VERIFIED_RESULTS",date=provenance["snapshot_utc"][:10],
         snapshot_utc=provenance["snapshot_utc"],source_commit=source_commit,full_scientific_release=False,
         missing_policy="EXPLICIT_YEAR_GROUP_GAPS_NO_INTERPOLATION",
         reference_policy="VERIFIED_FULL_FOCUS_SUPPORT_PER_FIGURE" if balance.is_file() else "PENDING_INDEPENDENT_COMPARABILITY_MAPPING",
         replication_package=PACKAGE,replication_package_sha256=sha(target),replication_package_bytes=target.stat().st_size)
    qa["release_status"]="INTERIM_VERIFIED_POINTS_FULL_SCIENCE_INCOMPLETE"
    put_json(site/"GUIDED_QA.json",qa)
    write_manifest(site)
    return dict(files=len(code),bytes=target.stat().st_size,sha256=sha(target),source_commit=source_commit)

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    for key in ("repo","site","inputs","provenance"):parser.add_argument("--"+key,type=Path,required=True)
    parser.add_argument("--source-commit",required=True)
    a=parser.parse_args()
    print(json.dumps(make_package(a.repo,a.site,a.inputs,json.loads(a.provenance.read_text(encoding="utf-8")),a.source_commit)))
