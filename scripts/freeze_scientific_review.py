"""Bind completed real-source Q reviews to their exact inputs and current code.

This does not run estimators or turn missing reviews into approvals. The existing
R finalizer checks the immutable manifest and every attachment before installing
scope-specific receipts. Private paths stay outside Git.
"""
import argparse
import csv
import hashlib
import json
import math
import re
import shutil
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


def sha(p):
    with Path(p).open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def read(p):
    with Path(p).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def verify_review_bindings(reviewed_grid, ses_bindings, ses_sources, claim_dependencies, claims):
    # A review of an earlier scope cannot certify newly added results merely
    # because its summary says zero errors. Compare every reviewed dependency.
    ses_modules={'ses_national','ses_harmonized','extension_ses_gender',
                 'extension_home_ses','extension_ses_school','extension_ses_class'}
    wanted_ses={cid:r for cid,r in reviewed_grid.items()
                if r['status']=='SCIENTIFICALLY_VALIDATED' and r['subgroup_variable'] in ses_modules}
    if len(ses_bindings)!=len(wanted_ses) or {r['cell_id'] for r in ses_bindings}!=wanted_ses.keys():
        raise ValueError('Q01 does not cover the exact selected result set')
    for row in ses_bindings:
        parent=wanted_ses[row['cell_id']]
        if any(row[k]!=parent[k] for k in ('target_contract_sha256','result_hash','source_edition_sha256')) or float(row['n_unweighted'])!=float(parent['n_unweighted']):
            raise ValueError('Q01 reviewed result dependency changed')
    chosen_ses={'ses_harmonized','extension_ses_gender','extension_ses_school','ses_peer_exposure'}
    wanted_sources={r['source_edition_sha256'] for r in reviewed_grid.values()
                    if r['status']=='SCIENTIFICALLY_VALIDATED' and r['survey']=='PISA' and r['subgroup_variable'] in chosen_ses}
    if {r['source_sha256'] for r in ses_sources}!=wanted_sources:
        raise ValueError('Q03/Q05 does not cover every used chosen-SES source')
    for row in claim_dependencies:
        parent=reviewed_grid.get(row['cell_id'])
        if not parent or parent['status']!='SCIENTIFICALLY_VALIDATED' or any(
            row[k]!=parent[v] for k,v in {'result_hash':'result_hash','target_contract_sha256':'target_contract_sha256',
              'source_sha256':'source_edition_sha256','input_fingerprint':'input_fingerprint','code_fingerprint':'code_fingerprint'}.items()):
            raise ValueError('Q08 claim dependency is not a current certified result')
    wanted_claims={(q['claim_id'],q[k]) for q in claims for k in ('parent_a','parent_b','gap_cell') if q.get(k)}
    got_claims=[(r['claim_id'],r['cell_id']) for r in claim_dependencies]
    if len(got_claims)!=len(set(got_claims)) or set(got_claims)!=wanted_claims:
        raise ValueError('Q08 dependencies do not match the exact registered claims')


def verified_snapshot_result_basis(snapshot, export, approval_sha256):
    commit = snapshot.get('result_commit', '')
    if (not re.fullmatch('[0-9a-f]{40}', commit)
            or export.get('result_commit') != commit
            or not snapshot.get('stable')
            or snapshot.get('inputs', {}).get('master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv') != approval_sha256
            or export.get('approved_registry_sha256') != approval_sha256):
        raise ValueError('Snapshot result commit or reviewed registry identity differs')
    return commit


def freeze(repo, root, reference_root=None, work=None):
    work = work or root / 'scientific_review_20261019'
    official_dir = root / 'scientific_review_20261019/official'
    mapping_dir = reference_root / 'reference_mapping' if reference_root else work / 'Q06_mapping_final'
    q06_dir = reference_root / 'Q06' if reference_root else work / 'Q06'
    reports = {
        'Q01': work / 'Q01/SES_SAMPLE_REVIEW.json',
        'Q02': work / 'Q02/OFFICIAL_SAMPLE_REVIEW.json',
        'Q03': work / 'Q03_Q05/FROZEN_SES_REVIEW.json',
        'Q04': repo / '06_pipeline/review_20261013/scientific_review/SCOPE_METHOD_REVIEW.json',
        'Q05': work / 'Q03_Q05/FROZEN_SES_REVIEW.json',
        'Q06': q06_dir / 'REFERENCE_REVIEW.json',
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
    if q['Q06'].get('policy') != 'FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3':
        raise ValueError('Q06 does not certify the current human-approved combination rule')
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
    initial = read(mapping_dir / 'PRIVATE_MAPPING_EVIDENCE.csv')
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
                            'sources': 'SES_SOURCE_CHECKS.csv',
                            'bindings': 'SES_REVIEW_TARGET_BINDINGS.csv'}[n], h)
    support_dir = work / 'Q01_ANALYSIS_SUPPORT'
    support_report = proof_json(support_dir / 'ANALYSIS_SUPPORT_REVIEW.json')
    if support_report['status'] != 'ACTUAL_ANALYSIS_SUPPORT_REVIEWED' or support_report['n_mismatches']:
        raise ValueError('Actual analysis-group support has not been verified')
    for p, h in support_report['code_sha256'].items():
        add(repo / '06_pipeline' / Path(p).name, h)
    add(support_dir / 'ANALYSIS_SUPPORT.csv', support_report['outputs']['coverage'])
    add(support_dir / 'ANALYSIS_SUPPORT_SOURCES.csv', support_report['outputs']['sources'])
    q2cfg = repo / '06_pipeline/review_20261013/OFFICIAL_SAMPLE_TABLES.json'
    add(q2cfg, q['Q02']['config_sha256'])
    add(repo / 'scripts/review_official_samples.py', q['Q02']['code_sha256'])
    add(root / 'international/SOURCE_RUN_MANIFEST.csv', q['Q02']['source_manifest_sha256'])
    official = json.loads(q2cfg.read_text(encoding='utf-8'))
    for f in official['tables'] + official['quality_source_review'] + official['mode_evidence']:
        if 'file' in f:
            add(official_dir / f['file'], f['sha256'])
    for n, h in q['Q02']['output_sha256'].items():
        add(work / 'Q02' / n, h)
    proof_json(root / 'cobreros_four/CALIBRATION_CERTIFICATE.json', q['Q03']['calibration_sha256'])
    proof_json(root / 'cobreros_four/PREPARATION_MANIFEST.json')
    proof_json(root / 'cobreros_four/RAW_INPUT_CLOSURE.json')
    application = {sha(p):p for p in (root / 'international/ses').glob('SES_*.json')}
    used = q['Q03']['application_sha256']
    if isinstance(used,str):
        used=[used]
    if not used or len(set(used))!=len(used) or any(h not in application for h in used):
        raise ValueError('Missing or ambiguous frozen SES application')
    for h in used:
        z = proof_json(application[h], h)
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
    mapping = proof_json(mapping_dir / 'BALANCE_MAPPING_REVIEW.json', q['Q06']['mapping_review_sha256'])
    add(mapping_dir / 'BALANCED_REFERENCE_EXPORT.json', q['Q06']['reference_export_sha256'])
    add(mapping_dir / 'FIGURES.json', q['Q06']['figure_registry_sha256'])
    add(repo / '06_pipeline/review_20261013/RANK_PRODUCT_CONTRACT.json', q['Q06']['rank_rule_policy_sha256'])
    add(repo / '06_pipeline/LO_DASHBOARD_COMPARABILITY.py', mapping['mapping_code_sha256'])
    add(repo / '06_pipeline/review_20261013/POPULATION_CORRECTIONS.json', mapping['population_review_sha256'])
    add(repo / '06_pipeline/review_20261013/SOURCE_PROJECTION_REVIEWS.json', mapping['source_projection_review_sha256'])
    add(mapping_dir / 'PRIVATE_MAPPING_EVIDENCE.csv', mapping['evidence_index_sha256'])
    add(mapping_dir / 'BALANCE_AVAILABLE.csv', mapping['available_sha256'])
    add(mapping_dir / 'PRODUCT_DERIVATION_REVIEW.csv', mapping['derivation_review_sha256'])
    # The reference engine consumes primitive cells. A complemented display
    # percentage has its own hash and must never replace its parent's identity.
    reviewed_grid = {r['cell_id']: r for r in read(scope_inputs['grid'])}
    artifact = proof_json(work / 'RESULT_ARTIFACT_VERIFICATION.json')
    if (artifact['status'] != 'ACTUAL_RESULT_SOURCE_METHOD_CERTIFICATES_REVERIFIED'
            or artifact['rows'] != sum(r['status']=='SCIENTIFICALLY_VALIDATED' for r in reviewed_grid.values())
            or artifact['reviewed_grid_sha256'] != sha(scope_inputs['grid'])):
        raise ValueError('Source/method artifact verification does not cover this exact review grid')
    add(root / 'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv', artifact['approval_sha256'])
    add(repo / '06_pipeline/GRID_ARCHIVE_BATCH.R', artifact['review_code_sha256'])
    add(repo / 'scripts/prepare_scientific_review_snapshot.R', artifact['snapshot_code_sha256'])
    export_proof = proof_json(work / 'snapshot/product_export/SNAPSHOT_EXPORT_EVIDENCE.json')
    snapshot_proof = proof_json(work / 'snapshot/SNAPSHOT.json')
    reviewed_result_commit = verified_snapshot_result_basis(snapshot_proof, export_proof, artifact['approval_sha256'])
    add(scope_inputs['dashboard'], export_proof['export_sha256'])
    add(scope_inputs['grid'], export_proof['source_grid_sha256'])
    add(repo / '06_pipeline/LO_FINAL_GUIDED_EXPORT.R', export_proof['exporter_sha256'])
    if export_proof['mapping_holds'] or export_proof['approved_registry_sha256'] != artifact['approval_sha256']:
        raise ValueError('Review export is not derived from the reverified sealed result registry')
    verify_review_bindings(reviewed_grid,
        read(work/'Q01/SES_REVIEW_TARGET_BINDINGS.csv'),
        read(work/'Q03_Q05/FROZEN_SES_COUNTRY_WAVE_REVIEW.csv'),
        read(work/'Q08/PAPER_CLAIM_DEPENDENCIES.csv'),
        json.loads((repo/'06_pipeline/review_20261013/PAPER_CLAIMS.json').read_text(encoding='utf-8'))['claims'])
    for cell in read(mapping_dir / 'BALANCE_AVAILABLE.csv'):
        parent = reviewed_grid[cell['cell_id']]
        if cell['result_hash'] != parent['result_hash'] or cell['source_record_id'] != parent['result_hash']:
            raise ValueError('Comparison mapping is not bound to its primitive result')
        for key in ['estimate', 'standard_error', 'n_unweighted']:
            if not math.isclose(float(cell[key]), float(parent[key]), rel_tol=1e-12, abs_tol=1e-9):
                raise ValueError('Comparison primitive numeric mismatch: ' + key)
    add(mapping_dir / 'FOCUS_CORE_TARGETS.csv', mapping['core_targets_sha256'])
    for f in read(mapping_dir / 'PRIVATE_MAPPING_EVIDENCE.csv'):
        add(f['path'], f['sha256'])
    # All unresolved public mappings must have an explicit reviewed exclusion.
    if any(not reason.startswith(('REGIONAL_POPULATION_NOT_NATIONAL:',
                                  'OFFICIAL_TREND_COMPARABILITY_QUALIFICATION:',
                                  'OFFICIAL_GRADE_CHANGE_NOT_COMPARABLE:'))
           for reason in mapping['reasons']):
        raise ValueError('Unresolved comparison mapping without a reviewed scientific reason')
    for n, h in q['Q06']['code_sha256'].items():
        add(repo / '06_pipeline' / n, h)
    for n, h in q['Q06']['output_sha256'].items():
        add(q06_dir / (n + '.csv'), h)
    public_reference = proof_json(q06_dir / 'PUBLICATION_REFERENCE_VERIFICATION.json')
    if public_reference['status'] != 'PASS' or public_reference['views'] != q['Q06']['views']:
        raise ValueError('Actual publication reference verification failed')
    add(mapping_dir / 'BALANCED_REFERENCE_EXPORT.json', public_reference['reference_export_sha256'])
    for n, h in public_reference['code_sha256'].items():
        add(repo / '06_pipeline' / n, h)
    add(repo / 'scripts/verify_reference_review_export.py', public_reference['verification_script_sha256'])
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
    support = read(support_dir / 'ANALYSIS_SUPPORT.csv')
    valid = {r['cell_id']: r for r in grid if r['status'] == 'SCIENTIFICALLY_VALIDATED'}
    if len(support) != len(valid) or {r['cell_id'] for r in support} != valid.keys():
        raise ValueError('Analysis support does not cover every selected result')
    for r in support:
        parent = valid[r['cell_id']]
        if (any(r[k] != parent[k] for k in ('result_hash', 'target_contract_sha256'))
                or r['source_sha256'] != parent['source_edition_sha256']
                or float(r['recorded_n']) != float(parent['n_unweighted'])
                or r['recorded_n_matches'] != 'TRUE'):
            raise ValueError('Analysis support dependency differs from its sealed result')
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
    policy_names = ['PAPER_QA_CURRENT.json', 'PAPER_CLAIMS.json', 'BALANCED_REFERENCE_POLICY.json', 'BALANCE_USER_DECISION_20261019.json',
                    'POPULATION_CORRECTIONS.json', 'PRODUCT_REQUIREMENTS.json', 'RANK_PRODUCT_CONTRACT.json',
                    'GENDER_POOL_USER_DECISION.json', 'SOURCE_PROJECTION_REVIEWS.json', 'NLD_POLICY_CORE_YEAR_ANCHOR.csv',
                    'ANALYSIS_SUPPORT_POLICY.json']
    code += [repo / '06_pipeline/review_20261013' / n for n in policy_names]
    code += [repo / '06_pipeline/SCOPE_APPROVALS.csv', repo / '06_pipeline/COUNTRY_PRODUCTION_APPROVALS.csv',
             repo / 'renv.lock', repo / 'scripts/freeze_scientific_review.py',
             repo / 'scripts/verify_reference_review_export.py']
    phase = repo / '06_pipeline/review_20261013/release47_20261020/RELEASE_PHASE_DECISION.json'
    if phase.exists():
        code.append(phase)
    bindings = [{'path': p.relative_to(repo).as_posix(), 'sha256': add(p)} for p in sorted(code)]
    assessments = {
        'Q01': 'Actual weighted/unweighted SES groups and missingness verified. Every sealed result also has independently counted pupils and schools per contrast component and PV; insufficient support is a separate reporting restriction, never a deleted target or fabricated missing source. Coverage is not a missing-at-random or representativeness claim.',
        'Q02': 'Official population, response, exclusions, mode and cycle qualifications reviewed for every used context. Documented unreported percentages remain unknown. AUT2009/ESP2018 trend qualifications, CAN2001 regional population and POL early grade-3 to grade-4 changes exclude comparable support without deleting historical targets.',
        'Q03': 'Pinned four-wave author code and parameter parity, plus every used canonical SES score and weight projection verified numerically. Author calibration countries are not dashboard admission.',
        'Q04': 'NOT_APPLICABLE_PROVEN: no selected two-wave dependencies or targets; no historical two-wave rerun authorized or performed.',
        'Q05': 'Frozen parameters, input mappings, observed components, imputation and extension-country coverage reviewed. Measurement invariance outside calibration remains a stated assumption, not an empirical finding.',
        'Q06': 'User decision 19 October: admission is per age-domain combination with three comparable waves. Full selected-combination focus anchors and jointly selected series/peer definitions are enforced; membership is fixed within a figure and may differ between figures. Equal-country means and ranks are numerically tested. Empty references stay empty; no benchmark/rank CI or group rank line.',
        'Q07': 'Chosen PISA SES retained; no added official ESCS robustness. Home-SES appendix has one usable released wave per study and no spliced historical scale or trend claim.',
        'Q08': 'Twelve retrospectively registered Dutch claims checked against exact parents and joint PV/replicate covariance. Three PISA trend tests include linking variance and Holm correction; IEA long-term intervals are explicitly conditional, with no formal trend test.'}
    manifest = dict(schema_version=1, status='REVIEWED_SCIENTIFIC_BASIS_WITH_EXPLICIT_LIMITATIONS',
                    historical_result_commit='ac9f0bdb15b5bf3fcf843f3e4f857995d182aef2',
                    reviewed_result_commit=reviewed_result_commit, reviewed_grid_sha256=sha(grid_copy),
                    review_work_directory=work.as_posix(),
                    reference_mapping_directory=mapping_dir.as_posix(), reference_review_directory=q06_dir.as_posix(),
                    approval_sha256=add(approval), target_contracts_path=contracts.as_posix(),
                    target_contracts_sha256=add(contracts), reviewed_target_count=len(grid),
                    runtime_bindings=bindings,
                    reviews=[dict(requirement_id=k, assessment=assessments[k], report_path=str(reports[k]),
                                  report_sha256=add(reports[k]), applicability='NOT_APPLICABLE_PROVEN' if k == 'Q04' else 'APPLICABLE_REVIEWED_WITH_QUALIFICATIONS') for k in reports],
                    evidence_files=[dict(path=p, sha256=h) for p, h in sorted(evidence.items())])
    output = work / 'SCIENTIFIC_REVIEW_MANIFEST.json'
    if output.exists():
        historical=work / ('SCIENTIFIC_REVIEW_MANIFEST_' + sha(output) + '.json')
        if not historical.exists():shutil.copyfile(output,historical)
    output.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(dict(status=manifest['status'], reviewed_targets=len(grid),
                         evidence_files=len(evidence), manifest_sha256=sha(output))))
    return manifest


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo', type=Path, required=True)
    p.add_argument('--root', type=Path, required=True)
    p.add_argument('--reference-root',type=Path)
    p.add_argument('--work',type=Path,help='New immutable review directory; preserve preceding scope evidence')
    a = p.parse_args()
    freeze(a.repo.resolve(), a.root.resolve(), a.reference_root.resolve() if a.reference_root else None,
           a.work.resolve() if a.work else None)
