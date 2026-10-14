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
  put('data/balanced_references.json',{'policy':'FULL_FOCUS_SUPPORT_6x3','focuses':{'NLD':{
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
if __name__=='__main__':unittest.main()
