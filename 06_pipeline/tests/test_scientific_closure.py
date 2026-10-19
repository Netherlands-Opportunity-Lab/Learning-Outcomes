"""Do not mistake successful CI on changed scientific code for a tested run."""
import hashlib
import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('closure', ROOT / 'scripts/record_scientific_closure.py')
closure = importlib.util.module_from_spec(spec)
spec.loader.exec_module(closure)


class ClosureCodeEquivalence(unittest.TestCase):
    def test_only_explicit_combination_or_population_exclusions(self):
        row=dict(country='CAN',survey='PIRLS',year='2016',domain='reading')
        self.assertEqual(closure.reviewed_scope_exclusions({'cell':row},{},[],[])[0]['reason'],'AGE_DOMAIN_NOT_ADMITTED')
        passed=[dict(row,combination_pass='TRUE')]
        with self.assertRaisesRegex(AssertionError,'Approved target removed'):
            closure.reviewed_scope_exclusions({'cell':row},{},passed,[])
        correction=dict(row,reason='REGIONAL_POPULATION_NOT_NATIONAL',review_id='official')
        self.assertEqual(closure.reviewed_scope_exclusions({'cell':row},{},passed,[correction])[0]['review_id'],'official')
        with self.assertRaisesRegex(AssertionError,'Approved target removed'):
            closure.reviewed_scope_exclusions({'cell':row},{},passed,[dict(correction,reason='OFFICIAL_TREND_COMPARABILITY_QUALIFICATION')])
    def test_report_only_commit_is_allowed_but_changed_runtime_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            def git(*args):
                return subprocess.check_output(['git', '-C', str(repo), *args], stderr=subprocess.DEVNULL).decode().strip()
            git('init')
            git('config', 'user.name', 'Scientific closure fixture')
            git('config', 'user.email', 'fixture@example.invalid')
            (repo / '.gitattributes').write_text('* -text\n', encoding='utf-8')
            (repo / 'method.R').write_bytes(b'original estimator\n')
            git('add', '.')
            git('commit', '-m', 'Execution fixture')
            execution = git('rev-parse', 'HEAD')
            bindings = [{'path': 'method.R', 'sha256': hashlib.sha256((repo / 'method.R').read_bytes()).hexdigest()}]
            (repo / 'report.md').write_text('Updated output coverage\n', encoding='utf-8')
            git('add', '.')
            git('commit', '-m', 'Report-only fixture')
            ci = git('rev-parse', 'HEAD')
            proof = closure.verify_ci_runtime(repo, execution, ci, bindings)
            self.assertEqual(proof['identical_reviewed_runtime_files'], 1)
            (repo / 'method.R').write_bytes(b'changed estimator\n')
            git('add', '.')
            git('commit', '-m', 'Changed runtime must fail')
            with self.assertRaisesRegex(AssertionError, 'runtime mismatch'):
                closure.verify_ci_runtime(repo, execution, git('rev-parse', 'HEAD'), bindings)


if __name__ == '__main__':
    unittest.main()
