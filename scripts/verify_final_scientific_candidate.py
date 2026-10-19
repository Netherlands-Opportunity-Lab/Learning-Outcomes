"""Check the actual existing finalizer's candidate against independent Q06 evidence.

No builder is invoked and no candidate is modified. This integration check
detects a missing R-to-Python binding even when both component tests succeed.
"""
import argparse
import csv
import hashlib
import json
from collections import Counter
from pathlib import Path


def sha(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def table(path):
    with path.open(encoding='utf-8-sig', newline='') as handle:
        return list(csv.DictReader(handle))


def verify(repo, root, output):
    state = root / 'FIXED_PRODUCTION_V1/all_required'
    work = root / 'scientific_review_20261019'
    summary = table(state / 'GUIDED_PREVIEW_SUMMARY.csv')[-1]
    assert summary['preview_status'] in ('PRIVATE_GUIDED_CANDIDATE_BUILT', 'REUSED_IMMUTABLE_PRIVATE_CANDIDATE')
    candidate = state / ('DASHBOARD_GUIDED_REVIEW_' + summary['preview_id'])
    manifest = read(candidate / 'BUILD_SHA256_MANIFEST.json')
    for row in manifest:
        path = (candidate / row['path']).resolve()
        assert path.is_relative_to(candidate.resolve())
        assert sha(path) == row['sha256'] and path.stat().st_size == row['bytes']
    qa = read(candidate / 'GUIDED_QA.json')
    assert qa['reference_policy_sha256'] == 'STRICT_BALANCE_DEFAULT'
    assert qa['scientific_source_sha256'] == sha(state / 'PRIVATE_GUIDED_VALIDATED_ROWS.csv')
    assert qa['balanced_references_sha256'] == sha(state / 'BALANCED_REFERENCE_EXPORT.json')
    expected_path = repo / '06_pipeline/review_20261013/scientific_review/REFERENCE_BY_VIEW.csv'
    expected = {(r['country'], r['figure_id']): r for r in table(expected_path)}
    review_manifest=work / 'SCIENTIFIC_REVIEW_MANIFEST.json'
    mapping_directory=Path(read(review_manifest).get('reference_mapping_directory',work / 'Q06_mapping_final')) if review_manifest.exists() else work / 'Q06_mapping_final'
    independent_path = mapping_directory / 'BALANCED_REFERENCE_EXPORT.json'
    independent = read(independent_path)
    independent_views = {(r['focus'], r['figure_id']): r for r in independent['views']}
    actual = {}
    for path in (candidate / 'data/references').glob('*.json'):
        data = read(path)
        assert data['policy'] == 'FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3'
        for row in data['figures']:
            key = row['focus'], row['figure_id']
            assert key not in actual
            actual[key] = row
    assert actual.keys() == expected.keys() == independent_views.keys()
    for key, row in actual.items():
        want = expected[key]
        for field, column in [('eligible_members', 'eligible_countries'), ('default_members', 'default_countries')]:
            assert row[field] == sorted(filter(None, want[column].split(';'))), (key, field)
        years = independent_views[key]['required_years']
        if isinstance(years, str):
            years = [years]
        assert set(row['required_years'].split(';')) == {str(y) for y in years}, (key, 'full required years')
        assert row['focus'] not in row['eligible_members']
        assert row['focus_excluded'] and row['country_weights'] == 'EQUAL_PER_COUNTRY'
        assert row['benchmark_uncertainty'] is False
    result = dict(status='ACTUAL_FINAL_CANDIDATE_MATCHES_INDEPENDENT_Q06',
        candidate_id=summary['preview_id'], views=len(actual),
        membership_differences=0, required_year_differences=0,
        actual_status_counts=dict(Counter(r['status'] for r in actual.values())),
        checked_candidate_files=len(manifest), scientific_data_rows=qa['scientific_data_rows'],
        source_sha256=qa['scientific_source_sha256'],
        actual_balance_export_sha256=qa['balanced_references_sha256'],
        independent_q06_export_sha256=sha(independent_path), reference_table_sha256=sha(expected_path),
        candidate_manifest_sha256=sha(candidate / 'BUILD_SHA256_MANIFEST.json'),
        builder_sha256=sha(repo / '06_pipeline/LO_FINAL_GUIDED_DASHBOARD_BUILD.py'),
        verification_script_sha256=sha(Path(__file__)), no_pupil_recalculation=True,
        public_deployment=False)
    output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    verify(args.repo, args.root, args.output)
