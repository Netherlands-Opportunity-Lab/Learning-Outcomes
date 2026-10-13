import csv,hashlib,importlib.util,json,tempfile,unittest
from pathlib import Path

REPO=Path(__file__).resolve().parents[2]
def load(name):
    p=REPO/"06_pipeline"/name
    s=importlib.util.spec_from_file_location(name[:-3],p)
    m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
    return m
dashboard=load("LO_FINAL_DASHBOARD_BUILD.py")
release=load("LO_FINAL_PUBLIC_GITHUB.py")
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

class PublicStagingTest(unittest.TestCase):
    def test_require_reviewed_42_science_rights_21_and_immutable_hashes(self):
        with tempfile.TemporaryDirectory() as temp:
            work=Path(temp);bundle=work/"bundle";bundle.mkdir()
            codes=["NLD"]+[f"X{i:02d}" for i in range(41)]
            with (bundle/"COMMON42_REGISTER.csv").open("w",newline="") as f:
                w=csv.writer(f)
                w.writerow(["route_code","country_id","country_name_nl",
                            "country_name_en","common42_member"])
                for c in codes:w.writerow([c,"iso3:"+c,c,c,"True"])
            grid=work/"validated.csv"
            columns=["cell_id","country","survey","year","domain","stat",
                     "group","estimate","se","n_unweighted","unit","family",
                     "variant","sample_id","scientific_status","source"]
            with grid.open("w",newline="") as f:
                w=csv.DictWriter(f,fieldnames=columns);w.writeheader()
                for c in codes:w.writerow(dict(cell_id="synthetic:"+c,
                    country=c,survey="PISA",year="2025",domain="reading",
                    stat="mean",group="total",estimate="500",se="2",
                    n_unweighted="600",unit="score_points",family="levels",
                    variant="official",sample_id="synthetic",
                    scientific_status="SCIENTIFICALLY_VALIDATED",
                    source="synthetic_not_actual"))
            prod=work/"approved";prod.mkdir()
            packs={"metadata":{"countries":[{"country_id":"iso3:"+c,
                        "country_name_nl":c,"country_name_en":c} for c in codes],
                        "panels":{"TEST":{"panel_id":"TEST"}}},
                "ranks":[{"panel_id":"TEST","wave":"PISA2025"}],
                "curated":{"slides":[{"number":i,"title":f"Test {i}",
                     "charts":[],"tables":[]} for i in range(1,22)]},
                "institutions":[],"quality":[]}
            evidence={}
            for key,value in packs.items():
                p=prod/(key+".json");p.write_text(json.dumps(value))
                evidence[key]=sha(p)
            (prod/"APPROVED_PRODUCT_SHA256.json").write_text(json.dumps(evidence))
            candidate=work/"candidate"
            result=dashboard.build(REPO,bundle,grid,candidate,payloads=prod)
            self.assertEqual(result["systems_with_results"],42)
            cert={k:v for k,v in release.REQUIRED_CERT.items()}
            cert["candidate_manifest_sha256"]=sha(candidate/"BUILD_SHA256_MANIFEST.json")
            cfile=work/"certificate.json";cfile.write_text(json.dumps(cert))
            gitroot=work/"gitroot";gitroot.mkdir()
            staged=release.stage(gitroot,candidate,cfile)
            self.assertEqual(staged["status"],"STAGED_NOT_PUBLISHED")
            self.assertEqual(staged["rights_status"],"PASS")
            with self.assertRaises(ValueError):
                release.stage(gitroot,candidate,cfile)
            cert["rights_status"]="HOLD";cfile.write_text(json.dumps(cert))
            with self.assertRaises(ValueError):
                release.stage(gitroot,candidate,cfile)

if __name__=="__main__":unittest.main()
