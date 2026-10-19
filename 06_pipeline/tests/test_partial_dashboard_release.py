"""Interim publication cannot launder changed points, fake completeness or refs."""
import csv, hashlib, importlib.util, io, json, tempfile, unittest, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]

def load(name,file):
    s=importlib.util.spec_from_file_location(name,ROOT/"06_pipeline"/file)
    m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m

m=load("partial","LO_PARTIAL_DASHBOARD_RELEASE.py")
b=load("builder","LO_FINAL_GUIDED_DASHBOARD_BUILD.py")
p=load("packager","LO_DASHBOARD_PUBLIC_PACKAGE.py")
strict=load("strict","LO_FINAL_GUIDED_PUBLIC_RELEASE.py")

class PartialRelease(unittest.TestCase):
    def fixture(self,site):
        def put(name,value):p.put_json(site/name,value)
        f=dict(figure_id="TR_MEAN_age15_reading",required_years="2018;2022",expected_series="total",
               unit="score_points",method_id="M_CORE",active_role="BASE",survey="PISA",domain="reading")
        row=dict(figure_id=f["figure_id"],country="NLD",year="2018",series_id="total",cell_id="cell-1",
                 estimate="500.123456789",se="2.1",n_unweighted="4000",sample_id="SAMPLE",
                 source_id="GRID:SHA256:"+"a"*64,scientific_status="SCIENTIFICALLY_VALIDATED",
                 input_fingerprint="a"*64,code_fingerprint="b"*64,result_hash="c"*64)
        csvfile=site.parent/"data.csv"
        with csvfile.open("w",newline="",encoding="utf-8") as stream:
            w=csv.DictWriter(stream,fieldnames=row);w.writeheader();w.writerow(row)
        put("data/common42.json",[{"code":"NLD","nl":"Nederland","en":"Netherlands"}])
        put("data/figure_registry.json",{"figures":[f]})
        put("data/countries/NLD.json",{"records":b.product_rows(csvfile,["NLD"],[f])})
        put("data/availability/NLD.json",{"figures":[dict(figure_id=f["figure_id"],display_state="PARTIAL",
            available_points=1,required_points=2,missing_points=[dict(year=2022,series_id="total")])]})
        put("data/explorer_references.json",dict(policy="FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3",figures=[dict(
            focus="NLD",figure_id=f["figure_id"],status="COMPARABILITY_PENDING",eligible_members=[],default_members=[],evidence_sha256=None)]))
        qa=dict(scientific_data_rows=1,availability_counts={"PARTIAL":1},review_release=dict(kind=m.KIND,full_scientific_release=False,source_commit="d"*40))
        for key in ("country_registry_sha256","figure_contract_sha256","scope_decisions_sha256"):qa[key]="a"*64
        qa["scientific_source_sha256"]=m.sha(csvfile)
        put("GUIDED_QA.json",qa)
        put("data/snapshot_provenance.json",dict(displayed_cell_validation="FRESH_SOURCE_CERTIFICATE_HASH_AND_NUMERIC_VERIFICATION",public_dashboard_points=1))
        for lang in ("nl","en"):
            put(f"info/{lang}/index.html",{})
            for q in ("trends","distribution","gaps","environment"):put(f"{lang}/country/NLD/{q}/index.html",{})
        content={name:b"fixture" for name in ("README.md","reproduce_dashboard.py","START.R","06_pipeline/RUN.R","release_inputs/PROVENANCE.json")}
        content["release_inputs/dashboard_cells.csv"]=csvfile.read_bytes()
        content["PACKAGE_MANIFEST.json"]=json.dumps(dict(source_commit="d"*40,files={n:hashlib.sha256(v).hexdigest() for n,v in content.items()})).encode()
        target=site/m.PACKAGE;target.parent.mkdir(parents=True)
        with zipfile.ZipFile(target,"w") as z:
            for name,data in content.items():z.writestr(name,data)
        cert=dict(release_kind=m.KIND,authorization="USER_2026_10_18_PUBLISH_AVAILABLE_LEAVE_MISSING_OPEN",
                  full_scientific_release=False,eligible_countries=["NLD"],approved_figure_ids=[f["figure_id"]])
        for field in ("displayed_cell_validation","rights_boundary","scope_decisions","dashboard_combination_admission","static_site_QA","dashboard_reproduction"):cert[field]="PASS"
        cert.update({k:v for k,v in qa.items() if k.endswith("_sha256")})
        return cert

    def check(self,site,cert):
        p.write_manifest(site);cert["candidate_manifest_sha256"]=m.sha(site/"BUILD_SHA256_MANIFEST.json")
        cf=site.parent/"cert.json";p.put_json(cf,cert)
        return strict.verify(site,cf)

    def test_partial_is_not_final_and_preserves_numeric_precision(self):
        with tempfile.TemporaryDirectory() as td:
            site=Path(td)/"site";site.mkdir();cert=self.fixture(site)
            self.assertEqual(self.check(site,cert)["release_gate"],"PASS_PARTIAL_DISPLAY_ONLY_FULL_SCIENCE_INCOMPLETE")
            cert.pop("release_kind")
            with self.assertRaisesRegex(ValueError,"approval missing"):self.check(site,cert)

    def test_changed_estimate_cannot_be_laundered_by_new_manifest(self):
        with tempfile.TemporaryDirectory() as td:
            site=Path(td)/"site";site.mkdir();cert=self.fixture(site)
            file=site/"data/countries/NLD.json";data=m.read(file);data["records"][0]["estimate"]=501
            p.put_json(file,data)
            with self.assertRaisesRegex(ValueError,"differ from verified package"):self.check(site,cert)

    def test_fake_complete_missing_group_and_reference_are_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            site=Path(td)/"site";site.mkdir();cert=self.fixture(site)
            file=site/"data/availability/NLD.json";original=m.read(file);bad=json.loads(json.dumps(original))
            bad["figures"][0]["display_state"]="VALIDATED";p.put_json(file,bad)
            with self.assertRaisesRegex(ValueError,"availability status"):self.check(site,cert)
            bad["figures"][0]["missing_points"]=[];p.put_json(file,bad)
            with self.assertRaisesRegex(ValueError,"missing points"):self.check(site,cert)
            p.put_json(file,original)
            file=site/"data/explorer_references.json";refs=m.read(file);refs["figures"][0]["eligible_members"]=["AUT"]
            p.put_json(file,refs)
            with self.assertRaisesRegex(ValueError,"unverified reference"):self.check(site,cert)

    def test_archive_cannot_hide_pupil_data(self):
        with tempfile.TemporaryDirectory() as td:
            site=Path(td)/"site";site.mkdir();cert=self.fixture(site)
            with zipfile.ZipFile(site/m.PACKAGE,"a") as z:z.writestr("private.sav",b"must never publish")
            with self.assertRaisesRegex(ValueError,"source/binary archive"):self.check(site,cert)

    def test_temporary_policy_requires_explicit_binding_and_exact_available_options(self):
        with tempfile.TemporaryDirectory() as td:
            site=Path(td)/"site";site.mkdir();cert=self.fixture(site)
            policy=site/'data/reference_policy.json'
            policy.write_bytes((ROOT/'05_publication/REFERENCE_POLICY.json').read_bytes())
            registry=Path(td)/'countries.csv'
            registry.write_text('country,dashboard_eligible,selected_for_production,country_name_nl,country_name_en,eligibility_basis,rich_candidate\nNLD,TRUE,TRUE,Nederland,Netherlands,SHA_VERIFIED_SOURCE_SUPPORT,TRUE\n',encoding='utf-8')
            qa=m.read(site/'GUIDED_QA.json')
            qa.update(reference_mode='AVAILABLE_CASES_PROVISIONAL',reference_policy_sha256=m.sha(policy))
            qa['review_release']['reference_policy']='AVAILABLE_CASES_PROVISIONAL'
            p.put_json(site/'GUIDED_QA.json',qa)
            figures=m.read(site/'data/figure_registry.json')['figures']
            rows=m.read(site/'data/countries/NLD.json')['records']
            refs=b.provisional_references(policy,b.country_contract(None,registry),figures,rows,qa['scientific_source_sha256'])
            p.put_json(site/'data/explorer_references.json',refs)
            target=site/m.PACKAGE
            with zipfile.ZipFile(target) as z:content={n:z.read(n) for n in z.namelist() if n!='PACKAGE_MANIFEST.json'}
            content['release_inputs/REFERENCE_POLICY.json']=policy.read_bytes()
            content['release_inputs/COUNTRY_SOURCE_ELIGIBILITY.csv']=registry.read_bytes()
            content['PACKAGE_MANIFEST.json']=json.dumps(dict(source_commit='d'*40,files={n:hashlib.sha256(v).hexdigest() for n,v in content.items()})).encode()
            with zipfile.ZipFile(target,'w') as z:
                for name,data in content.items():z.writestr(name,data)
            with self.assertRaisesRegex(ValueError,'unbound provisional'):self.check(site,cert)
            cert.update(temporary_reference_authorization='USER_2026_10_18_TEMPORARY_AVAILABLE_RESULTS',reference_policy_sha256=m.sha(policy))
            self.assertEqual(self.check(site,cert)['release_gate'],'PASS_PARTIAL_DISPLAY_ONLY_FULL_SCIENCE_INCOMPLETE')
            refs['figures'][0]['eligible_members']=['AUT']
            p.put_json(site/'data/explorer_references.json',refs)
            with self.assertRaisesRegex(ValueError,'differ from available approved points'):self.check(site,cert)

if __name__=="__main__":unittest.main()
