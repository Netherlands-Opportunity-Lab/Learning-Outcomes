"""Cross-platform acceptance on actual public aggregates, no pupil data."""
import importlib.util,json,shutil,subprocess,sys,tempfile,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / '05_publication'))
from candidate_storage import materialize

def main():
    pointer=ROOT/'05_publication/INTERIM_CURRENT.json'
    if not pointer.exists():
        print('No staged interim candidate yet; software-only checks.');return
    current=json.loads(pointer.read_text(encoding='utf-8'))
    candidate=ROOT/'05_publication/verified_guided_candidates'/current['candidate_id']
    spec=importlib.util.spec_from_file_location('package_check',ROOT/'06_pipeline/LO_PARTIAL_DASHBOARD_RELEASE.py')
    package_check=importlib.util.module_from_spec(spec);spec.loader.exec_module(package_check)
    with tempfile.TemporaryDirectory() as td:
        root=Path(td);site=root/'site'
        materialize(candidate,site)
        certificate=candidate/'PUBLIC_RELEASE_CERTIFICATION.json'
        if json.loads(certificate.read_text())['candidate_manifest_sha256']!=package_check.sha(site/'BUILD_SHA256_MANIFEST.json'):
            raise ValueError('Historical release certificate changed')
        # The public interim snapshot predates later scientific policy changes.
        # Reproduce it with its exact packaged gate, after current path/byte
        # checks. Current-release policy is tested separately; never relabel
        # the old all-six approval as approval of the new combination rule.
        package_check.verify_package(site/'replication/learning-outcomes-replication.zip')
        package=root/'package';package.mkdir()
        with zipfile.ZipFile(site/'replication/learning-outcomes-replication.zip') as z:z.extractall(package)
        spec=importlib.util.spec_from_file_location('historical_release',package/'06_pipeline/LO_FINAL_GUIDED_PUBLIC_RELEASE.py')
        release=importlib.util.module_from_spec(spec);spec.loader.exec_module(release)
        print(json.dumps(release.verify(site,certificate)))
        subprocess.run([sys.executable,str(package/'reproduce_dashboard.py'),'--output',str(root/'rebuilt')],check=True)

if __name__=='__main__':main()
