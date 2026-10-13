import csv,json,tempfile,unittest,importlib.util
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/"06_pipeline"/"LO_FINAL_GUIDED_DASHBOARD_BUILD.py"
spec=importlib.util.spec_from_file_location("lo_guided",SRC)
mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
def h(c):return c*64
class GuidedDashboard(unittest.TestCase):
 def contracts(self,b):
  codes=["NLD"]+[f"X{i:02d}" for i in range(41)]
  common=b/"COMMON42_REGISTER.csv"
  with common.open("w",newline="",encoding="utf-8") as f:
   w=csv.writer(f);w.writerow(["route_code","country_id",
    "country_name_nl","country_name_en","common42_member"])
   for c in codes:w.writerow([c,"iso3:"+c,c,c,"True"])
  figures=[]
  for fig,role,outcome in [
   ("TR_MEAN_age15_reading","TR_MEAN","mean_score"),
   ("TR_BASIC_age15_reading","TR_BASIC","at_or_above_basic"),
   ("EN_PERFORMANCE_PEER_age15_reading_direct_learning_environment",
    "EN_PERFORMANCE_PEER","high_proficiency_peer_exposure")]:
   row={k:"" for k in sorted(mod.CONTRACT_COLS)}
   row.update(figure_id=fig,question="environment" if role=="EN_PERFORMANCE_PEER" else "trends",
     survey="PISA",age="age15",domain="reading",outcome=outcome,
     split="none",view_mode="levels",peer_definition="direct_learning_environment"
       if role=="EN_PERFORMANCE_PEER" else "none",
     expected_series="self_below_high;self_high"
       if role=="EN_PERFORMANCE_PEER" else "total",
     required_years="2025",unit="score_points",
     label_nl=fig,label_en=fig,measure_label_nl="Score",measure_label_en="Score",
     subtitle_nl="Test",subtitle_en="Test",method_id="SYNTH_METHOD",
     old_figure_id=role)
   figures.append(row)
  with (b/"FIGURE_SERIES_CONTRACT_20261002.csv").open("w",newline="",encoding="utf-8") as f:
   w=csv.DictWriter(f,fieldnames=sorted(mod.CONTRACT_COLS))
   w.writeheader();w.writerows(figures)
  return codes
 def test_guided_site_has_42x_languages_deep_links_and_no_old_peers(self):
  with tempfile.TemporaryDirectory() as tmp:
   work=Path(tmp);bundle=work/"bundle";bundle.mkdir()
   codes=self.contracts(bundle)
   out=work/"candidate"
   summary=mod.build(ROOT,bundle,out,synthetic_contract=True)
   self.assertEqual(summary["system_count"],42)
   self.assertEqual(summary["active_figures"],2)
   self.assertEqual(summary["scientific_data_rows"],0)
   self.assertTrue((out/"nl"/"country"/"NLD"/"trends"/"index.html").exists())
   self.assertTrue((out/"en"/"country"/"X00"/"environment"/"index.html").exists())
   self.assertEqual(len(list((out/"data"/"availability").glob("*.json"))),42)
   self.assertTrue((out/"data"/"figure_registry.json").is_file())
   figs=json.loads((out/"data"/"figure_registry.json").read_text())["figures"]
   self.assertEqual([f["outcome"] for f in figs if "PEER" in f["figure_id"]],
                    ["peer_share_below_basic"])
   self.assertNotIn("TR_BASIC_age15_reading",[f["figure_id"] for f in figs])
   avail=json.loads((out/"data"/"availability"/"NLD.json").read_text())
   self.assertTrue(all(x["display_state"]=="PLACEHOLDER" for x in avail["figures"]))
   self.assertEqual(json.loads((out/"data"/"countries"/"NLD.json").read_text())["records"],[])
 def test_no_unvalidated_or_old_high_peer_values_are_accepted(self):
  with tempfile.TemporaryDirectory() as tmp:
   work=Path(tmp);bundle=work/"bundle";bundle.mkdir()
   self.contracts(bundle)
   grid=work/"science.csv"
   row=dict(figure_id="TR_MEAN_age15_reading",country="NLD",year="2025",
     estimate="492",se="2.4",n_unweighted="5120",sample_id="PISA_2025_NLD",
     source_id="synthetic_fixture",scientific_status="SCIENTIFICALLY_VALIDATED",
     input_fingerprint=h("a"),code_fingerprint=h("b"),result_hash=h("c"),
     series_id="total",series_role="focus")
   def write(r):
    with grid.open("w",newline="",encoding="utf-8") as f:
     w=csv.DictWriter(f,fieldnames=sorted(r))
     w.writeheader();w.writerow(r)
   write(row);out=work/"valid"
   summary=mod.build(ROOT,bundle,out,grid,synthetic_contract=True)
   availability=json.loads((out/"data"/"availability"/"NLD.json").read_text())["figures"]
   self.assertEqual(availability[0]["display_state"],"VALIDATED")
   r=json.loads((out/"data"/"countries"/"NLD.json").read_text())["records"][0]
   self.assertEqual(r["estimate"],492)
   self.assertNotIn("ci_low",r)
   row["scientific_status"]="COMPUTED_PENDING_VALIDATION";write(row)
   with self.assertRaises(ValueError):mod.build(ROOT,bundle,work/"hold",grid,synthetic_contract=True)
   row.update(scientific_status="SCIENTIFICALLY_VALIDATED",
      figure_id="EN_PERFORMANCE_PEER_age15_reading_direct_learning_environment")
   write(row)
   with self.assertRaises(ValueError):mod.build(ROOT,bundle,work/"peerhold",grid,synthetic_contract=True)
if __name__=="__main__":unittest.main()
