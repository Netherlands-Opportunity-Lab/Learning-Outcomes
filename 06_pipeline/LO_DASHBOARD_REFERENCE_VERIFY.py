"""Independently recompute exported R membership from exact aggregate mappings.

This does not grant scientific certification. It checks a pinned mapping audit,
rebinds its cells to the actual public results, and rejects changed membership,
periods, groups, defaults, or admission. Used at build and release time.
"""
from collections import Counter, defaultdict
import hashlib, json, re

COLS=('survey age_group domain year outcome split_dimension split_group definition_id '
      'ses_definition_id peer_definition peer_target_group threshold_id unit '
      'population_comparison_id method_comparison_id').split()
POLICY='FULL_FOCUS_CORE_PLUS_JOINT_VIEW_SUPPORT_6x3'
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

def verify(evidence,rows,countries,figures,input_sha=None):
    if evidence.get('schema_version')!=3 or evidence.get('policy')!=POLICY:fail('schema/policy')
    review=evidence.get('mapping_evidence',{})
    if review.get('status')!='EXACT_SOURCE_RESULT_METHOD_COMPARABILITY_BINDINGS':fail('mapping audit missing')
    if input_sha and evidence.get('dashboard_input_sha256')!=input_sha:fail('changed dashboard input')
    actual={r['cell_id']:r for r in rows}
    if len(actual)!=len(rows):fail('duplicate public cell')
    cells={};support=defaultdict(set);core_cycles=defaultdict(set)
    for values in evidence['cells']:
        c=dict(zip(evidence['cell_columns'],values));cid=c['cell_id'];p=actual.get(cid)
        if cid in cells or p is None:fail('unapproved/duplicate mapping cell')
        if c['result_hash']!=p['result_hash'] or c['country']!=p['country_id'].split(':')[-1] or int(c['year'])!=p['year']:
            fail('changed result binding')
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
    if len(cells)!=review.get('mapped_cells'):fail('mapping audit count')
    admission={}
    for country in countries:
        counts=defaultdict(int)
        for identity,years in core_cycles.items():
            if identity[0]==country:counts[identity[1:4]]=max(counts[identity[1:4]],len(years))
        admission[country]=all(counts[(s,age,d)]>=3 for s,age,d in (
            ('PIRLS','age10','reading'),('TIMSS','age10','mathematics'),('TIMSS','age10','science'),
            ('PISA','age15','reading'),('PISA','age15','mathematics'),('PISA','age15','science')))
    if {a['country']:a['dashboard_eligible'] for a in evidence['admission']}!=admission:fail('6x3 admission')
    targets=defaultdict(set)
    for row in evidence['core_targets']:targets[row['country']].add(row['cell_id'])
    byfigure=defaultdict(list)
    for row in rows:byfigure[(row['country_id'].split(':')[-1],row['figure_id'])].append(row)
    views={(v['focus'],v['figure_id']):v for v in evidence['views']}
    dictionary=evidence.get('key_dictionary')
    def decode(value):return dictionary[int(value)-1] if dictionary is not None else value
    if len(views)!=len(evidence['views']) or set(views)!={(c,f['figure_id']) for c in countries for f in figures}:fail('view scope')
    for country in countries:
        core=targets[country]
        if not core:fail('empty focus core')
        if country=='NLD':
            required={f'NLD|{s}|{y}|{d}|core|mean|total|total|||score_points|' for (s,d),ys in ANCHOR.items() for y in ys}
            if not required<=core:fail('shortened Dutch anchor')
        for f in figures:
            v=views[(country,f['figure_id'])];current=byfigure[(country,f['figure_id'])]
            ids={r['cell_id'] for r in current}
            if set(arr(v['view_cell_ids']))!=ids:fail('view mapping changed')
            expected={(int(y),g) for y in f['required_years'].split(';') for g in f['expected_series'].split(';')}
            present={(r['year'],r['series_id']) for r in current}
            incomplete='FOCUS_CORE_INCOMPLETE' if not core<=cells.keys() else 'FOCUS_VIEW_INCOMPLETE' if expected!=present else 'COMPARABILITY_PENDING' if not ids<=cells.keys() else None
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
                eligible=candidate!=country and admission[candidate] and not missing
                o=options[candidate]
                if (o['eligible']!=eligible or o['dashboard_eligible']!=admission[candidate]
                    or o['missing_cells']!=len(missing) or o['required_cells']!=len(required)
                    or {decode(k) for k in filter(None,o['missing_keys'].split(';'))} !=
                       (set(sorted(missing)[:3]) if dictionary is not None else missing)):fail('membership/coverage differs')
                if eligible:allowed.append(candidate)
            if set(arr(v['default_members']))!=set(allowed)&set(arr(evidence['rich_candidates'])):fail('default changed')
            if v['status']!=('BALANCED_REFERENCE_AVAILABLE' if allowed else 'NO_ELIGIBLE_REFERENCE'):fail('status differs')
    return dict(status='PASS',mapped_cells=len(cells),views=len(views),admitted_result_countries=sum(admission.values()))
