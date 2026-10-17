import importlib.util,tempfile,unittest
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'repair_cleanup_plan.py'
s=importlib.util.spec_from_file_location('cleanup_repair',p)
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
class CleanupGraph(unittest.TestCase):
 def test_cycle_resolves_to_permanent_keeper_and_excludes_personal_files(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d)/'project'
   def row(a,b):return dict(target_path=str(a),keeper_path=str(b),expected_sha256='a'*64,expected_size_bytes='100')
   a,b,c=[root/k for k in ('a','b','c')]
   rows=[row(a,b),row(b,c),row(c,a),row(Path(d)/'personal',a)]
   fixed,report=m.repair(rows,[root])
   self.assertEqual(report['excluded_outside_roots_or_without_hash'],1)
   self.assertEqual(report['repaired_targets'],2)
   self.assertFalse(report['deletion_authorized'])
   self.assertFalse({r['keeper_path'] for r in fixed}&{r['target_path'] for r in fixed})
