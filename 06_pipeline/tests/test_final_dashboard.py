import csv
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "06_pipeline" / "LO_FINAL_DASHBOARD_BUILD.py"
spec = importlib.util.spec_from_file_location("lo_dashboard_build", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class FinalDashboardTest(unittest.TestCase):
    def test_private_preview_and_no_false_final_release(self):
        with tempfile.TemporaryDirectory() as td:
            td = Path(td)
            bundle = td/"bundle"
            bundle.mkdir()
            members=[dict(route_code=f"X{i:02d}",
              country_id=f"iso3:X{i:02d}",
              country_name_nl=f"Land {i}",country_name_en=f"Country {i}",
              common42_member="True") for i in range(41)]
            members.append(dict(route_code="NLD",country_id="iso3:NLD",
              country_name_nl="Nederland",country_name_en="Netherlands",
              common42_member="True"))
            with (bundle/"COMMON42_REGISTER.csv").open("w",newline="") as f:
                w=csv.DictWriter(f,fieldnames=members[0].keys())
                w.writeheader();w.writerows(members)
            rows=[dict(cell_id="TEST|NLD|PISA|2025|reading",country="NLD",
              survey="PISA",year="2025",domain="reading",stat="mean",
              group="total",estimate="488.5",se="2.1",n_unweighted="5400",
              unit="score_points",family="levels",variant="official",
              sample_id="TEST_APPROVED_SAMPLE",scientific_status="SCIENTIFICALLY_VALIDATED",
              source="synthetic_test_only")]
            grid=td/"grid.csv"
            with grid.open("w",newline="") as f:
                w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader()
                w.writerows(rows)
            out=td/"preview"
            result=module.build(ROOT,bundle,grid,out)
            self.assertEqual(result["science_rows"],1)
            self.assertEqual(result["systems_with_results"],1)
            self.assertEqual(len(list((out/"product_data"/"countries").glob("*.json"))),42)
            self.assertTrue((out/"BUILD_SHA256_MANIFEST.json").is_file())
            nld=json.loads((out/"product_data"/"countries"/"iso3_NLD.json").read_text())
            self.assertEqual(nld["format"],"column-dictionary-v1")
            self.assertEqual(nld["length"],1)
            other=json.loads((out/"product_data"/"countries"/"iso3_X00.json").read_text())
            self.assertEqual(other["length"],0)
            self.assertEqual(len(json.loads((out/"product_data"/"metadata.json").read_text())["countries"]),42)
            self.assertEqual(json.loads((out/"DASHBOARD_GATE.json").read_text())["mode"],
              "PRIVATE_CANDIDATE_NOT_PUBLISHED")
            with self.assertRaises(ValueError):
                module.build(ROOT,bundle,grid,td/"final",release=True)
            rows[0]["scientific_status"]="COMPUTED_PENDING_VALIDATION"
            with grid.open("w",newline="") as f:
                w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader()
                w.writerows(rows)
            with self.assertRaises(ValueError):
                module.build(ROOT,bundle,grid,td/"invalid")

if __name__=="__main__":
    unittest.main()
