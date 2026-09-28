from pathlib import Path
import re,sys
root=Path(__file__).resolve().parents[1]
errors=[]
required=[
 "README.md","REPRODUCIBILITY.md","DATA_SOURCES.md","METHODS.md","KNOWN_LIMITATIONS.md",
 "01_data_download_preprocessing/README.md","02_analysis/README.md","03_dashboard/README.md",
 "04_products_or_release/README.md","PRODUCTION_MANIFEST.json"
]
for rel in required:
    if not (root/rel).exists(): errors.append(f"missing {rel}")
for p in root.rglob("*"):
    if not p.is_file() or ".git" in p.parts: continue
    rel=p.relative_to(root).as_posix()
    if re.search(r"(^|/)(cache|extracts|microdata|private|aggregate_replicates)(/|$)",rel,re.I): errors.append(f"forbidden path {rel}")
    if p.suffix.lower() in {".sav",".zsav",".sas7bdat",".dta",".por",".xpt",".dat"}: errors.append(f"microdata type {rel}")
    if p == Path(__file__).resolve(): continue
    if p.suffix.lower() in {".md",".txt",".csv",".json",".yml",".yaml",".r",".py",".js",".css",".html",".cff"} and p.stat().st_size<6_000_000:
        try: s=p.read_text(encoding="utf-8",errors="ignore")
        except Exception: continue
        pat1="C:"+"/Users/"
        pat2="C:"+"\\Users\\"
        if pat1 in s or pat2 in s: errors.append(f"absolute user path {rel}")
if errors:
    print("FAIL")
    print("\n".join(errors))
    sys.exit(1)
print("PASS repository boundary checks")
