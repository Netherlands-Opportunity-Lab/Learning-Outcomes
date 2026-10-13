#!/usr/bin/env python3
"""Independently verify and stage the ACTIVE guided dashboard for GitHub Pages.

Requires all science/rights/paper/replication and 21-slide QA receipts. Old
2026-09 public release is unchanged until review merges verified candidate.
"""
from __future__ import annotations
import argparse,hashlib,json,re,shutil
from pathlib import Path
BAD_EXT={".sav",".zsav",".dta",".rdata",".rds",".rda",".sqlite",
 ".db",".parquet",".sas7bdat",".xls",".xlsx",".zip",".gz"}
REQUIRED_CERT={k:"PASS" for k in ("scientific_status","rights_status",
 "Q01_Q08","all50_research_scope","dashboard42","slides21",
 "replication","static_site_QA","peer_below_basic_definition")}
def fail(s):raise ValueError("GUIDED_PUBLIC_RELEASE_HOLD: "+s)
def sha(p):
 h=hashlib.sha256()
 with p.open("rb") as f:
  for block in iter(lambda:f.read(1048576),b""):h.update(block)
 return h.hexdigest()
def verify(site,cert_file):
 if not site.is_dir() or not cert_file.is_file():
  fail("missing guided dashboard or source-verified certificate")
 cert=json.loads(cert_file.read_text(encoding="utf-8"))
 for key,val in REQUIRED_CERT.items():
  if cert.get(key)!=val:fail("scientific or rights approval missing "+key)
 source_lock=cert.get("scientific_source_sha256","")
 figure_lock=cert.get("figure_contract_sha256","")
 if not re.fullmatch("[0-9a-f]{64}",source_lock) or not re.fullmatch(
        "[0-9a-f]{64}",figure_lock):
  fail("source and original figure contract SHA not certified")
 manifest_file=site/"BUILD_SHA256_MANIFEST.json"
 if not manifest_file.is_file() or cert.get(
     "candidate_manifest_sha256")!=sha(manifest_file):
  fail("candidate manifest does not match independent certificate")
 entries=json.loads(manifest_file.read_text(encoding="utf-8"))
 if not entries:fail("empty verified candidate manifest")
 included=set()
 for entry in entries:
  rel=Path(entry["path"])
  if rel.is_absolute() or ".." in rel.parts or rel.as_posix() in included:
   fail("unsafe or duplicate manifest path")
  included.add(rel.as_posix())
  path=site/rel
  if not path.is_file() or path.suffix.lower() in BAD_EXT:
   fail("missing or forbidden public file "+rel.as_posix())
  if path.stat().st_size!=int(entry["bytes"]) or sha(path)!=entry["sha256"]:
   fail("candidate output changed "+rel.as_posix())
 actual={p.relative_to(site).as_posix() for p in site.rglob("*")
         if p.is_file() and p!=manifest_file}
 if actual!=included:fail("untracked extra/omitted release files")
 paths=["data/common42.json","data/figure_registry.json",
   "data/method_registry.json","nl/index.html","en/index.html",
   "assets/app-shell.js","locales/nl.json","locales/en.json"]
 if not all((site/p).is_file() for p in paths):
  fail("guided runtime contract incomplete")
 countries=json.loads((site/"data/common42.json").read_text(encoding="utf-8"))
 ids=[r["code"] for r in countries]
 if len(ids)!=42 or len(set(ids))!=42 or "NLD" not in ids:
  fail("42-system country register invalid")
 fig=json.loads((site/"data/figure_registry.json").read_text())["figures"]
 ids_fig=[f["figure_id"] for f in fig]
 if len(ids_fig)!=132 or len(set(ids_fig))!=132:
  fail("active 132-of-138 figure overlay contract changed")
 if any(f["figure_id"].startswith("TR_BASIC") for f in fig):
  fail("obsolete complementary graph still exposed")
 if any(f["figure_id"].startswith("EN_PERFORMANCE_PEER") and
    (f["outcome"]!="peer_share_below_basic" or
     f["method_id"]!="M_PEER_BELOW_BASIC_NEW_METHOD_HOLD") for f in fig):
  fail("old high-peer method presented as below-basic")
 qa=json.loads((site/"GUIDED_QA.json").read_text(encoding="utf-8"))
 if qa["system_count"]!=42 or qa["active_figures"]!=132:
  fail("candidate figure count or country scope changed")
 if qa["availability_counts"].get("PLACEHOLDER",0)>0:
  fail("unreviewed incomplete figures must be resolved or documented unavailable")
 for c in ids:
  rec=site/"data"/"countries"/(c+".json")
  ava=site/"data"/"availability"/(c+".json")
  if not rec.is_file() or not ava.is_file():
   fail("missing country or scientific availability "+c)
  data=json.loads(rec.read_text(encoding="utf-8"))
  av=json.loads(ava.read_text(encoding="utf-8"))["figures"]
  if len(av)!=132 or {v["figure_id"] for v in av}!=set(ids_fig):
   fail("missing figure availability decisions "+c)
  if any(v["display_state"] not in ("VALIDATED","UNAVAILABLE")
          for v in av):fail("unreviewed figure availability "+c)
  for row in data["records"]:
   if row["figure_id"] not in ids_fig:fail("uncontracted public result")
   if row.get("series_role")=="comparator":
    if "ci_low" in row or "ci_high" in row or "se" in row:
     fail("uncertainty bars on equal-weight comparator line")
 for lang in ("nl","en"):
  for country in ids:
   for question in ("trends","distribution","gaps","environment"):
    if not (site/lang/"country"/country/question/"index.html").is_file():
     fail("incomplete bilingual deep routes")
 return {"candidate_manifest_sha256":sha(manifest_file),
   "systems":42,"active_figures":132,
   "scientific_rows":qa["scientific_data_rows"],
   "release_gate":"PASS_SIGNED_BUT_NOT_DEPLOYED"}
def stage(repo,site,certificate):
 verified=verify(site,certificate)
 rid=verified["candidate_manifest_sha256"][:20]
 dest=repo/"05_publication"/"verified_guided_candidates"/rid
 if dest.exists():fail("release SHA directory already staged")
 dest.parent.mkdir(parents=True,exist_ok=True)
 shutil.copytree(site,dest)
 shutil.copy2(certificate,dest/"PUBLIC_RELEASE_CERTIFICATION.json")
 receipt=dict(verified,release_id=rid,
  status="STAGED_ON_FEATURE_BRANCH_NOT_DEPLOYED")
 (dest/"GUIDED_RELEASE_RECEIPT.json").write_text(
  json.dumps(receipt,indent=2,sort_keys=True),encoding="utf-8")
 return receipt
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--repo",type=Path,required=True)
 p.add_argument("--candidate",type=Path,required=True)
 p.add_argument("--certificate",type=Path,required=True)
 p.add_argument("--verify-only",action="store_true")
 a=p.parse_args()
 result=(verify(a.candidate,a.certificate) if a.verify_only
          else stage(a.repo,a.candidate,a.certificate))
 print(json.dumps(result,sort_keys=True))
if __name__=="__main__":main()
