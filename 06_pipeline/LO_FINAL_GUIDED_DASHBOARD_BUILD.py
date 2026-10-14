#!/usr/bin/env python3
"""Build the active bilingual guided source-eligible dashboard from the pinned
138-figure contract and independently validated aggregate product rows.

This module does not read student records, does not borrow September numeric
results, and never overwrites the live GitHub Pages release. Every missing
country/figure cell remains an explicit placeholder.
"""
from __future__ import annotations
import argparse,csv,hashlib,json,math,re,shutil
from collections import defaultdict
from pathlib import Path

CONTRACT_COLS={"figure_id","question","age","domain","survey","outcome",
 "split","view_mode","peer_definition","expected_series","unit","method_id",
 "label_nl","label_en","measure_label_nl","measure_label_en",
 "subtitle_nl","subtitle_en","required_years","old_figure_id"}
PRODUCT_COLS={"figure_id","country","year","estimate","se","n_unweighted",
 "scientific_status","input_fingerprint","code_fingerprint",
 "result_hash","sample_id","source_id","series_id"}
QUESTIONS=("trends","distribution","gaps","environment")
BAD_EXT={".sav",".zsav",".sas7bdat",".dta",".rdata",".sqlite",".db",".parquet",
 ".rds",".rda",".xlsx",".xls",".zip",".gz"}
def fail(msg):raise ValueError("GUIDED_DASHBOARD_HOLD: "+msg)
def sha(path):
 h=hashlib.sha256()
 with path.open("rb") as stream:
  for block in iter(lambda:stream.read(1048576),b""):h.update(block)
 return h.hexdigest()
def readcsv(path):
 if not path.is_file():fail("missing "+str(path.name))
 with path.open(encoding="utf-8-sig",newline="") as f:
  reader=csv.DictReader(f)
  if not reader.fieldnames:fail("empty schema: "+path.name)
  return set(reader.fieldnames),list(reader)
def numeric(value,col):
 try: x=float(value)
 except (TypeError,ValueError):fail("invalid "+col)
 if not math.isfinite(x):fail("nonfinite "+col)
 return x
def country_contract(bundle,registry=None,allow_synthetic=False):
 if registry is None:
  if not allow_synthetic:fail("certified dynamic country registry required")
  cols,rows=readcsv(bundle/"COMMON42_REGISTER.csv")
  return [r for r in rows if r["common42_member"].upper()=="TRUE"]
 cols,rows=readcsv(registry)
 need={"country","dashboard_eligible","selected_for_production","country_name_nl","country_name_en","eligibility_basis"}
 if not need<=cols:fail("dynamic country registry schema")
 members=[r for r in rows if r["dashboard_eligible"].upper()=="TRUE" and r["selected_for_production"].upper()=="TRUE"]
 ids=[r["country"] for r in members]
 if len(set(ids))!=len(ids) or any(not re.fullmatch("[A-Z0-9]{3}",c) for c in ids):fail("invalid country registry identities")
 if any(r["eligibility_basis"]!="SHA_VERIFIED_SOURCE_SUPPORT" for r in members):fail("uncertified source eligibility")
 return [dict(r,route_code=r["country"],country_id="iso3:"+r["country"]) for r in members]
def read_scope_decisions(path):
 if path is None:return {}
 cols,rows=readcsv(path)
 if not {"approval_id","status","decision_date","user_evidence"}<=cols:fail("scope decision schema")
 if len(rows)!=17 or {r["approval_id"] for r in rows}!={f"A{i:02d}" for i in range(1,18)}:fail("scope decision IDs")
 for r in rows:
  if r["status"] not in ("APPROVED","REJECTED","DEFERRED","PENDING"):fail("scope decision status")
  if r["status"]!="PENDING" and (not r["decision_date"] or not r["user_evidence"]):fail("human decision evidence missing")
 return {r["approval_id"]:r["status"] for r in rows}
def figure_contract(bundle,allow_synthetic=False,decisions=None):
 decisions=decisions or {}
 cols,rows=readcsv(bundle/"FIGURE_SERIES_CONTRACT_20261002.csv")
 if not CONTRACT_COLS <= cols or (
     not allow_synthetic and len(rows)!=138):
  fail("138 figure source contract changed")
 ids=[r["figure_id"] for r in rows]
 if len(ids)!=len(set(ids)):fail("duplicate figure IDs")
 output=[]
 for r in rows:
  figure={k:r.get(k,"") for k in sorted(CONTRACT_COLS)}
  figure["figure_id"]=r["figure_id"]
  figure["chart_type"]="time_series"
  figure["y_axis_policy"]="dynamic"
  figure["release_role"]=r.get("release_role","")
  figure["required_years"]=r.get("required_years","")
  family=r["figure_id"].split("_age",1)[0]
  figure["historical_figure_id"]=r["figure_id"]
  # Product decisions are overlays, NEVER mutate the original source lock.
  if family=="TR_POSITION":
   # A09 authorizes a derived rank time series, not legacy panel values or
   # a separate pupil-level calculation. Its contract is recorded in the
   # product grid; publish only after the rank derivation is certified.
   figure["active_role"]="APPROVED_DERIVATION_PENDING_CERTIFIED_EXPORT" if decisions.get("A09")=="APPROVED" else "RANK_NOT_APPROVED"
   continue
  if family=="TR_BASIC":
   figure["active_role"]="DERIVED_COMPLEMENT_SEPARATE_GRAPH_REMOVED"
   continue
  if family=="GP_SES_HIGH":
   if decisions.get("A02")!="APPROVED":continue
   figure["active_role"]="OPTIONAL_APPENDIX"
  elif family=="EN_PERFORMANCE_PEER":
   if decisions.get("A01")!="APPROVED":
    if decisions.get("A03")=="APPROVED":
     figure["active_role"]="APPROVED_HIGH_PEER";output.append(figure)
    continue
   if decisions.get("A03")=="APPROVED":
    high=dict(figure,figure_id=r["figure_id"].replace("EN_PERFORMANCE_PEER_","EN_PERFORMANCE_PEER_HIGH_",1),active_role="APPROVED_HIGH_PEER")
    output.append(high)
   # Existing figure IDs keep their linkage, but the new mandatory metric
   # is peer share BELOW basic; old high-peer estimates cannot fill them.
   figure.update(outcome="peer_share_below_basic",
     label_nl=("Aandeel klasgenoten onder basisniveau – directe leeromgeving" if
       r["peer_definition"]=="direct_learning_environment" else
       "Aandeel leerlingen onder basisniveau – gehele school"),
     label_en=("Share of peers below basic – direct learning setting" if
       r["peer_definition"]=="direct_learning_environment" else
       "Share below-basic peers – whole school"),
     measure_label_nl="Percentage klasgenoten onder basisniveau",
     measure_label_en="Share of peers below basic",
     subtitle_nl=("Beschrijvend; directe leeromgeving en gehele school "
                  "worden afzonderlijk weergegeven. Geen causaal effect."),
     subtitle_en=("Descriptive; direct learning setting and whole school "
                  "are distinct. Not a causal effect."),
     expected_series="total;self_below_basic;self_at_or_above_basic",
     method_id="M_PEER_BELOW_BASIC_NEW_METHOD_HOLD")
   figure["active_role"]="PRIMARY_NEW_BELOW_BASIC_PEER"
  else:
   figure["active_role"]="REQUIRED_OR_EXISTING_SECONDARY"
  if family=="GP_SES_BASIC":
   figure.update(outcome="below_basic_by_ses",label_nl="Onder basisniveau naar SES",label_en="Below basic by SES",measure_label_nl="Aandeel onder basisniveau",measure_label_en="Share below basic")
  # Only documented vocabulary, with no fabricated science values.
  output.append(figure)
 return output
def product_rows(path,countries,figures):
 if path is None:return []
 cols,rows=readcsv(path)
 if not PRODUCT_COLS<=cols:fail("validated product-grid export schema incomplete")
 countries=set(countries);figures={f["figure_id"]:f for f in figures}
 observed=set();out=[]
 for r in rows:
  fid=r["figure_id"];country=r["country"]
  if fid not in figures or country not in countries:
   fail("result outside active figure or dynamic country contract")
  f=figures[fid]
  if r["scientific_status"]!="SCIENTIFICALLY_VALIDATED":
   fail("unreviewed numeric row for "+fid)
  if f["active_role"]=="PRIMARY_NEW_BELOW_BASIC_PEER" and (
    r.get("outcome_id","")!="peer_share_below_basic" or
    not r.get("peer_denominator_verified","").upper()=="PASS" or
    not r.get("self_exclusion_verified","").upper()=="PASS"):
   fail("old high-peer data cannot fill revised below-basic peer figure")
  for key in ("input_fingerprint","code_fingerprint","result_hash"):
   if not re.fullmatch("[0-9a-fA-F]{64}",r[key]):
    fail("invalid scientific lineage "+key)
  if not r["sample_id"] or not r["source_id"]:
   fail("missing sample/source provenance")
  year=r["year"]
  if not re.fullmatch("[12][0-9]{3}",year):
   fail("bad survey year")
  if r.get("survey") and r["survey"]!=f["survey"]:fail("survey mismatch")
  if r.get("domain") and r["domain"]!=f["domain"]:fail("domain mismatch")
  if year not in f["required_years"].split(";"):
   fail("year not declared for "+fid)
  estimate=numeric(r["estimate"],"estimate")
  se=numeric(r["se"],"se")
  n=numeric(r["n_unweighted"],"n_unweighted")
  if se<0 or n<1 or n!=int(n):fail("negative SE or invalid sample N")
  role=r.get("series_role","focus") or "focus"
  if role not in ("focus","comparator"):
   fail("unexpected series role")
  # No SE/CI drawn on the combined eligible-country comparator (only points).
  if role=="comparator":
   if r.get("comparison_fixed_panel_pass","").upper()!="PASS":
    fail("comparator not drawn from exact fixed panel")
   if r.get("comparison_method","")!="EQUAL_COUNTRY_WEIGHT_LEAVE_FOCUS_OUT":
    fail("wrong comparator weights")
  k=(country,fid,year,r["series_id"],role)
  if k in observed:fail("duplicate country/figure/year/series")
  observed.add(k)
  val=dict(figure_id=fid,country_id="iso3:"+country,year=int(year),
     estimate=estimate,n_unweighted=int(n),unit=f["unit"],
     series_id=r["series_id"],series_role=role,
     series_label_nl=r.get("series_label_nl",r["series_id"]),
     series_label_en=r.get("series_label_en",r["series_id"]),
     split_group=r.get("split_group",r["series_id"]),
     source_id=r["source_id"],method_id=f["method_id"],
     quality_status="SCIENTIFICALLY_VALIDATED",
     availability_status="VALIDATED")
  if role=="focus":
   val["se"]=se
   # Missing 95% CI must be truly absent; null is converted to numeric 0
   # by the old frontend's +r.ci_low JS coercion.
   if r.get("ci_low","") and r.get("ci_high",""):
    low=numeric(r["ci_low"],"ci_low");high=numeric(r["ci_high"],"ci_high")
    if not low<=estimate<=high:fail("CI excludes point estimate")
    val.update(ci_low=low,ci_high=high)
  else:
   val["comparator_n"]=int(numeric(r.get("comparator_n",""),"comparator_n"))
   if val["comparator_n"] <1:fail("comparator count invalid")
  out.append(val)
 return out
def reviewed_unavailable(path,countries,figures):
 if path is None:return {}
 cols,rows=readcsv(path)
 need={"country","figure_id","decision","reason_nl","reason_en"}
 if not need <= cols:fail("unavailability review schema missing")
 allowed={f["figure_id"] for f in figures}
 seen={}
 for r in rows:
  k=(r["country"],r["figure_id"])
  if k in seen or k[0] not in countries or k[1] not in allowed:
   fail("duplicated or out-of-scope unavailable review")
  if r["decision"]!="REVIEWED_UNAVAILABLE" or not r["reason_nl"] or not r["reason_en"]:
   fail("unreviewed or undocumented unavailable status")
  if any(tag in r["reason_nl"]+r["reason_en"] for tag in ("C:\\\\Users\\\\","/Users/")):
   fail("private path in public unavailability reason")
  seen[k]=r
 return seen
def figure_complete(current,figure):
 required={x for x in figure["required_years"].split(";") if x}
 groups={x for x in figure["expected_series"].split(";") if x}
 pairs={(str(row["year"]),row["series_id"]) for row in current if row["series_role"]=="focus"}
 return bool(required) and bool(groups) and {(y,g) for y in required for g in groups}.issubset(pairs)

def build(repo,bundle,destination,scientific_rows=None,synthetic_contract=False,
          unavailable_review=None,country_registry=None,scope_decisions=None,balance_export=None):
 if destination.exists():fail("immutable candidate path already exists")
 source=repo/"05_publication"/"preview_overlay"
 for rel in ("index.html","assets/app-shell.js","assets/styles.css",
             "locales/nl.json","locales/en.json"):
  if not (source/rel).is_file():fail("guided source missing "+rel)
 countries=country_contract(bundle,country_registry,synthetic_contract)
 figures=figure_contract(bundle,synthetic_contract,read_scope_decisions(scope_decisions))
 if not figures:fail("no active figure contracts")
 ids={x["route_code"] for x in countries}
 numeric_rows=product_rows(scientific_rows,ids,figures)
 unavailable=reviewed_unavailable(unavailable_review,ids,figures)
 by_country=defaultdict(list)
 for row in numeric_rows:by_country[row["country_id"].split(":")[1]].append(row)
 destination.mkdir(parents=True)
 shutil.copytree(source/"assets",destination/"assets")
 shutil.copytree(source/"locales",destination/"locales")
 template=(source/"index.html").read_text(encoding="utf-8")
 (destination/"data"/"countries").mkdir(parents=True)
 (destination/"data"/"availability").mkdir(parents=True)
 (destination/"data"/"common42.json").write_text(json.dumps([
  {"code":r["route_code"],"nl":r["country_name_nl"],
   "en":r["country_name_en"]} for r in countries],ensure_ascii=False),
  encoding="utf-8")
 if balance_export is not None:
  shutil.copyfile(balance_export,destination/"data"/"balanced_references.json")
 (destination/"data"/"figure_registry.json").write_text(
  json.dumps({"figures":figures},ensure_ascii=False),encoding="utf-8")
 method_ids=sorted({f["method_id"] for f in figures})
 method_text={m:{"nl":"Methode en bronversie: "+m+
                     "; zie gecontroleerd wetenschappelijk register.",
             "en":"Method and source edition: "+m+
                     "; consult the reviewed scientific register."}
              for m in method_ids}
 (destination/"data"/"method_registry.json").write_text(
  json.dumps({"methods":method_text},ensure_ascii=False),encoding="utf-8")
 availability_states=defaultdict(int)
 for country in sorted(ids):
  records=by_country[country]
  (destination/"data"/"countries"/(country+".json")).write_text(
   json.dumps({"records":records},ensure_ascii=False,allow_nan=False,
              separators=(",",":")),encoding="utf-8")
  present=defaultdict(list)
  for row in records:present[row["figure_id"]].append(row)
  available=[]
  for f in figures:
   current=present[f["figure_id"]]
   # At least one focus series per year, and all declared waves, required
   # to call a full trend graph VALIDATED. Partial rows stay visible in data
   # only as a private review candidate; front-end chart stays placeholder.
   years={str(row["year"]) for row in current if row["series_role"]=="focus"}
   required=set(x for x in f["required_years"].split(";") if x)
   roles=set(row["series_id"] for row in current if row["series_role"]=="focus")
   expected={x for x in f["expected_series"].split(";") if x}
   present_pairs={(str(row["year"]),row["series_id"]) for row in current if row["series_role"]=="focus"}
   fully=figure_complete(current,f)
   reviewed=unavailable.get((country,f["figure_id"]))
   if reviewed and current:
    fail("cannot mark a figure unavailable while releasing numeric rows")
   st="VALIDATED" if fully else ("UNAVAILABLE" if reviewed else "PLACEHOLDER")
   availability_states[st]+=1
   reason_nl=("Alle vereiste meetjaren en groepen wetenschappelijk gecontroleerd."
       if fully else reviewed["reason_nl"] if reviewed else
       "Nog niet volledig wetenschappelijk gevalideerd; geen verzonnen waarden.")
   reason_en=("All required survey waves and groups scientifically validated."
       if fully else reviewed["reason_en"] if reviewed else
       "Scientific evidence incomplete; no fabricated estimates.")
   available.append(dict(figure_id=f["figure_id"],display_state=st,
      reason_nl=reason_nl,reason_en=reason_en))
  (destination/"data"/"availability"/(country+".json")).write_text(
   json.dumps({"figures":available},ensure_ascii=False),encoding="utf-8")
 for locale in ("nl","en"):
  for parts in ((locale,),*((locale,"country",c,q)
        for c in sorted(ids) for q in QUESTIONS)):
   folder=destination.joinpath(*parts)
   folder.mkdir(parents=True,exist_ok=True)
   base="../"*len(parts)
   (folder/"index.html").write_text(
     template.replace("__BASE__",base),encoding="utf-8")
 (destination/"index.html").write_text(
  '<!doctype html><meta charset="utf-8"><title>Learning Outcomes</title>'
  '<meta http-equiv="refresh" content="0; url=nl/">'
  '<a href="nl/">Nederlands</a> · <a href="en/">English</a>',
  encoding="utf-8")
 (destination/".nojekyll").write_text("",encoding="utf-8")
 (destination/"robots.txt").write_text("User-agent: *\nDisallow: /\n",encoding="utf-8")
 summary={"scientific_data_rows":len(numeric_rows),"system_count":len(ids),
   "active_figures":len(figures),
   "availability_counts":dict(sorted(availability_states.items())),
   "scientific_source_sha256":sha(scientific_rows) if scientific_rows else "NO_DATA",
   "figure_contract_sha256":sha(bundle/"FIGURE_SERIES_CONTRACT_20261002.csv"),
   "balanced_references_sha256":sha(balance_export) if balance_export else "MISSING",
   "country_registry_sha256":sha(country_registry) if country_registry else "SYNTHETIC_ONLY",
   "scope_decisions_sha256":sha(scope_decisions) if scope_decisions else "PENDING_DEFAULT",
   "release_status":"PRIVATE_GUIDED_CANDIDATE_NOT_PUBLIC"}
 (destination/"GUIDED_QA.json").write_text(json.dumps(summary,indent=2),
                                          encoding="utf-8")
 entries=[]
 for path in sorted(destination.rglob("*")):
  if not path.is_file():continue
  if path.suffix.lower() in BAD_EXT:fail("unsafe public source file type")
  relative=path.relative_to(destination).as_posix()
  entries.append({"path":relative,"sha256":sha(path),
                  "bytes":path.stat().st_size})
 (destination/"BUILD_SHA256_MANIFEST.json").write_text(
  json.dumps(entries,indent=2),encoding="utf-8")
 return summary
def main():
 p=argparse.ArgumentParser()
 p.add_argument("--repo",type=Path,required=True)
 p.add_argument("--bundle",type=Path,required=True)
 p.add_argument("--output",type=Path,required=True)
 p.add_argument("--validated-grid",type=Path)
 p.add_argument("--reviewed-unavailable",type=Path)
 p.add_argument("--country-registry",type=Path,required=True)
 p.add_argument("--scope-decisions",type=Path,required=True)
 p.add_argument("--balanced-references",type=Path)
 args=p.parse_args()
 print(json.dumps(build(args.repo,args.bundle,args.output,
                   args.validated_grid,
                   unavailable_review=args.reviewed_unavailable,country_registry=args.country_registry,
                   scope_decisions=args.scope_decisions,balance_export=args.balanced_references),sort_keys=True))
if __name__=="__main__":main()
