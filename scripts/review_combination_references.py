"""Revalidate the new comparison policy on the retained certified aggregates.

The historical science snapshot remains byte-for-byte intact. The derived
snapshot filters only explicit task and population decisions and keeps exact
parent records; there are no pupil calculations or changed estimates here.
"""
import argparse
import csv
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'06_pipeline'))
from LO_DASHBOARD_COMPARABILITY import population_review_index, population_review_for


def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()


def read(p):
    with p.open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))


def write(p,rows):
    p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,list(rows[0]));w.writeheader();w.writerows(rows)


def main(repo,root,rscript):
    work=root/'scientific_review_20261019';out=work/'combination_scope'
    old=work/'snapshot';snapshot=out/'reference_snapshot';audit=out/'reference_mapping'
    snapshot.mkdir(parents=True,exist_ok=False)
    frozen=json.loads((old/'SNAPSHOT.json').read_text())
    for name,expected in frozen['inputs'].items():
        if sha(old/name)!=expected:raise ValueError('Historical input changed: '+name)
    inputs={}
    # Use hard links to unchanged immutable aggregate/source-proof indices;
    # no private pupil data or redundant historical copies are created.
    for name in ['master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv',
        'master_reconciliation/SOURCE_UNAVAILABLE_CELLS.csv',
        'master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv']:
        target=snapshot/name;target.parent.mkdir(parents=True,exist_ok=True)
        os.link(old/name,target);inputs[name]=sha(target)
    name='product_export/PRIVATE_TASKS.csv';target=snapshot/name
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(out/'EXACT_ALL_REQUIRED_TASKS.csv',target);inputs[name]=sha(target)
    ids={r['metric_key'] for r in read(target)}
    corrections=json.loads((repo/'06_pipeline/review_20261013/POPULATION_CORRECTIONS.json').read_text())
    excluded=population_review_index(corrections['corrections'])
    original_rows=read(old/'public_inputs/dashboard_cells.csv')
    rows=[r for r in original_rows if r['cell_id'] in ids and not
          population_review_for(excluded,r['country'],r['survey'],r['year'],r['domain'])]
    write(snapshot/'public_inputs/dashboard_cells.csv',rows)
    source_registry=out/'all_required/COUNTRY_SOURCE_ELIGIBILITY.csv'
    name='public_inputs/COUNTRY_SOURCE_ELIGIBILITY.csv'
    shutil.copyfile(source_registry,snapshot/name);inputs[name]=sha(snapshot/name)
    proof=dict(export_sha256=sha(snapshot/'public_inputs/dashboard_cells.csv'),
        historical_export_sha256=sha(old/'public_inputs/dashboard_cells.csv'),
        historical_export_evidence_sha256=sha(old/'product_export/SNAPSHOT_EXPORT_EVIDENCE.json'),
        exact_tasks_sha256=inputs['product_export/PRIVATE_TASKS.csv'],
        decision_sha256=sha(repo/'06_pipeline/review_20261013/BALANCE_USER_DECISION_20261019.json'),
        population_review_sha256=sha(repo/'06_pipeline/review_20261013/POPULATION_CORRECTIONS.json'),
        reuse='EXACT_HISTORICAL_ROWS_FILTERED_BY_APPROVED_COMBINATIONS_AND_POPULATIONS',
        original_rows=len(original_rows),retained_rows=len(rows),pupil_recalculation=False)
    (snapshot/'product_export/SNAPSHOT_EXPORT_EVIDENCE.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8')
    (snapshot/'SNAPSHOT.json').write_text(json.dumps(dict(inputs=inputs,
        parent_snapshot_sha256=sha(old/'SNAPSHOT.json'),result_commit=frozen['result_commit'],
        scope_impact_sha256=sha(out/'COMBINATION_SCOPE_IMPACT.json'),stable=True),indent=2)+'\n',encoding='utf-8')
    subprocess.run([sys.executable,str(repo/'06_pipeline/LO_DASHBOARD_COMPARABILITY.py'),
        '--snapshot',str(snapshot),'--output',str(audit),'--previous',str(work/'Q06_mapping_final')],check=True)
    shutil.copyfile(work/'Q06_mapping_final/FIGURES.json',audit/'FIGURES.json')
    subprocess.run([rscript,'--vanilla',str(repo/'06_pipeline/LO_DASHBOARD_REFERENCE_EXPORT.R'),
        str(repo),str(snapshot),str(audit)],check=True)
    # Invoke the same independent verifier used by publication, including every
    # real point, source/method key, full-year set and country checkbox option.
    import importlib.util
    spec=importlib.util.spec_from_file_location('builder',repo/'06_pipeline/LO_FINAL_GUIDED_DASHBOARD_BUILD.py')
    builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
    export=audit/'BALANCED_REFERENCE_EXPORT.json'
    evidence=json.loads(export.read_text(encoding='utf-8-sig'))
    figures=json.loads((audit/'FIGURES.json').read_text())['figures']
    country_codes=evidence['scope_countries']
    products=builder.product_rows(snapshot/'public_inputs/dashboard_cells.csv',country_codes,figures)
    references=builder.explorer_references(export,country_codes,figures,products,proof['export_sha256'])
    (out/'COMBINATION_REFERENCES.json').write_text(json.dumps(references,separators=(',',':'))+'\n',encoding='utf-8')
    rows=[dict(country=r['focus'],figure_id=r['figure_id'],status=r['status'],required_years=r['required_years'],
        eligible_countries=';'.join(r['eligible_members']),default_countries=';'.join(r['default_members'])) for r in references['figures']]
    write(out/'COMBINATION_REFERENCE_BY_VIEW.csv',rows)
    result=dict(status='ALL_EXISTING_SOURCE_CERTIFIED_COUNTRY_VIEWS_REVALIDATED',
        countries=len(country_codes),views=len(rows),scientific_product_rows=len(products),
        policy=references['policy'],source_registry_sha256=sha(source_registry),
        exact_tasks_sha256=inputs['product_export/PRIVATE_TASKS.csv'],
        reference_export_sha256=sha(export),reference_table_sha256=sha(out/'COMBINATION_REFERENCE_BY_VIEW.csv'),
        independent_verifier_sha256=sha(repo/'06_pipeline/LO_DASHBOARD_REFERENCE_VERIFY.py'),
        builder_sha256=sha(repo/'06_pipeline/LO_FINAL_GUIDED_DASHBOARD_BUILD.py'),
        review_script_sha256=sha(Path(__file__)),pupil_recalculation=False,public_deployment=False,
        limitation='This verifies the currently source-certified countries. Additional source candidates require separate certification and any new approved estimates.')
    (out/'COMBINATION_REFERENCE_REVIEW.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result))


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--repo',type=Path,required=True)
    p.add_argument('--root',type=Path,required=True);p.add_argument('--rscript',required=True)
    a=p.parse_args();main(a.repo.resolve(),a.root.resolve(),a.rscript)
