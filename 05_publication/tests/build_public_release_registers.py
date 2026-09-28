#!/usr/bin/env python3
"""Generate final public-dashboard registers and verify fidelity.

This script never estimates scientific quantities. It:
1. inventories the controlled public runtime;
2. applies the publication gate;
3. compares every public country/system result row to the frozen result master;
4. compares precomputed ranks/panels/quality/curated metadata to the final dashboard;
5. writes the public manifest, gate, fidelity evidence and QA report.

The full final dashboard ZIP is an input because its bulk result masters are
intentionally not committed to the public repository.
"""
from pathlib import Path
import argparse,csv,gzip,hashlib,io,json,zipfile

ANALYSIS="FINAL_ANALYSIS_FREEZE_20260928"
RELEASE="PUBLIC_DASHBOARD_20260928_FINAL"
SCIENCE_SHA="749a0de8e6ab707f4ecd887247ea8fde82f55656"
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
MASTERS={"product_data/FINAL_PRODUCT_BASIS.csv.gz","product_data/RESULTATEN_MASTER.csv.gz"}
NON_RUNTIME_CONTROL={
 "product_data/FINAL_IMPACT_MATRIX.csv",
 "product_data/FINAL_OPEN_POINTS_STATUS.csv",
 "product_data/FINAL_TECHNICAL_VALIDATION.csv",
 "product_data/FINAL_USE_STATUS_REGISTER.csv"
}

def sha(b): return hashlib.sha256(b).hexdigest()
def canon(v):
    if v is None:return ""
    if isinstance(v,(dict,list)):
        return json.dumps(v,ensure_ascii=False,sort_keys=True,separators=(",",":"))
    return str(v)
def expand_country(obj):
    if obj.get("format")!="column-dictionary-v1":
        raise ValueError("unsupported country data contract")
    rows=[{} for _ in range(obj["length"])]
    for key,col in obj["columns"].items():
        vals=col["values"]
        for row_idx,val_idx in enumerate(col["indices"]):
            if val_idx>=0: rows[row_idx][key]=vals[val_idx]
    return rows
def fingerprint(rows,fields):
    h=hashlib.sha256()
    for row in rows:
        h.update(("\x1f".join(canon(row.get(f,"")) for f in fields)+"\n").encode())
    return h.hexdigest()
def classify(file):
    if file in MASTERS:
        return ("PUBLIC_SUMMARY_ONLY","EXCLUDED","complete_derived_master",ANALYSIS,
                "Complete derived bulk master is documented by size/hash only; bytes are not part of the public site.")
    if file in NON_RUNTIME_CONTROL:
        return ("PUBLIC_OK","NOT_USED_BY_SITE","project_control_metadata",ANALYSIS+":release registers",
                "Safe project-authored control metadata remains in the repository but is not needed by the public site runtime.")
    if file.startswith("product_data/countries/"):
        return ("PUBLIC_OK","INCLUDED","aggregate_country_profile",ANALYSIS+":RESULTATEN_MASTER country/system subset",
                "Frozen aggregate records required for interactive country/system views.")
    if file=="product_data/ranks.json":
        return ("PUBLIC_OK","INCLUDED","precomputed_ranks",ANALYSIS+":panel/rank release",
                "Frozen precomputed ranks; browser never recalculates ranks.")
    if file=="product_data/metadata.json":
        return ("PUBLIC_OK","INCLUDED","methods_panels_sources_metadata",ANALYSIS+":panel/source registers",
                "Frozen panel N/membership, source and methods metadata required for interpretation.")
    if file=="product_data/quality.json":
        return ("PUBLIC_OK","INCLUDED","aggregate_quality_metadata",ANALYSIS+":quality/representativeness registers",
                "Frozen aggregate quality and representativeness metadata.")
    if file=="product_data/curated.json":
        return ("PUBLIC_OK","INCLUDED","curated_product_mapping","FINAL_PROJECT_PRODUCTS_HANDOFF:figure/presentation registers",
                "Frozen product/figure mapping used by public presentation.")
    if file=="product_data/institutions.json":
        return ("PUBLIC_OK","INCLUDED","institutional_context_metadata","FINAL_PROJECT_PRODUCTS_HANDOFF:institutional context register",
                "Frozen project-authored institutional context metadata fetched by the dashboard.")
    if file.startswith("product_figures/") and file.endswith(".svg"):
        return ("PUBLIC_OK","INCLUDED","project_authored_vector_figure","FINAL_PROJECT_PRODUCTS_HANDOFF:figure release",
                "Project-authored vector figure based on frozen aggregates.")
    if file.startswith("product_figures/") and file.endswith(".csv"):
        return ("PUBLIC_OK","INCLUDED","figure_level_aggregate_data","FINAL_PROJECT_PRODUCTS_HANDOFF:figure data map",
                "Small aggregate data file directly supporting a project-authored figure.")
    return ("PUBLIC_OK","INCLUDED","public_runtime_asset","FINAL_DASHBOARD_RELEASE_20260928",
            "Frozen public runtime asset.")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--runtime-zip",required=True)
    ap.add_argument("--final-dashboard-zip",required=True)
    ap.add_argument("--git-base-sha",required=True)
    ap.add_argument("--production-manifest",default="03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv")
    ap.add_argument("--output-dir",default="05_publication")
    args=ap.parse_args()
    out=Path(args.output_dir);out.mkdir(parents=True,exist_ok=True)

    prod=list(csv.DictReader(open(args.production_manifest,encoding="utf-8")))
    prod_by_file={r["file"]:r for r in prod}

    with zipfile.ZipFile(args.runtime_zip) as zf:
        runtime_names=sorted(n for n in zf.namelist() if not n.endswith("/"))
        runtime={n:zf.read(n) for n in runtime_names}
    expected_runtime={r["file"] for r in prod if classify(r["file"])[1]=="INCLUDED"}
    if set(runtime_names)!=expected_runtime:
        raise SystemExit("runtime inventory does not equal minimal INCLUDED gate")

    with zipfile.ZipFile(args.final_dashboard_zip) as zf:
        master_txt=gzip.decompress(zf.read("dashboard/product_data/RESULTATEN_MASTER.csv.gz")).decode("utf-8-sig")
        master_rows=list(csv.DictReader(io.StringIO(master_txt)));master={r["id"]:r for r in master_rows}
        full_meta=json.loads(zf.read("dashboard/product_data/metadata.json"))
        full_ranks=json.loads(zf.read("dashboard/product_data/ranks.json"))
        full_quality=json.loads(zf.read("dashboard/product_data/quality.json"))
        full_curated=json.loads(zf.read("dashboard/product_data/curated.json"))
        byte_mismatches=[]
        for name,b in runtime.items():
            frozen="dashboard/"+name
            if frozen not in zf.namelist() or zf.read(frozen)!=b: byte_mismatches.append(name)

    # Field-level result fidelity.
    missing=mismatches=total=0
    for name in [n for n in runtime_names if n.startswith("product_data/countries/") and n.endswith(".json")]:
        for row in expand_country(json.loads(runtime[name])):
            total+=1; rid=canon(row.get("id")); frozen=master.get(rid)
            if frozen is None: missing+=1; continue
            for field in FIELDS:
                pv=canon(row.get(field,""));fv=canon(frozen.get(field,""))
                if field=="sample":
                    try:
                        pv=canon(json.loads(pv)) if pv else ""
                        fv=canon(json.loads(fv)) if fv else ""
                    except Exception: pass
                if pv!=fv:mismatches+=1

    ranks=json.loads(runtime["product_data/ranks.json"])
    meta=json.loads(runtime["product_data/metadata.json"])
    quality=json.loads(runtime["product_data/quality.json"])
    curated=json.loads(runtime["product_data/curated.json"])
    panel_rows=lambda m:[m["panels"][k] for k in sorted(m["panels"])]

    fidelity={
      "release":RELEASE,"analysis_release":ANALYSIS,"git_base_sha":args.git_base_sha,
      "comparison_scope":{"country_profile_files":sum(n.startswith("product_data/countries/") for n in runtime_names),
         "country_profile_rows":total,"fields":FIELDS,"ranks_rows":len(ranks),
         "panels":len(meta["panels"]),"quality_rows":len(quality),"public_runtime_files":len(runtime_names)},
      "publication_only_runtime_minimisation":{"removed_not_required_by_frontend":sorted(NON_RUNTIME_CONTROL),
         "reason":"Not fetched or linked by the public frontend; omitted without changing scientific result rows."},
      "results":{"missing_result_ids":missing,"country_profile_field_mismatches":mismatches,
         "rank_fingerprint_public":fingerprint(ranks,RANK_FIELDS),"rank_fingerprint_freeze":fingerprint(full_ranks,RANK_FIELDS),
         "panel_fingerprint_public":fingerprint(panel_rows(meta),PANEL_FIELDS),"panel_fingerprint_freeze":fingerprint(panel_rows(full_meta),PANEL_FIELDS),
         "ranks_match":ranks==full_ranks,"panels_match":panel_rows(meta)==panel_rows(full_meta),
         "quality_match":quality==full_quality,"curated_mapping_match":curated==full_curated,
         "runtime_file_byte_mismatches":len(byte_mismatches)},
    }
    fidelity["pass"]=(missing==0 and mismatches==0 and fidelity["results"]["ranks_match"]
                      and fidelity["results"]["panels_match"] and fidelity["results"]["quality_match"]
                      and fidelity["results"]["curated_mapping_match"] and not byte_mismatches)

    # Gate.
    gate=[]
    for r in prod:
        status,usage,kind,prov,reason=classify(r["file"])
        gate.append({"filename":r["file"],"site_usage":usage,"classification":status,"kind":kind,
                     "bytes":r["bytes"],"sha256":r["sha256"],"reason":reason,"provenance_id":prov})
    gate.extend([
      {"filename":"official OECD/IEA pupil/source files","site_usage":"EXCLUDED","classification":"DO_NOT_PUBLISH","kind":"restricted_source_data","bytes":"","sha256":"","reason":"Source/provider terms; public site is not a source-data mirror.","provenance_id":"OECD/IEA official source registry"},
      {"filename":"pupil/school microdata","site_usage":"EXCLUDED","classification":"DO_NOT_PUBLISH","kind":"microdata","bytes":"","sha256":"","reason":"Never published; privacy and source terms.","provenance_id":"local official PUFs"},
      {"filename":"replicate/analysis caches","site_usage":"EXCLUDED","classification":"PRIVATE_REPRODUCIBILITY_ONLY","kind":"analysis_cache","bytes":"","sha256":"","reason":"Controlled reproducibility only.","provenance_id":"local final analysis cache registry"},
      {"filename":"private source inventories","site_usage":"EXCLUDED","classification":"PRIVATE_REPRODUCIBILITY_ONLY","kind":"private_inventory","bytes":"","sha256":"","reason":"May contain private/local filenames or paths.","provenance_id":"local source inventory"},
      {"filename":"chat transcripts/personal files","site_usage":"EXCLUDED","classification":"DO_NOT_PUBLISH","kind":"personal_content","bytes":"","sha256":"","reason":"Not part of scientific release; may contain personal information.","provenance_id":"project history only"},
      {"filename":"credentials/tokens/.env/private keys","site_usage":"EXCLUDED","classification":"DO_NOT_PUBLISH","kind":"credentials","bytes":"","sha256":"","reason":"Security boundary.","provenance_id":"none"},
      {"filename":"user-specific absolute paths","site_usage":"EXCLUDED","classification":"DO_NOT_PUBLISH","kind":"local_paths","bytes":"","sha256":"","reason":"Privacy/reproducibility boundary; public assets contain none.","provenance_id":"sanitised code only"},
      {"filename":"assessment items/reading passages/questionnaire reproductions/copied IEA figures","site_usage":"EXCLUDED","classification":"DO_NOT_PUBLISH","kind":"third_party_content","bytes":"","sha256":"","reason":"Not required; source/reproduction rights restricted or uncertain.","provenance_id":"OECD/IEA source materials"}
    ])
    cols=["filename","site_usage","classification","kind","bytes","sha256","reason","provenance_id"]
    with (out/"PUBLIC_DATA_GATE.csv").open("w",newline="",encoding="utf-8") as f:
        w=csv.DictWriter(f,fieldnames=cols);w.writeheader();w.writerows(gate)

    # Public manifest contains actual site runtime plus summary-only bulk masters.
    files=[]
    for name in runtime_names:
        r=prod_by_file[name];files.append({"filename":name,"bytes":int(r["bytes"]),"sha256":r["sha256"],
          "publication_status":"PUBLIC_OK","source_provenance_id":classify(name)[3]})
    for name in sorted(MASTERS):
        r=prod_by_file[name];files.append({"filename":name,"bytes":int(r["bytes"]),"sha256":r["sha256"],
          "publication_status":"PUBLIC_SUMMARY_ONLY","source_provenance_id":ANALYSIS})
    rb=Path(args.runtime_zip).read_bytes()
    manifest={"release":RELEASE,"analysis_release":ANALYSIS,"git_base_sha":args.git_base_sha,
      "dashboard_release_date":"2026-09-28","canonical_dashboard_source":"03_dashboard/app/",
      "public_layer":"05_publication/","runtime_transport":"05_publication/public_dashboard_runtime_20260928.zip",
      "runtime_transport_bytes":len(rb),"runtime_transport_sha256":sha(rb),"public_runtime_file_count":len(runtime_names),
      "publication_rule":"Minimal frozen aggregate runtime only; no source microdata, caches or full bulk masters.",
      "files":files}
    (out/"PUBLIC_DASHBOARD_MANIFEST.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    (out/"PUBLIC_RESULT_FIDELITY.json").write_text(json.dumps(fidelity,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

    qa=f"""# Public dashboard integration QA — 28 September 2026

- Scientific/product lock: `{SCIENCE_SHA}`
- Analysis release: `{ANALYSIS}`
- Integration base SHA: `{args.git_base_sha}`
- Public runtime files: {len(runtime_names)}
- Runtime bytes: {len(rb)}
- Runtime SHA-256: `{sha(rb)}`
- Published country/system result rows compared: {total:,}
- Missing result IDs: {missing}
- Field mismatches: {mismatches}
- Rank rows: {len(ranks):,} — {'PASS' if ranks==full_ranks else 'FAIL'}
- Panels: {len(meta['panels']):,} — {'PASS' if panel_rows(meta)==panel_rows(full_meta) else 'FAIL'}
- Quality rows: {len(quality):,} — {'PASS' if quality==full_quality else 'FAIL'}
- Runtime byte mismatches against definitive dashboard source files: {len(byte_mismatches)}

No estimate, SE, CI, rank or scientific aggregate is recomputed for publication.

## Result
**{'PASS' if fidelity['pass'] else 'FAIL'}**
"""
    (out/"PUBLICATION_QA_REPORT_20260928_FINAL.md").write_text(qa,encoding="utf-8")
    if not fidelity["pass"]:raise SystemExit("FAIL: public-to-freeze fidelity mismatch")
    print("PASS: public release registers generated and fidelity verified")

if __name__=="__main__":
    main()
