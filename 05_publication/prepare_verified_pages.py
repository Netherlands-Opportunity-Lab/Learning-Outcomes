"""Prepare only a certified October dashboard; never mix September payloads."""
import importlib.util,json,os,re,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
storage_spec=importlib.util.spec_from_file_location('candidate_storage',Path(__file__).with_name('candidate_storage.py'))
storage=importlib.util.module_from_spec(storage_spec);storage_spec.loader.exec_module(storage)
materialize=storage.materialize
spec=importlib.util.spec_from_file_location('release',ROOT/'06_pipeline/LO_FINAL_GUIDED_PUBLIC_RELEASE.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
def prepare(candidate,output):
 if not re.fullmatch('[a-f0-9]{20}',candidate):raise ValueError('Invalid certified candidate ID')
 site=ROOT/'05_publication/verified_guided_candidates'/candidate
 # Stage() adds its certificate and receipt after the immutable manifest. Check
 # a clean working copy of exactly manifested assets, with the original hashes.
 if output.exists():raise ValueError('Output must be a fresh directory')
 materialize(site,output)
 proof=m.verify(output,site/'PUBLIC_RELEASE_CERTIFICATION.json')
 cert=json.loads((site/'PUBLIC_RELEASE_CERTIFICATION.json').read_text(encoding='utf-8'))
 archive_sha=cert.get('preserved_september_runtime_sha256')
 if archive_sha:
  if output.resolve()!=(ROOT/'public_site_dist').resolve():raise ValueError('Archive requires the bounded Pages output')
  if m.sha(ROOT/'05_publication/public_dashboard_runtime_20260928.zip')!=archive_sha:raise ValueError('September archive changed')
  env=dict(os.environ,LO_BUILD_SEPTEMBER_ARCHIVE='1')
  subprocess.run([sys.executable,str(ROOT/'05_publication/build_public_pages.py')],env=env,check=True)
  proof['september_archive']='archive/2026-09-28/'
 print(json.dumps(proof,sort_keys=True))
if __name__=='__main__':prepare(os.environ.get('DASHBOARD_CANDIDATE',''),ROOT/'public_site_dist')
