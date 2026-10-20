// Pure figure selection and certified-aggregate derivations. No student data.
export const list = value => value == null ? [] : Array.isArray(value) ? value : [value];
export const number = v => v === null || v === undefined || typeof v === 'boolean' || String(v).trim() === '' ? NaN : Number(v);
export const words = v => String(v || '').split(';').filter(Boolean);
export const SUBJECTS = ['age10:reading','age10:mathematics','age10:science','age15:reading','age15:mathematics','age15:science'];
export function compatible(f, subject) {
  const [age,domain] = subject.split(':');
  const survey = age === 'age15' ? 'PISA' : domain === 'reading' ? 'PIRLS' : 'TIMSS';
  return f.age === age && (f.domain === domain || f.domain === 'all') && f.survey === survey;
}
export function splitKey(f) {
  let split = f.split || 'none';
  if (split === 'migration') split += f.figure_id.endsWith('_ANY_PARENT_ABROAD') ? '_any' : f.figure_id.endsWith('_BOTH_PARENTS_ABROAD') ? '_both' : '_generation';
  if (f.question === 'environment') return `peers:${split}:${f.peer_definition === 'whole_school' ? 'school' : 'class'}`;
  return split;
}
export function statisticKey(f) {
  if (f.view_mode === 'difference') return 'gap';
  if (f.question === 'environment') return f.outcome === 'peer_share_below_basic' ? 'below_basic' : f.outcome === 'high_proficiency_peer_exposure' ? 'high_proficiency' : 'peer_share';
  if (f.outcome.includes('mean') || f.outcome === 'mean_score') return 'mean_score';
  if (f.outcome === 'below_basic_by_ses') return 'below_basic';
  return f.outcome;
}
// Each rank direction is explicit and descriptive, never an implied causal
// or normative claim. Gap ranks use magnitude, retaining signed source values.
export const RANK_RULES = {
  mean_score:{direction:'descending',transform:'identity'},
  below_basic:{direction:'ascending',transform:'identity'},
  high_proficiency:{direction:'descending',transform:'identity'},
  p10:{direction:'descending',transform:'identity'},
  p50:{direction:'descending',transform:'identity'},
  p90:{direction:'descending',transform:'identity'},
  p90_minus_p10:{direction:'ascending',transform:'identity'},
  gap:{direction:'ascending',transform:'absolute'}
};
export function choices(figures, subject, split) {
  const fs = figures.filter(f => compatible(f, subject));
  return {splits:[...new Set(fs.map(splitKey))], statistics:[...new Set(fs.filter(f=>splitKey(f)===split).map(statisticKey))]};
}
export function selectFigure(figures, selection) {
  return figures.find(f => compatible(f, selection.subject) && splitKey(f) === selection.split && statisticKey(f) === selection.statistic) || null;
}
export function normalizeSelection(figures, selection) {
  const out = {...selection};
  if (!SUBJECTS.includes(out.subject)) out.subject = 'age10:reading';
  let options = choices(figures,out.subject,out.split);
  if (!options.splits.includes(out.split)) out.split = options.splits.includes('none') ? 'none' : options.splits[0];
  options = choices(figures,out.subject,out.split);
  if (!options.statistics.includes(out.statistic)) out.statistic = options.statistics.includes('mean_score') ? 'mean_score' : options.statistics[0];
  if (!RANK_RULES[out.statistic] || out.split?.startsWith('peers:')) out.rank = false;
  return out;
}
export function readSelection(search, defaults) {
  const q = new URLSearchParams(search), out = {country:'NLD',subject:'age10:reading',split:'none',statistic:'mean_score',rank:false,compare:true,uncertainty:true,other:'',...defaults};
  for (const k of ['country','subject','split','statistic','other']) if(q.has(k))out[k]=q.get(k);
  for (const k of ['rank','compare','uncertainty']) if(q.has(k))out[k]=q.get(k)==='1';
  out.members = q.has('members') ? [...new Set(q.get('members').split(',').filter(Boolean))].sort() : null;
  return out;
}
export function selectionSearch(state) {
  const q = new URLSearchParams();
  for(const k of ['country','subject','split','statistic'])q.set(k,state[k]);
  if(state.rank)q.set('rank','1');
  q.set('uncertainty',state.uncertainty?'1':'0');
  q.set('compare',state.compare?'1':'0');
  if(state.members !== null)q.set('members',state.members.join(','));
  if(state.other)q.set('other',state.other);
  return '?'+q;
}

// Display-only derivations from certified aggregates. Keep input values and
// hashes intact; never infer a unit from the magnitude of a result. Core tail
// shares are exported as proportions; SES tails and peer shares are already %.
export const DISPLAY_POLICY = {
  id:'FOCUS_NORMAL_95_AND_CORE_PERCENT_V2', confidence_level:0.95, critical_value:1.96,
  interval_method:'NORMAL_APPROXIMATION_FROM_VERIFIED_SE', focus_only:true,
  default_visible:true, rank_intervals:false, reference_intervals:false,
  core_proportion_figures:['TR_BELOW','TR_HIGH'], interval_bounds_clipped:false,
  reference_line:'CONNECT_ADJACENT_AVAILABLE_WAVES_WITH_MEMBERSHIP_NOTE',
  rank_membership_changes_break_line:true
};
export function presentationRows(rows,f,rank=false) {
  return rows.map(row=>{
    if(row.display_policy===DISPLAY_POLICY.id)return {...row};
    const r={...row},family=f.figure_id?.split('_age')[0];
    const scale=!rank&&f.unit==='percent'&&DISPLAY_POLICY.core_proportion_figures.includes(family)?100:1;
    if(scale!==1){
      r.input_estimate=number(r.estimate);r.estimate=r.input_estimate*scale;
      r.input_unit='proportion';r.display_scale=scale;
      for(const key of ['se','ci_low','ci_high'])if(Number.isFinite(number(r[key]))){r['input_'+key]=number(r[key]);r[key]=number(r[key])*scale;}
    }
    r.display_policy=DISPLAY_POLICY.id;
    if(rank||r.unit==='rank'||r.series_role!=='focus')return r;
    const estimate=number(r.estimate),se=number(r.se),low=number(r.ci_low),high=number(r.ci_high);
    if(!Number.isFinite(estimate))return r;
    if(number(r.ci_level)===.95&&Number.isFinite(low)&&Number.isFinite(high)&&low<=estimate&&estimate<=high){
      r.ci_level=.95;r.ci_method='SUPPLIED_95_INTERVAL';
    }else if(Number.isFinite(se)&&se>=0){
      r.ci_low=estimate-1.96*se;r.ci_high=estimate+1.96*se;
      r.ci_level=.95;r.ci_method=DISPLAY_POLICY.interval_method;r.ci_critical_value=1.96;
    }
    if(r.ci_method)r.ci_parent_result_hash=r.result_hash;
    return r;
  });
}
export function completeRows(rows, f) {
  const years=words(f.required_years), groups=words(f.expected_series), found=new Set();
  for (const r of rows) {
    const key=`${r.year}:${r.series_id}`;
    if (found.has(key) || !Number.isFinite(number(r.estimate)) || !years.includes(String(r.year)) || !groups.includes(r.series_id)) return false;
    found.add(key);
  }
  return years.length>0 && groups.length>0 && years.every(y=>groups.every(g=>found.has(`${y}:${g}`)));
}
// Partial focus data are displayable; comparison/rank completeness stays strict.
export function displayableRows(rows,f,availability) {
  if(!['VALIDATED','PARTIAL'].includes(availability?.display_state))return [];
  const years=words(f.required_years),groups=words(f.expected_series),seen=new Set();
  return rows.filter(r=>{
    const key=`${r.year}:${r.series_id}`;
    if(seen.has(key))throw new Error('DUPLICATE_DISPLAY_CELL');
    seen.add(key);
    return r.quality_status==='SCIENTIFICALLY_VALIDATED'&&Number.isFinite(number(r.estimate))&&years.includes(String(r.year))&&groups.includes(r.series_id);
  });
}
// Reference lines connect adjacent available survey waves; contributor changes
// remain explicit in notes/table/downloads. Missing waves, construct breaks and
// changing rank bases still break the line. This is display, not panel balancing.
export function breakBetween(previous,current,f) {
  if(!previous)return true;
  const years=words(f.required_years).map(Number).sort((a,b)=>a-b);
  return years.indexOf(+current.year)!==years.indexOf(+previous.year)+1 || current.series_break_before===true || current.series_break_before==='TRUE' ||
    (current.comparison_status==='PROVISIONAL' && current.series_role!=='comparator' && previous.comparison_membership_key!==current.comparison_membership_key);
}
export const provisional = contract => contract?.mode==='AVAILABLE_CASES_PROVISIONAL';
export function referenceStatus(contract, focus, members) {
  if (!contract || !(contract.status==='BALANCED_REFERENCE_AVAILABLE'||provisional(contract)&&contract.status==='PROVISIONAL_REFERENCE_AVAILABLE')) return {ok:false,reason:({
    AGE_DOMAIN_NOT_ADMITTED:'admission',NO_AVAILABLE_REFERENCE:'available_missing',
    NO_ELIGIBLE_REFERENCE:'coverage',FOCUS_CORE_INCOMPLETE:'focus_core',FOCUS_VIEW_INCOMPLETE:'focus_view'
  })[contract?.status]||'pending'};
  if(!members.length)return {ok:false,reason:'empty'};
  const eligible = list(contract.eligible_members);
  if(members.includes(focus) || new Set(members).size!==members.length || members.some(c=>!eligible.includes(c)))return {ok:false,reason:'ineligible'};
  return {ok:true};
}
export function referenceOption(contract,focus,country) {
  if(country===focus)return {allowed:false,reason:'focus'};
  if(provisional(contract))return {allowed:list(contract.eligible_members).includes(country),reason:list(contract.eligible_members).includes(country)?'provisional':'available_missing',detail:list(contract.eligibility).find(r=>r.country===country)};
  if(list(contract?.eligible_members).includes(country))return {allowed:true,reason:'eligible'};
  if(contract?.status==='FOCUS_CORE_INCOMPLETE')return {allowed:false,reason:'focus_core'};
  if(contract?.status==='FOCUS_VIEW_INCOMPLETE')return {allowed:false,reason:'focus_view'};
  const detail=list(contract?.eligibility).find(r=>r.country===country);
  if(contract?.status==='AGE_DOMAIN_NOT_ADMITTED'||['FAIL_SELECTED_COMBINATION_MIN3','FAIL_DASHBOARD_6x3'].includes(detail?.reason))return {allowed:false,reason:'admission'};
  if(detail?.missing_cells>0)return {allowed:false,reason:'missing',detail};
  return {allowed:false,reason:'pending'};
}
// A selected member must have every year × series. No yearwise reweighting,
// stale precomputed average, silently dropped member, or averaged uncertainty.
// The certified focus contract defines the period. Extra years of a reference
// country are irrelevant; none of the required focus years/groups may disappear.
export function focusFigure(figure,contract) {
  if(!figure)return null;
  if(contract && Object.hasOwn(contract,'required_years'))return {...figure,required_years:contract.required_years};
  return {...figure};
}
function requiredReferenceRows(payload,f) {
  const years=words(f.required_years),groups=words(f.expected_series);
  return list(payload?.records).filter(r=>r.figure_id===f.figure_id && r.series_role!=='comparator' && years.includes(String(r.year)) && groups.includes(r.series_id));
}
export function referenceRows(f, focus, members, payloads, contract) {
  if(provisional(contract))return provisionalReferenceRows(f,focus,members,payloads,contract);
  const status=referenceStatus(contract,focus,members);
  if(!status.ok)throw new Error('REFERENCE_'+status.reason.toUpperCase());
  const tables = members.map(c=>{
    const rows=requiredReferenceRows(payloads[c],f);
    if(!completeRows(rows,f))throw new Error('REFERENCE_INCOMPLETE_'+c);
    return new Map(rows.map(r=>[`${r.year}:${r.series_id}`,r]));
  });
  return words(f.required_years).flatMap(year=>words(f.expected_series).map(group=>{
    const parents=tables.map(t=>t.get(`${year}:${group}`));
    return {figure_id:f.figure_id,year:+year,series_id:'reference:'+group,parent_series_id:group,series_role:'comparator',estimate:parents.reduce((s,r)=>s+number(r.estimate),0)/members.length,
      comparator_n:members.length,members:[...members],unit:f.unit,method_id:'EQUAL_COUNTRY_WEIGHT_LEAVE_FOCUS_OUT_V1',
      source_id:parents.map(r=>r.source_id).join(';'),parent_result_hashes:parents.map(r=>r.result_hash),
      reference_contract_hash:contract.evidence_sha256};
  }));
}
export function rankRows(f, statistic, focus, members, payloads, contract, other='') {
  if(provisional(contract))return provisionalRankRows(f,statistic,focus,members,payloads,contract,other);
  referenceRows(f,focus,members,payloads,contract); // validates the full panel
  if(other && !members.includes(other))throw new Error('RANK_OTHER_NOT_IN_REFERENCE');
  const rule=RANK_RULES[statistic];if(!rule)throw new Error('RANK_RULE_UNDEFINED');
  const universe=[focus,...members], tables=new Map();
  for(const c of universe){const rows=requiredReferenceRows(payloads[c],f);if(!completeRows(rows,f))throw new Error('RANK_INCOMPLETE_'+c);tables.set(c,new Map(rows.map(r=>[`${r.year}:${r.series_id}`,r])));}
  const transform=v=>rule.transform==='absolute'?Math.abs(v):v;
  return [focus,...(other?[other]:[])].flatMap(country=>words(f.required_years).flatMap(year=>words(f.expected_series).map(group=>{
    const key=`${year}:${group}`, row=tables.get(country).get(key), value=transform(number(row.estimate));
    const parents=universe.map(c=>tables.get(c).get(key));
    const values=parents.map(r=>transform(number(r.estimate)));
    const better=values.filter(v=>rule.direction==='descending'?v>value:v<value).length;
    const tied=values.filter(v=>v===value).length;
    return {...row,series_id:country+':'+group,parent_series_id:group,country_id:'iso3:'+country,series_role:country===focus?'focus':'other',
      source_estimate:row.estimate,estimate:1+better+(tied-1)/2,se:null,ci_low:null,ci_high:null,unit:'rank',comparator_n:members.length,
      members:[...members],method_id:'POINT_RANK_AVERAGE_TIES_V1',rank_direction:rule.direction,rank_transform:rule.transform,
      parent_result_hashes:parents.map(r=>r.result_hash),reference_contract_hash:contract.evidence_sha256};
  })));
}

// User-authorised temporary mode. Keep the full x-axis; each observed point
// carries its actual contributors, exclusions and hashes. No zero fill or CI.
function availablePointSets(f,focus,members,payloads,contract) {
  const status=referenceStatus(contract,focus,members);
  if(!status.ok)throw new Error('REFERENCE_'+status.reason.toUpperCase());
  const tables=new Map(),years=words(f.required_years),groups=words(f.expected_series);
  for(const c of [focus,...members]) {
    const table=new Map();
    for(const r of list(payloads[c]?.records)) {
      if(r.figure_id!==f.figure_id||r.series_role==='comparator'||r.quality_status!=='SCIENTIFICALLY_VALIDATED'||!Number.isFinite(number(r.estimate))||!years.includes(String(r.year))||!groups.includes(r.series_id))continue;
      const key=`${r.year}:${r.series_id}`;
      if(table.has(key))throw new Error('DUPLICATE_AVAILABLE_CELL');
      table.set(key,r);
    }
    tables.set(c,table);
  }
  return years.flatMap(year=>groups.map(group=>{
    const key=`${year}:${group}`,main=tables.get(focus).get(key),contributors=[],excluded=[];
    for(const country of members){const row=tables.get(country).get(key);
      // A temporary coverage waiver does not relabel a known pooled category.
      const differs=f.split==='gender'&&main&&row&&/other/i.test(row.series_label_en||'')!==/other/i.test(main.series_label_en||'');
      if(!row||differs)excluded.push({country,reason:differs?'KNOWN_DEFINITION_DIFFERENCE':'POINT_NOT_AVAILABLE'});
      else contributors.push({country,row});
    }
    return {year:+year,group,main,contributors,excluded};
  }));
}
function provisionalMetadata(point,members,contract) {
  const actual=point.contributors.map(x=>x.country);
  return {comparison_status:'PROVISIONAL',comparator_n:actual.length,members:actual,
    selected_members:[...members],excluded_members:point.excluded.map(x=>x.country),exclusion_reasons:point.excluded,
    comparison_membership_key:[...actual].sort().join(';'),reference_policy_sha256:contract.reference_policy_sha256,
    reference_contract_hash:contract.evidence_sha256,parent_result_hashes:point.contributors.map(x=>x.row.result_hash)};
}
function provisionalReferenceRows(f,focus,members,payloads,contract) {
  return availablePointSets(f,focus,members,payloads,contract).filter(p=>p.contributors.length).map(p=>({
    figure_id:f.figure_id,year:p.year,series_id:'reference:'+p.group,parent_series_id:p.group,series_role:'comparator',
    estimate:p.contributors.reduce((sum,x)=>sum+number(x.row.estimate),0)/p.contributors.length,
    unit:f.unit,method_id:'EQUAL_AVAILABLE_COUNTRY_WEIGHT_TEMPORARY_V1',
    series_label_nl:p.main?.series_label_nl,series_label_en:p.main?.series_label_en,
    source_id:p.contributors.map(x=>x.row.source_id).join(';'),...provisionalMetadata(p,members,contract)}));
}
function provisionalRankRows(f,statistic,focus,members,payloads,contract,other) {
  if(other&&!members.includes(other))throw new Error('RANK_OTHER_NOT_IN_REFERENCE');
  const rule=RANK_RULES[statistic];if(!rule)throw new Error('RANK_RULE_UNDEFINED');
  const transform=v=>rule.transform==='absolute'?Math.abs(v):v;
  return availablePointSets(f,focus,members,payloads,contract).filter(p=>p.main&&p.contributors.length).flatMap(p=>{
    const universe=[{country:focus,row:p.main},...p.contributors],values=universe.map(x=>transform(number(x.row.estimate)));
    return universe.filter(x=>x.country===focus||x.country===other).map(({country,row})=>{
      const value=transform(number(row.estimate)),better=values.filter(v=>rule.direction==='descending'?v>value:v<value).length,tied=values.filter(v=>v===value).length;
      return {...row,series_id:country+':'+p.group,parent_series_id:p.group,country_id:'iso3:'+country,series_role:country===focus?'focus':'other',
        source_estimate:row.estimate,estimate:1+better+(tied-1)/2,se:null,ci_low:null,ci_high:null,unit:'rank',
        method_id:'AVAILABLE_COUNTRY_POINT_RANK_TEMPORARY_V1',rank_direction:rule.direction,rank_transform:rule.transform,
        ...provisionalMetadata(p,members,contract),rank_basis_n:universe.length,rank_basis_members:universe.map(x=>x.country),
        parent_result_hashes:universe.map(x=>x.row.result_hash)};
    });
  });
}
