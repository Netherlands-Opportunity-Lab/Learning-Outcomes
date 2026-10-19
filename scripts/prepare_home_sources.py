"""Bind exact IEA home files, including earlier TIMSS cycles, without guessing absence.

Only an ASH sibling of the byte-identical approved ASG source is extracted.
This distinguishes digital/main/bridge files in the same official archive.
An absent member is recorded explicitly; it does not prove an unasked question.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import shutil
import zipfile


def sha(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def prepare(manifest, root, archives, output):
    manifest, root, archives, output = (p.resolve() for p in (manifest, root, archives, output))
    with manifest.open(encoding='utf-8-sig', newline='') as f:
        contexts = list(csv.DictReader(f))
    oldpath = root / 'international/HOME_SOURCE_MANIFEST.csv'
    with oldpath.open(encoding='utf-8-sig', newline='') as f:
        old = {(r['country'], r['survey'], r['year']): r for r in csv.DictReader(f)}
    records, proof, opened = [], [], {}
    try:
        for row in contexts:
            if row['survey'] == 'PISA':
                continue
            key = tuple(row[k] for k in ('country', 'survey', 'year'))
            previous = old.get(key)
            if previous and previous['path']:
                if sha(Path(previous['path'])) != previous['sha256']:
                    raise ValueError('Changed existing home source')
                records.append(previous)
                continue
            raw = Path(row['raw_path'])
            name = 'ash' + raw.name[3:]
            target, archive, member = None, '', ''
            if row['survey'] == 'PIRLS':
                parts = list(raw.parts)
                positions = [i for i, p in enumerate(parts) if p.upper() == 'ASG']
                if len(positions) != 1:
                    raise ValueError('Explicit PIRLS ASG/ASH directory binding required')
                parts[positions[0]] = 'ASH'
                parent = Path(*parts).parent
                hits = [p for p in parent.iterdir() if p.name.lower() == name.lower()] if parent.exists() else []
                if len(hits) > 1:
                    raise ValueError('Ambiguous home source')
                if hits:
                    target = hits[0]
            else:
                archive = archives / f"TIMSS{row['year']}_IDB_SPSS_G4.zip"
                if archive not in opened:
                    opened[archive] = zipfile.ZipFile(archive)
                z = opened[archive]
                siblings = [n for n in z.namelist() if Path(n).name.lower() == raw.name.lower()]
                matches = [n for n in siblings if hashlib.sha256(z.read(n)).hexdigest() == row['raw_sha256']]
                if len(matches) != 1:
                    raise ValueError('Exact ASG archive member identity unresolved: ' + str(key))
                parent = Path(matches[0]).parent
                members = [n for n in z.namelist() if Path(n).parent == parent and Path(n).name.lower() == name.lower()]
                if len(members) > 1:
                    raise ValueError('Ambiguous ASH sibling')
                if members:
                    member = members[0]
                    if z.getinfo(member).file_size > 100 * 1024**2:
                        raise ValueError('Unexpected home-file size')
                    target = root / 'international/home_sources' / row['year'] / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    content = z.read(member)
                    if target.exists():
                        if sha(target) != hashlib.sha256(content).hexdigest():
                            raise ValueError('Existing home source differs')
                    else:
                        if shutil.disk_usage(root).free < 4 * 1024**3:
                            raise ValueError('Home extraction space reserve')
                        target.write_bytes(content)
            records.append(dict(country=key[0], survey=key[1], year=key[2],
                path=target.as_posix() if target else '', sha256=sha(target) if target else '',
                archive=str(archive) if member else '', member=member))
            proof.append(dict(country=key[0], survey=key[1], year=key[2],
                status='EXACT_HOME_FILE_BOUND' if target else 'NO_MATCHING_HOME_MEMBER_IN_REVIEWED_SOURCE',
                student_source_sha256=row['raw_sha256'], archive=str(archive), member=member))
    finally:
        for z in opened.values():
            z.close()
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open('w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, list(records[0]), lineterminator='\n')
        w.writeheader(); w.writerows(records)
    receipt = dict(source_manifest_sha256=sha(manifest), home_manifest_sha256=sha(output),
        contexts=len(records), with_home_file=sum(bool(r['path']) for r in records),
        previous_paths_preserved=True, reviewed=proof, code_sha256=sha(Path(__file__)))
    output.with_suffix('.json').write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in receipt.items() if k != 'reviewed'}))


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    for name in ('manifest', 'root', 'archives', 'output'):
        p.add_argument('--'+name, type=Path, required=True)
    a = p.parse_args(); prepare(a.manifest, a.root, a.archives, a.output)
