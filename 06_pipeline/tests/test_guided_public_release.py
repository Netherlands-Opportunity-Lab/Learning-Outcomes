import hashlib,importlib.util,json,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('guided_release',ROOT/'06_pipeline/LO_FINAL_GUIDED_PUBLIC_RELEASE.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class ReleaseGate(unittest.TestCase):
 def fixture(self,p):
  def put(path,obj):
   f=p/path;f.parent.mkdir(parents=True,exist_ok=True)
   f.write_text(json.dumps(obj),encoding='utf-8')
  put('data/common42.json',[{'code':'NLD'}])
  put('data/figure_registry.json',{'figures':[{'figure_id':'TR_MEAN_age15_reading'}]})
  for f in ['data/method_registry.json','nl/index.html','en/index.html','assets/app-shell.js','locales/nl.json','locales/en.json']:put(f,{})
  put('data/balanced_references.json',{'policy':'FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3','focuses':{'NLD':{
   'required_keys':['full_focus_key'],'options':[],'default_members':[],
   'default_points':[],'country_weights':'EQUAL_PER_COUNTRY'}}})
  qa={'system_count':1,'active_figures':1,'availability_counts':{'UNAVAILABLE':1},'scientific_data_rows':0}
  for k in ['country_registry_sha256','scope_decisions_sha256','scientific_source_sha256','figure_contract_sha256']:qa[k]='a'*64
  qa['balanced_references_sha256']=m.sha(p/'data/balanced_references.json')
  put('GUIDED_QA.json',qa)
  put('data/countries/NLD.json',{'records':[]})
  put('data/availability/NLD.json',{'figures':[{'figure_id':'TR_MEAN_age15_reading','display_state':'UNAVAILABLE'}]})
  for lang in ['nl','en']:
   for q in ['trends','distribution','gaps','environment']:put(f'{lang}/country/NLD/{q}/index.html',{})
  cert=dict(m.REQUIRED_CERT,eligible_countries=['NLD'],approved_figure_ids=['TR_MEAN_age15_reading'])
  cert.update({k:v for k,v in qa.items() if k.endswith('_sha256')})
  self.manifest(p,cert)
  return cert
 def manifest(self,p,cert):
  entries=[{'path':f.relative_to(p).as_posix(),'bytes':f.stat().st_size,'sha256':m.sha(f)}
   for f in p.rglob('*') if f.is_file() and f.name!='BUILD_SHA256_MANIFEST.json']
  (p/'BUILD_SHA256_MANIFEST.json').write_text(json.dumps(entries),encoding='utf-8')
  cert['candidate_manifest_sha256']=m.sha(p/'BUILD_SHA256_MANIFEST.json')
 def test_lazy_country_contracts_match_independent_proof(self):
  with tempfile.TemporaryDirectory() as d:
   site=Path(d);(site/'data/references').mkdir(parents=True)
   verified=dict(policy='FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3',figures=[
    dict(focus='NLD',figure_id='f',required_years='2018;2022;2025',eligible_members=['CAN'])])
   (site/'data/explorer_references.json').write_text(json.dumps(dict(schema_version=2,policy=verified['policy'],country_files={'NLD':'data/references/NLD.json'})))
   path=site/'data/references/NLD.json'
   payload=dict(schema_version=1,policy=verified['policy'],figures=verified['figures'])
   path.write_text(json.dumps(payload));m.verify_reference_payloads(site,['NLD'],verified)
   changed=json.loads(path.read_text());changed['figures'][0]['required_years']='2022;2025'
   path.write_text(json.dumps(changed))
   with self.assertRaisesRegex(ValueError,'independently verified'):
    m.verify_reference_payloads(site,['NLD'],verified)
 def test_dynamic_country_and_mutations(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);p=root/'site';p.mkdir();c=self.fixture(p);cf=root/'cert.json'
   def verify():cf.write_text(json.dumps(c),encoding='utf-8');return m.verify(p,cf)
   self.assertEqual(verify()['systems'],1)
   c['eligible_countries']=['NLD','AUT']
   with self.assertRaises(ValueError):verify()
   c['eligible_countries']=['NLD'];(p/'data/countries/NLD.json').write_text('{}')
   with self.assertRaises(ValueError):verify()
 def test_self_reference_and_unsafe_path(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);p=root/'site';p.mkdir();c=self.fixture(p);cf=root/'cert.json'
   bf=p/'data/balanced_references.json';b=json.loads(bf.read_text());b['focuses']['NLD']['default_members']=['NLD']
   bf.write_text(json.dumps(b));q=json.loads((p/'GUIDED_QA.json').read_text());q['balanced_references_sha256']=m.sha(bf)
   (p/'GUIDED_QA.json').write_text(json.dumps(q));c['balanced_references_sha256']=m.sha(bf);self.manifest(p,c)
   cf.write_text(json.dumps(c))
   with self.assertRaises(ValueError):m.verify(p,cf)
   mf=p/'BUILD_SHA256_MANIFEST.json';a=json.loads(mf.read_text());a[0]['path']='..\\private.txt'
   mf.write_text(json.dumps(a));c['candidate_manifest_sha256']=m.sha(mf);cf.write_text(json.dumps(c))
   with self.assertRaises(ValueError):m.verify(p,cf)
 def test_per_view_release_and_manifested_pages_copy(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);p=root/'site';p.mkdir();c=self.fixture(p);cf=root/'cert.json'
   bp=p/'data/balanced_references.json'
   view={'focus':'NLD','view_cell_ids':['exact_cell'], 'required_keys':['core_key','exact_cell'],
    'options':[], 'default_members':[], 'default_points':[], 'country_weights':'EQUAL_PER_COUNTRY'}
   balance={'schema_version':2,'policy':'FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3','views':[view]}
   def recertify():
    bp.write_text(json.dumps(balance),encoding='utf-8')
    qp=p/'GUIDED_QA.json';q=json.loads(qp.read_text(encoding='utf-8'))
    q['balanced_references_sha256']=m.sha(bp);qp.write_text(json.dumps(q),encoding='utf-8')
    c['balanced_references_sha256']=m.sha(bp);self.manifest(p,c)
    cf.write_text(json.dumps(c),encoding='utf-8')
   ep=p/'data/explorer_references.json';ep.write_text(json.dumps({'figures':[]}),encoding='utf-8')
   recertify();self.assertEqual(m.verify(p,cf)['systems'],1)
   view['view_cell_ids']=[];recertify()
   with self.assertRaisesRegex(ValueError,'exact view-to-figure'):m.verify(p,cf)
   view['view_cell_ids']=['exact_cell'];recertify()
   receipt=m.stage(root,p,cf)
   spec=importlib.util.spec_from_file_location('prepare_pages',ROOT/'05_publication/prepare_verified_pages.py')
   pages=importlib.util.module_from_spec(spec);spec.loader.exec_module(pages);pages.ROOT=root
   pages.prepare(receipt['release_id'],root/'output')
   self.assertEqual(m.sha(root/'output/BUILD_SHA256_MANIFEST.json'),c['candidate_manifest_sha256'])
   self.assertFalse((root/'output/PUBLIC_RELEASE_CERTIFICATION.json').exists())
   with self.assertRaises(ValueError):pages.prepare('../escape',root/'unsafe')
if __name__=='__main__':unittest.main()
