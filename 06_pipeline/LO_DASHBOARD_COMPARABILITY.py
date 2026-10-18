"""Bind published aggregates to independently checked sample/method identities.

Read-only with respect to the production master. No pupil estimation or source
recoding takes place here. Inputs must be the frozen, numerically verified export.
The output is consumed by LO_BALANCED_MEMBERSHIP.R, not a new country selector.
"""
from __future__ import annotations
import argparse, csv, hashlib, json, math, re
from collections import Counter
from functools import lru_cache
from pathlib import Path

COLS = ('survey age_group domain year outcome split_dimension split_group '
        'definition_id ses_definition_id peer_definition peer_target_group '
        'threshold_id unit population_comparison_id method_comparison_id').split()

def sha(path):
    with Path(path).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

def readcsv(path):
    with Path(path).open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))

def writecsv(path, rows):
    with Path(path).open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)

def put(path,data):
    Path(path).write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8',newline='\n')

def array(x):return x if isinstance(x,list) else [] if x is None else [x]

@lru_cache(maxsize=None)
def checked(path, expected):
    if not re.fullmatch('[a-f0-9]{64}',expected) or sha(path)!=expected:
        raise ValueError('CHANGED_EVIDENCE: '+Path(path).name)
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))

@lru_cache(maxsize=None)
def certificate_cells(path,expected):
    c=checked(path,expected)
    if c.get('status')!='SCIENTIFICALLY_VALIDATED':raise ValueError('UNCERTIFIED_RESULTS')
    return {x['cell_id']:x for x in c['cells']}

@lru_cache(maxsize=None)
def source_receipts(path,expected):
    """Only follow hashed JSON evidence edges; never guess a sibling filename."""
    data=checked(path,expected);found=[]
    if data.get('status')=='RAW_SAMPLE_AND_FIELDS_VERIFIED':found.append((data,expected))
    if data.get('status')=='RAW_SAMPLE_AND_SELECTED_COLUMNS_VERIFIED' and data.get('exact_id_set') is True:
        found.append((dict(data,n=data['pupil_count'],raw_sha256=data['source_sha256']),expected))
    for edge in array(data.get('evidence_files')):
        p=edge['path']
        # Method certificates may reference an entire prior result master.
        # That is not a source edge and must not trigger a recursive re-audit.
        if Path(p).name in ('SOURCE_VERIFICATION.json','PARENT_SOURCE_VERIFICATION.json','SOURCE_SUPPORT_CERTIFICATE.json','RAW_CORE_VERIFICATION.json'):
            found.extend(source_receipts(p,edge['sha256']))
    return found

def inherit_source_identity(receipt, pool, depth=0):
    """Resolve a hashed canonical projection edge without changing its cohort."""
    if receipt.get('raw_sha256') or depth>=4:return receipt
    for parent,h in pool:
        if (receipt.get('parent_canonical_sha256')==parent.get('canonical_sha256')
            and all(receipt.get(k)==parent.get(k) for k in ('country','year','n'))
            and (not receipt.get('parent_source_certificate_sha256') or receipt['parent_source_certificate_sha256']==h)):
            p=inherit_source_identity(parent,pool,depth+1)
            if p.get('raw_sha256'):
                return dict(receipt,raw_sha256=p['raw_sha256'],all_source_records_retained=p.get('all_source_records_retained',False))
    return receipt

@lru_cache(maxsize=None)
def support_receipts(path,expected,canonical):
    data=checked(path,expected)
    found=source_receipts(path,expected)
    # The Dutch admission audit points to result certificates. Follow only
    # method certificates for this exact canonical source, not their full grid.
    for e in array(data.get('evidence_files')):
        if Path(e['path']).suffix.lower()!='.json':continue
        d=checked(e['path'],e['sha256'])
        if d.get('status')=='SCIENTIFICALLY_VALIDATED':
            methods={(c['certification_path'],c['certification_sha256']) for c in d['cells'] if c['source_edition_sha256']==canonical}
            for p,h in methods:found.extend(source_receipts(p,h))
    return [(r,h) for r,h in found if r.get('canonical_sha256')==canonical]

def method_family(row):
    """Reviewed implementation aliases only; design and PV rules also match.

    The Dutch pilot and international producer use the same independent
    estimators, with different version labels. All other labels remain exact.
    """
    m=row['method_version']
    m=m.replace('_RAW_FAY_PV_','_RAW_DESIGN_PV_').replace('_RAW_JRR_PV_','_RAW_DESIGN_PV_')
    if m=='PISA2022_CORE_MEAN_TAIL_FAY_PV_INDEPENDENT_CHECK_V1':m='PISA_MODERN_core_RAW_DESIGN_PV_INDEPENDENT_V1'
    if m=='PISA2025_NLD_LABELLED_MALE_ONLY_OFFICIAL_PARITY_V1':m='PISA_MODERN_gender_RAW_DESIGN_PV_INDEPENDENT_V1'
    if m=='PISA_LEGACY_language_exact_RAW_DESIGN_PV_INDEPENDENT_PROJECTION_V2':m='PISA_LEGACY_language_exact_RAW_DESIGN_PV_INDEPENDENT_V1'
    return m

def fingerprint(parts):return hashlib.sha256(json.dumps(parts,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()

@lru_cache(maxsize=None)
def checked_lineage(path,expected):
    if sha(path)!=expected:raise ValueError('CHANGED_DERIVATION_LINEAGE')
    return {r['cell_id']:r for r in readcsv(path)}

def map_cell(product,row,task,support,grid=None):
    if row['status']!='SCIENTIFICALLY_VALIDATED':
        raise ValueError('RESULT_BINDING')
    if row['result_hash']!=product['result_hash']:
        # The established R export hashes its below-basic complement as a
        # derived product. Bind it to the exact parent, unit and linear transform.
        if (not product['figure_id'].startswith('GP_SES_BASIC_') or task['stat'] not in ('base_share','q1_basic','q4_basic')
            or task['unit'] not in ('percent','proportion') or product['source_id']!='GRID:SHA256:'+row['result_hash']):
            raise ValueError('RESULT_BINDING')
        scale=100 if task['unit']=='proportion' else 1
        expected=100-float(row['estimate'])*scale
        if not math.isclose(float(product['estimate']),expected,abs_tol=1e-9) or not math.isclose(float(product['se']),float(row['standard_error'])*scale,abs_tol=1e-9):
            raise ValueError('COMPLEMENT_NUMERIC_BINDING')
    cert=certificate_cells(row['certification_path'],row['certification_sha256'])
    cell=cert.get(row['cell_id'])
    if not cell or cell['result_hash']!=row['result_hash']:raise ValueError('RESULT_CERTIFICATE_IDENTITY')
    for k in ('sample_id','input_fingerprint','code_fingerprint','source_edition_sha256',
              'method_version','weight_design','pv_rule','variance_rule'):
        if str(cell.get(k,''))!=row[k]:raise ValueError('RESULT_CERTIFICATE_'+k)
    for k in ('sample_id','input_fingerprint','code_fingerprint'):
        if product[k]!=row[k]:raise ValueError('PUBLIC_RESULT_'+k)
    audit_cell=cell;method_row=row
    if row['method_version']=='DERIVED_CORE_HIGH_PROPORTION_TO_NATIONAL_PERCENT_V1':
        top=checked(row['certification_path'],row['certification_sha256'])
        edges=[e for e in top['evidence_files'] if Path(e['path']).name=='EXACT_PARENT_LINEAGE.csv']
        if len(edges)!=1 or grid is None:raise ValueError('DERIVED_PARENT_LINEAGE_REQUIRED')
        lineage=checked_lineage(edges[0]['path'],edges[0]['sha256']).get(row['cell_id'])
        if not lineage or float(lineage['multiplier'])!=100:raise ValueError('DERIVED_MULTIPLIER')
        parent=grid[lineage['parent_cell_id']]
        if (parent['result_hash']!=lineage['parent_result_sha256'] or parent['statistic']!='total_high'
            or any(parent[k]!=row[k] for k in ('country','survey','year','domain','sample_id','source_edition_sha256','threshold_id'))
            or not math.isclose(float(row['estimate']),100*float(parent['estimate']),abs_tol=1e-9)
            or not math.isclose(float(row['standard_error']),100*float(parent['standard_error']),abs_tol=1e-9)
            or float(row['n_unweighted'])!=float(parent['n_unweighted'])):raise ValueError('DERIVED_PARENT_BINDING')
        audit_cell=certificate_cells(parent['certification_path'],parent['certification_sha256'])[parent['cell_id']]
        if audit_cell['result_hash']!=parent['result_hash']:raise ValueError('DERIVED_PARENT_CERTIFICATE')
        method_row=parent
    method=checked(audit_cell['certification_path'],audit_cell['certification_sha256'])
    if method.get('status')!='METHOD_SAMPLE_INPUT_CERTIFIED' or method_row['cell_id'] not in array(method.get('cell_ids')):
        raise ValueError('METHOD_CELL_BINDING')
    for k in ('sample_id','method_version','weight_design','pv_rule','variance_rule','source_edition_sha256'):
        if method.get(k)!=method_row[k]:raise ValueError('METHOD_'+k)
    sc=checked(support['certificate_path'],support['certificate_sha256'])
    if (sc.get('status')!='SOURCE_SUPPORT_VERIFIED' or sc.get('country')!=row['country']
            or sc.get('source_sha256')!=support['source_sha256'] or not sc.get('comparability_evidence')
            or '|'.join(support[k] for k in COLS) not in array(sc.get('support_keys'))):
        raise ValueError('SOURCE_SUPPORT_BINDING')
    # Admission and estimation may use different canonical projections. Bind
    # those to the SAME original bytes and complete national source sample.
    pool=source_receipts(audit_cell['certification_path'],audit_cell['certification_sha256'])
    if (row['method_version']=='PISA2025_NLD_LABELLED_MALE_ONLY_OFFICIAL_PARITY_V1'
            and task['module']=='gender' and task['group']=='boy' and task['stat']=='mean'):
        # The source receipt explicitly hashes the checked MALE=1 correction;
        # its immutable raw cohort and independently checked BRR/PV design stay
        # identical. This never turns Female / Other into a girls-only group.
        pool=pool+[(dict(x,canonical_sha256=x['gender_correction_canonical_sha256']),h)
            for x,h in pool if x.get('gender_correction_canonical_sha256')==row['source_edition_sha256']]
    receipts=[(inherit_source_identity(x,pool),h) for x,h in pool
              if x.get('canonical_sha256')==row['source_edition_sha256']
              and x.get('country')==row['country'] and str(x.get('year'))==row['year']]
    supports=support_receipts(support['certificate_path'],support['certificate_sha256'],support['source_sha256'])
    # The earliest Dutch core certificate has a direct identical canonical
    # source binding; later projections need the raw-byte/sample equivalence.
    identical_source=row['source_edition_sha256']==support['source_sha256']
    if identical_source:receipts=receipts or supports
    def parent_link(a,b,bh):
        return a.get('parent_canonical_sha256')==b.get('canonical_sha256') and a.get('parent_source_certificate_sha256')==bh
    matches=[(a,ah,b,bh) for a,ah in receipts for b,bh in supports
             if ((a.get('raw_sha256') and a['raw_sha256']==b.get('raw_sha256')) or parent_link(a,b,bh))
             and a.get('n')==b.get('n') and a.get('country')==b.get('country')
             and a.get('year')==b.get('year')]
    if matches:a,ah,b,bh=matches[0]
    elif identical_source:
        # Same checked canonical bytes and the national-population support
        # certificate: no inference from matching country labels is involved.
        a=receipts[0][0] if receipts else {};b=a
        ah=cell['certification_sha256'];bh=support['certificate_sha256']
    else:raise ValueError('SAMPLE_SOURCE_EQUIVALENCE_UNRESOLVED')
    if row['survey']!='PISA' and not identical_source and (not (a.get('all_source_records_retained') or parent_link(a,b,bh)) or not b.get('all_source_records_retained')):
        raise ValueError('INCOMPLETE_GRADE_COHORT')
    if task['module'] in ('peer_below_basic','high_proficiency_peer_exposure'):
        if any(row.get(k)!='PASS' for k in ('peer_denominator_verified','self_exclusion_verified','method_certification_status')):
            raise ValueError('PEER_VERIFICATION_REQUIRED')
    core=task['module']=='core' and task['stat']=='mean'
    dimensions=row['cell_id'].split('|')[4:]
    # The approved conditional pooling policy does not make girls+other
    # equivalent to girls. The actual published construct stays in the key.
    gender=''
    if task['module']=='gender':
        gender='female_or_other' if 'other' in product['series_label_en'].lower() else 'female_male'
    weights=row['weight_design'].replace('W_FSTUWT_W_FSTURWT1_80_FAY_0.5','W_FSTUWT_80_REPLICATE_WEIGHTS_FAY_0.5')
    comparison_method=support['method_comparison_id'] if core else fingerprint([
        method_family(row),weights,row['pv_rule'],row['variance_rule'],gender])
    result=dict(zip(COLS,[row['survey'],support['age_group'],row['domain'],row['year'],
        'mean_score' if core else task['stat'],'none' if core else task['module'],
        'total' if core else task['group'],support['definition_id'] if core else fingerprint(dimensions),
        task['definition'] if 'ses' in task['module'] else 'none',task['peer_definition'] or 'none',
        row['peer_target_group'] or 'none',task['threshold'] or 'none',task['unit'],
        support['population_comparison_id'],comparison_method]))
    result.update(cell_id=row['cell_id'],country=row['country'],estimate=row['estimate'],
        standard_error=row['standard_error'],n_unweighted=row['n_unweighted'],status=row['status'],
        result_hash=product['result_hash'],source_record_id=product['result_hash'],
        verification_id=fingerprint([row['certification_sha256'],cell['certification_sha256'],support['certificate_sha256'],ah,bh]),
        source_certificate_sha256=support['certificate_sha256'],result_certificate_sha256=row['certification_sha256'])
    return result

def build(snapshot,output,previous=None):
    output.mkdir(parents=True,exist_ok=False)
    proof=json.loads((snapshot/'product_export/SNAPSHOT_EXPORT_EVIDENCE.json').read_text(encoding='utf-8-sig'))
    product_path=snapshot/'public_inputs/dashboard_cells.csv'
    if proof['export_sha256']!=sha(product_path):raise ValueError('FROZEN_EXPORT_CHANGED')
    frozen=json.loads((snapshot/'SNAPSHOT.json').read_text(encoding='utf-8-sig'))
    for name,expected in frozen['inputs'].items():
        if sha(snapshot/name)!=expected:raise ValueError('FROZEN_INPUT_CHANGED: '+name)
    grid={r['cell_id']:r for r in readcsv(snapshot/'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv')}
    tasks={r['metric_key']:r for r in readcsv(snapshot/'product_export/PRIVATE_TASKS.csv')}
    support={(r['country'],r['survey'],r['year'],r['domain']):r for r in readcsv(snapshot/'master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv')}
    results=[];issues=[]
    if previous is not None:
        prior=json.loads((previous/'BALANCE_MAPPING_REVIEW.json').read_text())
        if prior['dashboard_input_sha256']!=sha(product_path) or prior['available_sha256']!=sha(previous/'BALANCE_AVAILABLE.csv'):
            raise ValueError('CHANGED_PREVIOUS_MAPPING')
        results=readcsv(previous/'BALANCE_AVAILABLE.csv')
    mapped={r['cell_id'] for r in results}
    for i,p in enumerate(readcsv(product_path)):
        if p['cell_id'] in mapped:continue
        r=grid[p['cell_id']]; t=tasks[p['cell_id']]
        key=tuple(r[k] for k in ('country','survey','year','domain'))
        s=support.get(key)
        if s is None and r['domain']=='all':
            s=next((v for k,v in support.items() if k[:3]==key[:3]),None)
        try:
            if s is None:raise ValueError('NO_SOURCE_SUPPORT')
            results.append(map_cell(p,r,t,s,grid))
        except ValueError as e:issues.append(dict(cell_id=r['cell_id'],country=r['country'],reason=str(e)))
        if (i+1)%5000==0:print('COMPARABILITY_CHECKED',i+1,'mapped',len(results),'unresolved',len(issues),flush=True)
    if not results:raise ValueError('NO_PROVEN_COMPARISON_CELLS')
    writecsv(output/'BALANCE_AVAILABLE.csv',results)
    if issues:writecsv(output/'BALANCE_MAPPING_ISSUES.csv',issues)
    core=[dict(country=t['country'],cell_id=t['metric_key']) for t in tasks.values() if t['module']=='core' and t['stat']=='mean']
    writecsv(output/'FOCUS_CORE_TARGETS.csv',core)
    evidence=dict(schema_version=1,status='EXACT_SOURCE_RESULT_METHOD_COMPARABILITY_BINDINGS',
        dashboard_input_sha256=sha(product_path),snapshot_sha256=sha(snapshot/'SNAPSHOT.json'),
        scientific_export_evidence_sha256=sha(snapshot/'product_export/SNAPSHOT_EXPORT_EVIDENCE.json'),
        mapped_cells=len(results),unresolved_cells=len(issues),reasons=dict(Counter(r['reason'] for r in issues)),
        available_sha256=sha(output/'BALANCE_AVAILABLE.csv'),core_targets_sha256=sha(output/'FOCUS_CORE_TARGETS.csv'),
        mapping_code_sha256=sha(__file__),previous_audit_sha256=sha(previous/'BALANCE_MAPPING_REVIEW.json') if previous else None,
        no_pupil_recalculation=True,no_new_scientific_freeze=True)
    put(output/'BALANCE_MAPPING_REVIEW.json',evidence)
    print(json.dumps(evidence))

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--snapshot',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    p.add_argument('--previous',type=Path)
    a=p.parse_args();build(a.snapshot,a.output,a.previous)
