"""Bind completed real-source Q reviews to their exact inputs and current code.

This does not run estimators or turn missing reviews into approvals. The existing
R finalizer checks the immutable manifest and every attachment before installing
scope-specific receipts. Private paths stay outside Git.
"""
import argparse
import csv
import hashlib
import json
import shutil
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


def sha(p):
    with Path(p).open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def read(p):
    with Path(p).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def freeze(repo, root):
    work = root / 'scientific_review_20261019'
    reports = {
        'Q01': work / 'Q01/SES_SAMPLE_REVIEW.json',
        'Q02': work / 'Q02/OFFICIAL_SAMPLE_REVIEW.json',
        'Q03': work / 'Q03_Q05/FROZEN_SES_REVIEW.json',
        'Q04': repo / '06_pipeline/review_20261013/scientific_review/SCOPE_METHOD_REVIEW.json',
        'Q05': work / 'Q03_Q05/FROZEN_SES_REVIEW.json',
        'Q06': work / 'Q06/REFERENCE_REVIEW.json',
        'Q07': repo / '06_pipeline/review_20261013/scientific_review/SCOPE_METHOD_REVIEW.json',
        'Q08': work / 'Q08/PAPER_CLAIM_REVIEW.json',
    }
    q = {k: json.loads(p.read_text(encoding='utf-8-sig')) for k, p in reports.items()}
    expected = ['ACTUAL_SES_SAMPLE_COUNTS_VERIFIED', 'OFFICIAL_COUNTRY_CYCLE_REVIEW_COMPLETE',
                'PINNED_AUTHOR_AND_ALL_USED_CANONICAL_SCORES_VERIFIED',
                'ACTUAL_SELECTED_SCOPE_AND_PRODUCT_PLACEMENT_VERIFIED',
                'PINNED_AUTHOR_AND_ALL_USED_CANONICAL_SCORES_VERIFIED',
                'FULL_ANCHORS_AND_ACTUAL_MEAN_RANK_DERIVATIONS_VERIFIED',
                'ACTUAL_SELECTED_SCOPE_AND_PRODUCT_PLACEMENT_VERIFIED',
                'REGISTERED_CLAIMS_AND_JOINT_COVARIANCE_VERIFIED']
    if [v['status'] for v in q.values()] != expected:
        raise ValueError('Real scientific review incomplete')
    if (q['Q01']['count_mismatches'] or q['Q02']['contexts'] != q['Q02']['complete']
            or q['Q02']['missing'] or q['Q02']['errors']
            or q['Q03']['scored_canonical_max_difference'] > 1e-12
            or max(q['Q03']['numerical_parameter_differences'].values()) > 1e-8
            or q['Q04']['two_wave_analysis_targets'] or q['Q07']['appendix_leaks']
            or q['Q07']['official_PISA_ESCS_analysis_targets'] or q['Q07']['forbidden_targets']
            or q['Q08']['claim_count'] != 12 or q['Q08']['formal_tests'] != 3):
        raise ValueError('Scientific numerical/scope review failed')
    # Windows realpath resolution per repeated cell can dominate runtime.
    # Inputs below are absolute canonical paths; hash unique files once using
    # bounded I/O concurrency, then check every claimed expected hash.
    initial = read(work / 'Q06_mapping_final/PRIVATE_MAPPING_EVIDENCE.csv')
    grid_for_sources = read(root / 'FIXED_PRODUCTION_V1/all_required/PRIVATE_MASTER_GRID.csv')
    paths = {Path(f['path']).as_posix() for f in initial}
    paths.update(Path(r['source_path']).as_posix() for r in grid_for_sources if r['status'] == 'SCIENTIFICALLY_VALIDATED')
    evidence = {}
    with ThreadPoolExecutor(max_workers=16) as pool:
        for n, (path, value) in enumerate(pool.map(lambda p: (p, sha(p)), sorted(paths)), 1):
            evidence[path] = value
            if n % 5000 == 0:
                print('REVIEW_EVIDENCE_HASHED', n, 'of', len(paths), flush=True)

    def add(p, expected_hash=None):
        p = Path(p)
        key = p.as_posix()
        if key not in evidence:
            evidence[key] = sha(p)
        if expected_hash and evidence[key] != expected_hash:
            raise ValueError('Changed scientific evidence: ' + p.name)
        return evidence[key]

    def proof_json(p, expected_hash=None):
        add(p, expected_hash)
        z = json.loads(Path(p).read_text(encoding='utf-8-sig'))
        for key in ['evidence_files', 'input_and_code_hashes']:
            for f in z.get(key, []):
                add(f['path'], f['sha256'])
        return z

    for p in reports.values():
        add(p)
    for p, h in q['Q01']['code_sha256'].items():
        add(repo / '06_pipeline' / Path(p).name, h)
    for n, h in q['Q01']['outputs'].items():
        add(work / 'Q01' / {'coverage': 'SES_ANALYSIS_SAMPLE_COVERAGE.csv',
                            'sources': 'SES_SOURCE_CHECKS.csv'}[n], h)
    q2cfg = repo / '06_pipeline/review_20261013/OFFICIAL_SAMPLE_TABLES.json'
    add(q2cfg, q['Q02']['config_sha256'])
    add(repo / 'scripts/review_official_samples.py', q['Q02']['code_sha256'])
    add(root / 'international/SOURCE_RUN_MANIFEST.csv', q['Q02']['source_manifest_sha256'])
    official = json.loads(q2cfg.read_text(encoding='utf-8'))
    for f in official['tables'] + official['quality_source_review'] + official['mode_evidence']:
        if 'file' in f:
            add(work / 'official' / f['file'], f['sha256'])
    for n, h in q['Q02']['output_sha256'].items():
        add(work / 'Q02' / n, h)
    proof_json(root / 'cobreros_four/CALIBRATION_CERTIFICATE.json', q['Q03']['calibration_sha256'])
    proof_json(root / 'cobreros_four/PREPARATION_MANIFEST.json')
    proof_json(root / 'cobreros_four/RAW_INPUT_CLOSURE.json')
    application = list((root / 'international/ses').glob('SES_*.json'))
    if len(application) != 1:
        raise ValueError('Ambiguous frozen SES application')
    z = proof_json(application[0], q['Q03']['application_sha256'])
    for f in z['files']:
        add(f['path'], f['sha256'])
    add(repo / '06_pipeline/LO_FROZEN_SES_REVIEW.R', q['Q03']['review_code_sha256'])
    add(work / 'Q03_Q05/FROZEN_SES_COUNTRY_WAVE_REVIEW.csv', q['Q03']['output_sha256'])
    grid_copy = work / 'REVIEWED_MASTER_GRID.csv'
    if not grid_copy.exists():
        original_grid = root / 'FIXED_PRODUCTION_V1/all_required/PRIVATE_MASTER_GRID.csv'
        if sha(original_grid) != q['Q04']['input_sha256']['grid']:
            raise ValueError('Grid changed before scientific snapshot')
        shutil.copyfile(original_grid, grid_copy)
    scope_inputs = dict(tasks=work / 'snapshot/product_export/PRIVATE_TASKS.csv',
                        grid=grid_copy,
                        decisions=repo / '06_pipeline/SCOPE_APPROVALS.csv',
                        products=repo / '06_pipeline/review_20261013/PRODUCT_REQUIREMENTS.json',
                        author_preparation=root / 'cobreros_four/PREPARATION_MANIFEST.json',
                        dashboard=work / 'snapshot/public_inputs/dashboard_cells.csv',
                        gender_policy=repo / '06_pipeline/review_20261013/GENDER_POOL_USER_DECISION.json',
                        review_code=repo / 'scripts/review_scope_contracts.py')
    for n, h in q['Q04']['input_sha256'].items():
        add(scope_inputs[n], h)
    mapping_dir = work / 'Q06_mapping_final'
    mapping = proof_json(mapping_dir / 'BALANCE_MAPPING_REVIEW.json', q['Q06']['mapping_review_sha256'])
    add(mapping_dir / 'BALANCED_REFERENCE_EXPORT.json', q['Q06']['reference_export_sha256'])
    add(repo / '06_pipeline/LO_DASHBOARD_COMPARABILITY.py', mapping['mapping_code_sha256'])
    add(repo / '06_pipeline/review_20261013/POPULATION_CORRECTIONS.json', mapping['population_review_sha256'])
    add(repo / '06_pipeline/review_20261013/SOURCE_PROJECTION_REVIEWS.json', mapping['source_projection_review_sha256'])
    add(mapping_dir / 'PRIVATE_MAPPING_EVIDENCE.csv', mapping['evidence_index_sha256'])
    add(mapping_dir / 'BALANCE_AVAILABLE.csv', mapping['available_sha256'])
    add(mapping_dir / 'FOCUS_CORE_TARGETS.csv', mapping['core_targets_sha256'])
    for f in read(mapping_dir / 'PRIVATE_MAPPING_EVIDENCE.csv'):
        add(f['path'], f['sha256'])
    # All unresolved public mappings must have an explicit reviewed exclusion.
    if any(not reason.startswith(('REGIONAL_POPULATION_NOT_NATIONAL:',
                                  'OFFICIAL_TREND_COMPARABILITY_QUALIFICATION:'))
           for reason in mapping['reasons']):
        raise ValueError('Unresolved comparison mapping without a reviewed scientific reason')
    for n, h in q['Q06']['code_sha256'].items():
        add(repo / '06_pipeline' / n, h)
    for n, h in q['Q06']['output_sha256'].items():
        add(work / 'Q06' / (n + '.csv'), h)
    proof_json(reports['Q08'])
    add(repo / '06_pipeline/review_20261013/PAPER_CLAIMS.json', q['Q08']['registration_sha256'])
    add(repo / '06_pipeline/LO_PAPER_CLAIM_REVIEW.R', q['Q08']['review_code_sha256'])
    add(work / 'Q08/PAPER_CLAIM_RESULTS.csv', q['Q08']['result_sha256'])
    add(work / 'Q08/PAPER_CLAIM_DEPENDENCIES.csv', q['Q08']['dependencies_sha256'])
    approval = root / 'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'
    add(approval)
    # The actual source inputs for appendix results as well as the dashboard.
    # Rehash each unique source once; no fitting or pupil-output publication.
    grid = read(scope_inputs['grid'])
    for r in grid:
        if r['status'] == 'SCIENTIFICALLY_VALIDATED':
            add(r['source_path'], r['source_edition_sha256'])
    contracts = work / 'REVIEWED_TARGET_CONTRACTS.csv'
    with contracts.open('w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, ['cell_id', 'target_contract_sha256'], lineterminator='\n')
        writer.writeheader()
        writer.writerows({k: r[k] for k in writer.fieldnames} for r in sorted(grid, key=lambda r: r['cell_id']))
    add(contracts)
    # Current runtime and policies are checked relative to the caller's repo,
    # so a different checkout cannot keep using receipts for obsolete code.
    code = list((repo / '06_pipeline').glob('*.R')) + list((repo / '06_pipeline').glob('*.py'))
    policy_names = ['PAPER_QA_CURRENT.json', 'PAPER_CLAIMS.json', 'BALANCED_REFERENCE_POLICY.json',
                    'POPULATION_CORRECTIONS.json', 'PRODUCT_REQUIREMENTS.json', 'RANK_PRODUCT_CONTRACT.json',
                    'GENDER_POOL_USER_DECISION.json', 'SOURCE_PROJECTION_REVIEWS.json', 'NLD_POLICY_CORE_YEAR_ANCHOR.csv']
    code += [repo / '06_pipeline/review_20261013' / n for n in policy_names]
    code += [repo / '06_pipeline/SCOPE_APPROVALS.csv', repo / '06_pipeline/COUNTRY_PRODUCTION_APPROVALS.csv',
             repo / 'renv.lock', repo / 'scripts/freeze_scientific_review.py']
    bindings = [{'path': p.relative_to(repo).as_posix(), 'sha256': add(p)} for p in sorted(code)]
    assessments = {
        'Q01': 'Actual weighted/unweighted analysis groups, SES missingness and saved result N verified; coverage is not a missing-at-random or representativeness claim.',
        'Q02': 'Official population, response, exclusions, mode and cycle qualifications reviewed for every used context. Documented unreported percentages remain unknown. AUT2009/ESP2018 trend qualifications and CAN2001 regional population exclude comparable support without deleting historical targets.',
        'Q03': 'Pinned four-wave author code and parameter parity, plus every used canonical SES score and weight projection verified numerically. Author calibration countries are not dashboard admission.',
        'Q04': 'NOT_APPLICABLE_PROVEN: no selected two-wave dependencies or targets; no historical two-wave rerun authorized or performed.',
        'Q05': 'Frozen parameters, input mappings, observed components, imputation and extension-country coverage reviewed. Measurement invariance outside calibration remains a stated assumption, not an empirical finding.',
        'Q06': 'Full focus anchors and jointly selected series/peer definitions enforced; admission is six combinations with three comparable waves. Equal-country means and country ranks numerically tested. Empty references stay empty; no benchmark/rank CI or group rank line.',
        'Q07': 'Chosen PISA SES retained; no added official ESCS robustness. Home-SES appendix has one usable released wave per study and no spliced historical scale or trend claim.',
        'Q08': 'Twelve retrospectively registered Dutch claims checked against exact parents and joint PV/replicate covariance. Three PISA trend tests include linking variance and Holm correction; IEA long-term intervals are explicitly conditional, with no formal trend test.'}
    manifest = dict(schema_version=1, status='REVIEWED_SCIENTIFIC_BASIS_WITH_EXPLICIT_LIMITATIONS',
                    historical_result_commit='ac9f0bdb15b5bf3fcf843f3e4f857995d182aef2',
                    approval_sha256=add(approval), target_contracts_path=contracts.as_posix(),
                    target_contracts_sha256=add(contracts), reviewed_target_count=len(grid),
                    runtime_bindings=bindings,
                    reviews=[dict(requirement_id=k, assessment=assessments[k], report_path=str(reports[k]),
                                  report_sha256=add(reports[k]), applicability='NOT_APPLICABLE_PROVEN' if k == 'Q04' else 'APPLICABLE_REVIEWED_WITH_QUALIFICATIONS') for k in reports],
                    evidence_files=[dict(path=p, sha256=h) for p, h in sorted(evidence.items())])
    output = work / 'SCIENTIFIC_REVIEW_MANIFEST.json'
    output.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(dict(status=manifest['status'], reviewed_targets=len(grid),
                         evidence_files=len(evidence), manifest_sha256=sha(output))))
    return manifest


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo', type=Path, required=True)
    p.add_argument('--root', type=Path, required=True)
    a = p.parse_args()
    freeze(a.repo.resolve(), a.root.resolve())
