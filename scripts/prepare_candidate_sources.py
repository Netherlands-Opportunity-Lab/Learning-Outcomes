"""Prepare explicit additional source contexts; this is not admission or certification.

Preserve every existing source contract. Candidate source rows are taken from
the retained, hash-pinned discovery indices and must pass the real R audit.
Never reinterpret a missing local file as non-participation.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path


def rows(p):
    with p.open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def sha(p):
    with p.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def build(repo, root, output):
    private = root / 'international'
    screen_path = repo / '06_pipeline/review_20261013/scientific_review/COMBINATION_CANDIDATE_SCREEN.json'
    screen = json.loads(screen_path.read_text(encoding='utf-8'))
    candidates = set(screen['new_candidate_countries'])
    old = rows(private / 'SOURCE_RUN_MANIFEST.csv')
    iea = rows(private / 'IEA_POPULATION_REVIEW.csv')
    adjudication_path=repo/'06_pipeline/review_20261013/CANDIDATE_POPULATION_ADJUDICATIONS.json'
    overrides=json.loads(adjudication_path.read_text(encoding='utf-8'))['source_overrides']
    override_keys={(r['country'],r['survey'],int(r['year'])):r for r in overrides}
    fields = list(old[0])
    keys = {(r['country'], r['survey'], int(r['year'])) for r in old}
    proposed = sorted({(r['country'], r['survey'], y)
        for r in screen['combinations'] if r['country'] in candidates for y in r['years']} | set(override_keys))
    new = []
    for country, survey, year in proposed:
        if (country, survey, year) in keys:
            continue
        if survey == 'PISA':
            templates = [r for r in old if r['survey'] == survey and int(r['year']) == year]
            identities = {(r['raw_path'], r['raw_sha256'], r['control_path'], r['index_path']) for r in templates}
            if len(identities) != 1:
                raise ValueError(f'Ambiguous source edition {survey} {year}')
            record = templates[0].copy()
            record.update(country=country, source_country=country,
                population_note='Official PISA participant age-target sample; source scores and country-cycle sampling/trend qualifications require explicit verification.',
                population_evidence=f'https://www.oecd.org/en/data/datasets/pisa-{year}-database.html')
            if year == 2009 and country in ('CRI', 'MDA', 'MLT', 'MYS'):
                record['population_note'] += ' PISA 2009+ administration in 2010, published in the combined official 2009 file; keep this timing qualification.'
        else:
            found = [r for r in iea if r['country'] == country and r['survey'] == survey and int(r['year']) == year
                     and (r['source_context_status'] == 'CORE_POPULATION_CHECKED' or (country,survey,year) in override_keys)]
            if len(found) != 1:
                raise ValueError(f'Ambiguous IEA source {country} {survey} {year}')
            r = found[0]
            record = dict(country=country, survey=survey, year=str(year), raw_path=r['raw_path'], raw_sha256=r['raw_sha256'],
                source_country=r['country_id'], control_path='', index_path='', allowed_grades=r['allowed_grades'],
                population_note=r['population_note'], population_evidence=r['population_evidence'])
            if (country,survey,year) in override_keys:
                review=override_keys[(country,survey,year)]
                record.update({k:review[k] for k in ('allowed_grades','population_note','population_evidence')})
        if not Path(record['raw_path']).is_file():
            raise ValueError('Missing actual local source: ' + record['raw_path'])
        new.append(record)
    output.mkdir(parents=True, exist_ok=True)
    for filename, records in [('CANDIDATE_SOURCE_MANIFEST.csv', new), ('PROPOSED_SOURCE_RUN_MANIFEST.csv', old + new)]:
        with (output / filename).open('w', encoding='utf-8', newline='') as f:
            w = csv.DictWriter(f, fields, lineterminator='\n'); w.writeheader(); w.writerows(records)
    report = dict(status='PREPARED_SOURCE_CONTEXTS_NOT_CERTIFIED', countries=sorted(candidates),
        candidate_count=len(candidates), new_contexts=len(new), previous_contexts=len(old),
        combined_contexts=len(old)+len(new), original_contracts_preserved=True,
        input_sha256={str(p.name): sha(p) for p in (screen_path, private/'SOURCE_RUN_MANIFEST.csv', private/'IEA_POPULATION_REVIEW.csv',adjudication_path)},
        code_sha256=sha(Path(__file__)))
    (output/'PREPARATION.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for flag in ('repo','root','output'): p.add_argument('--'+flag,type=Path,required=True)
    a=p.parse_args();build(a.repo,a.root,a.output)
