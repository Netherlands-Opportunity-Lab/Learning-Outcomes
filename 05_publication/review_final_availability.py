"""Explain every missing displayed point from the reviewed exact-cell grid.

This aggregate-only review preserves every figure/year/group and all numerical
rows. It never turns an uncomputed or unmapped target into source absence.
It replays only the identity transforms of LO_FINAL_GUIDED_EXPORT.R and checks
them against every released point before applying the same mapping to gaps.
"""
import argparse
from collections import Counter, defaultdict
import csv
import gzip
import hashlib
import json
from pathlib import Path


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def rows(path):
    opener = gzip.open if path.suffix == '.gz' else open
    with opener(path, 'rt', encoding='utf-8-sig', newline='') as stream:
        yield from csv.DictReader(stream)


REASONS = {
    'SCALE_NOT_DEFINED_IN_CYCLE': ('Deze gekozen schaal bestaat niet in deze meetgolf.', 'The selected scale does not exist in this survey wave.'),
    'REQUIRED_FIELD_NOT_OBSERVED': ('Een benodigd bronveld ontbreekt in de gecontroleerde bestanden.', 'A required source field is absent from the reviewed files.'),
    'LEARNING_ENVIRONMENT_NOT_OBSERVED': ('De gekozen leeromgeving is niet afzonderlijk geobserveerd.', 'The selected learning environment is not separately observed.'),
    'ANALYTIC_GROUP_UNUSABLE': ('De gekozen analysegroep heeft geen bruikbare waarnemingen.', 'The selected analysis group has no usable observations.'),
    'OFFICIAL_TREND_NOT_COMPARABLE': ('De officiële bron staat deze trendvergelijking niet toe.', 'The official source does not support this trend comparison.'),
    'GROUP_DEFINITION_NOT_OBSERVED': ('De vereiste groepsdefinitie is in deze meetgolf niet geobserveerd.', 'The required group definition is not observed in this wave.'),
    'QUESTIONNAIRE_NOT_ADMINISTERED': ('De benodigde vragenlijst is hier niet afgenomen.', 'The required questionnaire was not administered here.'),
    'DOMAIN_NOT_VALID_IN_SOURCE': ('Dit domein ontbreekt of is ongeldig in deze broneditie.', 'This domain is absent or invalid in this source edition.'),
    'ANALYSIS_BELOW_PUBLICATION_THRESHOLD': ('De analysegroep voldoet niet aan de grens voor aantallen leerlingen of scholen.', 'The analysis group does not meet the pupil or school count threshold.'),
}


def identity(source_id, cell, figures):
    fid, group = source_id, cell['subgroup_level']
    module, stat, definition = cell['subgroup_variable'], cell['statistic'], cell['outcome_id']
    family = fid.split('_age')[0]
    study_id = fid + '_' + cell['survey']
    if fid not in figures and any(k == study_id or k.startswith(study_id + '_') for k in figures):
        fid = study_id
    if family == 'EN_PERFORMANCE_PEER' and module != 'peer_below_basic':
        fid = fid.replace('EN_PERFORMANCE_PEER_', 'EN_PERFORMANCE_PEER_HIGH_', 1)
    if family in ('GP_MIGRATION_LEVELS', 'GP_MIGRATION_GAP', 'EN_MIGRATION_PEER'):
        if definition in ('MIGRATION_ANY_PARENT_ABROAD', 'MIGRATION_BOTH_PARENTS_ABROAD'):
            fid += '_' + definition.removeprefix('MIGRATION_')
        if family == 'EN_MIGRATION_PEER' and module == 'migration_binary_peer':
            group = stat
        if family == 'EN_MIGRATION_PEER' and module == 'peer_baseline' and stat == 'reference_share':
            group = 'population_reference_share'
    if family == 'EN_LANGUAGE_PEER':
        group = 'population_test_language_share' if module == 'peer_baseline' and stat == 'test_language_share' else stat
    if family == 'EN_SES_PEER' and module == 'peer_baseline' and stat in ('q1_share', 'q4_share'):
        group = 'population_' + stat
    if family == 'EN_PERFORMANCE_PEER' and module == 'peer_baseline' and stat == 'high_share':
        group = 'population_high_share'
    if fid not in figures and fid + '_' + cell['survey'] in figures:
        fid += '_' + cell['survey']
    if fid not in figures or group not in figures[fid]['expected_series'].split(';'):
        return None
    return cell['country'], fid, int(cell['year']), group


def review(site, coverage, trace):
    figures = {f['figure_id']: f for f in json.loads((site/'data/figure_registry.json').read_text())['figures']}
    cells = {c['cell_id']: c for c in rows(coverage)}
    lookup = defaultdict(set)
    for link in rows(trace):
        if link['product'] != 'DASHBOARD':
            continue
        cell = cells[link['cell_id']]
        key = identity(link['figure_id'], cell, figures)
        if key:
            lookup[key].add(cell['cell_id'])
    countries = [c['code'] for c in json.loads((site/'data/common42.json').read_text())]
    shown, pending, evidence, states, counts = 0, [], [], Counter(), Counter()
    updates = {}
    for country in countries:
        numerical = json.loads((site/f'data/countries/{country}.json').read_text())['records']
        for r in numerical:
            key = country, r['figure_id'], int(r['year']), r['series_id']
            if lookup[key] != {r['cell_id']}:
                raise ValueError('Exact task mapping differs from plotted point: '+str(key))
            shown += 1
        path = site/f'data/availability/{country}.json'
        availability = json.loads(path.read_text())
        for figure in availability['figures']:
            fid = figure['figure_id']
            for gap in figure['missing_points']:
                key = country, fid, int(gap['year']), gap['series_id']
                ids = sorted(lookup[key])
                if len(ids) != 1:
                    pending.append(dict(point=key, issue='MISSING_OR_AMBIGUOUS_APPROVED_TARGET', candidates=ids))
                    continue
                cell = cells[ids[0]]
                reason = cell['main_reason']
                if cell['national_use'] == 'EXCLUDE_FROM_COMPARABLE_TREND_SUPPORT':
                    reason = 'OFFICIAL_TREND_NOT_COMPARABLE'
                elif reason == 'RESULT_AVAILABLE' and cell['analysis_support_allows_publication'] == 'False':
                    reason = 'ANALYSIS_BELOW_PUBLICATION_THRESHOLD'
                if reason not in REASONS:
                    pending.append(dict(point=key, issue='VALID_RESULT_MISSING_FROM_PRODUCT_OR_UNFINISHED_TARGET', cell_id=ids[0], reason=reason))
                    continue
                item = dict(country=country, figure_id=fid, **gap, cell_id=ids[0],
                            main_reason=reason, reason_nl=REASONS[reason][0], reason_en=REASONS[reason][1],
                            status=cell['status'], hold_reason=cell['hold_reason'],
                            target_contract_sha256=cell['target_contract_sha256'],
                            result_hash=cell['result_hash'], source_edition_sha256=cell['source_edition_sha256'],
                            population_review_id=cell['population_review_id'],
                            analysis_min_component_n=cell['analysis_min_component_n'],
                            analysis_min_component_school_n=cell['analysis_min_component_school_n'],
                            quality_notes=cell['quality_notes'])
                gap.update({k: item[k] for k in ('cell_id','main_reason','reason_nl','reason_en')})
                evidence.append(item)
                counts[reason] += 1
            if figure['display_state'] == 'PLACEHOLDER':
                figure['display_state'] = 'UNAVAILABLE'
            if figure['missing_points']:
                figure['missingness_review'] = 'EXACT_REVIEWED_CELL_EVIDENCE'
                figure['reason_nl'] = 'Ontbrekende meetpunten zijn beoordeeld; de reden staat per jaar en groep onder Beschikbaarheid.'
                figure['reason_en'] = 'Missing points have been reviewed; see Availability for the reason for each year and group.'
            states[figure['display_state']] += 1
        updates[path] = availability
    if pending:
        raise ValueError(json.dumps(dict(unresolved_count=len(pending),
            by_figure=dict(Counter(p['point'][1] for p in pending)),
            examples=pending[-8:]), ensure_ascii=False))
    proof = dict(schema_version=1, status='ALL_MISSING_POINTS_HAVE_EXACT_REVIEWED_CAUSES',
                 coverage_sha256=sha(coverage), product_trace_sha256=sha(trace),
                 numerical_rows_identity_checked=shown, reviewed_missing_points=len(evidence),
                 reasons=dict(counts), points=evidence, code_sha256=sha(Path(__file__)))
    for path, data in updates.items():
        path.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8',newline='\n')
    proof_path = site/'data/absence_evidence.json'
    proof_path.write_text(json.dumps(proof,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8',newline='\n')
    qa_path = site/'GUIDED_QA.json'
    qa = json.loads(qa_path.read_text())
    qa.update(availability_counts=dict(sorted(states.items())), reviewed_absence_evidence_sha256=sha(proof_path))
    qa_path.write_text(json.dumps(qa,indent=2)+'\n',encoding='utf-8',newline='\n')
    manifest = [dict(path=p.relative_to(site).as_posix(),bytes=p.stat().st_size,sha256=sha(p))
                for p in sorted(site.rglob('*')) if p.is_file() and p.name!='BUILD_SHA256_MANIFEST.json']
    (site/'BUILD_SHA256_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
    return {k:v for k,v in proof.items() if k!='points'}


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--site',type=Path,required=True)
    p.add_argument('--coverage',type=Path,required=True)
    p.add_argument('--trace',type=Path,required=True)
    a=p.parse_args()
    print(json.dumps(review(a.site,a.coverage,a.trace)))
