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
 "Q01_Q08","approved_research_scope","dashboard_6x3","full_focus_balance","slides21",
 "replication","static_site_QA","scope_decisions")}
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
  if not isinstance(entry.get("path"),str) or "\\" in entry["path"] or ":" in entry["path"]:
   fail("manifest paths must use repository-relative forward slashes")
  rel=Path(entry["path"])
  if rel.is_absolute() or ".." in rel.parts or rel.as_posix() in included:
   fail("unsafe or duplicate manifest path")
  included.add(rel.as_posix())
  path=site/rel
  if not path.resolve().is_relative_to(site.resolve()) or path.is_symlink():
   fail("manifest file escapes candidate directory")
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
 if not ids or len(set(ids))!=len(ids) or any(not re.fullmatch("[A-Z0-9]{3}",c) for c in ids):
  fail("dynamic country register invalid")
 if sorted(ids)!=sorted(cert.get("eligible_countries",[])):fail("country evidence differs from build")
 fig=json.loads((site/"data/figure_registry.json").read_text())["figures"]
 ids_fig=[f["figure_id"] for f in fig]
 if not ids_fig or len(set(ids_fig))!=len(ids_fig):fail("duplicate or empty approved figures")
 if sorted(ids_fig)!=sorted(cert.get("approved_figure_ids",[])):fail("figure scope differs from certificate")
 if any(f["figure_id"].startswith("TR_BASIC") for f in fig):
  fail("obsolete complementary graph still exposed")
 if any(f.get("active_role")=="PRIMARY_NEW_BELOW_BASIC_PEER" and
    (f["outcome"]!="peer_share_below_basic" or
     f["method_id"]!="M_PEER_BELOW_BASIC_NEW_METHOD_HOLD") for f in fig):
  fail("old high-peer method presented as below-basic")
 qa=json.loads((site/"GUIDED_QA.json").read_text(encoding="utf-8"))
 if qa["system_count"]!=len(ids) or qa["active_figures"]!=len(ids_fig):
  fail("candidate figure count or country scope changed")
 for field in ("country_registry_sha256","scope_decisions_sha256","scientific_source_sha256","figure_contract_sha256","balanced_references_sha256"):
  if not re.fullmatch("[a-f0-9]{64}",qa.get(field,"")) or qa[field]!=cert.get(field):fail("missing exact "+field)
 balance_path=site/"data"/"balanced_references.json"
 if not balance_path.is_file() or sha(balance_path)!=qa["balanced_references_sha256"]:fail("balanced reference export missing or changed")
 balance=json.loads(balance_path.read_text(encoding="utf-8"))
 if balance.get("schema_version")==2:
  if balance.get("policy")!="FULL_FOCUS_CORE_PLUS_JOINT_VIEW_SUPPORT_6x3":fail("unknown per-view reference policy")
  records=balance.get("views",[])
  if not isinstance(records,list) or {v.get("focus") for v in records}!=set(ids):fail("focus view coverage differs from country scope")
  if any(not v.get("view_cell_ids") for v in records):fail("exact view-to-figure binding missing")
  if not (site/"data/explorer_references.json").is_file():fail("interactive reference contract missing")
  iterator=[(v["focus"],v) for v in records]
 else:
  if balance.get("policy")!="FULL_FOCUS_SUPPORT_6x3" or set(balance.get("focuses",{}))!=set(ids):fail("focus balance coverage differs from country scope")
  iterator=list(balance["focuses"].items())
 for focus,record in iterator:
  members=record.get("default_members",[])
  if isinstance(members,str):members=[members]
  options=record.get("options",[])
  eligible={o["country"] for o in options if o["eligible"]}
  if focus in members or len(set(members))!=len(members) or not set(members)<=eligible:fail("ineligible default reference members")
  if not record.get("required_keys") or record.get("country_weights")!="EQUAL_PER_COUNTRY":fail("empty or invalid full-focus reference contract")
  for point in record.get("default_points",[]):
   if set(point["members"].split(";"))!=set(members) or point["n_countries"]!=len(members) or point["benchmark_se_displayed"]:fail("changing or invalid reference panel")
 if qa["availability_counts"].get("PLACEHOLDER",0)>0:
  fail("unreviewed incomplete figures must be resolved or documented unavailable")
 for c in ids:
  rec=site/"data"/"countries"/(c+".json")
  ava=site/"data"/"availability"/(c+".json")
  if not rec.is_file() or not ava.is_file():
   fail("missing country or scientific availability "+c)
  data=json.loads(rec.read_text(encoding="utf-8"))
  av=json.loads(ava.read_text(encoding="utf-8"))["figures"]
  if len(av)!=len(ids_fig) or {v["figure_id"] for v in av}!=set(ids_fig):
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
   "systems":len(ids),"active_figures":len(ids_fig),
   "scientific_rows":qa["scientific_data_rows"],
   "release_gate":"PASS_REVIEW_CERTIFICATE_NOT_DEPLOYED"}
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
