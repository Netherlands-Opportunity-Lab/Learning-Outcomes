"""Record a completed existing finalizer; never create scientific approvals.

Private review files stay private. This public receipt retains their hashes,
the exact current/historical scope relation, and independently observed CI.
"""
import argparse
import collections
import csv
import datetime
import hashlib
import json
import subprocess
from pathlib import Path


def sha(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def rows(path):
    with path.open(encoding='utf-8-sig', newline='') as handle:
        yield from csv.DictReader(handle)


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def record(repo, root, output, ci_path, execution_commit):
    state = root / 'FIXED_PRODUCTION_V1/all_required'
    work = root / 'scientific_review_20261019'
    manifest = read_json(work / 'SCIENTIFIC_REVIEW_MANIFEST.json')
    binding = read_json(state / 'SCIENTIFIC_REVIEW_BINDING.json')
    quality = list(rows(state / 'SCIENTIFIC_QUALITY_SUMMARY.csv'))
    assert len(quality) == 1
    quality = quality[0]
    assert int(quality['paper_gates_pass']) == int(quality['paper_gates_required']) == 8
    assert int(quality['active_missing']) == 0 and quality['primary_peer_gate'] == 'PASS'
    assert quality['scientific_freeze'] == 'ELIGIBLE_FOR_INDEPENDENT_REVIEW'
    assert binding['review_manifest_sha256'] == sha(work / 'SCIENTIFIC_REVIEW_MANIFEST.json')
    stages = {r['stage']: r for r in rows(state / 'FIXED_STAGE_STATUS.csv')}
    assert stages['finalize']['status'] == 'SCIENTIFIC_BASIS_REVIEWED_PRODUCT_RELEASE_PENDING'
    assert stages['audit']['timestamp_utc'] < stages['finalize']['timestamp_utc']
    assert stages['produce']['timestamp_utc'] < stages['finalize']['timestamp_utc']
    assert stages['guided-preview']['status'] in (
        'PRIVATE_GUIDED_CANDIDATE_BUILT', 'REUSED_IMMUTABLE_PRIVATE_CANDIDATE')
    approval = root / 'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'
    assert sha(approval) == binding['approval_sha256'] == manifest['approval_sha256']
    for item in manifest['runtime_bindings']:
        assert sha(repo / item['path']) == item['sha256'], item['path']

    fields = ['country', 'status', 'target_contract_sha256', 'result_hash']
    def keyed(path):
        result = {}
        for row in rows(path):
            assert row['cell_id'] not in result
            result[row['cell_id']] = {k: row[k] for k in fields}
        return result
    before = keyed(work / 'REVIEWED_MASTER_GRID.csv')
    current = keyed(state / 'PRIVATE_MASTER_GRID.csv')
    admitted = sorted(r['country'] for r in rows(state / 'COUNTRY_SOURCE_ELIGIBILITY.csv')
                      if r['dashboard_eligible'].lower() == 'true')
    reviewed = sorted(r['country'] for r in rows(repo / '06_pipeline/review_20261013/scientific_review/VERIFIED_COUNTRY_ADMISSION.csv')
                      if r['dashboard_eligible'].lower() == 'true')
    assert admitted == reviewed
    assert not (current.keys() - before.keys()), 'Unreviewed new targets'
    removed = before.keys() - current.keys()
    assert all(before[k]['country'] not in admitted for k in removed), 'Approved target removed'
    assert all(current[k] == before[k] for k in current), 'Changed target/status/result'
    counts = collections.Counter(r['status'] for r in current.values())
    assert all(k == 'SCIENTIFICALLY_VALIDATED' or k.startswith('UNAVAILABLE_') for k in counts)
    assert len(current) == binding['current_targets']
    assert int(quality['documented_unavailable_total']) == sum(
        n for k, n in counts.items() if k.startswith('UNAVAILABLE_'))

    def git(*arguments):
        return subprocess.check_output(['git', '-C', str(repo), *arguments], text=True).strip()
    head = git('rev-parse', 'HEAD')
    branch = git('branch', '--show-current')
    assert branch == 'feat/reproducible-storage-and-cleanup-20261010'
    remote = git('ls-remote', 'origin', 'refs/heads/' + branch).split()[0]
    assert head == remote, 'Result commit not remotely verified'
    git('merge-base', '--is-ancestor', manifest['historical_result_commit'], head)
    git('merge-base', '--is-ancestor', execution_commit, head)
    public = repo / '04_results/review/all_required'
    deposited = read_json(public / 'manifest.json')
    assert deposited['target_rows'] == len(current)
    assert deposited['validated_rows'] == counts['SCIENTIFICALLY_VALIDATED']
    for entry in deposited['files']:
        assert sha(public / entry['file']) == entry['sha256']

    ci = read_json(ci_path)
    assert ci['head_sha'] == execution_commit and ci['conclusion'] == 'success'
    assert len(ci['jobs']) == 6 and all(j['conclusion'] == 'success' for j in ci['jobs'])
    receipts = list(rows(root / 'master_reconciliation/SCIENTIFIC_PAPER_GATES.csv'))
    assert {r['requirement_id'] for r in receipts} == {f'Q{i:02d}' for i in range(1, 9)}
    for r in receipts:
        assert r['status'] == 'PASS' and sha(Path(r['evidence_path'])) == r['evidence_sha256']
    files = ['FIXED_INPUT_MANIFEST.json', 'PRIVATE_MASTER_GRID.csv', 'SCIENTIFIC_REVIEW_BINDING.json',
             'SCIENTIFIC_QUALITY_SUMMARY.csv', 'PAPER_Q01_Q08_GATES.csv', 'BALANCED_REFERENCE_EXPORT.json',
             'GUIDED_PREVIEW_SUMMARY.csv', 'GUIDED_SCIENTIFIC_USE_EXCLUSIONS.csv',
             'ACTIVE_REQUIREMENT_REGISTER.csv', 'PRIVATE_ACTIVE_PRODUCT_CELL_TRACE.csv']
    result = dict(schema_version=1, status='SCIENTIFIC_BASIS_REVIEWED_WITH_EXPLICIT_LIMITATIONS',
        recorded_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        historical_result_commit=manifest['historical_result_commit'], execution_commit=execution_commit,
        deposited_result_commit=head, remote_result_commit_verified=remote,
        scope='all_required', current_targets=len(current), status_counts=dict(counts),
        remaining_compute_targets=0, new_pupil_calculations=0,
        original_target_count=len(before), historical_approved_master_rows=sum(1 for _ in rows(approval)),
        historical_approved_master_unchanged=True, approval_sha256=sha(approval),
        historical_targets_outside_current_dashboard_scope=dict(collections.Counter(before[k]['country'] for k in removed)),
        admission_count=len(admitted), admitted_countries=admitted,
        scientific_binding=binding, quality_summary=quality, latest_stages=stages,
        q_receipts=[{k: r[k] for k in ['requirement_id', 'status', 'evidence_sha256']} for r in receipts],
        private_artifact_sha256={name: sha(state / name) for name in files},
        platform_checks=ci,
        limits=['Q04 not applicable: unused two-wave variant excluded.',
                'Frozen SES measurement invariance outside calibration remains an assumption.',
                'Home-SES has one usable wave per IEA study; no spliced trend.',
                'IEA long-term contrasts are descriptive with scale-conditional uncertainty; no formal trend test.',
                'Population, mode, exclusions and nonresponse qualifications remain visible.',
                'This is scientific scope/review closure; final products, rights and clean source replication are separate.'])
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(json.dumps({k: result[k] for k in ['status', 'current_targets', 'status_counts', 'admission_count', 'deposited_result_commit']}))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--ci', type=Path, required=True)
    parser.add_argument('--execution-commit', required=True)
    args = parser.parse_args()
    record(args.repo, args.root, args.output, args.ci, args.execution_commit)
