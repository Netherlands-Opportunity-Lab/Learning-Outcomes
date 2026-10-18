"""Temporary coverage cannot masquerade as a balanced scientific comparison."""
import importlib.util,json,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('build',ROOT/'06_pipeline/LO_FINAL_GUIDED_DASHBOARD_BUILD.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class ProvisionalReferences(unittest.TestCase):
 def fixture(self):
  countries=[dict(route_code=c,rich_candidate='TRUE' if c in ('NLD','AUT') else 'FALSE') for c in ('NLD','AUT','CAN','USA')]
  figures=[dict(figure_id='f',required_years='2018;2022',expected_series='girl;boy')]
  rows=[dict(country_id='iso3:'+c,figure_id='f',year=2018,series_id='girl',quality_status='SCIENTIFICALLY_VALIDATED') for c in ('NLD','AUT','CAN')]
  return countries,figures,rows
 def test_partial_countries_eligible_without_shortening_axis_or_claiming_balance(self):
  c,f,r=self.fixture();out=m.provisional_references(ROOT/'05_publication/REFERENCE_POLICY.json',c,f,r,'a'*64)
  v=next(v for v in out['figures'] if v['focus']=='NLD')
  self.assertEqual(v['eligible_members'],['AUT','CAN']);self.assertEqual(v['default_members'],['AUT'])
  self.assertEqual(v['required_years'],'2018;2022');self.assertEqual(v['expected_series'],'girl;boy')
  self.assertEqual(v['status'],'PROVISIONAL_REFERENCE_AVAILABLE');self.assertIs(v['full_period_balance_verified'],False)
  self.assertEqual(next(x for x in v['eligibility'] if x['country']=='USA')['reason'],'NO_AVAILABLE_POINTS')
 def test_unknown_or_disguised_policy_rejected(self):
  c,f,r=self.fixture();policy=json.loads((ROOT/'05_publication/REFERENCE_POLICY.json').read_text())
  with tempfile.TemporaryDirectory() as td:
   p=Path(td)/'policy.json'
   for key,value in [('authorization',''),('final_scientific_policy','APPROVED'),('show_contributors',False),('full_period_balance_required',True)]:
    changed=dict(policy);changed[key]=value;p.write_text(json.dumps(changed))
    with self.assertRaisesRegex(ValueError,'invalid temporary'):m.provisional_references(p,c,f,r,'a'*64)
 def test_pending_estimates_never_become_available(self):
  c,f,r=self.fixture();r[0]['quality_status']='PENDING'
  with self.assertRaisesRegex(ValueError,'unvalidated'):m.provisional_references(ROOT/'05_publication/REFERENCE_POLICY.json',c,f,r,'a'*64)
if __name__=='__main__':unittest.main()
