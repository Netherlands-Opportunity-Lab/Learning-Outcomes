#!/usr/bin/env python3
"""Build the active bilingual guided source-eligible dashboard from the pinned
138-figure contract and independently validated aggregate product rows.

This module does not read student records, does not borrow September numeric
results, and never overwrites the live GitHub Pages release. Every missing
country/figure cell remains an explicit placeholder.
"""
from __future__ import annotations
import argparse,csv,hashlib,importlib.util,json,math,re,shutil
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
 names={"AUT":("Oostenrijk","Austria"),"CAN":("Canada","Canada"),"RUS":("Rusland","Russian Federation")}
 for r in members:
  for locale,index in (("nl",0),("en",1)):
   key="country_name_"+locale
   if r["country"] in names and r[key] in ("",r["country"]):r[key]=names[r["country"]][index]
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
   # A02 authorizes the appendix only, not an extra dashboard choice.
   # Numeric rows remain in the separately certified appendix export.
   continue
  elif family=="EN_PERFORMANCE_PEER":
   if decisions.get("A01")!="APPROVED":
    if decisions.get("A03")=="APPROVED":
     figure["active_role"]="APPROVED_HIGH_PEER";output.append(figure)
    continue
   if decisions.get("A03")=="APPROVED":
    high=dict(figure,figure_id=r["figure_id"].replace("EN_PERFORMANCE_PEER_","EN_PERFORMANCE_PEER_HIGH_",1),active_role="APPROVED_HIGH_PEER",
      expected_series="self_below_high;self_high;population_high_share")
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
  # The historical source_valid_* placeholders are not literal group names.
  # Only PISA's independently certified binary assessment-language construct
  # has one stable mapping here; do not coerce IEA frequency categories.
  if figure["survey"]=="PISA":
   if family in ("GP_SES_LEVELS","GP_SES_GAP","GP_SES_BASIC"):
    # The chosen Cobreros construct has four waves. Historical slide
    # templates must not request unapproved pre-2015 SES observations.
    # Full core-score anchors remain separate comparison requirements.
    figure["required_years"]="2015;2018;2022;2025"
   if family=="EN_SES_PEER":
    figure["required_years"]="2015;2018;2022;2025"
    figure["expected_series"]="q1_target_pct_q4_peers;q4_target_pct_q1_peers;population_q1_share;population_q4_share"
    figure["method_id"]="COBREROS_FOURWAVE_13ITEM_PEERS_AND_NATIONAL_BASELINES"
   if family=="GP_LANGUAGE_LEVELS" and figure["expected_series"]=="source_valid_groups":
    figure["expected_series"]="test_language_home;other_language_home"
   elif family=="GP_LANGUAGE_GAP" and figure["expected_series"]=="source_valid_contrast":
    figure["expected_series"]="other_minus_test"
  # Only documented vocabulary, with no fabricated science values.
  output.append(figure)
 # Expand ambiguous historical source placeholders into exact source/construct
 # contracts. This never removes a required year because observations are absent.
 exact=[]
 for f in output:
  family=f["figure_id"].split("_age",1)[0]
  sources=("PIRLS","TIMSS") if f["survey"]=="PIRLS_TIMSS" else (f["survey"],)
  for survey in sources:
   z=dict(f)
   if f["survey"]=="PIRLS_TIMSS":
    z.update(figure_id=f["figure_id"]+"_"+survey,survey=survey,
      required_years="2001;2006;2011;2016;2021" if survey=="PIRLS" else "2003;2007;2011;2015;2019;2023")
   if family=="EN_SES_PEER":
    z["expected_series"]="q1_target_pct_q4_peers;q4_target_pct_q1_peers;population_q1_share;population_q4_share"
   if family=="EN_LANGUAGE_PEER":
    z["expected_series"]=("other_language_target_pct_test_language_home_peers" if survey=="PISA" else "less_often_target_pct_always_almost_peers")+";population_test_language_share"
   if survey=="PISA" and family in ("EN_LANGUAGE_PEER","EN_MIGRATION_PEER"):
    z["required_years"]="2003;2006;2009;2012;2015;2018;2022;2025"
   if survey in ("PIRLS","TIMSS"):
    if family=="GP_LANGUAGE_LEVELS":z["expected_series"]="always_almost;sometimes_never"
    if family=="GP_LANGUAGE_GAP":z["expected_series"]="sometimes_never_minus_always_almost"
   if family in ("GP_MIGRATION_LEVELS","GP_MIGRATION_GAP","EN_MIGRATION_PEER"):
    z["expected_series"]={"GP_MIGRATION_LEVELS":"native;first_generation;second_generation","GP_MIGRATION_GAP":"first_minus_native;second_minus_native","EN_MIGRATION_PEER":"first_generation_target_pct_native_peers;second_generation_target_pct_native_peers"}[family]
    z["outcome_construct"]="MIGRATION_GENERATION_SOURCE_LABELLED"
    for definition,label in (("ANY_PARENT_ABROAD","ten minste één ouder buiten het land geboren"),("BOTH_PARENTS_ABROAD","beide ouders buiten het land geboren")):
     b=dict(z,figure_id=z["figure_id"]+"_"+definition,outcome_construct="MIGRATION_"+definition,
       expected_series={"GP_MIGRATION_LEVELS":"reference;migration","GP_MIGRATION_GAP":"migration_minus_reference","EN_MIGRATION_PEER":"migration_target_pct_reference_peers;population_reference_share"}[family])
     b["label_nl"]=z.get("label_nl","")+" — "+label
     exact.append(b)
   exact.append(z)
 return exact
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
  family=fid.split("_age",1)[0]
  if family in ("GP_MIGRATION_LEVELS","GP_MIGRATION_GAP","EN_MIGRATION_PEER") and (
      r.get("outcome_id")!=f.get("outcome_construct") or r["series_id"] not in f["expected_series"].split(";")):
   fail("migration source construct or group mismatch")
  if family=="EN_LANGUAGE_PEER" and (
      r.get("outcome_id") not in (("home_language_peer_exposure","same_as_assessment_language_vs_other") if f["survey"]=="PISA" else ("frequency_always_almost_vs_sometimes_never",)) or
      r["series_id"] not in f["expected_series"].split(";")):
   fail("home language peer construct mismatch")
  if f["survey"] in ("PIRLS","TIMSS") and family in ("GP_LANGUAGE_LEVELS","GP_LANGUAGE_GAP","EN_SES_PEER"):
   expected_construct="books5_fractional" if family=="EN_SES_PEER" else "frequency_always_almost_vs_sometimes_never"
   if r.get("outcome_id")!=expected_construct or r["series_id"] not in f["expected_series"].split(";"):
    fail("IEA source construct or group mismatch")
  if f["survey"]=="PISA" and fid.split("_age",1)[0]=="EN_SES_PEER":
   if (r.get("outcome_id")!="Cobreros_fourwave_13item_trend_comparable" or
       r["series_id"] not in f["expected_series"].split(";")):
    fail("PISA SES peer construct or contextual baseline mismatch")
  if r["scientific_status"]!="SCIENTIFICALLY_VALIDATED":
   fail("unreviewed numeric row for "+fid)
  if f["survey"]=="PISA" and fid.split("_age",1)[0] in ("GP_LANGUAGE_LEVELS","GP_LANGUAGE_GAP"):
   if (r.get("outcome_id")!="same_as_assessment_language_vs_other" or
       r["series_id"] not in f["expected_series"].split(";")):
    fail("PISA language construct or group mismatch")
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
     cell_id=r.get("cell_id",""),
     estimate=estimate,n_unweighted=int(n),unit=f["unit"],
     series_id=r["series_id"],series_role=role,
     series_label_nl=r.get("series_label_nl",r["series_id"]),
     series_label_en=r.get("series_label_en",r["series_id"]),
     split_group=r.get("split_group",r["series_id"]),
     source_id=r["source_id"],method_id=f["method_id"],
     sample_id=r["sample_id"],input_fingerprint=r["input_fingerprint"],
     code_fingerprint=r["code_fingerprint"],result_hash=r["result_hash"],
     n_definition=r.get("n_definition") or "N_DEFINITION_NOT_REGISTERED",
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

def explorer_references(balance_path,countries,figures,rows,scientific_sha=None):
 """Bind certified comparison views to public figures through exact cell IDs.

 Absence of the new mapping is an explicit pending state, never permission
 to infer comparability from plotted values. All constituent views (including
 peer baseline definitions) must pass; their eligible sets are intersected.
 """
 def array(value):return [] if value is None else value if isinstance(value,list) else [value]
 evidence=json.loads(balance_path.read_text(encoding="utf-8-sig")) if balance_path else {}
 if evidence.get('schema_version')==3:
  spec=importlib.util.spec_from_file_location('reference_verify',Path(__file__).with_name('LO_DASHBOARD_REFERENCE_VERIFY.py'))
  verifier=importlib.util.module_from_spec(spec);spec.loader.exec_module(verifier)
  verifier.verify(evidence,rows,countries,figures,scientific_sha)
 raw_views=evidence.get("views")
 # jsonlite serializes the named list returned by split/lapply as an object.
 # Accept that documented v2 R representation as well as the v3 array. Treating
 # the object as one view silently lost every real focus/reference binding.
 if isinstance(raw_views,dict):
  if evidence.get('schema_version')!=2 or any(not isinstance(v,dict) or not v.get('focus') or not v.get('view_id') for v in raw_views.values()):
   fail('invalid named R reference views')
  views=list(raw_views.values())
 else:views=array(raw_views)
 output=[]
 # The immutable evidence file can be large; hash it once for the entire build.
 evidence_sha=sha(balance_path) if balance_path else None
 views_by_country=defaultdict(list)
 for view in views:views_by_country[view.get('focus')].append(view)
 combination_admission={(r['country'],r['survey'],r['domain']):bool(r['combination_pass'])
                        for r in array(evidence.get('combination_admission'))}
 by_country=defaultdict(lambda:defaultdict(list))
 for row in rows:
  if row["series_role"]=="focus":by_country[row["country_id"].split(":")[-1]][row["figure_id"]].append(row)
 for country in sorted(countries):
  for f in figures:
   current=by_country[country][f["figure_id"]]
   cell_ids={r.get("cell_id") for r in current if r.get("cell_id")}
   matches=[v for v in views_by_country[country] if (v.get('figure_id')==f['figure_id'] or
       not v.get('figure_id') and cell_ids.intersection(array(v.get("view_cell_ids"))))]
   if not matches and not current and f.get('historical_figure_id'):
    # An entirely unavailable split still has required target years. Use its
    # exact source contract/construct, never Dutch years or another definition.
    for v in views_by_country[country]:
     parts=v.get('view_id','').split('::')
     if (len(parts)==5 and parts[0]==f['historical_figure_id'] and parts[1]==f['survey']
         and (not f.get('outcome_construct') or parts[2]==f['outcome_construct'])):
      matches.append(v)
   mapped=set().union(*(set(array(v.get("view_cell_ids"))) for v in matches)) if matches else set()
   # Dutch templates do not define another focus country's period. The R
   # contracts retain its own full target years, including unavailable cells.
   required_years=f['required_years']
   if country!='NLD' and matches and all('required_years' in v for v in matches):
    required_years=';'.join(sorted({str(y) for v in matches for y in array(v['required_years'])}))
   focus_figure=dict(f,required_years=required_years)
   admitted=combination_admission.get((country,f['survey'],f['domain']),True)
   if f['domain']=='all' and combination_admission:
    admitted=any(ok for (c,s,d),ok in combination_admission.items() if (c,s)==(country,f['survey']))
   if not admitted:
    if current:fail('numeric product outside admitted age-domain combination')
    required_years=''
    focus_figure=dict(f,required_years='')
   ready=bool(matches) and len(cell_ids)==len(current) and cell_ids<=mapped and figure_complete(current,focus_figure)
   ready=ready and admitted
   ready=ready and all(v.get("status") in ("BALANCED_REFERENCE_AVAILABLE","NO_ELIGIBLE_REFERENCE") for v in matches)
   eligible=set(countries)-{country};defaults=set(eligible)
   if ready:
    for v in matches:
     if v.get("focus_excluded") is not True or v.get("country_weights")!="EQUAL_PER_COUNTRY" or v.get("benchmark_uncertainty") is not False or not v.get("required_keys"):
      fail("invalid reference policy for "+country)
     options=array(v.get("options"))
     allowed={o["country"] for o in options if o.get("eligible") is True and o.get("dashboard_eligible") is True}
     eligible &= allowed
     defaults &= set(array(v.get("default_members")))
    # Publishing a member also requires a complete exact figure payload.
    eligible={c for c in eligible if figure_complete(by_country[c][f["figure_id"]],focus_figure)}
    defaults &= eligible
   else:eligible=set();defaults=set()
   reasons=[]
   for candidate in sorted(set(countries)-{country}):
    opts=[o for v in matches for o in array(v.get('options')) if o['country']==candidate]
    bad=[o for o in opts if not o.get('eligible')]
    keys=sorted(set(evidence['key_dictionary'][int(k)-1] if evidence.get('key_dictionary') else k
        for o in bad for k in o.get('missing_keys','').split(';') if k))
    reasons.append(dict(country=candidate,missing_cells=max((o.get('missing_cells',0) for o in bad),default=0),
      reason=bad[0]['reason'] if bad else 'FULL_BALANCED_SUPPORT' if candidate in eligible else 'FOCUS_NOT_READY',
      missing_examples=[dict(survey=k.split('|')[0],domain=k.split('|')[2],year=int(k.split('|')[3])) for k in keys[:3]]))
   pending=next((v['status'] for v in matches if v['status'] in ('AGE_DOMAIN_NOT_ADMITTED','FOCUS_CORE_INCOMPLETE','FOCUS_VIEW_INCOMPLETE')),
     'FOCUS_VIEW_INCOMPLETE' if matches and not figure_complete(current,focus_figure) else 'COMPARABILITY_PENDING')
   if not admitted:pending='AGE_DOMAIN_NOT_ADMITTED'
   output.append(dict(focus=country,figure_id=f["figure_id"],
     status="BALANCED_REFERENCE_AVAILABLE" if ready and eligible else "NO_ELIGIBLE_REFERENCE" if ready else pending,
     eligible_members=sorted(eligible),default_members=sorted(defaults),
     eligibility=reasons,
     evidence_sha256=evidence_sha,
     view_ids=sorted(v["view_id"] for v in matches),required_years=required_years,
     expected_series=f["expected_series"],focus_excluded=True,country_weights="EQUAL_PER_COUNTRY",benchmark_uncertainty=False))
 return dict(schema_version=1,policy="FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3",figures=output)

def provisional_references(policy_path,countries,figures,rows,input_sha):
 """Explicit temporary display policy; never a scientific comparability PASS."""
 policy=json.loads(policy_path.read_text(encoding='utf-8'))
 required=dict(mode='AVAILABLE_CASES_PROVISIONAL',authorization='USER_2026_10_18_TEMPORARY_AVAILABLE_RESULTS',
   country_membership='PER_YEAR_AND_SERIES',country_weights='EQUAL_PER_AVAILABLE_COUNTRY',
   cell_requirement='EXISTING_VALIDATED_PUBLIC_AGGREGATES',full_period_balance_required=False,
   show_contributors=True,final_scientific_policy='UNCHANGED')
 if any(policy.get(k)!=v for k,v in required.items()):fail('invalid temporary comparison policy')
 policy_sha=sha(policy_path)
 counts=defaultdict(int)
 for row in rows:
  if row['quality_status']!='SCIENTIFICALLY_VALIDATED':fail('unvalidated provisional input')
  counts[(row['country_id'].split(':')[-1],row['figure_id'])]+=1
 ids=sorted(c['route_code'] for c in countries)
 rich={c['route_code'] for c in countries if c.get('rich_candidate','').upper()=='TRUE'}
 output=[]
 for focus in ids:
  for f in figures:
   available=[c for c in ids if c!=focus and counts[c,f['figure_id']]>0]
   output.append(dict(focus=focus,figure_id=f['figure_id'],mode=policy['mode'],
    status='PROVISIONAL_REFERENCE_AVAILABLE' if available else 'NO_AVAILABLE_REFERENCE',
    eligible_members=available,default_members=sorted(set(available)&rich),
    eligibility=[dict(country=c,available_points=counts[c,f['figure_id']],reason='AVAILABLE_POINTS' if c in available else 'NO_AVAILABLE_POINTS') for c in ids if c!=focus],
    evidence_sha256=input_sha,reference_policy_sha256=policy_sha,
    required_years=f['required_years'],expected_series=f['expected_series'],
    focus_excluded=True,country_weights='EQUAL_PER_AVAILABLE_COUNTRY',benchmark_uncertainty=False,
    full_period_balance_verified=False))
 return dict(schema_version=1,policy=policy['mode'],figures=output)

def build(repo,bundle,destination,scientific_rows=None,synthetic_contract=False,
          unavailable_review=None,country_registry=None,scope_decisions=None,balance_export=None,reference_policy=None):
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
 if (source/"info").is_dir():shutil.copytree(source/"info",destination/"info")
 template=(source/"index.html").read_text(encoding="utf-8")
 (destination/"data"/"countries").mkdir(parents=True)
 (destination/"data"/"availability").mkdir(parents=True)
 (destination/"data"/"common42.json").write_text(json.dumps([
  {"code":r["route_code"],"nl":r["country_name_nl"],
   "en":r["country_name_en"]} for r in countries],ensure_ascii=False),
  encoding="utf-8",newline="\n")
 if balance_export is not None:
  shutil.copyfile(balance_export,destination/"data"/"balanced_references.json")
 if reference_policy is not None:
  shutil.copyfile(reference_policy,destination/'data/reference_policy.json')
  references=provisional_references(reference_policy,countries,figures,numeric_rows,sha(scientific_rows))
 else:
  references=explorer_references(balance_export,ids,figures,numeric_rows,sha(scientific_rows) if scientific_rows else None)
 (destination/'data/references').mkdir()
 for country in sorted(ids):
  (destination/f'data/references/{country}.json').write_text(json.dumps(dict(
     schema_version=1,policy=references['policy'],figures=[v for v in references['figures'] if v['focus']==country]),ensure_ascii=False),encoding='utf-8',newline='\n')
 (destination/"data"/"explorer_references.json").write_text(json.dumps(dict(
   schema_version=2,policy=references['policy'],country_files={c:f'data/references/{c}.json' for c in sorted(ids)}),ensure_ascii=False),encoding="utf-8",newline="\n")
 (destination/"data"/"figure_registry.json").write_text(
  json.dumps({"figures":figures},ensure_ascii=False),encoding="utf-8",newline="\n")
 method_ids=sorted({f["method_id"] for f in figures})
 method_text={m:{"nl":"Methode en bronversie: "+m+
                     "; zie gecontroleerd wetenschappelijk register.",
             "en":"Method and source edition: "+m+
                     "; consult the reviewed scientific register."}
              for m in method_ids}
 (destination/"data"/"method_registry.json").write_text(
  json.dumps({"methods":method_text},ensure_ascii=False),encoding="utf-8",newline="\n")
 availability_states=defaultdict(int)
 reference_by_view={(r['focus'],r['figure_id']):r for r in references['figures']}
 for country in sorted(ids):
  records=by_country[country]
  (destination/"data"/"countries"/(country+".json")).write_text(
   json.dumps({"records":records},ensure_ascii=False,allow_nan=False,
              separators=(",",":")),encoding="utf-8",newline="\n")
  present=defaultdict(list)
  for row in records:present[row["figure_id"]].append(row)
  available=[]
  for f in figures:
   current=present[f["figure_id"]]
   # Only a full year x group grid is VALIDATED. The user explicitly requested
   # verified partial points on 18 Oct; missing pairs remain named gaps and
   # never relax full-period reference or rank requirements.
   years={str(row["year"]) for row in current if row["series_role"]=="focus"}
   reference=reference_by_view[(country,f['figure_id'])]
   focus_figure=dict(f,required_years=reference.get('required_years',f['required_years']))
   required=set(x for x in focus_figure['required_years'].split(';') if x)
   roles=set(row["series_id"] for row in current if row["series_role"]=="focus")
   expected={x for x in f["expected_series"].split(";") if x}
   present_pairs={(str(row["year"]),row["series_id"]) for row in current if row["series_role"]=="focus"}
   fully=figure_complete(current,focus_figure)
   admitted=reference.get('status')!='AGE_DOMAIN_NOT_ADMITTED'
   reviewed=unavailable.get((country,f["figure_id"]))
   if reviewed and current:
    fail("cannot mark a figure unavailable while releasing numeric rows")
   st="UNAVAILABLE" if not admitted else "VALIDATED" if fully else ("PARTIAL" if current else "UNAVAILABLE" if reviewed else "PLACEHOLDER")
   availability_states[st]+=1
   reason_nl=("Minder dan drie vergelijkbare meetgolven voor deze leeftijd en uitkomst."
       if not admitted else "Alle vereiste meetjaren en groepen wetenschappelijk gecontroleerd."
       if fully else reviewed["reason_nl"] if reviewed else
       "De beschikbare punten zijn gecontroleerd. Ontbrekende meetjaren of groepen blijven open." if current else "Resultaten worden nog toegevoegd.")
   reason_en=("Fewer than three comparable survey waves for this age and outcome."
       if not admitted else "All required survey waves and groups scientifically validated."
       if fully else reviewed["reason_en"] if reviewed else
       "Available points are verified. Missing years or groups remain open." if current else "Results will be added.")
   available.append(dict(figure_id=f["figure_id"],display_state=st,
      reason_nl=reason_nl,reason_en=reason_en,available_points=len(present_pairs),
      required_points=len(required)*len(expected),
      missing_points=[dict(year=int(y),series_id=g) for y in sorted(required) for g in sorted(expected) if (y,g) not in present_pairs]))
  (destination/"data"/"availability"/(country+".json")).write_text(
   json.dumps({"figures":available},ensure_ascii=False),encoding="utf-8",newline="\n")
 for locale in ("nl","en"):
  for parts in ((locale,),*((locale,"country",c,q)
        for c in sorted(ids) for q in QUESTIONS)):
   folder=destination.joinpath(*parts)
   folder.mkdir(parents=True,exist_ok=True)
   base="../"*len(parts)
   (folder/"index.html").write_text(
     template.replace("__BASE__",base),encoding="utf-8",newline="\n")
 (destination/"index.html").write_text(
  '<!doctype html><meta charset="utf-8"><title>Learning Outcomes</title>'
  '<meta http-equiv="refresh" content="0; url=nl/">'
  '<a href="nl/">Nederlands</a> · <a href="en/">English</a>',
  encoding="utf-8",newline="\n")
 (destination/".nojekyll").write_text("",encoding="utf-8",newline="\n")
 (destination/"robots.txt").write_text("User-agent: *\nDisallow: /\n",encoding="utf-8",newline="\n")
 summary={"scientific_data_rows":len(numeric_rows),"system_count":len(ids),
   "active_figures":len(figures),
   "availability_counts":dict(sorted(availability_states.items())),
   "scientific_source_sha256":sha(scientific_rows) if scientific_rows else "NO_DATA",
   "figure_contract_sha256":sha(bundle/"FIGURE_SERIES_CONTRACT_20261002.csv"),
   "balanced_references_sha256":sha(balance_export) if balance_export else "MISSING",
   "reference_policy_sha256":sha(reference_policy) if reference_policy else "STRICT_BALANCE_DEFAULT",
   "reference_mode":references['policy'],
   "country_registry_sha256":sha(country_registry) if country_registry else "SYNTHETIC_ONLY",
   "scope_decisions_sha256":sha(scope_decisions) if scope_decisions else "PENDING_DEFAULT",
   "release_status":"PRIVATE_GUIDED_CANDIDATE_NOT_PUBLIC"}
 (destination/"GUIDED_QA.json").write_text(json.dumps(summary,indent=2),
                                          encoding="utf-8",newline="\n")
 entries=[]
 for path in sorted(destination.rglob("*")):
  if not path.is_file():continue
  if path.suffix.lower() in BAD_EXT:fail("unsafe public source file type")
  relative=path.relative_to(destination).as_posix()
  entries.append({"path":relative,"sha256":sha(path),
                  "bytes":path.stat().st_size})
 (destination/"BUILD_SHA256_MANIFEST.json").write_text(
  json.dumps(entries,indent=2),encoding="utf-8",newline="\n")
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
 p.add_argument("--reference-policy",type=Path)
 args=p.parse_args()
 print(json.dumps(build(args.repo,args.bundle,args.output,
                   args.validated_grid,
                   unavailable_review=args.reviewed_unavailable,country_registry=args.country_registry,
                   scope_decisions=args.scope_decisions,balance_export=args.balanced_references,
                   reference_policy=args.reference_policy),sort_keys=True))
if __name__=="__main__":main()
