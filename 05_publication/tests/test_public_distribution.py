"""Adversarial publication-boundary tests; numerical approval cannot override privacy."""
import importlib.util,json,tempfile,unittest,zipfile
from pathlib import Path

spec=importlib.util.spec_from_file_location('public_distribution',Path(__file__).resolve().parents[1]/'public_distribution.py')
p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)

class Boundary(unittest.TestCase):
    def test_reject_private_source_prose(self):
        with self.assertRaises(ValueError):p.check_names(['04_products_or_release/current47/scripts/build_paper.py'])
    def test_reject_renamed_documents(self):
        for name in ['downloads/report.pdf','archive/slides.PPTX','result.sav']:
            with self.subTest(name=name),self.assertRaises(ValueError):p.check_names([name])
    def test_reject_unsafe_paths(self):
        for name in ['../report.csv','C:/private/file','x\\y','/tmp/a']:
            with self.subTest(name=name),self.assertRaises(ValueError):p.check_names([name])
    def test_allow_scientific_evidence(self):
        p.check_names(['06_pipeline/review_20261013/scientific_review/PAPER_CLAIM_RESULTS.csv','assets/brand/logo.svg'])
    def test_reject_nested_archive(self):
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/'test.zip'
            with zipfile.ZipFile(path,'w') as z:z.writestr('hidden.zip',b'not reviewed')
            with self.assertRaises(ValueError):p.verify_archive(path)
    def test_fail_on_old_manifest_without_boundary(self):
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/'test.zip'
            with zipfile.ZipFile(path,'w') as z:z.writestr('PACKAGE_MANIFEST.json',json.dumps({'files':{}}))
            with self.assertRaises(ValueError):p.verify_archive(path)

if __name__=='__main__':unittest.main()
