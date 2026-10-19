import gzip
import importlib.util
from pathlib import Path
import tempfile
import unittest
FILE=Path(__file__).resolve().parents[2]/'scripts/report_grid_coverage.py'
s=importlib.util.spec_from_file_location('coverage_report',FILE)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)

class CoverageReport(unittest.TestCase):
 def test_disjoint_reason_and_zero_are_not_missing(self):
  self.assertEqual(m.main_reason(dict(status='SCIENTIFICALLY_VALIDATED',estimate='0',standard_error='0')),'RESULT_AVAILABLE')
  cases=[('Home Questionnaire not administered','QUESTIONNAIRE_NOT_ADMINISTERED'),
   ('Older Home Resources for Learning is a different construct; do not splice or backfill','SCALE_NOT_DEFINED_IN_CYCLE'),
   ('Required parents birthplace fields absent; home language cannot identify this construct','REQUIRED_FIELD_NOT_OBSERVED'),
   ('No valid national programme identifier for the selected school-programme peer environment','LEARNING_ENVIRONMENT_NOT_OBSERVED'),
   ('PIRLS2006 ALWAYS / SOMETIMES / NEVER only; cannot identify the chosen construct','GROUP_DEFINITION_NOT_OBSERVED')]
  for reason,expected in cases:self.assertEqual(m.main_reason(dict(status='UNAVAILABLE_VERIFIED_SOURCE_FIELD',hold_reason=reason)),expected)
  self.assertEqual(m.main_reason(dict(status='UNAVAILABLE_VERIFIED_ANALYTIC_SAMPLE',hold_reason='EMPTY_TARGET_IN_REQUIRED_SURVEY_REPLICATE')),'ANALYTIC_GROUP_UNUSABLE')
  self.assertEqual(m.main_reason(dict(status='NEEDS_COMPUTE',hold_reason='')),'SOURCE_LINK_MISSING')
 def test_projection_preserves_exact_target_status_result_and_trace(self):
  grid=[dict(cell_id=c,status='SCIENTIFICALLY_VALIDATED',target_contract_sha256='target'+c,result_hash='result'+c) for c in ['a','b']]
  links=[dict(cell_id=c) for c in ['a','b']]
  reuse=[dict(grid[0],prior_result_hash=grid[0]['result_hash'])]
  selected,trace=m.project_exact_reuse(grid,links,reuse)
  self.assertEqual(selected,[grid[0]]);self.assertEqual(trace,[links[0]])
  for field in ['status','target_contract_sha256','prior_result_hash']:
   with self.assertRaisesRegex(ValueError,'Changed projected'):
    m.project_exact_reuse(grid,links,[dict(reuse[0],**{field:'changed'})])
  with self.assertRaisesRegex(ValueError,'Uncontracted'):
   m.project_exact_reuse(grid,links+[dict(cell_id='unknown')],reuse)
 def test_compressed_exact_grid_deterministic_and_private_paths_rejected(self):
  with tempfile.TemporaryDirectory() as tmp:
   a=Path(tmp)/'a.csv.gz';b=Path(tmp)/'different.csv.gz';rows=[dict(cell_id='test',estimate='0')]
   m.write(a,rows,['cell_id','estimate']);m.write(b,rows,['cell_id','estimate'])
   self.assertEqual(a.read_bytes(),b.read_bytes())
   self.assertEqual(gzip.decompress(a.read_bytes()).decode(),'cell_id,estimate\ntest,0\n')
   with self.assertRaisesRegex(ValueError,'Private path'):m.write(a,[dict(cell_id='C:'+'/Users/private')],['cell_id'])

if __name__=='__main__':unittest.main()
