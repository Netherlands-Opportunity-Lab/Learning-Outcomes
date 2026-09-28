from pathlib import Path
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "public_site_dist"
MANIFEST = ROOT / "05_publication" / "PUBLIC_DASHBOARD_MANIFEST.json"

errors=[]
def check(cond,msg):
    if not cond: errors.append(msg)

required=[
 "index.html","downloads.html","assets/app-product.js","assets/styles.css",
 "product_data/metadata.json","product_data/ranks.json","product_data/curated.json",
 "product_data/institutions.json","product_data/quality.json","product_data/countries/iso3_NLD.json",
 "docs/SCIENTIFIC_BOUNDARIES.md","docs/PUBLICATION_STATUS.md",
 "docs/PUBLICATION_RIGHTS_REVIEW.md","docs/REPLICATION_GUIDE.md"
]
for rel in required: check((OUT/rel).exists(),"missing "+rel)

blocked=["product_data/FINAL_PRODUCT_BASIS.csv.gz","product_data/RESULTATEN_MASTER.csv.gz"]
for rel in blocked: check(not (OUT/rel).exists(),"blocked bulk file present: "+rel)

forbidden_ext={".sav",".zsav",".sas7bdat",".dta",".por",".xpt",".sps",".sas",".sd2",".rdata",".dat"}
for p in OUT.rglob("*"):
    if p.is_file():
        check(p.suffix.lower() not in forbidden_ext,"source/microdata file type present: "+str(p.relative_to(OUT)))

m=json.loads(MANIFEST.read_text(encoding="utf-8"))
expected={r["filename"]:(int(r["bytes"]),r["sha256"]) for r in m["files"] if r["publication_status"]=="PUBLIC_OK"}
for rel,(n,exp) in expected.items():
    p=OUT/rel
    check(p.exists(),"public manifest runtime file missing: "+rel)
    if p.exists():
        b=p.read_bytes()
        check(len(b)==n,"manifest byte mismatch: "+rel)
        check(hashlib.sha256(b).hexdigest()==exp,"manifest SHA mismatch: "+rel)

meta_path=OUT/"product_data/metadata.json"
if meta_path.exists():
    meta=json.loads(meta_path.read_text(encoding="utf-8"))
    check(meta.get("final_freeze")=="FINAL_ANALYSIS_FREEZE_20260928","wrong final_freeze")
    check(meta.get("final_basis_rows")==283284,"wrong final_basis_rows")

downloads=(OUT/"downloads.html").read_text(encoding="utf-8") if (OUT/"downloads.html").exists() else ""
for name in ["FINAL_PRODUCT_BASIS.csv.gz","RESULTATEN_MASTER.csv.gz"]:
    check(not re.search(r'href=["\'][^"\']*'+re.escape(name),downloads,re.I),"bulk download link present: "+name)
index=(OUT/"index.html").read_text(encoding="utf-8") if (OUT/"index.html").exists() else ""
check("Publieke onderzoeksversie" in index,"public label missing")

if errors:
    print("PUBLIC SITE QA FAIL"); print("\n".join(errors)); sys.exit(1)
print("PUBLIC SITE QA PASS")
print("Minimal public runtime hashes, release metadata and download boundary validated.")
