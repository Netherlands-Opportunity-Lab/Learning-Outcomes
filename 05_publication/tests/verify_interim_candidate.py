"""Cross-platform acceptance on actual public aggregates, no pupil data."""
import importlib.util,json,shutil,subprocess,sys,tempfile,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]

def main():
    pointer=ROOT/'05_publication/INTERIM_CURRENT.json'
    if not pointer.exists():
        print('No staged interim candidate yet; software-only checks.');return
    current=json.loads(pointer.read_text(encoding='utf-8'))
    candidate=ROOT/'05_publication/verified_guided_candidates'/current['candidate_id']
    spec=importlib.util.spec_from_file_location('release',ROOT/'06_pipeline/LO_FINAL_GUIDED_PUBLIC_RELEASE.py')
    release=importlib.util.module_from_spec(spec);spec.loader.exec_module(release)
    entries=json.loads((candidate/'BUILD_SHA256_MANIFEST.json').read_text(encoding='utf-8'))
    with tempfile.TemporaryDirectory() as td:
        root=Path(td);site=root/'site';site.mkdir()
        for entry in entries:
            rel=Path(entry['path'])
            if rel.is_absolute() or '..' in rel.parts or ':' in str(rel) or '\\' in entry['path']:raise ValueError('Unsafe release path')
            dest=site/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(candidate/rel,dest)
        shutil.copyfile(candidate/'BUILD_SHA256_MANIFEST.json',site/'BUILD_SHA256_MANIFEST.json')
        print(json.dumps(release.verify(site,candidate/'PUBLIC_RELEASE_CERTIFICATION.json')))
        # The release gate inspected every archive member before extraction.
        package=root/'package';package.mkdir()
        with zipfile.ZipFile(site/'replication/learning-outcomes-replication.zip') as z:z.extractall(package)
        subprocess.run([sys.executable,str(package/'reproduce_dashboard.py'),'--output',str(root/'rebuilt')],check=True)

if __name__=='__main__':main()
