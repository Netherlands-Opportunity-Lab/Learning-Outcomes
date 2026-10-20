"""Build the Dutch paper/deck appendix from the reviewed aggregate result basis.

This is not an estimator. Exact result, source and task identities must match
the published scientific support review. Small groups are retained as explicit
quality restrictions and never receive a plotted numeric replacement.
"""
import argparse
import csv
import gzip
import hashlib
import json
from pathlib import Path


def sha(p):
    with p.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def read_csv(p):
    opener = gzip.open if p.suffix == '.gz' else open
    with opener(p, 'rt', encoding='utf-8-sig', newline='') as f:
        yield from csv.DictReader(f)


def table_path(root, name):
    a, b = root / name, root / (name + '.gz')
    if a.exists() == b.exists():
        raise ValueError('Expected one current representation: ' + name)
    return a if a.exists() else b


def export(repo, out):
    review = repo / '06_pipeline/review_20261013/scientific_review'
    results = repo / '04_results/review/all_required'
    manifest = json.loads((results / 'manifest.json').read_text())
    science = json.loads((review / 'SCIENTIFIC_REVIEW_MANIFEST.json').read_text())
    phase = json.loads((repo / '06_pipeline/review_20261013/release47_20261020/RELEASE_PHASE_DECISION.json').read_text())
    if manifest['target_rows'] != 90829 or science['reviewed_target_count'] != 90829:
        raise ValueError('The current47 scientific basis is not yet closed')
    for item in manifest['files']:
        if sha(results / item['file']) != item['sha256']:
            raise ValueError('Changed public result deposit: ' + item['file'])
    support_path = table_path(review, 'ANALYSIS_SUPPORT.csv')
    if science['outputs'].get(support_path.name) != sha(support_path):
        raise ValueError('Support review is not bound to the scientific manifest')
    support = {r['cell_id']: r for r in read_csv(support_path) if r['country'] == 'NLD'}
    restriction = {r['cell_id']: r['use_restriction'] for r in read_csv(review / 'RESULT_USE_RESTRICTIONS.csv') if r['country'] == 'NLD'}
    rows = []
    for r in read_csv(results / 'results.csv'):
        if r['country'] != 'NLD':
            continue
        s = support.get(r['cell_id'])
        if not s or any(s[a] != r[b] for a, b in [
            ('result_hash', 'result_hash'), ('source_sha256', 'source_edition_sha256'),
            ('target_contract_sha256', 'target_contract_sha256')]):
            raise ValueError('Appendix row does not match reviewed identities: ' + r['cell_id'])
        if s['recorded_n_matches'].upper() != 'TRUE':
            raise ValueError('Unverified analysis sample')
        reason = restriction.get(r['cell_id'], '')
        if float(s['min_component_n']) < 30:
            reason = reason or 'QUALITY_FEWER_THAN_30_TARGET_PUPILS'
        elif float(s['min_component_school_n']) < 5:
            reason = reason or 'QUALITY_FEWER_THAN_5_IDENTIFIED_TARGET_SCHOOLS'
        scale = 100 if r['unit'] == 'proportion' else 1
        z = dict(r, publication_eligible=not reason, publication_restriction=reason,
                 min_component_n=int(float(s['min_component_n'])),
                 min_component_school_n=int(float(s['min_component_school_n'])),
                 max_missing_school_n=int(float(s['max_missing_school_n'])),
                 display_unit='percent' if scale == 100 else r['unit'],
                 display_factor=scale,
                 display_estimate=float(r['estimate']) * scale if not reason else None,
                 display_standard_error=float(r['standard_error']) * scale if not reason else None)
        rows.append(z)
    high = []
    for age, survey, domain in [('age10', 'PIRLS', 'reading'), ('age10', 'TIMSS', 'mathematics'),
                               ('age10', 'TIMSS', 'science'), ('age15', 'PISA', 'reading'),
                               ('age15', 'PISA', 'mathematics'), ('age15', 'PISA', 'science')]:
        all_rows = [r for r in rows if r['survey'] == survey and r['domain'] == domain and
                    r['module'] in ['ses_national', 'ses_harmonized'] and r['stat'] in ['q1_high', 'q4_high']]
        points = [dict(r, year=int(r['year']), estimate=r['display_estimate'],
                       standard_error=r['display_standard_error'], series_id=r['subgroup'],
                       series_role='focus', label='Onderste kwart SES' if r['subgroup'] == 'q1' else 'Bovenste kwart SES')
                  for r in all_rows if r['publication_eligible']]
        high.append(dict(id='APPENDIX_A02_' + age + '_' + domain, age=age, survey=survey, domain=domain,
                         unit='percent', rows=points, years=sorted({int(r['year']) for r in all_rows}),
                         expected_series=['q1', 'q4'], availability={}, default_reference=[]))
    claims = list(read_csv(review / 'PAPER_CLAIM_RESULTS.csv'))
    dependencies = list(read_csv(review / 'PAPER_CLAIM_DEPENDENCIES.csv'))
    by_id = {r['cell_id']: r for r in rows}
    for d in dependencies:
        p = by_id[d['cell_id']]
        if d['result_hash'] != p['result_hash'] or not p['publication_eligible']:
            raise ValueError('Paper claim has an unavailable or changed parent')
    selected = {r['cell_id'] for r in rows}
    status = [r for r in read_csv(results / 'target_status.csv')
              if r['cell_id'].startswith('NLD|') or '|NLD|' in r['cell_id']]
    extensions = [r for r in rows if r['module'].startswith('extension_') or
                  r['module'] in ['ses_national', 'ses_harmonized'] and r['stat'] in ['q1_high', 'q4_high']]
    coverage = [r for r in read_csv(table_path(review, 'SES_ANALYSIS_SAMPLE_COVERAGE.csv')) if r['country'] == 'NLD']
    quality = [r for r in read_csv(review / 'COUNTRY_CYCLE_SAMPLE_QUALITY.csv') if r['country'] == 'NLD']
    combos = [r for r in read_csv(review / 'VERIFIED_COUNTRY_COMBINATIONS.csv') if r['country'] == 'NLD']
    out.mkdir(parents=True, exist_ok=True)
    provenance = dict(result_manifest_sha256=sha(results / 'manifest.json'),
                      scientific_manifest_sha256=sha(review / 'SCIENTIFIC_REVIEW_MANIFEST.json'),
                      support_sha256=sha(support_path), primary_result_commit=science['result_basis'],
                      target_count=manifest['target_rows'], research_scope='CURRENT47',
                      numeric_policy='Full binary64 values; only rendered labels are rounded',
                      builder_sha256=sha(Path(__file__)))
    data = dict(provenance=provenance, results=rows, high_ses_panels=high, extensions=extensions,
                claims=claims, claim_dependencies=dependencies, ses_coverage=coverage,
                official_quality=quality, netherlands_combinations=combos, target_status=status)
    (out / 'RESEARCH_TABLES.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    for name, records in [('PAPER_APPENDIX_POINT_LINEAGE.csv', extensions),
                          ('NLD_SES_ANALYSIS_COVERAGE.csv', coverage),
                          ('NLD_OFFICIAL_SAMPLE_QUALITY.csv', quality)]:
        fields = list(records[0]) if records else ['cell_id']
        with (out / name).open('w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fields, lineterminator='\n')
            writer.writeheader()
            writer.writerows(records)
    print(json.dumps(dict(status='RESEARCH_TABLES_FROM_REVIEWED_AGGREGATES', nld_results=len(rows),
                          appendix_rows=len(extensions), registered_claims=len(claims),
                          display_restrictions=sum(not r['publication_eligible'] for r in rows))))


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    a = p.parse_args()
    export(a.repo.resolve(), a.out.resolve())
