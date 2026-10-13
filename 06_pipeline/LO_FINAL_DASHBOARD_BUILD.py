#!/usr/bin/env python3
"""Build a NEW, private, static 42-system dashboard candidate from validated
aggregate grid rows. Never replaces the locked September public site.
Full release needs a separate verified receipt; no pupil data are read.
"""
from __future__ import annotations
import argparse, csv, hashlib, json, shutil
from pathlib import Path

REQUIRED = {"cell_id", "country", "survey", "year", "domain", "stat",
            "group", "estimate", "se", "n_unweighted", "unit", "family",
            "variant", "sample_id", "scientific_status", "source"}
FORBIDDEN = {".sav", ".zsav", ".dta", ".rds", ".rdata", ".sqlite",
             ".db", ".parquet", ".sas7bdat", ".xlsx"}
def fail(why):
    raise ValueError("DASHBOARD_HOLD: " + why)
def sha(path):
    h=hashlib.sha256()
    with path.open("rb") as f:
        for b in iter(lambda:f.read(1048576),b""):h.update(b)
    return h.hexdigest()
def valid_rows(csv_path,allowed):
    with csv_path.open(encoding="utf-8-sig",newline="") as f:
        r=csv.DictReader(f)
        if not r.fieldnames or not REQUIRED <= set(r.fieldnames):
            fail("validated grid export missing required fields")
        rows=list(r)
    seen=set()
    for row in rows:
        k=row["cell_id"]
        if not k or k in seen:fail("empty/duplicate cell id")
        seen.add(k)
        if row["scientific_status"]!="SCIENTIFICALLY_VALIDATED":
            fail("unvalidated scientific row")
        if row["country"] not in allowed:fail("country outside dashboard42")
        if row["survey"] not in ("PISA","PIRLS","TIMSS"):
            fail("unknown survey")
        for col in ("estimate","se","n_unweighted"):
            try:v=float(row[col])
            except (ValueError,TypeError):fail("numeric value/N missing")
            if v!=v or abs(v)==float("inf"):fail("nonfinite "+col)
            if col=="se" and v<0:fail("negative SE")
            if col=="n_unweighted" and (v<1 or int(v)!=v):fail("bad N")
        if not row["sample_id"] or not row["source"]:
            fail("missing sample or provenance")
    return rows
def encode(rows):
    columns={}
    keys=sorted({k for row in rows for k in row})
    for key in keys:
        values=[]; indices=[]; lookup={}
        for row in rows:
            if key not in row:
                indices.append(-1);continue
            value=row[key]
            marker=json.dumps(value,sort_keys=True,ensure_ascii=False)
            if marker not in lookup:
                lookup[marker]=len(values);values.append(value)
            indices.append(lookup[marker])
        columns[key]={"values":values,"indices":indices}
    return {"format":"column-dictionary-v1","length":len(rows),"columns":columns}
def build(repo,bundle,grid_file,out,release=False,receipt=None):
    if out.exists():fail("candidate output exists; preserve immutable attempt")
    common=list(csv.DictReader((bundle/"COMMON42_REGISTER.csv").open(
        encoding="utf-8-sig",newline="")))
    dashboard=[x for x in common if x["common42_member"].upper()=="TRUE"]
    codes=[x["route_code"] for x in dashboard]
    if len(codes)!=42 or len(set(codes))!=42 or "NLD" not in codes:
        fail("dashboard42 scope changed")
    rows=valid_rows(grid_file,set(codes))
    if release:
        if receipt is None or not receipt.exists():fail("release receipt missing")
        data=json.loads(receipt.read_text(encoding="utf-8"))
        if data.get("scientific_status")!="PASS" or data.get("rights_status")!="PASS" or data.get("Q01_Q08")!="PASS" or data.get("dashboard_42")!="PASS":
            fail("scientific/rights/Q01-Q08/42-system release gates incomplete")
        if set(row["country"] for row in rows)!=set(codes):
            fail("complete 42-system data coverage missing")
    if not rows:fail("no independently validated country results")
    out.mkdir(parents=True,exist_ok=False)
    app=repo/"03_dashboard"/"app"
    for filename in ("index.html","downloads.html"):
        shutil.copy2(app/filename,out/filename)
    for d in ("assets","docs"):
        shutil.copytree(app/d,out/d)
    data=out/"product_data";countries=data/"countries"
    countries.mkdir(parents=True)
    by_country={c:[] for c in codes}
    for row in rows:
        r={k:v for k,v in row.items() if k not in
          ("scientific_status","cell_id","sample_id")}
        r["id"]=row["cell_id"]
        r["country_id"]="iso3:"+row["country"]
        r["status"]="descriptive"
        r["estimate"]=float(row["estimate"]);r["se"]=float(row["se"])
        r["n_unweighted"]=int(float(row["n_unweighted"]))
        for col in ("ci_low","ci_high"):
            r[col]=float(row[col]) if row.get(col) else None
        r["year"]=str(row["year"])
        by_country[row["country"]].append(r)
    for country,records in by_country.items():
        (countries/f"iso3_{country}.json").write_text(
          json.dumps(encode(records),ensure_ascii=False,
                     separators=(",",":"),allow_nan=False),encoding="utf-8")
    meta={"countries":[{"country_id":x["country_id"],
           "country_name_nl":x["country_name_nl"],
           "country_name_en":x["country_name_en"]}
           for x in dashboard],"panels":{}}
    payloads={"metadata":meta,"ranks":[],"curated":{"slides":[]},
              "institutions":[],"quality":[]}
    # Existing static frontend has these five explicit data-contract slots.
    # Rank and curated products need their own approved release artifacts:
    # an empty slot is never silently replaced by 2026-09-28 old results.
    for name,value in payloads.items():
        (data/(name+".json")).write_text(json.dumps(value,ensure_ascii=False),
                    encoding="utf-8")
    # A new public release is not built until comparative/curated/quality
    # content is also validated. This module makes a reviewable private draft.
    status={"mode":"PRIVATE_CANDIDATE_NOT_PUBLISHED",
      "science_rows":len(rows),"systems_with_results":sum(bool(x) for x in by_country.values()),
      "dashboard_systems":42,"comparators_precomputed":False,
      "rank_release":"HOLD","curated_21_slides":"HOLD",
      "scientific_release_requested":bool(release)}
    (out/"DASHBOARD_GATE.json").write_text(json.dumps(status,indent=2),
                                           encoding="utf-8")
    index=out/"index.html"
    html=index.read_text(encoding="utf-8")
    html=html.replace("Privéversie · 28-09-2026",
       "Nieuwe onderzoeksvoorvertoning · NIET GEPUBLICEERD")
    index.write_text(html,encoding="utf-8")
    manifest=[]
    for path in sorted(out.rglob("*")):
        if not path.is_file():continue
        if path.suffix.lower() in FORBIDDEN:fail("forbidden source extension")
        rel=path.relative_to(out).as_posix()
        manifest.append({"path":rel,"sha256":sha(path),
                         "bytes":path.stat().st_size})
    (out/"BUILD_SHA256_MANIFEST.json").write_text(json.dumps(manifest,indent=2),
                                                   encoding="utf-8")
    return status
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--repo",type=Path,required=True)
    p.add_argument("--bundle",type=Path,required=True)
    p.add_argument("--validated-grid",type=Path,required=True)
    p.add_argument("--output",type=Path,required=True)
    p.add_argument("--release",action="store_true")
    p.add_argument("--receipt",type=Path)
    args=p.parse_args()
    status=build(args.repo,args.bundle,args.validated_grid,
                 args.output,release=args.release,receipt=args.receipt)
    print(json.dumps(status,sort_keys=True))
if __name__=="__main__":main()
