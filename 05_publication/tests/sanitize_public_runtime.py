#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, re, zipfile

ROOT=Path(__file__).resolve().parents[2]
TARGET=ROOT/"05_publication"/"public_dashboard_runtime_20260928.zip"
RECEIPT=ROOT/"05_publication"/"PUBLIC_RUNTIME_SANITIZE_RECEIPT.json"
REMOVE={
 "product_data/FINAL_IMPACT_MATRIX.csv",
 "product_data/FINAL_OPEN_POINTS_STATUS.csv",
 "product_data/FINAL_TECHNICAL_VALIDATION.csv",
 "product_data/FINAL_USE_STATUS_REGISTER.csv",
}
TEXT_EXT={".json",".csv",".svg",".md",".txt",".html",".js",".css"}
FORBIDDEN_EXT={".sav",".zsav",".sas7bdat",".dta",".por",".xpt",".dat",".sps",".sas",".sd2",".rdata"}

def sha(b): return hashlib.sha256(b).hexdigest()

with zipfile.ZipFile(TARGET) as src:
    names=sorted(n for n in src.namelist() if not n.endswith("/") and n not in REMOVE)
    payload={n:src.read(n) for n in names}

for name,b in payload.items():
    lower=name.lower()
    if any(lower.endswith(x) for x in FORBIDDEN_EXT):
        raise SystemExit("forbidden source/microdata file: "+name)
    if re.search(r"(^|/)(cache|extracts|microdata|private|aggregate_replicates)(/|$)",name,re.I):
        raise SystemExit("forbidden private/cache path: "+name)
    if Path(name).suffix.lower() in TEXT_EXT:
        s=b.decode("utf-8","ignore")
        if ("C:"+"/Users/") in s or ("C:"+"\\Users\\") in s:
            raise SystemExit("absolute local user path remains in "+name)
        if re.search(r"BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY",s):
            raise SystemExit("private key material in "+name)

tmp=TARGET.with_suffix(".tmp.zip")
with zipfile.ZipFile(tmp,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=9) as out:
    for name in names:
        info=zipfile.ZipInfo(name)
        info.date_time=(2026,9,28,0,0,0)
        info.compress_type=zipfile.ZIP_DEFLATED
        info.external_attr=0o644<<16
        out.writestr(info,payload[name])
tmp.replace(TARGET)
b=TARGET.read_bytes()
receipt={
 "release":"PUBLIC_DASHBOARD_20260928_FINAL",
 "runtime_file":"05_publication/public_dashboard_runtime_20260928.zip",
 "file_count":len(names),
 "bytes":len(b),
 "sha256":sha(b),
 "removed_not_runtime_required":sorted(REMOVE),
 "absolute_local_path_scan":"PASS",
 "forbidden_source_microdata_scan":"PASS"
}
RECEIPT.write_text(json.dumps(receipt,indent=2)+"\n",encoding="utf-8")
print(json.dumps(receipt))
