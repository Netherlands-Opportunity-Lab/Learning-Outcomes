#!/usr/bin/env python3
"""Package exactly the current manifest-driven files, excluding old working files."""
from pathlib import Path
import hashlib,csv,zipfile,json
R=Path(__file__).resolve().parents[1];OUT=R.parent/'dashboard_delivery';OUT.mkdir(exist_ok=True)
allowedcsv={p.name for p in (R/'source_snapshot').glob('*.csv')}|{p.name for p in (R/'addenda').glob('*.csv')}
files=[]
for f in ['index.html','downloads.html','README.md','DASHBOARD_VALIDATION.md','assets/app.js','assets/styles.css','scripts/build_bundle.py','scripts/build_downloads.py','scripts/validate_release.py','scripts/package_release.py','tests/render_checks.cjs','docs/SCIENTIFIC_BOUNDARIES.md','docs/PUBLICATION_STATUS.md','docs/DATA_CONTRACT.md','docs/DEPLOYMENT_README.md']:
 files.append(R/f)
for folder in ['source_snapshot','addenda','audit']:
 files.extend(p for p in (R/folder).rglob('*') if p.is_file() and p.suffix!='.png' and p.name not in ['GITHUB_STEP4_RECEIPT.json','GITHUB_STEP4_RECEIPT.md'])
files.extend(p for p in (R/'data/csv').glob('*.csv') if p.name in allowedcsv)
for file in ['countries','release','metadata','international','nl_international_reference','domain_context','figures']:
 files.append(R/f'data/json/{file}.json')
files.extend((R/'data/json/profiles').glob('*.json'))
for sub in ['png','svg','pdf','plotting_data','metadata']:
 files.extend((R/'figures'/sub).glob('*'))
files.extend([R/'figures/BUILD_COMPLETE.json',R/'figures/FIGURE_MANIFEST.csv'])
files=sorted(set(p for p in files if p.is_file()))
manifest=[{'path':p.relative_to(R).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in files]
with (OUT/'DASHBOARD_MANIFEST_SHA256.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=manifest[0]);w.writeheader();w.writerows(manifest)
zipfile_path=OUT/'PISA_PIRLS_DASHBOARD_STEP4_PRIVATE.zip'
with zipfile.ZipFile(zipfile_path,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for p in files:z.write(p,'PISA_PIRLS_DASHBOARD_STEP4_PRIVATE/'+p.relative_to(R).as_posix())
 z.write(OUT/'DASHBOARD_MANIFEST_SHA256.csv','PISA_PIRLS_DASHBOARD_STEP4_PRIVATE/MANIFEST_SHA256.csv')
source_zip=OUT/'DASHBOARD_BUILD_INPUTS.zip'
with zipfile.ZipFile(source_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for p in files:
  if p.relative_to(R).parts[0] in {'source_snapshot','addenda'}:z.write(p,p.relative_to(R).as_posix())
summary={'files':len(files)+1,'archive':zipfile_path.name,'bytes':zipfile_path.stat().st_size,'sha256':hashlib.sha256(zipfile_path.read_bytes()).hexdigest(),'source_zip_bytes':source_zip.stat().st_size,'source_zip_sha256':hashlib.sha256(source_zip.read_bytes()).hexdigest()}
(OUT/'PACKAGE.json').write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary))
