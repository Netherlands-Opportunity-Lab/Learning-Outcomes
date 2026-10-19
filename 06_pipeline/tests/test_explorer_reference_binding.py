import importlib.util,json,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('explorer_build',ROOT/'06_pipeline/LO_FINAL_GUIDED_DASHBOARD_BUILD.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class ReferenceBinding(unittest.TestCase):
 def test_foreign_focus_uses_its_full_contract_period(self):
  with tempfile.TemporaryDirectory() as temp:
   p=Path(temp)/'balance.json'
   f=dict(figure_id='f',required_years='2018;2022;2025',expected_series='girl;boy')
   rows=[dict(figure_id='f',country_id='iso3:'+c,year=y,series_id=g,series_role='focus',cell_id=f'{c}_{y}_{g}')
         for c,ys in [('SWE',[2018,2022]),('NLD',[2018,2022,2025])] for y in ys for g in ['girl','boy']]
   v=dict(focus='SWE',view_id='gender',view_cell_ids=[r['cell_id'] for r in rows if r['country_id']=='iso3:SWE'],
     required_years=['2018','2022'],required_keys=['full_own_core','gender_all_own_years'],
     status='BALANCED_REFERENCE_AVAILABLE',focus_excluded=True,country_weights='EQUAL_PER_COUNTRY',
     benchmark_uncertainty=False,default_members=['NLD'],options=[dict(country='NLD',eligible=True,dashboard_eligible=True)])
   def run(named=False):
    p.write_text(json.dumps({'schema_version':2,'views':{'SWE:::gender':v} if named else [v]}),encoding='utf-8')
    return next(x for x in m.explorer_references(p,['NLD','SWE'],[f],rows)['figures'] if x['focus']=='SWE')
   self.assertEqual(run()['eligible_members'],['NLD'])
   named=run(named=True);array=run()
   self.assertNotEqual(named.pop('evidence_sha256'),array.pop('evidence_sha256'))
   self.assertEqual(named,array)
   self.assertEqual(run()['required_years'],'2018;2022')
   v['required_years'].append('2025')
   self.assertEqual(run()['eligible_members'],[])
   self.assertEqual(run(named=True)['eligible_members'],[])
   f.update(historical_figure_id='f',survey='PIRLS',outcome_construct='total')
   v['view_id']='f::PIRLS::total::::standard'
   v['required_years']=['2018','2022']
   v['status']='FOCUS_VIEW_INCOMPLETE'
   rows[:]=[r for r in rows if r['country_id']!='iso3:SWE']
   empty=run(named=True)
   self.assertEqual(empty['required_years'],'2018;2022')
   self.assertEqual(empty['status'],'FOCUS_VIEW_INCOMPLETE')
   self.assertEqual(empty['eligible_members'],[])
 def test_exact_cells_joint_groups_and_missing_mapping(self):
  with tempfile.TemporaryDirectory() as temp:
   p=Path(temp)/'balance.json'
   f={'figure_id':'f','required_years':'2018;2022','expected_series':'girl;boy'}
   rows=[dict(figure_id='f',country_id='iso3:'+c,year=y,series_id=g,series_role='focus',cell_id=f'{c}_{y}_{g}') for c in ['NLD','AUT','CAN'] for y in [2018,2022] for g in ['girl','boy']]
   ids=[r['cell_id'] for r in rows if r['country_id']=='iso3:NLD']
   v=dict(focus='NLD',view_id='gender',view_cell_ids=ids,required_keys=['core','gender_all_years'],status='BALANCED_REFERENCE_AVAILABLE',focus_excluded=True,country_weights='EQUAL_PER_COUNTRY',benchmark_uncertainty=False,default_members=['AUT'],options=[{'country':c,'eligible':True,'dashboard_eligible':True} for c in ['AUT','CAN']])
   def run(view,rs=rows):
    p.write_text(json.dumps({'views':view}),encoding='utf-8');return next(x for x in m.explorer_references(p,['NLD','AUT','CAN'],[f],rs)['figures'] if x['focus']=='NLD')
   result=run([v]);self.assertEqual(result['eligible_members'],['AUT','CAN']);self.assertEqual(result['default_members'],['AUT'])
   self.assertEqual(run([])['status'],'COMPARABILITY_PENDING')
   broken=[r for r in rows if r['cell_id']!='CAN_2022_boy'];self.assertEqual(run([v],broken)['eligible_members'],['AUT'])
   v2=dict(v,view_id='context',view_cell_ids=[ids[-1]],default_members=[],options=[])
   self.assertEqual(run([v,v2])['eligible_members'],[])
   self.assertEqual(run([dict(v,status='FOCUS_VIEW_INCOMPLETE')])['status'],'FOCUS_VIEW_INCOMPLETE')
   with self.assertRaisesRegex(ValueError,'invalid reference policy'):run([dict(v,benchmark_uncertainty=True)])
if __name__=='__main__':unittest.main()
