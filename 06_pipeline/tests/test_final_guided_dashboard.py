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
   self.assertEqual(summary["active_figures"],1)
   self.assertEqual(summary["scientific_data_rows"],0)
   self.assertTrue((out/"nl"/"country"/"NLD"/"trends"/"index.html").exists())
   self.assertTrue((out/"en"/"country"/"X00"/"environment"/"index.html").exists())
   self.assertEqual(len(list((out/"data"/"availability").glob("*.json"))),42)
   self.assertTrue((out/"data"/"figure_registry.json").is_file())
   figs=json.loads((out/"data"/"figure_registry.json").read_text())["figures"]
   self.assertEqual([f["outcome"] for f in figs if "PEER" in f["figure_id"]],
                    [])
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
     series_id="total",series_role="focus",n_definition="SYNTHETIC_ANALYTIC_FRAME")
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
   self.assertEqual(r["sample_id"],row["sample_id"])
   self.assertEqual(r["input_fingerprint"],h("a"))
   self.assertEqual(r["code_fingerprint"],h("b"))
   self.assertEqual(r["result_hash"],h("c"))
   self.assertEqual(r["n_definition"],"SYNTHETIC_ANALYTIC_FRAME")
   self.assertNotIn("ci_low",r)
   row["scientific_status"]="COMPUTED_PENDING_VALIDATION";write(row)
   with self.assertRaises(ValueError):mod.build(ROOT,bundle,work/"hold",grid,synthetic_contract=True)
   row.update(scientific_status="SCIENTIFICALLY_VALIDATED",
      figure_id="EN_PERFORMANCE_PEER_age15_reading_direct_learning_environment")
   write(row)
   with self.assertRaises(ValueError):mod.build(ROOT,bundle,work/"peerhold",grid,synthetic_contract=True)
 def test_joint_year_group_hole_does_not_pass_marginal_coverage(self):
  f=dict(required_years="2018;2022",expected_series="boy;girl")
  rows=[dict(year=2018,series_id="boy",series_role="focus"),dict(year=2022,series_id="girl",series_role="focus")]
  self.assertFalse(mod.figure_complete(rows,f))
  rows.extend([dict(year=2018,series_id="girl",series_role="focus"),dict(year=2022,series_id="boy",series_role="focus")])
  self.assertTrue(mod.figure_complete(rows,f))
 def test_pisa_language_placeholder_resolution_and_construct_guard(self):
  with tempfile.TemporaryDirectory() as tmp:
   b=Path(tmp);self.contracts(b)
   path=b/"FIGURE_SERIES_CONTRACT_20261002.csv"
   with path.open(encoding="utf-8") as f: rows=list(csv.DictReader(f))
   for name,groups in [("LEVELS","source_valid_groups"),("GAP","source_valid_contrast")]:
    item=dict(rows[0],figure_id=f"GP_LANGUAGE_{name}_age15_reading",expected_series=groups)
    rows.append(item)
   rows.append(dict(rows[0],figure_id="GP_SES_HIGH_age15_reading",expected_series="q1;q4"))
   with path.open("w",newline="",encoding="utf-8") as f:
    w=csv.DictWriter(f,fieldnames=sorted(mod.CONTRACT_COLS));w.writeheader();w.writerows(rows)
   figures=mod.figure_contract(b,allow_synthetic=True,decisions={"A02":"APPROVED"})
   self.assertFalse(any(x["figure_id"].startswith("GP_SES_HIGH_") for x in figures))
   f=next(x for x in figures if x["figure_id"]=="GP_LANGUAGE_LEVELS_age15_reading")
   self.assertEqual(f["expected_series"],"test_language_home;other_language_home")
   gap=next(x for x in figures if x["figure_id"]=="GP_LANGUAGE_GAP_age15_reading")
   self.assertEqual(gap["expected_series"],"other_minus_test")
   row=dict(figure_id=f["figure_id"],country="NLD",year="2025",estimate="500",se="2",n_unweighted="5000",
    sample_id="synthetic",source_id="synthetic",scientific_status="SCIENTIFICALLY_VALIDATED",
    input_fingerprint=h("a"),code_fingerprint=h("b"),result_hash=h("c"),series_id="test_language_home",
    outcome_id="same_as_assessment_language_vs_other")
   grid=b/"grid.csv"
   def save():
    with grid.open("w",newline="",encoding="utf-8") as stream:
     w=csv.DictWriter(stream,fieldnames=list(row));w.writeheader();w.writerow(row)
   save();actual=mod.product_rows(grid,["NLD"],figures)
   self.assertEqual(len(actual),1)
   self.assertFalse(mod.figure_complete(actual,f)) # missing the other group
   row["outcome_id"]="dutch_vs_other";save()
   with self.assertRaisesRegex(ValueError,"language construct"):mod.product_rows(grid,["NLD"],figures)
 def test_dynamic_admission_does_not_force_rich_20_or_common42(self):
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp)/"countries.csv"
   rows=[dict(country=c,dashboard_eligible=ok,selected_for_production="TRUE",country_name_nl=c,country_name_en=c,eligibility_basis="SHA_VERIFIED_SOURCE_SUPPORT") for c,ok in [("NLD","TRUE"),("Z99","TRUE"),("AUT","FALSE")]]
   with path.open("w",newline="",encoding="utf-8") as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
   self.assertEqual([r["route_code"] for r in mod.country_contract(Path(tmp),path)],["NLD","Z99"])
if __name__=="__main__":unittest.main()

