import csv
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('candidate_check', ROOT / 'scripts/verify_final_scientific_candidate.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class ActualCandidateProof(unittest.TestCase):
    def test_independent_membership_full_years_and_source_bytes(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            state = root / 'FIXED_PRODUCTION_V1/all_required'
            work = root / 'scientific_review_20261019/Q06_mapping_final'
            repo = root / 'repo'
            expected = repo / '06_pipeline/review_20261013/scientific_review'
            candidate = state / 'DASHBOARD_GUIDED_REVIEW_fixture'
            for p in (candidate / 'data/references', work, expected):
                p.mkdir(parents=True)
            (repo / '06_pipeline/LO_FINAL_GUIDED_DASHBOARD_BUILD.py').write_text('fixture', encoding='utf-8')
            def csv_file(path, rows):
                with path.open('w', encoding='utf-8', newline='') as f:
                    w = csv.DictWriter(f, list(rows[0])); w.writeheader(); w.writerows(rows)
            def json_file(path, value):
                path.write_text(json.dumps(value), encoding='utf-8')
            csv_file(state / 'GUIDED_PREVIEW_SUMMARY.csv', [dict(preview_status='PRIVATE_GUIDED_CANDIDATE_BUILT', preview_id='fixture')])
            csv_file(expected / 'REFERENCE_BY_VIEW.csv', [dict(country='NLD', figure_id='f', eligible_countries='ITA', default_countries='ITA')])
            json_file(work / 'BALANCED_REFERENCE_EXPORT.json', dict(views=[dict(focus='NLD', figure_id='f', required_years=['2018', '2022'])]))
            (state / 'PRIVATE_GUIDED_VALIDATED_ROWS.csv').write_text('source', encoding='utf-8')
            (state / 'BALANCED_REFERENCE_EXPORT.json').write_text('balance', encoding='utf-8')
            json_file(candidate / 'GUIDED_QA.json', dict(reference_policy_sha256='STRICT_BALANCE_DEFAULT',
                scientific_source_sha256=m.sha(state / 'PRIVATE_GUIDED_VALIDATED_ROWS.csv'),
                balanced_references_sha256=m.sha(state / 'BALANCED_REFERENCE_EXPORT.json'), scientific_data_rows=2))
            row = dict(focus='NLD', figure_id='f', eligible_members=['ITA'], default_members=['ITA'],
                required_years='2018;2022', focus_excluded=True, country_weights='EQUAL_PER_COUNTRY',
                benchmark_uncertainty=False, status='BALANCED_REFERENCE_AVAILABLE')
            def check():
                json_file(candidate / 'data/references/NLD.json', dict(policy='FULL_FOCUS_CORE_PLUS_JOINT_VIEW_SUPPORT_6x3', figures=[row]))
                # Simulate a self-consistent builder manifest; the independent
                # scientific expectation must still catch the wrong payload.
                files = [p for p in candidate.rglob('*') if p.is_file() and p.name != 'BUILD_SHA256_MANIFEST.json']
                json_file(candidate / 'BUILD_SHA256_MANIFEST.json', [dict(path=p.relative_to(candidate).as_posix(), sha256=m.sha(p), bytes=p.stat().st_size) for p in files])
                return m.verify(repo, root, root / 'proof.json')
            self.assertEqual(check()['membership_differences'], 0)
            row['eligible_members'] = []
            with self.assertRaises(AssertionError): check()
            row['eligible_members'] = ['ITA']; row['required_years'] = '2022'
            with self.assertRaises(AssertionError): check()
            row['required_years'] = '2018;2022'
            (state / 'PRIVATE_GUIDED_VALIDATED_ROWS.csv').write_text('changed', encoding='utf-8')
            with self.assertRaises(AssertionError): check()


if __name__ == '__main__':
    unittest.main()
