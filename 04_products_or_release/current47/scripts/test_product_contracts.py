"""Regressions for missing waves and altered written result statements.

Uses the sealed public aggregate fixtures, never pupil records.
"""
import copy
import json
import unittest
from pathlib import Path

from verify_research_products import verify_axes, verify_prose

PRODUCT = Path(__file__).resolve().parents[1]


def read(name):
    return json.loads((PRODUCT / name).read_text(encoding="utf-8"))


class ProductContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.model = read("data/RESEARCH_PRODUCT_DATA.json")
        cls.axes = read("data/paper_figures/PAPER_FIGURE_MANIFEST.json")
        cls.paper = read("paper/PAPER_PRODUCT_TRACE.json")
        cls.tables = read("data/RESEARCH_TABLES.json")
        cls.text = (PRODUCT / "paper/Leerprestaties_paper_current47.md").read_text(encoding="utf-8")

    def test_actual_all_six_figures_keep_full_anchors(self):
        self.assertEqual(verify_axes(self.model, self.axes), 36)

    def test_shortened_pirls_migration_axis_is_rejected(self):
        changed = copy.deepcopy(self.axes)
        changed["figures"]["migration_levels"]["rendered_axis_proof"][0]["trained_x_range"] = [2001, 2006]
        with self.assertRaisesRegex(AssertionError, "Truncated"):
            verify_axes(self.model, changed)

    def test_missing_year_must_stay_in_anchor(self):
        changed = copy.deepcopy(self.axes)
        changed["figures"]["migration_levels"]["rendered_axis_proof"][0]["required_years"] = [2001, 2006]
        with self.assertRaisesRegex(AssertionError, "Changed required"):
            verify_axes(self.model, changed)

    def test_missingness_is_recorded_without_zero_fill(self):
        changed = copy.deepcopy(self.axes)
        changed["figures"]["migration_levels"]["rendered_axis_proof"][0]["missing_years"] = []
        with self.assertRaises(AssertionError):
            verify_axes(self.model, changed)

    def test_low_peer_series_are_visually_distinct(self):
        colors = self.axes["figures"]["peer_basic"]["series_colors"]
        self.assertEqual(len({colors[x] for x in [
            "Alle leerlingen", "Zelf onder basisniveau", "Zelf op/boven basisniveau"]}), 3)

    def test_actual_prose_has_exact_registered_parents(self):
        self.assertGreater(verify_prose(self.paper, self.tables, self.text), 40)

    def test_changed_abstract_is_rejected(self):
        changed = self.text.replace("-27,0 PIRLS-punten", "-270,0 PIRLS-punten")
        self.assertNotEqual(changed, self.text)
        with self.assertRaisesRegex(AssertionError, "Written statement"):
            verify_prose(self.paper, self.tables, changed)

    def test_missing_prose_parent_is_rejected(self):
        changed = copy.deepcopy(self.paper)
        statement = next(x for x in changed["prose_statements"] if x["exact_parent_records"])
        statement["exact_parent_records"].pop()
        with self.assertRaisesRegex(AssertionError, "parents changed"):
            verify_prose(changed, self.tables, self.text)


if __name__ == "__main__":
    unittest.main()
