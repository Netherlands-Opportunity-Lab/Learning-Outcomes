import json,subprocess
from pathlib import Path
repo=Path(__file__).resolve().parents[2]
current=json.loads((repo/'05_publication/INTERIM_CURRENT.json').read_text(encoding='utf-8'))
site=repo/'05_publication/verified_guided_candidates'/current['candidate_id']
subprocess.run(['node',str(repo/'05_publication/tests/verify_current47_selections.mjs'),str(repo),str(site),'dashboard-selection-proof.json'],check=True)
