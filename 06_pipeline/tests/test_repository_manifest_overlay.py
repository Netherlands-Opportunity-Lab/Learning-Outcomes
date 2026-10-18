"""The full repository check must preserve historical ignore protections."""
import hashlib,json,subprocess,sys,tempfile,unittest
from pathlib import Path
REPO=Path(__file__).resolve().parents[2]

class HistoricalIgnoreProtection(unittest.TestCase):
    def test_exact_publication_addition_passes_but_removed_protection_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            names=['README.md','REPRODUCIBILITY.md','DATA_SOURCES.md','METHODS.md','KNOWN_LIMITATIONS.md',
              '01_data_download_preprocessing/README.md','02_analysis/README.md','03_dashboard/README.md',
              '04_products_or_release/README.md','03_dashboard/app/index.html','03_dashboard/app/downloads.html',
              '03_dashboard/app/assets/app-product.js','03_dashboard/app/assets/styles.css']
            for name in names:
                p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text('fixture\n',encoding='utf-8')
            data=root/'03_dashboard/data/PRODUCTION_DATA_MANIFEST.csv';data.parent.mkdir(parents=True)
            data.write_text('file\n'+'\n'.join(['product_data/FINAL_PRODUCT_BASIS.csv.gz','product_data/RESULTATEN_MASTER.csv.gz','product_data/metadata.json','product_data/ranks.json','product_data/curated.json','product_data/quality.json'])+'\n',encoding='utf-8')
            original=b'.env\n*.sav\n*secret*\n*token*\n'
            p=root/'.gitignore'
            (root/'PRODUCTION_MANIFEST.json').write_text(json.dumps({'files':[{'path':'.gitignore','bytes':len(original),'sha256':hashlib.sha256(original).hexdigest()}]}),encoding='utf-8')
            validator=root/'scripts/validate_repository.py';validator.parent.mkdir()
            validator.write_bytes((REPO/'scripts/validate_repository.py').read_bytes())
            def check(content):
                p.write_bytes(content)
                return subprocess.run([sys.executable,str(validator)],text=True,capture_output=True)
            self.assertEqual(check(original).returncode,0)
            additions=b'__pycache__/\n*.pyc\n\n# Generated publication build\npublic_site_dist/\n'
            self.assertEqual(check(original+additions).returncode,0)
            # Do not turn a stale-manifest fix into a blanket exemption.
            for changed in [(original+additions).replace(b'.env\n',b''),original+additions+b'!*.sav\n',original+additions+additions]:
                result=check(changed)
                self.assertNotEqual(result.returncode,0)
                self.assertIn('manifest',result.stdout)

if __name__=='__main__':unittest.main()
