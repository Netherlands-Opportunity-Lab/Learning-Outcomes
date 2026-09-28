#!/usr/bin/env python3
"""Rebuild public release registers and verify public-to-freeze fidelity.

This script does not compute scientific estimates. It compares the controlled
public runtime against the final dashboard package and its frozen
RESULTATEN_MASTER, then writes publication registers.
"""
from pathlib import Path
import argparse, csv, gzip, hashlib, io, json, zipfile

ANALYSIS_RELEASE="FINAL_ANALYSIS_FREEZE_20260928"
PUBLIC_RELEASE="PUBLIC_DASHBOARD_20260928_FINAL"
FIELDS=[
 "id","country","survey","domain","year","stat","group","definition","unit",
 "estimate","se","ci_low","ci_high","edition","variant","family","source",
 "table","cell","se_cell","start_year","status","note","method","population",
 "original_estimate","original_se","sample","series_key"
]
RANK_FIELDS=["panel_id","wave","country_id","n","estimate","se","point_rank",
             "rank_best","rank_worst","familywise_alpha","method"]
PANEL_FIELDS=["panel_id","type","metric","n","waves","admission_rule",
              "quality_rule","scientific_status","_source","_id","members"]
BLOCKED={"product_data/FINAL_PRODUCT_BASIS.csv.gz",
         "product_data/RESULTATEN_MASTER.csv.gz"}

def sha(b): return hashlib.sha256(b).hexdigest()
def canon(v):
    if v is None: return ""
    if isinstance(v,(dict,list)):
        return json.dumps(v,ensure_ascii=False,sort_keys=True,separators=(",",":"))
    return str(v)

def expand_country(obj):
    if obj.get("format")!="column-dictionary-v1":
        raise ValueError("Unsupported country data contract")
    rows=[{} for _ in range(obj["length"])]
    for key,col in obj["columns"].items():
        vals=col["values"]
        for row_idx,val_idx in enumerate(col["indices"]):
            if val_idx>=0:
                rows[row_idx][key]=vals[val_idx]
    return rows

def fp_rows(rows,fields):
    h=hashlib.sha256()
    for row in rows:
        h.update(("\x1f".join(canon(row.get(f,"")) for f in fields)+"\n").encode())
    return h.hexdigest()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--runtime-zip",required=True)
    ap.add_argument("--final-dashboard-zip",required=True)
    ap.add_argument("--git-base-sha",required=True)
    ap.add_argument("--output-dir",required=True)
    args=ap.parse_args()
    out=Path(args.output_dir); out.mkdir(parents=True,exist_ok=True)

    with zipfile.ZipFile(args.final_dashboard_zip) as zf:
        master_txt=gzip.decompress(
            zf.read("dashboard/product_data/RESULTATEN_MASTER.csv.gz")
        ).decode("utf-8-sig")
        master_rows=list(csv.DictReader(io.StringIO(master_txt)))
        master={r["id"]:r for r in master_rows}
        full_meta=json.loads(zf.read("dashboard/product_data/metadata.json"))
        full_ranks=json.loads(zf.read("dashboard/product_data/ranks.json"))
        full_quality=json.loads(zf.read("dashboard/product_data/quality.json"))
        full_curated=json.loads(zf.read("dashboard/product_data/curated.json"))

    with zipfile.ZipFile(args.runtime_zip) as zf:
        names=sorted(n for n in zf.namelist() if not n.endswith("/"))
        public={n:zf.read(n) for n in names}

    country_files=[n for n in names if n.startswith("product_data/countries/") and n.endswith(".json")]
    total=missing=mismatches=0
    for name in country_files:
        rows=expand_country(json.loads(public[name]))
        total+=len(rows)
        for row in rows:
            rid=canon(row.get("id"))
            frozen=master.get(rid)
            if frozen is None:
                missing+=1
                continue
            for field in FIELDS:
                pv=canon(row.get(field,"")); fv=canon(frozen.get(field,""))
                if field=="sample":
                    try:
                        pv=canon(json.loads(pv)) if pv else ""
                        fv=canon(json.loads(fv)) if fv else ""
                    except Exception:
                        pass
                if pv!=fv: mismatches+=1

    public_ranks=json.loads(public["product_data/ranks.json"])
    public_meta=json.loads(public["product_data/metadata.json"])
    public_quality=json.loads(public["product_data/quality.json"])
    public_curated=json.loads(public["product_data/curated.json"])
    panel_rows=lambda m:[m["panels"][k] for k in sorted(m["panels"])]

    with zipfile.ZipFile(args.final_dashboard_zip) as zf:
        byte_mismatches=0
        for name,b in public.items():
            frozen_name="dashboard/"+name
            if frozen_name not in zf.namelist() or zf.read(frozen_name)!=b:
                byte_mismatches+=1

    result={
      "release":PUBLIC_RELEASE,
      "analysis_release":ANALYSIS_RELEASE,
      "git_base_sha":args.git_base_sha,
      "country_profile_files":len(country_files),
      "country_profile_rows_compared":total,
      "missing_result_ids":missing,
      "field_mismatches":mismatches,
      "fields_compared":FIELDS,
      "ranks":{"rows":len(public_ranks),
               "public_fingerprint":fp_rows(public_ranks,RANK_FIELDS),
               "freeze_fingerprint":fp_rows(full_ranks,RANK_FIELDS),
               "pass":public_ranks==full_ranks},
      "panels":{"panels":len(public_meta["panels"]),
                "public_fingerprint":fp_rows(panel_rows(public_meta),PANEL_FIELDS),
                "freeze_fingerprint":fp_rows(panel_rows(full_meta),PANEL_FIELDS),
                "pass":panel_rows(public_meta)==panel_rows(full_meta)},
      "quality":{"rows":len(public_quality),"pass":public_quality==full_quality},
      "curated":{"pass":public_curated==full_curated},
      "runtime_files":len(public),
      "runtime_file_byte_mismatches":byte_mismatches,
    }
    result["pass"]=(
      missing==0 and mismatches==0 and result["ranks"]["pass"]
      and result["panels"]["pass"] and result["quality"]["pass"]
      and result["curated"]["pass"] and byte_mismatches==0
    )
    (out/"PUBLIC_RESULT_FIDELITY.json").write_text(
        json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    if not result["pass"]:
        raise SystemExit("FAIL: public-to-freeze fidelity mismatch")
    print("PASS",json.dumps({k:v for k,v in result.items()
                              if k not in {"fields_compared"}},ensure_ascii=False))

if __name__=="__main__":
    main()
