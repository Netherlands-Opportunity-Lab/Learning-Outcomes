"""Read-only product/grid/evidence audit. No pupil estimates or release writes.

Public outputs contain definitions and counts only. PRIVATE_* files contain
record identities and must stay local/private. Labels never grant reuse.
Run from RStudio with system2(LO_PYTHON, c(script, '--bundle', ..., '--out', ...)).
"""
import argparse, collections, csv, gzip, hashlib, json, math, re, sqlite3
from pathlib import Path
from PRODUCT_SCOPE_APPROVAL import apply_scope_approval, dependency_scope_status

COMMON42=set('ALB ARE AUS AZE BGR BRA CYP CZE DEU DNK ESP FIN FRA GEO HUN IRL ITA JOR KAZ LTU LVA MAR MKD MNE NLD NOR NZL POL PRT QAT SAU SGP SRB SVK SVN SWE TUR TWN USA HKG MAC XKX'.split())
REFERENCE=set('NLD AUS AUT BEL CAN CHE DEU DNK ESP FIN FRA GBR IRL ISL ITA KOR LUX NOR SWE USA'.split())
DERIVED={'GP_SES_GAP':['GP_SES_LEVELS'],'GP_GENDER_GAP':['GP_GENDER_LEVELS'],
 'GP_LANGUAGE_GAP':['GP_LANGUAGE_LEVELS'],'GP_MIGRATION_GAP':['GP_MIGRATION_LEVELS'],
 'DS_SPREAD':['DS_P10','DS_P90'],'TR_BASIC':['TR_BELOW'],'TR_POSITION':['TR_MEAN']}

def read_csv(path):
    with (gzip.open(path,'rt',encoding='utf-8-sig') if str(path).endswith('.gz') else Path(path).open(encoding='utf-8-sig',newline='')) as f:
        return list(csv.DictReader(f))

def sha(path):
    h=hashlib.sha256()
    with Path(path).open('rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
    return h.hexdigest()

def finite(x):
    try:return math.isfinite(float(x))
    except (TypeError,ValueError):return False

def numerical_pair(row):
    return finite(row.get('estimate')) and finite(row.get('se')) and float(row['se'])>=0

def numeric_equal(a,b):
    # A missing SE is not numerical agreement. Round-trip CSV tolerance only.
    return finite(a) and finite(b) and math.isclose(float(a),float(b),rel_tol=1e-12,abs_tol=1e-9)

def write_csv(path,rows,fields):
    with Path(path).open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');w.writeheader();w.writerows(rows)

def family(figure):return figure.split('_age')[0]

def new_low_peer_cells(tasks,countries):
    contexts={(t['country'],t['survey'],t['year'],t['domain'],t['peer_definition'],t['contract_figure_id']) for t in tasks
        if family(t['contract_figure_id'])=='EN_PERFORMANCE_PEER' and t['country'] in countries}
    cells=[]
    for country,survey,year,domain,peer,fig in sorted(contexts):
        threshold='PISA_BELOW_LEVEL2' if survey=='PISA' else 'IEA_BELOW_INTERMEDIATE_475'
        for group in ('total','self_below_basic','self_at_or_above_basic'):
            cells.append({'cell_id':'|'.join(('NEW_PEER_BELOW_BASIC',country,survey,year,domain,peer,group,threshold)),
              'country':country,'survey':survey,'year':year,'domain':domain,'peer_definition':peer,'group':group,
              'threshold':threshold,'historical_context_figure':fig,'status':'NEW_TARGET_NOT_VALIDATED_NOT_AUTHORIZED_TO_COMPUTE'})
    return cells

def scopes(bundle):
    common={r['route_code'] for r in read_csv(bundle/'COMMON42_REGISTER.csv') if r['common42_member'].upper()=='TRUE'}
    ref={r['country'] for r in read_csv(bundle/'PPP_COMPARATOR_MEMBERSHIP_v2.csv') if r['strictly_above_czechia'].upper()=='TRUE'}
    if common!=COMMON42 or ref!=REFERENCE:raise ValueError('SCOPE_HOLD: exact membership differs, even if counts agree')
    return {'nld_only':{'NLD'},'nld_plus_19':ref,'all_required':common|ref}

def verify_reference_snapshot(raw_path,member_path,expected_sha):
    if sha(raw_path)!=expected_sha:raise ValueError('Reference snapshot SHA differs; do not substitute a current WDI revision')
    data=json.loads(Path(raw_path).read_text(encoding='utf-8'))
    values={r['countryiso3code']:r['value'] for r in data[1] if r['date']=='2024' and r['indicator']['id']=='NY.GDP.PCAP.PP.CD'}
    rows=read_csv(member_path)
    if len(rows)!=38 or len({r['country'] for r in rows})!=38:raise ValueError('OECD38 extract differs')
    if not all(numeric_equal(r['gdp_per_capita_ppp_value'],values.get(r['country'])) for r in rows):raise ValueError('Reference numeric parity failed')
    selected={r['country'] for r in rows if values[r['country']]>values['CZE']}
    if selected!=REFERENCE:raise ValueError('Strict greater-than Czechia membership differs')
    return {'raw_sha256':expected_sha,'threshold_czechia':values['CZE'],'strict_members_including_NLD':sorted(selected),'status':'RAW_SNAPSHOT_NUMERIC_PARITY_VERIFIED'}

def registry_evidence(path):
    """Read an aggregate table in a consistent RO transaction, no student data.

    Input fingerprint strings can be huge size/mtime lists; read their type,
    not the private strings. SQL identifiers are fixed, never caller input.
    """
    if not path:return [],{'status':'NOT_INSPECTED'}
    path=Path(path).resolve();before=(path.stat().st_size,path.stat().st_mtime_ns)
    with sqlite3.connect(path.as_uri()+'?mode=ro',uri=True) as con:
        con.row_factory=sqlite3.Row;con.execute('BEGIN')
        if con.execute('select count(*) from results_v4').fetchone()[0]>1000000:raise ValueError('oversized aggregate registry')
        records=[dict(r) for r in con.execute("""select record_version_id,metric_key,estimate,se,is_current,status,
            code_fingerprint,result_hash,source_file,specification_fingerprint,
            case when length(input_fingerprint)=64 and input_fingerprint not glob '*[^a-fA-F0-9]*' then 1 else 0 end as input_sha256_format
            from results_v4""")]
        info={'status':'READ_ONLY_SNAPSHOT','rows':len(records),'unique_keys':len({r['metric_key'] for r in records}),
          'current_rows':sum(r['is_current']==1 for r in records),'input_sha256_format_rows':sum(r['input_sha256_format'] for r in records),
          'registered_status_counts':dict(collections.Counter(r['status'] for r in records)),
          'specification_join_rows':con.execute('select count(*) from results_v4 r join specifications_v4 s on r.specification_fingerprint=s.specification_fingerprint').fetchone()[0],
          'task_file_join_rows':con.execute('select count(*) from results_v4 r join tasks_v4 t on r.source_file=t.result_file').fetchone()[0],
          'dependency_rows':con.execute('select count(*) from dependencies_v4').fetchone()[0],
          'n_or_sample_columns_present':False,'scientifically_approved_in_this_audit':0}
        info['registered_product_links']=[dict(r) for r in con.execute('select product_id,relation,count(*) n from lifecycle_product_result_links group by product_id,relation')]
    after=(path.stat().st_size,path.stat().st_mtime_ns)
    if before!=after:raise ValueError('Registry changed during audit; retry against a stable snapshot')
    info['file_sha256']=sha(path)
    return records,info

def verify_lo01_sources(rows):
    """Check explicit archive row pointers + file SHA, not a coarse value join."""
    groups=collections.defaultdict(list)
    for row in rows:groups[row.get('source_file','')].append(row)
    receipts=[]
    for name,items in sorted(groups.items()):
        p=Path(name); digest=sha(p) if p.is_file() else ''
        wanted={int(r['evidence_source_row']) for r in items if str(r.get('evidence_source_row','')).isdigit()}
        selected={}
        if p.is_file() and wanted:
            with (gzip.open(p,'rt',encoding='utf-8-sig') if p.suffix=='.gz' else p.open(encoding='utf-8-sig',newline='')) as f:
                for i,r in enumerate(csv.DictReader(f),1):
                    if i in wanted:selected[i]=r
        for r in items:
            idx=int(r['evidence_source_row']) if str(r.get('evidence_source_row','')).isdigit() else -1
            src=selected.get(idx,{})
            hash_ok=bool(digest) and digest==r.get('evidence_source_sha256')
            point_ok=numeric_equal(r.get('estimate'),src.get('estimate'))
            se_ok=numeric_equal(r.get('se'),src.get('se'))
            receipts.append({'metric_key':r['metric_key'],'record_version_id':r.get('record_version_id',''),
              'source_file_sha_verified':hash_ok,'source_row_found':bool(src),'estimate_equal':point_ok,
              'finite_se_equal':se_ok,'source_pair_verified':hash_ok and point_ok and se_ok,
              'scientific_approval':'NOT_GRANTED'})
    return receipts

def match_requirement(req,task):
    if req['scope']=='NLD' and task['country']!='NLD':return False
    if req['scope']=='ALL_REQUIRED' and task['country'] not in COMMON42|REFERENCE:return False
    if family(task['contract_figure_id']) not in req['figure_families']:return False
    return all(task.get(k) in values for k,values in req['task_filters'].items())

def validate_definitions(defs,figures):
    reqs=defs['requirements'];ids=[r['requirement_id'] for r in reqs]
    if len(ids)!=len(set(ids)):raise ValueError('Duplicate product requirement')
    fs={family(f['figure_id']) for f in figures}
    ss={s['dependency_id'] for s in defs['supplemental_requirements']}
    for r in reqs:
        if not set(r['figure_families'])<=fs:raise ValueError('Unknown figure family '+r['requirement_id'])
        if not set(r['additional_dependencies'])<=ss:raise ValueError('Unknown supplemental dependency')
        if not r['figure_families'] and not r['additional_dependencies']:raise ValueError('Unmapped requirement')
    for product,count in [('POLICY_DECK',21),('SCIENTIFIC_SEMINAR',50),('SCIENTIFIC_NOTE',18),('DASHBOARD',138)]:
        if sum(r['product']==product for r in reqs)!=count:raise ValueError('Product coverage mismatch '+product)
    if not {f'Q{i:02}' for i in range(1,9)}<=set(ids):raise ValueError('Missing paper requirements')

def audit(bundle,definitions,out,registry=None,verify_sources=False):
    bundle=Path(bundle);out=Path(out);out.mkdir(parents=True,exist_ok=True)
    defs=apply_scope_approval(json.loads(Path(definitions).read_text(encoding='utf-8')))
    tasks=read_csv(bundle/'engine/TASKS.csv');figures=read_csv(bundle/'FIGURE_SERIES_CONTRACT_20261002.csv')
    links=read_csv(bundle/'PRODUCT_FIGUUR_RESULTAAT.csv.gz');scope=scopes(bundle)
    keys={t['metric_key'] for t in tasks};figids={f['figure_id'] for f in figures}
    if len(tasks)!=79448 or len(keys)!=79448 or len(figures)!=138:raise ValueError('Pinned historical contract counts changed')
    if len(links)!=len(tasks) or {r['metric_key'] for r in links}!=keys:raise ValueError('Historical task/link mismatch')
    validate_definitions(defs,figures)
    lo01=read_csv(bundle/'evidence/LO01_HISTORICAL_CANDIDATES.csv.gz')
    lo02=read_csv(bundle/'evidence/LO02_RETURN_20261010_CURRENT_RESULTS.csv.gz')
    db,dbinfo=registry_evidence(registry)
    receipts=verify_lo01_sources(lo01) if verify_sources else []
    source_verified={r['metric_key'] for r in receipts if r['source_pair_verified']}
    candidate=collections.defaultdict(list)
    for source,rs in [('LO01',lo01),('LO02',lo02),('REGISTRY_V4',db)]:
        for r in rs:candidate[r['metric_key']].append((source,r))
    def count(ts):
        kk={t['metric_key'] for t in ts}
        return {'historical_cells':len(kk),'keys_with_candidates':sum(k in candidate for k in kk),
          'keys_with_finite_estimate_se':sum(any(numerical_pair(r) for _,r in candidate.get(k,[])) for k in kk),
          'keys_with_source_pair_verified':len(kk&source_verified),'scientifically_approved':0}
    grid=[]
    for t in tasks:
        cc=candidate.get(t['metric_key'],[]); nums=[r for _,r in cc if numerical_pair(r)]
        conflict=bool(nums) and any(not numeric_equal(nums[0]['estimate'],r['estimate']) or not numeric_equal(nums[0]['se'],r['se']) for r in nums[1:])
        grid.append({'metric_key':t['metric_key'],'figure_id':t['contract_figure_id'],'country':t['country'],
          'candidate_versions':len(cc),'finite_estimate_se_versions':len(nums),'source_pair_verified':t['metric_key'] in source_verified,
          'cross_archive_numeric_disagreement':conflict,'decision':'HOLD_NUMERIC_VERSION_RECONCILIATION' if conflict else 'CANDIDATE_REQUIRES_SCIENTIFIC_REVIEW' if cc else 'NO_MATCH_IN_INSPECTED_EXACT_KEY_SOURCES',
          'new_compute_authorized':False,'reuse_authorized':False})
    figure_rows=[]
    byfig=collections.defaultdict(list)
    for t in tasks:byfig[t['contract_figure_id']].append(t)
    for f in figures:
        fam=family(f['figure_id'])
        for label,countries in scope.items():
            ts=[t for t in byfig[f['figure_id']] if t['country'] in countries]
            figure_rows.append({'figure_id':f['figure_id'],'scope':label,**count(ts),
              'historical_comparator':f['comparison_default'],'requested_comparator':'OECD_PPP_GT_CZE_2024_FIXED',
              'current_role':'COMPLEMENT_NO_SEPARATE_DEFAULT_PLOT' if fam=='TR_BASIC' else 'PENDING_USER_APPROVAL_A01_A03' if fam=='EN_PERFORMANCE_PEER' else 'EXCLUDED_DEFAULT_OPTIONAL_NEEDS_A02' if fam=='GP_SES_HIGH' else 'HISTORICAL_SCOPE_NOT_BLANKET_APPROVAL',
              'derivation_dependencies':';'.join(DERIVED.get(fam,[])),
              'uncertainty_gate':'JOINT_PV_REPLICATE_OR_COVARIANCE' if fam in DERIVED and fam not in ('TR_BASIC','TR_POSITION') else 'COUNTRY_DESIGN_SE_REFERENCE_POINT_ONLY',
              'scientific_status':'HOLD'})
    dependencies=[];req_rows=[];private_links=[]
    for req in defs['requirements']:
        matched=[t for t in tasks if match_requirement(req,t)]
        req_rows.append({k:req[k] for k in ('requirement_id','product','source_locator','title','scope','role')}|count(matched)|{
          'scope_approval':req['scope_approval'],'approval_items':';'.join(req['approval_items']),
          'production_authorized_by_inventory':False,
          'supplemental_dependencies':';'.join(req['additional_dependencies']),
          'mapping_status':'SPECIFIED_WITH_OPEN_SUPPLEMENTAL_GATES' if req['additional_dependencies'] else 'HISTORICAL_GRID_LINKED_NOT_SCIENTIFICALLY_RELEASED'})
        matched_counts=collections.Counter(t['contract_figure_id'] for t in matched)
        selectedfigs={f['figure_id'] for f in figures if family(f['figure_id']) in req['figure_families'] and ('contract_figure_id' not in req['task_filters'] or f['figure_id'] in req['task_filters']['contract_figure_id']) and ('survey' not in req['task_filters'] or f['survey'] in req['task_filters']['survey'])}
        for f in sorted(selectedfigs):
            dependencies.append({'requirement_id':req['requirement_id'],'dependency_id':f,'kind':'HISTORICAL_FIGURE_CONTRACT','matched_cells':matched_counts[f],
              'status':'DERIVED_RANK_DEPENDENCY' if family(f)=='TR_POSITION' else 'SCOPED_PARTIAL_OR_COMPLETE_MATCH_REQUIRES_METHOD_REVIEW'})
        for s in req['additional_dependencies']:
            dependencies.append({'requirement_id':req['requirement_id'],'dependency_id':s,'kind':'SUPPLEMENTAL_SPECIFICATION','matched_cells':'','status':dependency_scope_status(s)})
        for t in matched:private_links.append({'requirement_id':req['requirement_id'],'cell_id':t['metric_key']})
    # Ranks need mean cells of the SAME survey/age/domain; not a seventh run.
    derived=[]
    for f in figures:
        fam=family(f['figure_id'])
        for dep in DERIVED.get(fam,[]):
            exact=dep+f['figure_id'][len(fam):]
            if exact not in figids:raise ValueError('Missing derived dependency '+exact)
            derived.append({'figure_id':f['figure_id'],'input_figure_id':exact,'source_identity_gate':'SAME_COUNTRY_WAVE_SAMPLE_EDITION_CONSTRUCT','joint_uncertainty_required':fam not in ('TR_BASIC','TR_POSITION')})
    scope_counts=[]
    low_cells=new_low_peer_cells(tasks,scope['all_required'])
    for req in defs['requirements']:
        if 'S_LOW_PEER' not in req['additional_dependencies']:continue
        cells=[r for r in low_cells if (req['scope']!='NLD' or r['country']=='NLD') and
          ('contract_figure_id' not in req['task_filters'] or r['historical_context_figure'] in req['task_filters']['contract_figure_id'])]
        for r in cells:private_links.append({'requirement_id':req['requirement_id'],'cell_id':r['cell_id']})
        dependencies.append({'requirement_id':req['requirement_id'],'dependency_id':'NEW_PEER_BELOW_BASIC','kind':'NEW_GRID_CELLS','matched_cells':len(cells),'status':'PROPOSED_TARGETS_PENDING_USER_A01_NOT_VALIDATED'})
    for label,countries in scope.items():
        ts=[t for t in tasks if t['country'] in countries]
        active=[t for t in ts if family(t['contract_figure_id']) not in ('TR_BASIC','GP_SES_HIGH','EN_PERFORMANCE_PEER')]
        contexts={(t['country'],t['survey'],t['year'],t['domain'],t['peer_definition']) for t in ts if family(t['contract_figure_id'])=='EN_PERFORMANCE_PEER'}
        scope_counts.append({'scope':label,'countries':len(countries),**count(ts),'active_historical_cells':len(active),'new_below_basic_peer_cells':3*len(contexts),'additional_supplemental_cell_count':'NOT_EXPANDED_DO_NOT_TREAT_AS_ZERO'})
    evidence_summary=[]
    for label,rs in [('LO01',lo01),('LO02',lo02),('REGISTRY_V4',db)]:
        evidence_summary.append({'source':label,'rows':len(rs),'distinct_keys':len({r['metric_key'] for r in rs}),'finite_estimate_se_rows':sum(numerical_pair(r) for r in rs),'registered_status_counts':dict(collections.Counter(r.get('scientific_status',r.get('status','MISSING')) for r in rs)),'scientifically_approved_in_this_audit':0})
    summary={'schema_version':1,'audit_source_commit':defs['source_commit'],'scope_counts':scope_counts,
      'requirements':len(req_rows),'inventory_is_user_approval':False,
      'scope_basis':'HISTORICAL_42_20_50_COUNTS_NOT_6x3_ELIGIBILITY_PROOF',
      'pending_scope_requirements':sum(bool(r['approval_items']) for r in defs['requirements']),
      'product_counts':dict(collections.Counter(r['product'] for r in req_rows)),
      'supplemental_specifications':len(defs['supplemental_requirements']),'historical_figure_contracts':len(figures),
      'historical_unique_cells':len(keys),'derived_rank_figures':sum(family(f['figure_id'])=='TR_POSITION' for f in figures),
      'evidence_sources':evidence_summary,'registry':dbinfo,
      'lo01_source_checks':{'performed':verify_sources,'rows':len(receipts),'sha_verified':sum(r['source_file_sha_verified'] for r in receipts),'estimate_equal':sum(r['estimate_equal'] for r in receipts),'finite_se_equal':sum(r['finite_se_equal'] for r in receipts),'verified_finite_pairs':sum(r['source_pair_verified'] for r in receipts)},
      'historical_grid_decisions':dict(collections.Counter(r['decision'] for r in grid)),
      'scientific_release':'NOT_GRANTED','new_compute_authorized':False,'limits':['No candidate is independently certified by this inventory or numeric parity test.','Source-pair parity tests the archived payload before any recorded derivation; it is not approval of a transformed target.','No exact-key match is not evidence that computation is necessary.','Supplemental specifications other than new low peers still require certified cell expansion.','Cross-archive numeric differences may reflect editions/samples; no winner chosen.']}
    manifest=[{'logical_source':rel,'sha256':sha(bundle/rel)} for rel in ['engine/TASKS.csv','PRODUCT_FIGUUR_RESULTAAT.csv.gz','FIGURE_SERIES_CONTRACT_20261002.csv','COMMON42_REGISTER.csv','PPP_COMPARATOR_MEMBERSHIP_v2.csv','OPEN_PAPER_REQUIREMENTS.csv','evidence/LO01_HISTORICAL_CANDIDATES.csv.gz','evidence/LO02_RETURN_20261010_CURRENT_RESULTS.csv.gz']]
    manifest.append({'logical_source':'PRODUCT_REQUIREMENTS.json','sha256':sha(definitions)})
    for name in ('VERIFIED_PPP_MEMBERSHIP_2024.csv','RECOVERED_REFERENCE_SOURCE_AUDIT.json'):
        path=Path(definitions).parent/name
        if path.exists():manifest.append({'logical_source':name,'sha256':sha(path)})
    if (out/'REFERENCE_NUMERIC_CHECK.json').exists():
        manifest.append({'logical_source':'REFERENCE_NUMERIC_CHECK.json','sha256':sha(out/'REFERENCE_NUMERIC_CHECK.json')})
    for name,rs,fields in [('PRODUCT_GRID_REQUIREMENTS.csv',req_rows,list(req_rows[0])),('PRODUCT_GRID_DEPENDENCIES.csv',dependencies,list(dependencies[0])),('FIGURE_SCOPE_EVIDENCE.csv',figure_rows,list(figure_rows[0])),('DERIVED_FIGURE_DEPENDENCIES.csv',derived,list(derived[0])),('SUPPLEMENTAL_RESULT_REQUIREMENTS.csv',defs['supplemental_requirements'],list(defs['supplemental_requirements'][0])),('SOURCE_MANIFEST.csv',manifest,['logical_source','sha256']),('PRIVATE_GRID_EVIDENCE.csv',grid,list(grid[0])),('PRIVATE_PRODUCT_CELL_LINKS.csv',private_links,['requirement_id','cell_id']),('PRIVATE_LO01_SOURCE_PARITY.csv',receipts,['metric_key','record_version_id','source_file_sha_verified','source_row_found','estimate_equal','finite_se_equal','source_pair_verified','scientific_approval'])]:write_csv(out/name,rs,fields)
    write_csv(out/'PRIVATE_NEW_LOW_PEER_GRID.csv',low_cells,list(low_cells[0]))
    (out/'EVIDENCE_AUDIT_SUMMARY.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    return summary

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--bundle',required=True);p.add_argument('--definitions',default=str(Path(__file__).parent/'review_20261013/PRODUCT_REQUIREMENTS.json'));p.add_argument('--out',required=True);p.add_argument('--registry');p.add_argument('--verify-lo01-sources',action='store_true');p.add_argument('--reference-raw');a=p.parse_args()
    if a.reference_raw:
        receipt=verify_reference_snapshot(a.reference_raw,Path(a.definitions).parent/'VERIFIED_PPP_MEMBERSHIP_2024.csv','0d21bdc1cc3070a632d09a76620dab0c971ba1c7053a95027b7f685f43db5df3')
        Path(a.out).mkdir(parents=True,exist_ok=True)
        (Path(a.out)/'REFERENCE_NUMERIC_CHECK.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    s=audit(a.bundle,a.definitions,a.out,a.registry,a.verify_lo01_sources)
    print(json.dumps({'requirements':s['requirements'],'historical_cells':s['historical_unique_cells'],'scope_counts':s['scope_counts'],'scientific_release':s['scientific_release']}))
