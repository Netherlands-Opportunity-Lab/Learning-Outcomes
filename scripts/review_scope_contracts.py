"""Check actual selected task identities against the human scope, without estimation."""
import argparse, collections, csv, hashlib, json
from pathlib import Path

def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def read(p):
 with p.open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
def build(repo,root,output):
 files={'tasks':root/'international/EXACT_ALL_REQUIRED_TASKS.csv',
  'grid':root/'FIXED_PRODUCTION_V1/all_required/PRIVATE_MASTER_GRID.csv',
  'decisions':repo/'06_pipeline/SCOPE_APPROVALS.csv',
  'products':repo/'06_pipeline/review_20261013/PRODUCT_REQUIREMENTS.json',
  'author_preparation':root/'cobreros_four/PREPARATION_MANIFEST.json',
  'dashboard':root/'scientific_review_20261019/snapshot/public_inputs/dashboard_cells.csv',
  'gender_policy':repo/'06_pipeline/review_20261013/GENDER_POOL_USER_DECISION.json',
  'review_code':Path(__file__)}
 tasks=read(files['tasks']);grid=read(files['grid']);by={r['metric_key']:r for r in tasks}
 if len(by)!=len(tasks) or set(by)!={r['cell_id']for r in grid}:raise ValueError('EXACT_TASK_GRID_IDENTITY')
 decisions={r['approval_id']:r for r in read(files['decisions'])}
 expected={'A01':'APPROVED','A02':'APPROVED','A03':'APPROVED','A04':'APPROVED','A05':'REJECTED','A06':'APPROVED','A07':'REJECTED','A08':'REJECTED','A09':'APPROVED','A10':'DEFERRED','A11':'APPROVED','A12':'APPROVED','A13':'APPROVED','A14':'APPROVED','A15':'DEFERRED','A16':'DEFERRED','A17':'REJECTED'}
 if any(decisions[k]['status']!=v for k,v in expected.items()):raise ValueError('DIRECT_DECISIONS_CHANGED_REVIEW_REQUIRED')
 ses=[r for r in tasks if r['survey']=='PISA' and 'ses' in r['module']]
 if any(r['definition']!='Cobreros_fourwave_13item_trend_comparable' or r['year']not in ('2015','2018','2022','2025') for r in ses):raise ValueError('UNCHOSEN_PISA_SES_CONSTRUCT')
 forbidden=('theil','absolute_ses','cross_age','cohort','language_migration','twowave','two_wave','official_escs')
 bad=[r['metric_key'] for r in tasks if any(k in r['metric_key'].lower()for k in forbidden)]
 if bad:raise ValueError('UNAPPROVED_TARGET_FAMILY')
 home=[r for r in grid if r['subgroup_variable']=='extension_home_ses']
 usable=[r for r in home if r['status']=='SCIENTIFICALLY_VALIDATED']
 if any((r['survey'],r['year'])not in [('PIRLS','2021'),('TIMSS','2023')] for r in usable):raise ValueError('HOME_SES_HISTORICAL_SPLICE')
 if any(not r['status'].startswith('UNAVAILABLE_') for r in home if int(r['year'])<(2021 if r['survey']=='PIRLS'else 2023)):raise ValueError('HOME_SES_MISSING_YEAR_NOT_ACCOUNTED')
 dashboard=read(files['dashboard']);appendix_leaks=[]
 for r in dashboard:
  t=by[r['cell_id']]
  if t['module'].startswith('extension_') or t['contract_figure_id'].startswith('GP_SES_HIGH'):appendix_leaks.append(r['cell_id'])
 if appendix_leaks:raise ValueError('APPENDIX_OR_SCIENTIFIC_EXTENSION_IN_MAIN_DASHBOARD')
 def groups(rows):
  c=collections.Counter((r['survey'],r['year'],r['status'])for r in rows)
  return [dict(survey=k[0],year=k[1],status=k[2],cells=n)for k,n in sorted(c.items())]
 products=json.loads(files['products'].read_text(encoding='utf-8'))
 unresolved_extensions=[r['requirement_id']for r in products['requirements'] if r.get('approval_items') and all(decisions[a]['status']=='APPROVED' for a in r['approval_items']) and not r.get('figure_families') and not r.get('current_figure_families') and not r.get('derivation')]
 if unresolved_extensions:raise ValueError('CHOSEN_PRODUCT_WITHOUT_PRIMITIVE_OR_DERIVATION_MAPPING')
 result=dict(schema_version=1,status='ACTUAL_SELECTED_SCOPE_AND_PRODUCT_PLACEMENT_VERIFIED',
  input_sha256={k:sha(p)for k,p in files.items()},tasks=len(tasks),grid_cells=len(grid),
  chosen_PISA_SES_targets=len(ses),chosen_PISA_SES_definition='Cobreros_fourwave_13item_trend_comparable',
  two_wave_analysis_targets=0,official_PISA_ESCS_analysis_targets=0,forbidden_targets=0,
  Q04_disposition='NOT_APPLICABLE_TO_SELECTED_METHOD; exclusion demonstrated from every exact task identity and pinned author preparation',
  home_SES_coverage=groups(home),home_SES_usable_cells=len(usable),
  home_SES_temporal_claim='One released comparable Home-SES wave per study in current scope; no within-study Home-SES trend and no cross-study joined scale.',
  dashboard_cells=len(dashboard),appendix_leaks=0,unmapped_chosen_products=0,
  migration_definitions=sorted({r['definition']for r in tasks if r['module']in ('migration','migration_generation')}),
  modules=dict(collections.Counter(r['module']for r in tasks)),
  limitations='Task-level scope audit; scientific numerical and sample validity require the separately linked Q dossiers. Historical slide titles are not approved empirical claims.')
 output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
 return result

if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--root',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
 a=p.parse_args();r=build(Path(__file__).resolve().parents[1],a.root,a.output)
 print(r['status'],r['tasks'],'tasks;',r['home_SES_usable_cells'],'Home-SES cells')
