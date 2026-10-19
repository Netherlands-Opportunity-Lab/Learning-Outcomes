"""Publish allowlisted aggregate review evidence, never private source files."""
import argparse
import csv
import gzip
import hashlib
import json
import re
import sys
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'06_pipeline'))
from LO_DASHBOARD_COMPARABILITY import population_review_index, population_review_for


def sha(p):
    with p.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def publish(repo, root):
    w = root / 'scientific_review_20261019'
    out = repo / '06_pipeline/review_20261013/scientific_review'
    out.mkdir(exist_ok=True)
    manifest_path = w / 'SCIENTIFIC_REVIEW_MANIFEST.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    w = Path(manifest.get('review_work_directory',w))
    mappings = {
        'Q01_SES_SAMPLE_REVIEW.json': 'Q01/SES_SAMPLE_REVIEW.json',
        'Q02_OFFICIAL_SAMPLE_REVIEW.json': 'Q02/OFFICIAL_SAMPLE_REVIEW.json',
        'Q03_Q05_FROZEN_SES_REVIEW.json': 'Q03_Q05/FROZEN_SES_REVIEW.json',
        'Q06_REFERENCE_REVIEW.json': 'Q06/REFERENCE_REVIEW.json',
        'Q06_PUBLICATION_REFERENCE_VERIFICATION.json': 'Q06/PUBLICATION_REFERENCE_VERIFICATION.json',
        'Q08_PAPER_CLAIM_REVIEW.json': 'Q08/PAPER_CLAIM_REVIEW.json',
        'RESULT_ARTIFACT_VERIFICATION.json': 'RESULT_ARTIFACT_VERIFICATION.json',
    }
    q06_dir=Path(manifest.get('reference_review_directory',w / 'Q06'))
    mapping_dir=Path(manifest.get('reference_mapping_directory',w / 'Q06_mapping_final'))
    def source(relative):
        if relative.startswith('Q06/'):return q06_dir / Path(relative).name
        if relative.startswith('Q06_mapping_final/'):return mapping_dir / Path(relative).name
        return w / relative
    source_hashes = {}
    private_pattern = r'(?<![A-Za-z0-9])[A-Za-z]:[/\\]|/Users/|/home/'
    for name, relative in mappings.items():
        p = source(relative)
        z = json.loads(p.read_text(encoding='utf-8'))
        if 'code_sha256' in z and isinstance(z['code_sha256'], dict):
            z['code_sha256'] = {Path(k).name: v for k, v in z['code_sha256'].items()}
        if 'evidence_files' in z:
            z['evidence_files'] = [dict(file=Path(f['path']).name, sha256=f['sha256']) for f in z['evidence_files']]
        z['private_full_review_sha256'] = sha(p)
        text = json.dumps(z, indent=2, ensure_ascii=False) + '\n'
        if re.search(private_pattern, text):
            raise ValueError('Private path in review export: ' + name)
        (out / name).write_text(text, encoding='utf-8')
        source_hashes[name] = sha(p)
    csvs = ['Q01/SES_ANALYSIS_SAMPLE_COVERAGE.csv', 'Q01/SES_SOURCE_CHECKS.csv','Q01/SES_REVIEW_TARGET_BINDINGS.csv',
            'Q02/COUNTRY_CYCLE_SAMPLE_QUALITY.csv', 'Q02/OFFICIAL_SAMPLE_TABLE_DEPENDENCIES.csv',
            'Q03_Q05/FROZEN_SES_COUNTRY_WAVE_REVIEW.csv', 'Q06/REFERENCE_BY_VIEW.csv',
            'Q06/REFERENCE_NUMERICAL_PROBES.csv', 'Q06/RANK_NUMERICAL_PROBES.csv',
            'Q06/REFERENCE_DEPENDENCIES.csv', 'Q08/PAPER_CLAIM_RESULTS.csv',
            'Q08/PAPER_CLAIM_DEPENDENCIES.csv', 'Q06_mapping_final/PRODUCT_DERIVATION_REVIEW.csv']
    for relative in csvs:
        p = source(relative)
        raw = p.read_bytes()
        if re.search(private_pattern, raw.decode('utf-8-sig')):
            raise ValueError('Private path in aggregate table: ' + p.name)
        name = p.name + ('.gz' if len(raw) > 2_000_000 else '')
        (out / name).write_bytes(gzip.compress(raw, mtime=0) if name.endswith('.gz') else raw)
        # A growing table can cross the compression threshold. Keep one
        # current representation; its previous bytes remain in Git history.
        obsolete = out / (p.name if name.endswith('.gz') else p.name + '.gz')
        if obsolete.is_file():
            obsolete.unlink()
        source_hashes[name] = sha(p)
    with (w / 'REVIEWED_MASTER_GRID.csv').open(encoding='utf-8-sig', newline='') as f:
        grid = list(csv.DictReader(f))
    corrections = json.loads((repo / '06_pipeline/review_20261013/POPULATION_CORRECTIONS.json').read_text(encoding='utf-8'))
    correction = population_review_index(corrections['corrections'])
    with (out / 'VERIFIED_COUNTRY_ADMISSION.csv').open(encoding='utf-8-sig', newline='') as f:
        admitted = {r['country'] for r in csv.DictReader(f) if r['dashboard_eligible'].lower() == 'true'}
    with (out / 'VERIFIED_COUNTRY_COMBINATIONS.csv').open(encoding='utf-8-sig', newline='') as f:
        combinations = {(r['country'],r['survey'],r['domain']) for r in csv.DictReader(f) if r['combination_pass'].lower()=='true'}
    restrictions = []
    migration_samples = []
    methods = set()
    method_cols = ['survey', 'age', 'domain', 'statistic', 'subgroup_variable', 'ses_construct_id',
                   'threshold_id', 'weight_design', 'pv_rule', 'variance_rule', 'linking_rule', 'method_version']
    for r in grid:
        methods.add(tuple(r.get(k, '') for k in method_cols))
        if r['status'] == 'SCIENTIFICALLY_VALIDATED' and r['subgroup_variable'] in ['migration', 'migration_generation']:
            migration_samples.append({k: r[k] for k in ['cell_id', 'country', 'survey', 'year', 'domain',
                'subgroup_variable', 'subgroup_level', 'statistic', 'n_unweighted', 'source_edition_sha256',
                'result_hash', 'certification_sha256']})
        correction_row = population_review_for(correction,r['country'],r['survey'],r['year'],r['domain'])
        combination_ok=(r['country'],r['survey'],r['domain']) in combinations
        if r['domain']=='all':combination_ok=any(c==r['country'] and s==r['survey'] for c,s,d in combinations)
        if correction_row or not combination_ok:
            restrictions.append(dict(cell_id=r['cell_id'], result_hash=r['result_hash'],
                country=r['country'], survey=r['survey'], year=r['year'],
                dashboard_country_admitted=r['country'] in admitted,
                dashboard_combination_admitted=combination_ok,
                use_restriction=correction_row['disposition'] if correction_row else 'AGE_DOMAIN_FAILS_COMPARABLE_MIN3',
                review_id=correction_row['review_id'] if correction_row else 'COUNTRY_ADMISSION_REVIEW',
                historical_result_retained=True))
    for name, rows, fields in [('RESULT_USE_RESTRICTIONS.csv', restrictions, list(restrictions[0])),
                               ('MIGRATION_RECORDED_ANALYSIS_SAMPLES.csv', migration_samples, list(migration_samples[0])),
                               ('METHOD_CONTRACTS.csv', [dict(zip(method_cols, row)) for row in sorted(methods)], method_cols)]:
        with (out / name).open('w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fields, lineterminator='\n'); writer.writeheader(); writer.writerows(rows)
    proof = dict(schema_version=1, status=manifest['status'], result_basis=manifest.get('reviewed_result_commit',manifest['historical_result_commit']),
                 historical_result_commit=manifest['historical_result_commit'],
                 private_manifest_sha256=sha(manifest_path), approval_sha256=manifest['approval_sha256'],
                 reviewed_target_count=manifest['reviewed_target_count'],
                 scientific_review_requirements=8, source_reports=source_hashes,
                 assessments=[{k: r[k] for k in ['requirement_id', 'assessment', 'applicability', 'report_sha256']}
                              for r in manifest['reviews']],
                 runtime_bindings=manifest['runtime_bindings'],
                 outputs={p.name: sha(p) for p in sorted(out.iterdir()) if p.is_file() and p.name != 'SCIENTIFIC_REVIEW_MANIFEST.json'})
    (out / 'SCIENTIFIC_REVIEW_MANIFEST.json').write_text(json.dumps(proof, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(dict(status=proof['status'], public_tables=len(csvs), restricted_historical_cells=len(restrictions))))


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo', type=Path, required=True); p.add_argument('--root', type=Path, required=True)
    a = p.parse_args(); publish(a.repo.resolve(), a.root.resolve())
