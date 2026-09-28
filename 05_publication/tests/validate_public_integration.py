#!/usr/bin/env python3
"""Repository-side checks for the public dashboard integration."""
from pathlib import Path
from html.parser import HTMLParser
import csv, hashlib, json, re, sys, zipfile

ROOT=Path(__file__).resolve().parents[2]
PUB=ROOT/"05_publication"
OUT=ROOT/"public_site_dist"
RUNTIME=PUB/"public_dashboard_runtime_20260928.zip"
MANIFEST=PUB/"PUBLIC_DASHBOARD_MANIFEST.json"
GATE=PUB/"PUBLIC_DATA_GATE.csv"
FIDELITY=PUB/"PUBLIC_RESULT_FIDELITY.json"
errors=[]

def check(cond,msg):
    if not cond: errors.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()

m=json.loads(MANIFEST.read_text(encoding="utf-8"))
check(m["analysis_release"]=="FINAL_ANALYSIS_FREEZE_20260928","wrong analysis release")
check(m["git_base_sha"]=="db8b7d7ddc22c6d96191148ffac9c2953dc00900","wrong integration base SHA")
check(sha(RUNTIME.read_bytes())==m["runtime_transport_sha256"],"runtime ZIP hash mismatch")

public_entries={r["filename"]:r for r in m["files"] if r["publication_status"]=="PUBLIC_OK"}
hold_entries={r["filename"]:r for r in m["files"] if r["publication_status"]!="PUBLIC_OK"}
check("product_data/FINAL_PRODUCT_BASIS.csv.gz" in hold_entries,"FINAL_PRODUCT_BASIS hold missing")
check("product_data/RESULTATEN_MASTER.csv.gz" in hold_entries,"RESULTATEN_MASTER hold missing")

with zipfile.ZipFile(RUNTIME) as zf:
    names=sorted(n for n in zf.namelist() if not n.endswith("/"))
    check(set(names)==set(public_entries),"runtime/public manifest inventory mismatch")
    for name in names:
        b=zf.read(name); e=public_entries[name]
        check(len(b)==e["bytes"],"byte mismatch "+name)
        check(sha(b)==e["sha256"],"SHA mismatch "+name)
        lower=name.lower()
        check(not any(lower.endswith(x) for x in
              [".sav",".zsav",".sas7bdat",".dta",".por",".xpt",".dat",".sps",".sas",".sd2",".rdata"]),
              "microdata/source file type in runtime: "+name)
        check(not re.search(r"(^|/)(cache|extracts|microdata|private|aggregate_replicates)(/|$)",name,re.I),
              "private/cache path in runtime: "+name)
        check(not re.search(r"(^|/)(demo|synthetic|example_data)(/|$)",name,re.I),
              "old demo/synthetic data path in runtime: "+name)

gate=list(csv.DictReader(GATE.open(encoding="utf-8")))
allowed={"PUBLIC_OK","PUBLIC_SUMMARY_ONLY","PRIVATE_REPRODUCIBILITY_ONLY","DO_NOT_PUBLISH"}
check(all(r["classification"] in allowed for r in gate),"unknown gate classification")
check(sum(r["classification"]=="PUBLIC_OK" for r in gate)==257,"PUBLIC_OK gate count mismatch")
check(not any(r["site_usage"]=="INCLUDED" and r["classification"]!="PUBLIC_OK" for r in gate),
      "non-public file marked included")

fid=json.loads(FIDELITY.read_text(encoding="utf-8"))
check(fid.get("pass") is True,"fidelity evidence is not PASS")
check(fid["comparison_scope"]["country_profile_rows"]==278431,"unexpected public result row count")
check(fid["results"]["missing_result_ids"]==0,"missing public result IDs")
check(fid["results"]["country_profile_field_mismatches"]==0,"public result field mismatch")
check(fid["results"]["runtime_file_byte_mismatches"]==0,"runtime byte mismatch")

# Built-site tests. build_public_pages.py must run before this script in CI.
for rel in ["index.html","downloads.html","assets/app-product.js","assets/styles.css",
            "product_data/metadata.json","product_data/ranks.json","product_data/quality.json",
            "docs/PUBLICATION_STATUS.md","docs/PUBLICATION_RIGHTS_REVIEW.md","docs/REPLICATION_GUIDE.md"]:
    check((OUT/rel).exists(),"built site missing "+rel)
for rel in ["product_data/FINAL_PRODUCT_BASIS.csv.gz","product_data/RESULTATEN_MASTER.csv.gz"]:
    check(not (OUT/rel).exists(),"blocked bulk file in built site: "+rel)

class LinkParser(HTMLParser):
    def __init__(self): super().__init__(); self.links=[]
    def handle_starttag(self,tag,attrs):
        for k,v in attrs:
            if k in {"href","src"} and v: self.links.append(v)
for html_file in OUT.rglob("*.html"):
    p=LinkParser(); p.feed(html_file.read_text(encoding="utf-8"))
    for link in p.links:
        if re.match(r"^(https?:|mailto:|data:|#)",link): continue
        target=(html_file.parent/link.split("#",1)[0].split("?",1)[0]).resolve()
        try: target.relative_to(OUT.resolve())
        except ValueError:
            errors.append("link escapes site: "+str(html_file.relative_to(OUT))+" -> "+link); continue
        check(target.exists(),"broken local link: "+str(html_file.relative_to(OUT))+" -> "+link)

downloads=(OUT/"downloads.html").read_text(encoding="utf-8")
for blocked in ["FINAL_PRODUCT_BASIS.csv.gz","RESULTATEN_MASTER.csv.gz"]:
    check(not re.search(r'href=["\'][^"\']*'+re.escape(blocked),downloads,re.I),
          "hidden/indirect bulk download link: "+blocked)

js=(OUT/"assets/app-product.js").read_text(encoding="utf-8")
check("Uses frozen aggregates. No rank, panel, pupil-level or contrast estimation." in js,
      "frozen-renderer contract comment missing")
for phrase in ["Geen vrijgegeven uitkomst","uitsluitend ontbrekende of geblokkeerde records"]:
    check(phrase in js,"blocked/empty state missing: "+phrase)
css=(OUT/"assets/styles.css").read_text(encoding="utf-8")
check(css.count("{")==css.count("}"),"CSS brace imbalance")

# No secrets/private absolute paths in public text output.
secret_patterns=[
 r"C:\\Users\\",r"C:/Users/",r"BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY",
 r"(?i)(api[_-]?key|access[_-]?token|secret)[=:][^\s]{8,}"
]
for p in OUT.rglob("*"):
    if not p.is_file() or p.suffix.lower() not in {".html",".js",".css",".json",".csv",".md",".txt",".svg"}:
        continue
    if p.stat().st_size>8_000_000: continue
    s=p.read_text(encoding="utf-8",errors="ignore")
    for pat in secret_patterns:
        check(re.search(pat,s) is None,"private path/secret pattern in "+str(p.relative_to(OUT)))

if errors:
    print("PUBLIC INTEGRATION QA FAIL")
    print("\n".join(errors))
    sys.exit(1)
print("PUBLIC INTEGRATION QA PASS")
print("inventory, publication gate, hashes, links, blocked states, downloads, privacy and fidelity evidence validated")
