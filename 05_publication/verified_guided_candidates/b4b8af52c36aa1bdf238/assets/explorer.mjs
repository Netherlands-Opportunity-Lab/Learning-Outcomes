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
  const q = new URLSearchParams(search), out = {country:'NLD',subject:'age10:reading',split:'none',statistic:'mean_score',rank:false,compare:true,other:'',...defaults};
  for (const k of ['country','subject','split','statistic','other']) if(q.has(k))out[k]=q.get(k);
  for (const k of ['rank','compare']) if(q.has(k))out[k]=q.get(k)==='1';
  out.members = q.has('members') ? [...new Set(q.get('members').split(',').filter(Boolean))].sort() : null;
  return out;
}
export function selectionSearch(state) {
  const q = new URLSearchParams();
  for(const k of ['country','subject','split','statistic'])q.set(k,state[k]);
  if(state.rank)q.set('rank','1');
  q.set('compare',state.compare?'1':'0');
  if(state.members !== null)q.set('members',state.members.join(','));
  if(state.other)q.set('other',state.other);
  return '?'+q;
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
export function breakBetween(previous,current,f) {
  if(!previous)return true;
  const years=words(f.required_years).map(Number).sort((a,b)=>a-b);
  return years.indexOf(+current.year)!==years.indexOf(+previous.year)+1 || current.series_break_before===true || current.series_break_before==='TRUE';
}
export function referenceStatus(contract, focus, members) {
  if (!contract || contract.status !== 'BALANCED_REFERENCE_AVAILABLE') return {ok:false,reason:({
    NO_ELIGIBLE_REFERENCE:'coverage',FOCUS_CORE_INCOMPLETE:'focus_core',FOCUS_VIEW_INCOMPLETE:'focus_view'
  })[contract?.status]||'pending'};
  if(!members.length)return {ok:false,reason:'empty'};
  const eligible = list(contract.eligible_members);
  if(members.includes(focus) || new Set(members).size!==members.length || members.some(c=>!eligible.includes(c)))return {ok:false,reason:'ineligible'};
  return {ok:true};
}
export function referenceOption(contract,focus,country) {
  if(country===focus)return {allowed:false,reason:'focus'};
  if(list(contract?.eligible_members).includes(country))return {allowed:true,reason:'eligible'};
  if(contract?.status==='FOCUS_CORE_INCOMPLETE')return {allowed:false,reason:'focus_core'};
  if(contract?.status==='FOCUS_VIEW_INCOMPLETE')return {allowed:false,reason:'focus_view'};
  const detail=list(contract?.eligibility).find(r=>r.country===country);
  if(detail?.reason==='FAIL_DASHBOARD_6x3')return {allowed:false,reason:'admission'};
  if(detail?.missing_cells>0)return {allowed:false,reason:'missing',detail};
  return {allowed:false,reason:'pending'};
}
// A selected member must have every year × series. No yearwise reweighting,
// stale precomputed average, silently dropped member, or averaged uncertainty.
export function referenceRows(f, focus, members, payloads, contract) {
  const status=referenceStatus(contract,focus,members);
  if(!status.ok)throw new Error('REFERENCE_'+status.reason.toUpperCase());
  const tables = members.map(c=>{
    const rows=list(payloads[c]?.records).filter(r=>r.figure_id===f.figure_id && r.series_role!=='comparator');
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
  referenceRows(f,focus,members,payloads,contract); // validates the full panel
  if(other && !members.includes(other))throw new Error('RANK_OTHER_NOT_IN_REFERENCE');
  const rule=RANK_RULES[statistic];if(!rule)throw new Error('RANK_RULE_UNDEFINED');
  const universe=[focus,...members], tables=new Map();
  for(const c of universe){const rows=list(payloads[c]?.records).filter(r=>r.figure_id===f.figure_id&&r.series_role!=='comparator');if(!completeRows(rows,f))throw new Error('RANK_INCOMPLETE_'+c);tables.set(c,new Map(rows.map(r=>[`${r.year}:${r.series_id}`,r])));}
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
