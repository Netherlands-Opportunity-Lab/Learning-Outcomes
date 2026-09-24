#!/usr/bin/env python3
"""Build browser profiles from frozen aggregate CSVs; never estimate or rank."""
from pathlib import Path
import csv, json, hashlib, shutil, re
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'source_snapshot'; OUT=ROOT/'data'
NUMERIC={'year','panel_n','rank','rank_n','estimate','se','ci_low','ci_high',
 'estimate_age10','estimate_age15','se_age10','se_age15','change_age15_minus_age10',
 'change_se_independent_proxy','pair_n','fractional_rank','benchmark_value',
 'benchmark_equal_country_mean','difference_from_benchmark','population_share_pct',
 'population_share_se_pct','nl_estimate','nl_se','reference_equal_country_mean',
 'reference_se_independent_proxy','nl_minus_reference','difference_se_independent_proxy',
 'n_students','n_schools','overall_exclusion_rate_pct','school_response_before_pct',
 'school_response_after_pct','student_response_pct','weighted_share_group1',
 'weighted_share_group0','se_share_group1','ci_low_share_group1','ci_high_share_group1',
 'missing_weighted_share','change','start_year','end_year','coverage_index3',
 'overall_response_after_pct','overall_response_before_pct','reported_mean_age','level_rank','level_fractional_rank'}
def read(name):
 rows=list(csv.DictReader((Path(name) if Path(name).is_absolute() else SOURCE/name).open(encoding='utf-8-sig',newline='')))
 for row in rows:
  for key,val in list(row.items()):
   if val=='':row[key]=None
   elif val.lower() in {'true','false'}:row[key]=val.lower()=='true'
   elif key in NUMERIC:
    try:row[key]=float(val) if '.' in val or 'e' in val.lower() else int(val)
    except ValueError:pass
 return rows
def dump(path,data):
 path.parent.mkdir(parents=True,exist_ok=True)
 path.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'),allow_nan=False)+'\n',encoding='utf-8')
tables={p.name:read(p.name) for p in SOURCE.glob('*.csv')}
if (OUT/'csv').exists():shutil.rmtree(OUT/'csv')
(OUT/'csv').mkdir(parents=True,exist_ok=True)
for file in SOURCE.glob('*.csv'):shutil.copyfile(file,OUT/'csv'/file.name)
bridges=tables['comparison_geography_bridges.csv']
def belongs(row,cid):
 if row.get('country_id')==cid:return True
 for bridge in bridges:
  if bridge['comparison_country_id']!=cid or bridge['observation_country_id']!=row.get('country_id'):continue
  if row.get('survey') and row['survey']!=bridge['survey']:continue
  year=row.get('year')
  if year is not None and not int(bridge['valid_from'])<=int(year)<=int(bridge['valid_to']):continue
  return True
 return False
mapping={'observations':'observations.csv','comparisons':'comparisons.csv',
 'latest_ses':'latest_wave_identical_ses_gap_rankings.csv','latest_levels':'latest_wave_identical_ses_group_levels.csv',
 'representativeness':'representativeness.csv','sorting':'cross_age_sorting_panel_views.csv',
 'international_escs':'international_escs_reading_2025.csv','main12':'PIRLS_MAIN12_FIXED_OBSERVATION_VIEWS.csv',
 'pirls_social':'PIRLS_RC1_SOCIAL_SORTING_RESULTS.csv','pirls_academic':'PIRLS_RC1_ACADEMIC_SORTING_RESULTS.csv',
 'pisa_social':'PISA_RC1_SOCIAL_SORTING_RESULTS.csv','pisa_academic':'PISA_RC1_SES_AND_ACADEMIC_RESULTS.csv',
 'demographic_pirls':'demographic_pirls_sorting.csv','demographic_pisa':'PISA_DEMOGRAPHIC_SORTING_THEIL_H.csv',
 'demographic_cross_age':'demographic_cross_age_changes.csv','official_changes':'official_reading_changes_to2025.csv'}
rank_addendum=read(str(ROOT/'addenda/LATEST_GROUP_LEVEL_RANKS.csv'))
domain_addendum=read(str(ROOT/'addenda/NL_DOMAIN_MEANS_CONDITIONAL.csv'))
countries=tables['countries.csv']
for country in countries:
 cid=country['country_id']
 profile={'meta':country,**{key:[r for r in tables[table] if belongs(r,cid)] for key,table in mapping.items()}}
 profile['latest_level_ranks']=[r for r in rank_addendum if belongs(r,cid)]
 country['profile_file']='profiles/'+re.sub(r'[^\w-]','_',cid)+'.json'
 dump(OUT/'json'/country['profile_file'],profile)
dump(OUT/'json/countries.json',countries)
dump(OUT/'json/domain_context.json',domain_addendum)
for file in (ROOT/'addenda').glob('*.csv'):shutil.copyfile(file,OUT/'csv'/file.name)
dump(OUT/'json/metadata.json',{key:tables[key+'.csv'] for key in ['panels','module_status','sources','caveats','groups','comparison_geography_bridges']})
dump(OUT/'json/nl_international_reference.json',tables['international_escs_NL_fixed_reference.csv'])
dump(OUT/'json/international.json',{'latest_ses':tables['latest_wave_identical_ses_gap_rankings.csv'],'latest_levels':tables['latest_wave_identical_ses_group_levels.csv'],'sorting':tables['cross_age_sorting_panel_views.csv']})
dump(OUT/'json/release.json',{'release_id':'dashboard-step4-20260924','analysis_release':'ANALYSIS_RELEASE_RC1_20260922_v3',
 'scope':'reading_complete_available_aggregates','domain_status':{'reading':'conditional','math':'limited_NL_overall_context_only','science':'limited_NL_overall_context_only'},
 'raw_microdata_included':False,'scientific_computation_frontend':False,
 'public_deployment':'not_activated_IEA_rights_condition_C001',
 'panel_policy':{'latest_default':'N45_max_available_conditional_user_requested','quality_sensitivity':'N43_without_ALB_USA','exact_id_sensitivity':'N44'},
 'source_year_status':'PISA2025 official release confirmed by parent audit; retained as 2025',
 'figure_status':'Revised figures integrated separately; legacy empty F09 and mixed-scale F04/F05 withdrawn',
 'not_a_new_scientific_freeze':True})
dump(OUT/'json/figures.json',json.loads((OUT/'json/figures.json').read_text()) if (OUT/'json/figures.json').exists() else [])
manifest=[{'file':p.name,'rows':len(tables[p.name]),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'source_release':'ANALYSIS_RELEASE_RC1_20260922_v3'} for p in sorted(SOURCE.glob('*.csv'))]
with (ROOT/'audit/SOURCE_MANIFEST.csv').open('w',newline='',encoding='utf-8') as f:
 w=csv.DictWriter(f,fieldnames=manifest[0]);w.writeheader();w.writerows(manifest)
print(f'Built {len(countries)} profiles from {len(tables)} frozen CSV tables. No ranks, estimates, gaps or panels recalculated.')
