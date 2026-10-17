"""Prepare only a certified October dashboard; never mix September payloads."""
import importlib.util,json,os,re,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('release',ROOT/'06_pipeline/LO_FINAL_GUIDED_PUBLIC_RELEASE.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
def prepare(candidate,output):
 if not re.fullmatch('[a-f0-9]{20}',candidate):raise ValueError('Invalid certified candidate ID')
 site=ROOT/'05_publication/verified_guided_candidates'/candidate
 # Stage() adds its certificate and receipt after the immutable manifest. Check
 # a clean working copy of exactly manifested assets, with the original hashes.
 if output.exists():raise ValueError('Output must be a fresh directory')
 entries=json.loads((site/'BUILD_SHA256_MANIFEST.json').read_text(encoding='utf-8'))
 for item in entries:
  rel=Path(item['path'])
  if rel.is_absolute() or '..' in rel.parts or ':' in str(rel) or '\\' in item['path']:raise ValueError('Unsafe asset path')
  src=site/rel;dest=output/rel
  if src.is_symlink() or not src.resolve().is_relative_to(site.resolve()):raise ValueError('Unsafe asset source')
  dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dest)
 shutil.copyfile(site/'BUILD_SHA256_MANIFEST.json',output/'BUILD_SHA256_MANIFEST.json')
 proof=m.verify(output,site/'PUBLIC_RELEASE_CERTIFICATION.json')
 print(json.dumps(proof,sort_keys=True))
if __name__=='__main__':prepare(os.environ.get('DASHBOARD_CANDIDATE',''),ROOT/'public_site_dist')
