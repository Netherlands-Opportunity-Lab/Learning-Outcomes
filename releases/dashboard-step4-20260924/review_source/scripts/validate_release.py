#!/usr/bin/env python3
from pathlib import Path
import csv,json,hashlib,sys,re
from collections import defaultdict
from urllib.parse import urlparse
from html.parser import HTMLParser
R=Path(__file__).resolve().parents[1]; checks=[]
def check(name,ok,detail=''):checks.append({'check':name,'status':'PASS' if ok else 'FAIL','detail':str(detail)})
def csvread(p):return list(csv.DictReader(p.open(encoding='utf-8-sig',newline='')))
def jread(p):return json.loads(p.read_text())
manifest=csvread(R/'audit/SOURCE_MANIFEST.csv')
check('41 canonical source tables',len(manifest)==41)
check('source snapshot checksums',all(hashlib.sha256((R/'source_snapshot'/r['file']).read_bytes()).hexdigest()==r['sha256'] for r in manifest))
check('export copies byte exact',all((R/'data/csv'/r['file']).read_bytes()==(R/'source_snapshot'/r['file']).read_bytes() for r in manifest))
countries=jread(R/'data/json/countries.json');check('136 country-system profiles',len(countries)==136)
check('all profiles readable',all((R/'data/json'/c['profile_file']).exists() for c in countries))
obs=csvread(R/'data/csv/observations.csv');check('core observation count',len(obs)==10059,len(obs))
check('integer years',all(r['year'].isdigit() for r in obs if r['year']))
latest=csvread(R/'data/csv/latest_wave_identical_ses_gap_rankings.csv');groups=defaultdict(list)
for r in latest:groups[(r['panel_policy'],r['age'],r['indicator_id'])].append(r)
check('eight SES panel-age-metric cells',len(groups)==8)
check('N43 and N45 finite memberships',all(len(v)==int(v[0]['panel_n']) and len({r['country_id'] for r in v})==int(v[0]['panel_n']) for v in groups.values()))
check('same members at both ages',all({r['country_id'] for r in groups[(p,'age10',i)]}=={r['country_id'] for r in groups[(p,'age15',i)]} for p in ['MAX_AVAILABLE_CONDITIONAL','PRIMARY_QUESTIONNAIRE_COMPARABLE'] for i in ['social_score_gap','social_proficiency_gap']))
maxset={r['country_id'] for r in latest if r['panel_n']=='45'};subset={r['country_id'] for r in latest if r['panel_n']=='43'}
check('N43 removes only ALB USA',maxset-subset=={'iso3:ALB','iso3:USA'} and subset<=maxset)
check('Kosovo bridge explicit','system:XKX' in maxset)
nl=jread(R/'data/json/profiles/iso3_NLD.json')
check('current release eligibility retained',all('release_main_eligible'in r for r in nl['observations']))
check('NL PIRLS participation warning retained',any(r['survey']=='PIRLS' and r['year']==2021 and 'IEA_PARTICIPATION_NOT_MET' in (r['caveat_ids'] or '') and r['school_response_before_pct']==44 and r['school_response_after_pct']==79 for r in nl['representativeness']))
check('nonempty social sorting source',len(nl['pirls_social'])>0 and len(nl['pisa_social'])>0)
check('MAIN12 without Norway finite',len(nl['main12'])>0 and all(r['country_id']!='iso3:NOR' for r in csvread(R/'data/csv/PIRLS_MAIN12_FIXED_OBSERVATION_VIEWS.csv')))
levels=csvread(R/'data/csv/LATEST_GROUP_LEVEL_RANKS.csv');check('704 separately controlled group ranks',len(levels)==704 and all(r.get('input_sha256') for r in levels))
check('addendum levels unchanged',all(any(all(s[k]==r[k] for k in ['panel_id','age','country_id','indicator_id','group_id','estimate','se']) for s in csvread(R/'data/csv/latest_wave_identical_ses_group_levels.csv')) for r in levels))
domain=jread(R/'data/json/domain_context.json');check('16 conditional Netherlands means only',len(domain)==16 and all(r['country_id']=='iso3:NLD' and r['statistic']=='overall_mean' and r['scientific_freeze'] is False for r in domain))
check('domain means carry external rounded checks',all(float(r['external_mean_abs_difference'])<=float(r['external_mean_match_tolerance']) and float(r['external_se_abs_difference'])<=float(r['external_se_match_tolerance']) for r in domain))
check('domain source links HTTPS',all(urlparse(r['external_url']).scheme=='https' for r in domain))
check('no raw microdata or chat files',not any(p.suffix.lower() in {'.rds','.sav','.dta','.sas7bdat','.docx'} or 'chat ' in p.name.lower() for p in R.rglob('*') if p.is_file()))
release=jread(R/'data/json/release.json');check('explicit private release',release['public_deployment']=='not_activated_IEA_rights_condition_C001')
check('no frontend scientific estimation',release['scientific_computation_frontend'] is False)
check('no automatic public deploy workflow',not (R/'.github/workflows/pages.yml').exists())
html=(R/'index.html').read_text(); js=(R/'assets/app.js').read_text()
check('all filter labels',all(f'for="{i}"' in html for i in ['countrySelect','ageSelect','questionSelect','domainSelect','panelSelect','localeSelect','trendSelect','sesSelect','sortingSelect']))
check('null values not treated as zero',"v!==null&&v!==undefined&&v!==''" in js)
check('frontend uses source eligible field','release_main_eligible===true' in js)
check('latest maximum default N45',"panel:'45'" in js)
check('both languages and share state',"locale:'nl'" in js and 'URLSearchParams' in js and 'panel' in js)
check('native SEs and intervals displayed','ci_low' in js and 'SE(r)' in js)
check('all revised figure records have images',all((R/f['png']).exists() for f in jread(R/'data/json/figures.json')))
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[]
 def handle_starttag(self,tag,attrs):
  for k,v in attrs:
   if k in {'href','src'} and v and not v.startswith(('#','data:','https:','http:')):self.links.append(v.split('?')[0])
missing=[]
for name in ['index.html','downloads.html']:
 parser=Links();parser.feed((R/name).read_text())
 missing.extend(f'{name}:{x}' for x in parser.links if not (R/x).exists())
check('all local UI and download links resolve',not missing,missing)
with (R/'audit/DATA_VALIDATION_CHECKS.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=['check','status','detail']);w.writeheader();w.writerows(checks)
fails=[x for x in checks if x['status']=='FAIL'];print(f'{len(checks)-len(fails)}/{len(checks)} data and release checks PASS');[print(x) for x in fails];sys.exit(1 if fails else 0)
