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
 "Q01_Q08","approved_research_scope","dashboard_combination_admission","full_focus_balance","slides21",
 "replication","static_site_QA","scope_decisions")}
def fail(s):raise ValueError("GUIDED_PUBLIC_RELEASE_HOLD: "+s)
def sha(p):
 h=hashlib.sha256()
 with p.open("rb") as f:
  for block in iter(lambda:f.read(1048576),b""):h.update(block)
 return h.hexdigest()

def verify_reviewed_absence(site,cert,qa):
 path=site/'data/absence_evidence.json'
 if not path.exists():return {}
 if sha(path)!=cert.get('reviewed_absence_evidence_sha256') or sha(path)!=qa.get('reviewed_absence_evidence_sha256'):
  fail('missing-point evidence differs from reviewed certificate')
 evidence=json.loads(path.read_text(encoding='utf-8'))
 if evidence.get('status')!='ALL_MISSING_POINTS_HAVE_EXACT_REVIEWED_CAUSES':
  fail('missing-point review unfinished')
 for key in ('coverage_sha256','product_trace_sha256'):
  if not re.fullmatch('[a-f0-9]{64}',evidence.get(key,'')) or evidence[key]!=cert.get(key):
   fail('missing-point review is not bound to '+key)
 points={}
 for p in evidence['points']:
  key=(p['country'],p['figure_id'],int(p['year']),p['series_id'])
  if key in points or not p.get('cell_id') or not re.fullmatch('[a-f0-9]{64}',p.get('target_contract_sha256','')):
   fail('missing or duplicate exact absent-point identity')
  reason=p['main_reason']
  if reason=='ANALYSIS_BELOW_PUBLICATION_THRESHOLD':
   def small(v,limit):
    try:return float(v)<limit
    except (ValueError,TypeError):return False
   if p['status']!='SCIENTIFICALLY_VALIDATED' or not (
       small(p['analysis_min_component_n'],30) or small(p['analysis_min_component_school_n'],5)):
    fail('small-group exclusion is not supported by actual counts')
  elif reason=='OFFICIAL_TREND_NOT_COMPARABLE':
   if not p.get('population_review_id'):fail('official trend exclusion lacks a source review')
  elif reason not in {'SCALE_NOT_DEFINED_IN_CYCLE','REQUIRED_FIELD_NOT_OBSERVED',
      'LEARNING_ENVIRONMENT_NOT_OBSERVED','ANALYTIC_GROUP_UNUSABLE',
      'GROUP_DEFINITION_NOT_OBSERVED','QUESTIONNAIRE_NOT_ADMINISTERED','DOMAIN_NOT_VALID_IN_SOURCE'} or not p['status'].startswith('UNAVAILABLE_') or not p.get('hold_reason'):
   fail('unresolved result cannot be relabelled as source absence')
  points[key]=p
 if len(points)!=evidence['reviewed_missing_points']:fail('missing-point evidence count')
 return points
def verify_reference_payloads(site,ids,recomputed):
 # The browser lazily loads per-country contracts. A correct global export
 # cannot certify a changed country file, even with a fresh self-manifest.
 expected_index=dict(schema_version=2,policy=recomputed['policy'],
   country_files={c:f'data/references/{c}.json' for c in sorted(ids)})
 index=site/'data/explorer_references.json'
 if not index.is_file() or json.loads(index.read_text(encoding='utf-8'))!=expected_index:
  fail('reference index differs from independently verified country scope')
 for country in ids:
  path=site/f'data/references/{country}.json'
  expected=dict(schema_version=1,policy=recomputed['policy'],
    figures=[v for v in recomputed['figures'] if v['focus']==country])
  if not path.is_file() or json.loads(path.read_text(encoding='utf-8'))!=expected:
   fail('reference options differ from independently verified per-combination support: '+country)

def verify(site,cert_file):
 if not site.is_dir() or not cert_file.is_file():
  fail("missing guided dashboard or source-verified certificate")
 cert=json.loads(cert_file.read_text(encoding="utf-8"))
 if cert.get("release_kind")=="PARTIAL_VERIFIED_RESULTS":
  # A direct user decision permits available points now. Keep the independent
  # final scientific release gate below intact; the interim gate cannot pass it.
  import importlib.util
  spec=importlib.util.spec_from_file_location("partial_release",Path(__file__).with_name("LO_PARTIAL_DASHBOARD_RELEASE.py"))
  partial=importlib.util.module_from_spec(spec);spec.loader.exec_module(partial)
  return partial.verify(site,cert_file)
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
 if balance.get("schema_version")==3:
  # Recompute membership from exact aggregate identities, not certificate labels.
  import importlib.util
  spec=importlib.util.spec_from_file_location('guided_builder',Path(__file__).with_name('LO_FINAL_GUIDED_DASHBOARD_BUILD.py'))
  builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
  rows=[r for c in ids for r in json.loads((site/f'data/countries/{c}.json').read_text(encoding='utf-8'))['records']]
  recomputed=builder.explorer_references(balance_path,ids,fig,rows,source_lock)
  verify_reference_payloads(site,ids,recomputed)
  iterator=[] # All v3 keys, missing views and membership were verified above.
 elif balance.get("schema_version")==2:
  if balance.get("policy")!="FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3":fail("unknown per-view reference policy")
  records=balance.get("views",[])
  if isinstance(records,dict):records=list(records.values())
  if not isinstance(records,list) or {v.get("focus") for v in records}!=set(ids):fail("focus view coverage differs from country scope")
  if any(not v.get("view_cell_ids") for v in records):fail("exact view-to-figure binding missing")
  if not (site/"data/explorer_references.json").is_file():fail("interactive reference contract missing")
  iterator=[(v["focus"],v) for v in records]
 else:
  if balance.get("policy")!="FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3" or set(balance.get("focuses",{}))!=set(ids):fail("focus balance coverage differs from country scope")
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
 absence=verify_reviewed_absence(site,cert,qa)
 used_absence=set()
 for c in ids:
  rec=site/"data"/"countries"/(c+".json")
  ava=site/"data"/"availability"/(c+".json")
  if not rec.is_file() or not ava.is_file():
   fail("missing country or scientific availability "+c)
  data=json.loads(rec.read_text(encoding="utf-8"))
  av=json.loads(ava.read_text(encoding="utf-8"))["figures"]
  if len(av)!=len(ids_fig) or {v["figure_id"] for v in av}!=set(ids_fig):
   fail("missing figure availability decisions "+c)
  for v in av:
   if v["display_state"] not in ("VALIDATED","UNAVAILABLE","PARTIAL"):
    fail("unreviewed figure availability "+c)
   gaps=v.get('missing_points',[])
   if v['display_state']=='PARTIAL' and not gaps:fail('partial figure has no explicit gaps')
   if gaps and v.get('missingness_review')!='EXACT_REVIEWED_CELL_EVIDENCE':
    fail('partial or unavailable figure lacks exact missing-point evidence')
   for gap in gaps:
    key=(c,v['figure_id'],int(gap['year']),gap['series_id'])
    p=absence.get(key)
    if not p or any(gap.get(k)!=p[k] for k in ('cell_id','main_reason','reason_nl','reason_en')):
     fail('displayed missing-point explanation differs from reviewed cause')
    used_absence.add(key)
  for row in data["records"]:
   if row["figure_id"] not in ids_fig:fail("uncontracted public result")
   if row.get("series_role")=="comparator":
    if "ci_low" in row or "ci_high" in row or "se" in row:
     fail("uncertainty bars on equal-weight comparator line")
   if (c,row['figure_id'],int(row['year']),row['series_id']) in absence:
    fail('a reviewed absent point also contains a numeric value')
 if used_absence!=set(absence):fail('unused or omitted missing-point review evidence')
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
