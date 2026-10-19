"""Official sample joins must preserve national populations and true unknowns."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

path = Path(__file__).resolve().parents[2] / 'scripts/review_official_samples.py'
spec = importlib.util.spec_from_file_location('sample_review', path)
review = importlib.util.module_from_spec(spec)
spec.loader.exec_module(review)


class SampleReview(unittest.TestCase):
    def extract(self, html, **extra):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'sample.html'
            p.write_text(html, encoding='utf-8')
            cfg = dict(file=p.name, sha256=review.sha(p), url='https://official.example/table',
                       table=0, country_column=0, fields={'exclusion_pct': 1})
            cfg.update(extra)
            return review.extract_table(p.parent, cfg, {'ireland': 'IRL', 'norwaygradefour': 'NOR'})

    def test_region_and_grade_do_not_replace_nation(self):
        x = self.extract('<table><tr><td>Northern Ireland</td><td>12</td></tr>'
                         '<tr><td>Ireland</td><td>0</td></tr>'
                         '<tr><td>Norway (5)</td><td>13</td></tr>'
                         '<tr><td>Norway (4)</td><td>2</td></tr></table>')
        self.assertEqual(x['IRL']['exclusion_pct'], 0)
        self.assertEqual(x['NOR']['exclusion_pct'], 2)

    def test_unknown_requires_explicit_documentation(self):
        html = '<table><tr><td>Ireland</td><td>—</td></tr></table>'
        with self.assertRaises(ValueError):
            self.extract(html)
        x = self.extract(html, official_unreported={'IRL': ['exclusion_pct']})
        self.assertIsNone(x['IRL']['exclusion_pct'])

    def test_duplicate_and_changed_source_are_rejected(self):
        row = '<tr><td>Ireland</td><td>12</td></tr>'
        with self.assertRaisesRegex(ValueError, 'Ambiguous'):
            self.extract('<table>' + row + row + '</table>')
        with self.assertRaisesRegex(ValueError, 'source changed'):
            self.extract('<table>' + row + '</table>', sha256='0' * 64)


if __name__ == '__main__':
    unittest.main()
