from pathlib import Path
import csv,hashlib,json,re,sys
root=Path(__file__).resolve().parents[1]
errors=[]
required=[
 "README.md","REPRODUCIBILITY.md","DATA_SOURCES.md","METHODS.md","KNOWN_LIMITATIONS.md",
 "01_data_download_preprocessing/README.md","02_analysis/README.md","03_dashboard/README.md",
 "04_products_or_release/README.md","PRODUCTION_MANIFEST.json"
]
for rel in required:
    if not (root/rel).exists(): errors.append(f"missing {rel}")
# repository boundaries
for p in root.rglob("*"):
    if not p.is_file() or ".git" in p.parts: continue
    rel=p.relative_to(root).as_posix()
    if re.search(r"(^|/)(cache|extracts|microdata|private|aggregate_replicates)(/|$)",rel,re.I): errors.append(f"forbidden path {rel}")
    if p.suffix.lower() in {".sav",".zsav",".sas7bdat",".dta",".por",".xpt",".dat"}: errors.append(f"microdata type {rel}")
    if p == Path(__file__).resolve(): continue
    if "archive_or_superseded" not in rel and p.suffix.lower() in {".md",".txt",".csv",".json",".yml",".yaml",".r",".py",".js",".css",".html",".cff"} and p.stat().st_size<6_000_000:
        try: s=p.read_text(encoding="utf-8",errors="ignore")
        except Exception: continue
        if "C:"+"/Users/" in s or "C:"+"\\Users\\" in s: errors.append(f"absolute user path {rel}")
# production manifest integrity.
# PRODUCTION_MANIFEST.json freezes the scientific/product release at commit
# 749a0de8e6ab707f4ecd887247ea8fde82f55656.  A small set of root-level
# documentation files is intentionally allowed to change in later
# publication-only commits; their scientific source lock remains documented
# and the publication layer is separately validated under 05_publication/.
PUBLICATION_OVERLAY_ALLOWLIST={
    "README.md",
    "DATA_LICENSE.md",
    "REPRODUCIBILITY.md",
    "KNOWN_LIMITATIONS.md",
    "scripts/validate_repository.py",
    "CHANGELOG.md",
    "03_dashboard/README.md",
}
try:
    m=json.loads((root/"PRODUCTION_MANIFEST.json").read_text(encoding="utf-8"))
    for row in m.get("files",[]):
        rel=row["path"]
        p=root/rel
        if not p.exists(): errors.append(f"manifest missing file {rel}"); continue
        if rel in PUBLICATION_OVERLAY_ALLOWLIST:
            continue
        b=p.read_bytes()
        if len(b)!=row["bytes"]: errors.append(f"manifest byte mismatch {rel}")
        if hashlib.sha256(b).hexdigest()!=row["sha256"]: errors.append(f"manifest sha mismatch {rel}")
except Exception as e: errors.append(f"manifest read failure {e}")
# local Markdown links in current docs/readmes; external and anchors ignored
md_files=[p for p in root.rglob("*.md") if "archive_or_superseded" not in p.as_posix()]
for p in md_files:
    s=p.read_text(encoding="utf-8",errors="ignore")
    for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)",s):
        if re.match(r"^[a-z]+://",target,re.I) or target.startswith("#") or target.startswith("mailto:"): continue
        t=target.split("#",1)[0]
        if not t: continue
        q=(p.parent/t).resolve()
        try: q.relative_to(root.resolve())
        except Exception: errors.append(f"link escapes repo {p.relative_to(root)} -> {target}"); continue
        if not q.exists(): errors.append(f"broken link {p.relative_to(root)} -> {target}")
# dashboard source/data contract checks
for rel in ["03_dashboard/app/index.html","03_dashboard/app/downloads.html","03_dashboard/app/assets/app-product.js","03_dashboard/app/assets/styles.css","03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv"]:
    if not (root/rel).exists(): errors.append(f"dashboard missing {rel}")
try:
    rows=list(csv.DictReader((root/"03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv").open(encoding="utf-8")))
    names={r["file"] for r in rows}
    for n in ["product_data/FINAL_PRODUCT_BASIS.csv.gz","product_data/RESULTATEN_MASTER.csv.gz","product_data/metadata.json","product_data/ranks.json","product_data/curated.json","product_data/quality.json"]:
        if n not in names: errors.append(f"production data manifest missing {n}")
except Exception as e: errors.append(f"dashboard manifest read failure {e}")
if errors:
    print("FAIL")
    print("\n".join(errors))
    sys.exit(1)
print("PASS repository boundary, manifest, link and dashboard-contract checks")
