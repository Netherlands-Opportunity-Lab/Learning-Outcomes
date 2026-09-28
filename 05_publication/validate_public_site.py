from pathlib import Path
import csv
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "public_site_dist"
MANIFEST = ROOT / "03_dashboard" / "data" / "PRODUCTION_DATA_MANIFEST.csv"

errors = []
def check(cond, msg):
    if not cond:
        errors.append(msg)

required = [
    "index.html",
    "downloads.html",
    "assets/app-product.js",
    "assets/styles.css",
    "product_data/metadata.json",
    "product_data/ranks.json",
    "product_data/curated.json",
    "product_data/quality.json",
    "product_data/countries/iso3_NLD.json",
    "docs/SCIENTIFIC_BOUNDARIES.md",
    "docs/PUBLICATION_STATUS.md",
    "docs/PUBLICATION_RIGHTS_REVIEW.md",
    "docs/REPLICATION_GUIDE.md",
]
for rel in required:
    check((OUT / rel).exists(), "missing " + rel)

blocked = [
    "product_data/FINAL_PRODUCT_BASIS.csv.gz",
    "product_data/RESULTATEN_MASTER.csv.gz",
]
for rel in blocked:
    check(not (OUT / rel).exists(), "blocked bulk file present: " + rel)

forbidden_ext = {".sav", ".zsav", ".sas7bdat", ".dta", ".por", ".xpt", ".sps", ".sas", ".sd2", ".rdata"}
for p in OUT.rglob("*"):
    if p.is_file():
        check(p.suffix.lower() not in forbidden_ext, "source/microdata file type present: " + str(p.relative_to(OUT)))

expected_hashes = {
    "assets/app-product.js": "ca9c971d7b77d5a4d7c1c2bc16a9cb1fda86c62a50970b6a17dc3500e3a45513",
    "assets/styles.css": "ed371d17977d8a112f69f28427785ac8c2d3960f10fa9f239febfbd3c53443ce",
    "product_data/metadata.json": "e2aebe623581b5b1273b334954e250da4475b4a69a63bdbd9c9a002017a6f72e",
    "product_data/ranks.json": "a5d9ca96b306f7598166f8f4d269430bd3d8b6066854d0f057741ba80654d996",
    "product_data/curated.json": "c8c902d0f3f35f2db1365052f978381e698c7d33a217c58ddd0ce6b42bab557a",
    "product_data/quality.json": "66a7b61daee2d6ec5893ed8dad700df0b13a1a3b5212f53b191fda6bc42be1ff",
    "product_data/countries/iso3_NLD.json": "daf18c7ae93157e7e87537b6025cca49b679cc5263efb7ac9d39af1133fff38e",
}
for rel, exp in expected_hashes.items():
    p = OUT / rel
    if p.exists():
        got = hashlib.sha256(p.read_bytes()).hexdigest()
        check(got == exp, f"critical hash mismatch {rel}: {got}")

rows = list(csv.DictReader(MANIFEST.open(encoding="utf-8")))
manifest = {r["file"]: (int(r["bytes"]), r["sha256"].lower()) for r in rows}
for rel, (n, sha) in manifest.items():
    if rel in blocked:
        continue
    p = OUT / rel
    check(p.exists(), "manifest runtime file missing: " + rel)
    if p.exists():
        b = p.read_bytes()
        check(len(b) == n, "manifest byte mismatch: " + rel)
        check(hashlib.sha256(b).hexdigest() == sha, "manifest SHA mismatch: " + rel)

meta_path = OUT / "product_data/metadata.json"
if meta_path.exists():
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    check(meta.get("final_freeze") == "FINAL_ANALYSIS_FREEZE_20260928", "wrong final_freeze")
    check(meta.get("final_basis_rows") == 283284, "wrong final_basis_rows")

downloads = (OUT / "downloads.html").read_text(encoding="utf-8") if (OUT / "downloads.html").exists() else ""
for name in ["FINAL_PRODUCT_BASIS.csv.gz", "RESULTATEN_MASTER.csv.gz"]:
    href_pattern = re.compile(r'href=["\'][^"\']*' + re.escape(name), re.I)
    check(not href_pattern.search(downloads), "bulk download link present: " + name)

index = (OUT / "index.html").read_text(encoding="utf-8") if (OUT / "index.html").exists() else ""
check("Publieke onderzoeksversie" in index, "public label missing")

if errors:
    print("PUBLIC SITE QA FAIL")
    print("\n".join(errors))
    sys.exit(1)

print("PUBLIC SITE QA PASS")
print("Scientific renderer hashes, final metadata, all public runtime hashes and publication boundary validated.")
