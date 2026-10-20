"""Independently recompute exported R membership from exact aggregate mappings.

This does not grant scientific certification. It checks a pinned mapping audit,
rebinds its cells to the actual public results, and rejects changed membership,
periods, groups, defaults, or admission. Used at build and release time.
"""
from collections import Counter, defaultdict
import hashlib, json, math, re

COLS=('survey age_group domain year outcome split_dimension split_group definition_id '
      'ses_definition_id peer_definition peer_target_group threshold_id unit '
      'population_comparison_id method_comparison_id').split()
POLICY='FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3'
ANCHOR={('PIRLS','reading'):[2001,2006,2011,2016,2021],
        ('TIMSS','mathematics'):[2003,2007,2011,2015,2019,2023],
        ('TIMSS','science'):[2003,2007,2011,2015,2019,2023],
        ('PISA','reading'):[2003,2006,2009,2012,2015,2018,2022,2025],
        ('PISA','mathematics'):[2003,2006,2009,2012,2015,2018,2022,2025],
        ('PISA','science'):[2006,2009,2012,2015,2018,2022,2025]}

def arr(x):return [] if x is None else x if isinstance(x,list) else [x]
def fail(reason):raise ValueError('REFERENCE_PROOF_INVALID: '+reason)
def key(row):return '|'.join(str(row[k]) for k in COLS)
def fingerprint(parts):return hashlib.sha256(json.dumps(parts,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()

def verify_product(c,p):
    """Validate the displayed affine product without losing its primitive hash."""
    if p.get('source_id')!='GRID:SHA256:'+c['result_hash']:
        fail('changed primitive parent')
    transform=c.get('product_transform');scale=float(c.get('product_multiplier','nan'))
    intercept=float(c.get('product_intercept','nan'))
    if transform=='IDENTITY':
        if (scale,intercept)!=(1,0) or c.get('product_unit')!=c['unit'] or c.get('product_result_hash')!=c['result_hash']:
            fail('changed identity transform')
    elif transform=='BELOW_BASIC_COMPLEMENT_V1':
        parts=c['cell_id'].split('|')
        expected_scale={'proportion':-100,'percent':-1}.get(c['unit'])
        if (not p['figure_id'].startswith('GP_SES_BASIC_') or len(parts)!=12 or parts[5] not in ('base_share','q1_basic','q4_basic')
            or expected_scale is None or (scale,intercept)!=(expected_scale,100)
            or c.get('product_unit')!='percent' or c.get('product_result_hash')==c['result_hash']):
            fail('changed complement transform')
    else:fail('unreviewed product transform')
    for field,expected in [('estimate',intercept+scale*float(c['estimate'])),
                           ('se',abs(scale)*float(c['standard_error'])),
                           ('n_unweighted',float(c['n_unweighted']))]:
        if not math.isclose(float(p[field]),expected,rel_tol=1e-12,abs_tol=1e-9):
            fail('changed displayed '+field)
    if (not math.isclose(float(c['product_estimate']),float(p['estimate']),rel_tol=1e-12,abs_tol=1e-9)
        or not math.isclose(float(c['product_standard_error']),float(p['se']),rel_tol=1e-12,abs_tol=1e-9)):
        fail('changed reviewed product value')

def verify(evidence,rows,countries,figures,input_sha=None):
    if evidence.get('schema_version')!=3 or evidence.get('policy')!=POLICY:fail('schema/policy')
    review=evidence.get('mapping_evidence',{})
    if review.get('status')!='EXACT_SOURCE_RESULT_METHOD_COMPARABILITY_BINDINGS':fail('mapping audit missing')
    if input_sha and evidence.get('dashboard_input_sha256')!=input_sha:fail('changed dashboard input')
    actual={r['cell_id']:r for r in rows}
    if len(actual)!=len(rows):fail('duplicate public cell')
    cells={};support=defaultdict(set);core_cycles=defaultdict(set)
    if 'scope_countries' in evidence and set(arr(evidence['scope_countries']))!=set(countries):fail('changed country scope')
    for values in evidence['cells']:
        c=dict(zip(evidence['cell_columns'],values));cid=c['cell_id'];p=actual.get(cid)
        if cid in cells or p is None:fail('unapproved/duplicate mapping cell')
        if 'scope_countries' in evidence and c['country'] not in countries:fail('mapping outside country scope')
        affine_review=review.get('product_numeric_review')=='ALL_IDENTITY_AND_AFFINE_PRODUCTS_BOUND_TO_EXACT_PRIMITIVE'
        displayed_hash=c.get('product_result_hash') if affine_review else c['result_hash']
        if displayed_hash!=p['result_hash'] or c['country']!=p['country_id'].split(':')[-1] or int(c['year'])!=p['year']:
            fail('changed result binding')
        if affine_review:
            if not re.fullmatch('[a-f0-9]{64}',displayed_hash or ''):fail('missing display evidence')
            verify_product(c,p)
        for field in ('result_hash','verification_id','source_certificate_sha256','result_certificate_sha256'):
            if not re.fullmatch('[a-f0-9]{64}',c.get(field,'')):fail('missing cell evidence')
        parts=cid.split('|')
        custom=parts[0]=='NEW_PEER_BELOW_BASIC'
        if custom:
            if len(parts)!=8 or parts[1:5]!=[c['country'],c['survey'],c['year'],c['domain']]:fail('new peer cell identity')
            peer,threshold,unit=parts[5],parts[7],'percent'
        else:
            if len(parts)!=12 or parts[:4]!=[c['country'],c['survey'],c['year'],c['domain']]:fail('cell identity')
            peer,threshold,unit=parts[8] or 'none',parts[9] or 'none',parts[10]
        core=parts[4:8]==['core','mean','total','total']
        if core:
            if (c['outcome'],c['split_dimension'],c['split_group'],c['definition_id'])!=('mean_score','none','total',c['survey']+'_DOMAIN_MEAN'):fail('core definition')
        elif c['definition_id']!=fingerprint(parts[4:]):fail('changed definition/threshold/peer identity')
        if c['peer_definition']!=peer or c['threshold_id']!=threshold or c['unit']!=unit:fail('changed primitive dimensions')
        k=key(c)
        if k in support[c['country']]:fail('duplicate country support')
        c['balance_key']=k;cells[cid]=c;support[c['country']].add(k)
        if core:
            identity=tuple(c[v] for v in ('country','survey','age_group','domain','population_comparison_id','method_comparison_id','definition_id','unit'))
            core_cycles[identity].add(c['year'])
    if len(cells)!=evidence.get('exported_mapped_cells',review.get('mapped_cells')):fail('mapping audit count')
    admission={}; combination_counts={}
    for country in countries:
        counts=defaultdict(int)
        for identity,years in core_cycles.items():
            if identity[0]==country:counts[identity[1:4]]=max(counts[identity[1:4]],len(years))
        combination_counts[country]=counts
        admission[country]=any(counts[(s,age,d)]>=3 for s,age,d in (
            ('PIRLS','age10','reading'),('TIMSS','age10','mathematics'),('TIMSS','age10','science'),
            ('PISA','age15','reading'),('PISA','age15','mathematics'),('PISA','age15','science')))
    if {a['country']:a['dashboard_eligible'] for a in evidence['admission']}!=admission:fail('per-combination admission')
    if 'combination_admission' in evidence:
        for r in arr(evidence['combination_admission']):
            n=combination_counts[r['country']][(r['survey'],r['age_group'],r['domain'])]
            if int(r['verified_comparable_cycles'])!=n or bool(r['combination_pass'])!=(n>=3):
                fail('changed combination cycle counts')
    targets=defaultdict(set)
    for row in evidence['core_targets']:targets[row['country']].add(row['cell_id'])
    byfigure=defaultdict(list)
    for row in rows:byfigure[(row['country_id'].split(':')[-1],row['figure_id'])].append(row)
    views={(v['focus'],v['figure_id']):v for v in evidence['views']}
    dictionary=evidence.get('key_dictionary')
    def decode(value):return dictionary[int(value)-1] if dictionary is not None else value
    if len(views)!=len(evidence['views']) or set(views)!={(c,f['figure_id']) for c in countries for f in figures}:fail('view scope')
    for country in countries:
        full_core=targets[country]
        if not full_core:fail('empty focus core')
        if country=='NLD':
            required={f'NLD|{s}|{y}|{d}|core|mean|total|total|||score_points|' for (s,d),ys in ANCHOR.items() for y in ys}
            if not required<=full_core:fail('shortened Dutch anchor')
        for f in figures:
            combination=(f['survey'],'age15' if f['survey']=='PISA' else 'age10',f['domain'])
            core={cid for cid in full_core if (cid.split('|')[1],cid.split('|')[3])==(f['survey'],f['domain'])}
            def admitted_for(candidate):
                counts=combination_counts[candidate]
                if f['domain']=='all':return any(n>=3 for k,n in counts.items() if k[:2]==combination[:2])
                return counts[combination]>=3
            combination_ok=admitted_for(country)
            v=views[(country,f['figure_id'])];current=byfigure[(country,f['figure_id'])]
            ids={r['cell_id'] for r in current}
            if set(arr(v['view_cell_ids']))!=ids:fail('view mapping changed')
            years=set(f['required_years'].split(';'))
            if country!='NLD' and 'required_years' in v:
                targets_for_view=[cid.split('|') for cid in arr(v.get('target_cell_ids'))]
                if any(len(p)!=12 and p[0]!='NEW_PEER_BELOW_BASIC' for p in targets_for_view):fail('invalid focus target contract')
                own_years={p[3] if p[0]=='NEW_PEER_BELOW_BASIC' else p[2] for p in targets_for_view}
                if any((p[1] if p[0]=='NEW_PEER_BELOW_BASIC' else p[0])!=country for p in targets_for_view):fail('other focus target contract')
                if set(str(y) for y in arr(v['required_years']))!=own_years:fail('shortened own-country years')
                years=own_years
            elif 'required_years' in v and set(str(y) for y in arr(v['required_years']))!=years:
                fail('shortened Dutch figure years')
            expected={(int(y),g) for y in years for g in f['expected_series'].split(';')}
            present={(r['year'],r['series_id']) for r in current}
            incomplete='AGE_DOMAIN_NOT_ADMITTED' if not combination_ok else 'FOCUS_CORE_INCOMPLETE' if f['domain']!='all' and (not core or not core<=cells.keys()) else 'FOCUS_VIEW_INCOMPLETE' if not years or expected!=present else 'COMPARABILITY_PENDING' if not ids<=cells.keys() else None
            if incomplete:
                if v['status']!=incomplete or arr(v.get('default_members')) or arr(v.get('options')):fail('unproved view enabled')
                continue
            required={cells[cid]['balance_key'] for cid in core|ids}
            if {decode(k) for k in arr(v['required_keys'])}!=required:fail('shortened focus requirements')
            options={o['country']:o for o in arr(v['options'])}
            if set(options)!=set(countries):fail('candidate omitted')
            allowed=[]
            for candidate in countries:
                missing=required-support[candidate]
                candidate_admitted=admitted_for(candidate)
                eligible=candidate!=country and candidate_admitted and not missing
                o=options[candidate]
                if (o['eligible']!=eligible or o['dashboard_eligible']!=candidate_admitted
                    or o['missing_cells']!=len(missing) or o['required_cells']!=len(required)
                    or {decode(k) for k in filter(None,o['missing_keys'].split(';'))} !=
                       (set(sorted(missing)[:3]) if dictionary is not None else missing)):fail('membership/coverage differs')
                if eligible:allowed.append(candidate)
            if set(arr(v['default_members']))!=set(allowed)&set(arr(evidence['rich_candidates'])):fail('default changed')
            if v['status']!=('BALANCED_REFERENCE_AVAILABLE' if allowed else 'NO_ELIGIBLE_REFERENCE'):fail('status differs')
    return dict(status='PASS',mapped_cells=len(cells),views=len(views),admitted_result_countries=sum(admission.values()))
