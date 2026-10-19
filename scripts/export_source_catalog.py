"""Export only portable, hash-pinned source identities from reviewed manifests.

Pupil data and private paths never leave the local audit. Source availability
does not certify eligibility; the R verifier and population review do that.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path


def sha(p):
    with p.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def read(p):
    with p.open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def export(root, output):
    source=root/'international/SOURCE_RUN_MANIFEST.csv'
    homes=root/'international/HOME_SOURCE_MANIFEST.csv'
    rows=read(source); home_rows=read(homes)
    control_hashes={p:sha(Path(p)) for p in {r['control_path'] for r in rows} if p}
    fields=['country','survey','year','raw_sha256','source_country','allowed_grades',
            'population_note','population_evidence']
    records=[dict({k:r[k] for k in fields},source_filename=Path(r['raw_path']).name,
                  control_filename=Path(r['control_path']).name if r['control_path'] else '',
                  control_sha256=control_hashes.get(r['control_path'],'')) for r in rows]
    records_home=[dict({k:r[k] for k in ('country','survey','year','sha256')},
                      source_filename=Path(r['path']).name if r['path'] else '',
                      availability='LOCALLY_HASH_VERIFIED' if r['path'] else 'NO_MATCHING_HOME_FILE_IN_REVIEWED_ARCHIVE') for r in home_rows]
    output.mkdir(parents=True,exist_ok=True)
    for name,data in [('SOURCE_CATALOG.csv',records),('HOME_SOURCE_CATALOG.csv',records_home)]:
        if any(':/Users/' in str(v) or '\\Users\\' in str(v) for r in data for v in r.values()):
            raise ValueError('Private path in public catalogue')
        with (output/name).open('w',encoding='utf-8',newline='') as f:
            w=csv.DictWriter(f,list(data[0]),lineterminator='\n');w.writeheader();w.writerows(data)
    proof=dict(source_contexts=len(rows),home_contexts=len(home_rows),
               source_manifest_sha256=sha(source),home_manifest_sha256=sha(homes),
               catalogue_sha256={n:sha(output/n) for n in ('SOURCE_CATALOG.csv','HOME_SOURCE_CATALOG.csv')},
               producer_sha256=sha(Path(__file__)),status='PORTABLE_SOURCE_IDENTITIES_EXPORTED_NOT_SCIENTIFIC_APPROVAL')
    (output/'SOURCE_CATALOG_PROVENANCE.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps(proof))


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    a=p.parse_args();export(a.root,a.output)
