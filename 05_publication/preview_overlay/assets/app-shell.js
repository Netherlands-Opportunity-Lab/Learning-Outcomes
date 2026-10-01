'use strict';
import {DEFAULTS,parseRoute,makeRoute,stateFromSearch,stateSearch,localeTarget} from './router.mjs';

const BASE=document.documentElement.dataset.base||'';
const state={...DEFAULTS,dict:null,countries:[],figures:[],methods:{},availability:[],records:[],routeValid:true,currentFigure:null,currentAvailability:null,isLanding:false};
const $=q=>document.querySelector(q), $$=q=>[...document.querySelectorAll(q)];
const get=(o,path)=>path.split('.').reduce((a,k)=>a?.[k],o);
const tr=key=>get(state.dict,key)??key;
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const route=(locale=state.locale,country=state.country,question=state.question)=>makeRoute(BASE,locale,country,question);

async function loadJson(p){const r=await fetch(`${BASE}${p}`);if(!r.ok)throw new Error(`${r.status} ${p}`);return r.json();}
function countryName(code){const c=state.countries.find(x=>x.code===code);return c?(state.locale==='nl'?c.nl:c.en):code;}
function figureLabel(f){return state.locale==='nl'?f.label_nl:f.label_en;}
function measureLabel(f){return state.locale==='nl'?f.measure_label_nl:f.measure_label_en;}
function figureSubtitle(f){return state.locale==='nl'?f.subtitle_nl:f.subtitle_en;}
function ageLabel(){return tr(`ages.${state.age}`);}
function domainLabel(){return tr(`domains.${state.domain}`);}

function applyTranslations(){
  document.documentElement.lang=state.locale;
  $$('[data-i18n]').forEach(el=>{const v=tr(el.dataset.i18n);if(v!==undefined)el.textContent=v;});
  $('#localeSelect').value=state.locale;
  $('#localeLabel').textContent=tr('a11y.language');
  document.title=state.isLanding?'International Learning Outcomes Explorer':`${tr(`questions.${state.question}.title`)} · International Learning Outcomes Explorer`;
  $('.visual-kicker').textContent=state.isLanding?tr('landing.example'):tr('landing.current');
}

function populateCountries(){
  const rows=[...state.countries].sort((a,b)=>countryName(a.code).localeCompare(countryName(b.code),state.locale==='nl'?'nl':'en'));
  if(!state.countries.some(c=>c.code===state.country))state.country='NLD';
  const sel=$('#countrySelect');
  sel.innerHTML=rows.map(c=>`<option value="${c.code}">${esc(countryName(c.code))}</option>`).join('');
  sel.value=state.country;
}

function applyPressed(container,value){$$(`#${container} button`).forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.value===value)));}
function applyQuestionPressed(){$$('#questionGrid .question-choice').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.question===state.question)));}
function setSelect(sel,items,value){sel.innerHTML=items.map(([v,n])=>`<option value="${esc(v)}">${esc(n)}</option>`).join('');if(items.some(x=>x[0]===value))sel.value=value;else if(items.length){sel.value=items[0][0];return items[0][0];}return value;}
function normalizeBaseState(){if(!['age10','age15'].includes(state.age))state.age=DEFAULTS.age;if(!['reading','mathematics','science'].includes(state.domain))state.domain=DEFAULTS.domain;}
function contextFigures(){return state.figures.filter(f=>f.question===state.question&&f.age===state.age&&(f.domain===state.domain||f.domain==='all'));}

function normalizeFigureState(){
  let fs=contextFigures();
  if(!fs.length){state.currentFigure=null;return;}
  if(state.question==='gaps'){
    const splits=[...new Set(fs.map(f=>f.split))];if(!splits.includes(state.split))state.split=splits[0];
    fs=fs.filter(f=>f.split===state.split);
    const modes=[...new Set(fs.map(f=>f.view_mode))];if(!modes.includes(state.view_mode))state.view_mode=modes[0];
    fs=fs.filter(f=>f.view_mode===state.view_mode);
  }else{state.split='none';state.view_mode='levels';}
  if(state.question==='environment'){
    const peers=[...new Set(fs.map(f=>f.peer_definition))];if(!peers.includes(state.peer_definition))state.peer_definition=peers[0];
    fs=fs.filter(f=>f.peer_definition===state.peer_definition);
  }
  const outcomes=[...new Set(fs.map(f=>f.outcome))];
  if(!outcomes.includes(state.outcome))state.outcome=outcomes[0];
  state.currentFigure=fs.find(f=>f.outcome===state.outcome)||fs[0];
}

function updateStepNumbers(){
  $('#ageGroup').dataset.step='3';$('#domainGroup').dataset.step='4';
  if(state.question==='gaps'){$('#splitGroup').dataset.step='5';$('#viewModeGroup').dataset.step='6';$('#outcomeGroup').dataset.step='7';}
  else if(state.question==='environment'){$('#peerGroup').dataset.step='5';$('#outcomeGroup').dataset.step='6';}
  else{$('#outcomeGroup').dataset.step='5';}
}

function renderContextControls(){
  const fs=contextFigures(),isGaps=state.question==='gaps',isEnv=state.question==='environment';
  $('#splitGroup').hidden=!isGaps;$('#viewModeGroup').hidden=!isGaps;$('#peerGroup').hidden=!isEnv;
  if(isGaps){const splits=[...new Set(fs.map(f=>f.split))];state.split=setSelect($('#splitSelect'),splits.map(s=>[s,tr(`splits.${s}`)]),state.split);applyPressed('viewModeControls',state.view_mode);}
  if(isEnv)applyPressed('peerControls',state.peer_definition);
  normalizeFigureState();
  let candidates=contextFigures();
  if(isGaps)candidates=candidates.filter(f=>f.split===state.split&&f.view_mode===state.view_mode);
  if(isEnv)candidates=candidates.filter(f=>f.peer_definition===state.peer_definition);
  const unique=[],seen=new Set();
  for(const f of candidates){if(!seen.has(f.outcome)){seen.add(f.outcome);unique.push([f.outcome,figureLabel(f)]);}}
  state.outcome=setSelect($('#outcomeSelect'),unique,state.outcome);
  normalizeFigureState();
  $('#domainGroup').hidden=Boolean(isEnv&&state.currentFigure&&state.currentFigure.domain==='all');
  applyPressed('ageControls',state.age);applyPressed('domainControls',state.domain);applyQuestionPressed();updateStepNumbers();
}

function availabilityFor(fid){return state.availability.find(x=>x.figure_id===fid)||null;}
function recordsFor(fid){return state.records.filter(r=>r.figure_id===fid);}
function statusText(a){return a?tr(`status.${a.display_state}`):tr('status.PLACEHOLDER');}
function placeholderHtml(a){const st=a?.display_state||'PLACEHOLDER';const reason=a?(state.locale==='nl'?a.reason_nl:a.reason_en):tr('status.bindingPending');return `<div class="status-placeholder status-${esc(st.toLowerCase())}"><div class="placeholder-mark" aria-hidden="true"></div><h3>${esc(statusText(a))}</h3><p>${esc(reason)}</p></div>`;}

function seriesLabel(r){
  const raw=r.series_label_nl&&state.locale==='nl'?r.series_label_nl:r.series_label_en&&state.locale==='en'?r.series_label_en:(r.series_role==='comparator'?'comparator':r.split_group||r.series_id||'total');
  if(raw==='total'&&seriesRole(r)!=='comparator')return countryName(state.country);
  const translated=tr(`seriesLabels.${raw}`);return translated===`seriesLabels.${raw}`?raw:translated;
}
function tableHtml(rows){if(!rows.length)return '';const nf=new Intl.NumberFormat(state.locale==='nl'?'nl-NL':'en-GB',{maximumFractionDigits:2});return `<details class="data-details"><summary>${esc(tr('figure.dataTable'))}</summary><div class="data-table-wrap"><table><thead><tr><th>${esc(tr('figure.year'))}</th><th>${esc(tr('figure.group'))}</th><th>${esc(tr('figure.estimate'))}</th><th>${esc(tr('figure.confidenceInterval'))}</th></tr></thead><tbody>${rows.map(r=>`<tr><td>${esc(r.year??'')}</td><td>${esc(seriesLabel(r))}</td><td>${Number.isFinite(+r.estimate)?nf.format(+r.estimate):'—'}</td><td>${Number.isFinite(+r.ci_low)&&Number.isFinite(+r.ci_high)?`${nf.format(+r.ci_low)} – ${nf.format(+r.ci_high)}`:'—'}</td></tr>`).join('')}</tbody></table></div></details>`;}
function seriesKey(r){return String(r.series_id||r.series_role||r.split_group||'total');}
function seriesRole(r){const k=seriesKey(r).toLowerCase();return r.series_role||(['comparator','comparison','comparison_group'].includes(k)?'comparator':'focus');}
function seriesStyle(key,role,index){if(role==='comparator')return {stroke:'#A7A7A7',dash:'7 5'};const semantic={q1:'#9A6D00',q4:'#6B5A8E',girl:'#6B5A8E',boy:'#315D8A',native:'#315D8A',first_generation:'#5EA6A7',second_generation:'#82A85B',third_generation:'#6B5A8E',self_below_high:'#9A6D00',self_high:'#315D8A'};const palette=['#315D8A','#6B5A8E','#9A6D00','#5EA6A7','#657A47'];return {stroke:semantic[key]||palette[index%palette.length],dash:'none'};}
function fmtNumber(v){return Number.isFinite(+v)?new Intl.NumberFormat(state.locale==='nl'?'nl-NL':'en-GB',{maximumFractionDigits:2}).format(+v):'—';}
function chartTooltipText(r){const ci=Number.isFinite(+r.ci_low)&&Number.isFinite(+r.ci_high)?`${fmtNumber(r.ci_low)} – ${fmtNumber(r.ci_high)}`:'—';return `${seriesLabel(r)} · ${tr('figure.tooltipYear')}: ${r.year} · ${tr('figure.tooltipEstimate')}: ${fmtNumber(r.estimate)} · ${tr('figure.tooltipCI')}: ${ci}`;}

function chartHtml(rows,f){
  const usable=rows.filter(r=>Number.isFinite(+r.estimate)&&Number.isFinite(+r.year));
  if(!usable.length)return tableHtml(rows);
  const mobile=window.innerWidth<=430,tablet=window.innerWidth<=760;
  const W=mobile?360:(tablet?720:940),H=mobile?340:(tablet?390:430),pad=mobile?{l:44,r:110,t:24,b:48}:(tablet?{l:58,r:125,t:26,b:52}:{l:62,r:140,t:28,b:54});
  const years=[...new Set(usable.map(r=>+r.year))].sort((a,b)=>a-b),unit=f.unit||usable[0]?.unit||'';
  let vals=usable.flatMap(r=>[r.estimate,r.ci_low,r.ci_high].filter(v=>Number.isFinite(+v)).map(Number)),lo=Math.min(...vals),hi=Math.max(...vals);
  if(unit==='percent'){lo=0;hi=100;}else if(unit==='rank'){lo=Math.max(1,Math.floor(lo));hi=Math.max(lo+1,Math.ceil(hi));}else{const gap=Math.max(hi-lo,10);lo-=gap*.12;hi+=gap*.12;}
  const minY=lo,maxY=hi,x0=years[0],x1=years.at(-1),sx=y=>pad.l+(y-x0)/(x1-x0||1)*(W-pad.l-pad.r),sy=v=>{const q=(v-minY)/(maxY-minY||1);return unit==='rank'?pad.t+q*(H-pad.t-pad.b):pad.t+(1-q)*(H-pad.t-pad.b);};
  const groups=new Map();for(const r of usable){const k=seriesKey(r);if(!groups.has(k))groups.set(k,[]);groups.get(k).push(r);}for(const a of groups.values())a.sort((a,b)=>+a.year-+b.year);
  let body='',idx=0;const ticks=4;
  for(let i=0;i<ticks;i++){const v=minY+(maxY-minY)*i/(ticks-1),y=sy(v);body+=`<line class="grid-line" x1="${pad.l}" x2="${W-pad.r}" y1="${y}" y2="${y}"></line><text class="axis-label" x="${pad.l-10}" y="${y+4}" text-anchor="end">${esc(fmtNumber(v))}</text>`;}
  for(const y of years)body+=`<text class="axis-label" x="${sx(y)}" y="${H-18}" text-anchor="middle">${y}</text>`;
  for(const [k,a] of groups){
    const role=seriesRole(a[0]),sty=seriesStyle(k,role,idx++);let d='',prev=null;
    for(const r of a){const x=sx(+r.year),y=sy(+r.estimate),br=String(r.series_break_before||'').toLowerCase()==='true'||r.series_break_before===1;if(prev&&!br)d+=` L ${x.toFixed(2)} ${y.toFixed(2)}`;else d+=`${d?' M':'M'} ${x.toFixed(2)} ${y.toFixed(2)}`;prev=r;}
    body+=`<path class="series-line" d="${d}" stroke="${sty.stroke}" ${sty.dash!=='none'?`stroke-dasharray="${sty.dash}"`:''}></path>`;
    for(const r of a){const x=sx(+r.year),y=sy(+r.estimate),tip=chartTooltipText(r);if(Number.isFinite(+r.ci_low)&&Number.isFinite(+r.ci_high))body+=`<line class="ci-line" x1="${x}" x2="${x}" y1="${sy(+r.ci_low)}" y2="${sy(+r.ci_high)}" stroke="${sty.stroke}"></line>`;body+=`<circle class="data-point" tabindex="0" role="img" aria-label="${esc(tip)}" data-tooltip="${esc(tip)}" cx="${x}" cy="${y}" r="5" fill="${sty.stroke}"></circle>`;}
    const last=a.at(-1);if(last)body+=`<text class="direct-label" x="${Math.min(W-8,sx(+last.year)+10)}" y="${sy(+last.estimate)+4}" fill="${sty.stroke}">${esc(seriesLabel(last))}</text>`;
  }
  const aria=tr('figure.chartAria').replace('{title}',figureLabel(f));
  return `<div class="chart-wrap"><svg class="time-chart" viewBox="0 0 ${W} ${H}" role="img" aria-label="${esc(aria)}">${body}</svg><div class="chart-tooltip" id="chartTooltip" role="status" aria-live="polite" hidden></div></div>${tableHtml(rows)}`;
}

function bindChartTooltip(){const tt=$('#chartTooltip');if(!tt)return;const show=(el,e)=>{tt.textContent=el.dataset.tooltip||'';tt.hidden=false;const wrap=el.closest('.chart-wrap'),box=wrap.getBoundingClientRect();let x=(e?.clientX??box.left+box.width*.5)-box.left+12,y=(e?.clientY??box.top+40)-box.top+12;tt.style.left=`${Math.max(8,Math.min(x,box.width-240))}px`;tt.style.top=`${Math.max(8,y)}px`;};const hide=()=>{tt.hidden=true;};$$('.data-point').forEach(el=>{el.addEventListener('pointerenter',e=>show(el,e));el.addEventListener('pointerleave',hide);el.addEventListener('focus',e=>show(el,e));el.addEventListener('blur',hide);el.addEventListener('pointerdown',e=>{e.preventDefault();show(el,e);});});}

function renderFigure(){
  const f=state.currentFigure;if(!f)return;
  const a=availabilityFor(f.figure_id);state.currentAvailability=a;const rows=recordsFor(f.figure_id);
  $('#figureQuestion').textContent=tr(`questions.${state.question}.routeTitle`);
  const years=[...new Set(rows.map(r=>+r.year).filter(Number.isFinite))].sort((a,b)=>a-b),yearText=years.length?` · ${f.survey} ${years[0]}–${years.at(-1)}`:` · ${f.survey}`;
  $('#figureContext').textContent=`${countryName(state.country)} · ${ageLabel()} · ${domainLabel()}${yearText}`;
  $('#measureLabel').textContent=measureLabel(f);$('#figureHeading').textContent=figureLabel(f);$('#figureSubtitle').textContent=figureSubtitle(f);
  const badge=$('#figureStatus');badge.textContent=statusText(a);badge.dataset.state=(a?.display_state||'PLACEHOLDER').toLowerCase();
  const usable=a?.display_state==='VALIDATED'&&rows.length>0;
  $('#chartStage').innerHTML=usable?chartHtml(rows,f):placeholderHtml(a);if(usable)bindChartTooltip();
  $('#downloadData').disabled=!usable;$('#downloadCountry').disabled=!state.records.length;
  const m=state.methods[f.method_id];$('#methodsCopy').textContent=m?(state.locale==='nl'?m.nl:m.en):tr('methods.copy');$('#methodDefinition').textContent=figureLabel(f);$('#methodAvailability').textContent=a?(state.locale==='nl'?a.reason_nl:a.reason_en):tr('status.bindingPending');
  const ses=Boolean(f.ses_definition_id);$('#sesDefinitionRow').hidden=!ses;$('#coverageRow').hidden=!ses;if(ses)$('#methodSesDefinition').textContent=f.ses_definition_id==='PISA_ESCS_TREND_COMPARABLE_COMMON42'?(state.locale==='nl'?'SES – trendvergelijkbaar':'SES – trend-comparable'):f.ses_definition_id;
  const ns=[...new Set(rows.map(r=>+r.comparator_n).filter(Number.isFinite))];$('#comparatorRow').hidden=!usable||!ns.length;$('#methodComparator').textContent=ns.length?tr('figure.comparatorN').replace('{n}',ns.join('–')):'';
}

function render(){
  normalizeBaseState();applyTranslations();populateCountries();$('#homeLink').href=route(state.locale,state.country,null);
  if(state.routeValid===false){$('#hero').hidden=true;$('#visualFirst').hidden=true;$('#guidedBuilder').hidden=true;$('#invalidRoute').hidden=false;return;}
  $('#hero').hidden=false;$('#visualFirst').hidden=false;$('#guidedBuilder').hidden=false;$('#invalidRoute').hidden=true;
  normalizeFigureState();renderContextControls();renderFigure();
}

function currentShareUrl(){
  const path=route(state.locale,state.country,state.question),query=stateSearch(state);return new URL(path+query,location.href).href;
}
function syncUrl(mode='replace'){
  const path=state.isLanding?route(state.locale,state.country,null):route(state.locale,state.country,state.question),query=state.isLanding?'':stateSearch(state),url=path+query+location.hash;
  history[mode==='push'?'pushState':'replaceState'](null,'',url);
}
function ensureRouted(){if(state.isLanding){state.isLanding=false;syncUrl('push');}else syncUrl('replace');}
function maybeScrollToFigure(){const reduce=window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;$('#visualFirst').scrollIntoView({behavior:reduce?'auto':'smooth',block:'start'});}
async function changeCountry(code){if(!state.countries.some(c=>c.code===code))return;state.country=code;state.isLanding=false;await loadCountryPayload();normalizeFigureState();syncUrl('push');render();maybeScrollToFigure();}
function switchLocale(locale){location.assign(localeTarget({base:BASE,locale,country:state.country,question:state.isLanding?null:state.question,search:state.isLanding?'':stateSearch(state),hash:location.hash}));}

const CSV_FIELDS=['country_id','country_name','survey','year','age_group','domain','outcome','split_dimension','split_group','peer_definition','estimate','se','ci_low','ci_high','unit','threshold_id','definition_id','ses_definition_id','comparator_n','method_id','source_id','quality_status','availability_status'];
function downloadCsv(rows,filename){const q=v=>'"'+String(v??'').replaceAll('"','""')+'"';const body=[CSV_FIELDS.join(','),...rows.map(r=>CSV_FIELDS.map(k=>q(k==='country_name'?countryName(state.country):r[k])).join(','))].join('\r\n');const u=URL.createObjectURL(new Blob(['\uFEFF'+body],{type:'text/csv;charset=utf-8'}));const a=document.createElement('a');a.href=u;a.download=filename;a.click();setTimeout(()=>URL.revokeObjectURL(u),1000);}
async function loadCountryPayload(){const [a,d]=await Promise.all([loadJson(`data/availability/${state.country}.json`),loadJson(`data/countries/${state.country}.json`)]);state.availability=a.figures||[];state.records=d.records||[];}

async function init(){
  const r=parseRoute(location.pathname);Object.assign(state,r);state.routeValid=r.valid;state.isLanding=Boolean(r.valid&&!r.question);
  Object.assign(state,stateFromSearch(location.search,state));
  if(state.isLanding&&!location.search){state.question='trends';state.age='age15';state.domain='reading';state.outcome='mean_score';state.split='none';state.view_mode='levels';}
  else if(state.isLanding){state.question='trends';}
  const [dict,countries,fr,mr]=await Promise.all([loadJson(`locales/${state.locale}.json`),loadJson('data/common42.json'),loadJson('data/figure_registry.json'),loadJson('data/method_registry.json')]);
  state.dict=dict;state.countries=countries;state.figures=fr.figures||[];state.methods=mr.methods||{};if(!state.countries.some(c=>c.code===state.country))state.country='NLD';
  await loadCountryPayload();render();

  $('#countrySelect').addEventListener('change',e=>changeCountry(e.target.value));
  $('#localeSelect').addEventListener('change',e=>switchLocale(e.target.value));
  $$('#questionGrid .question-choice').forEach(b=>b.addEventListener('click',()=>{state.question=b.dataset.question;state.isLanding=false;state.outcome='';state.split='none';state.view_mode='levels';normalizeFigureState();syncUrl('push');render();maybeScrollToFigure();}));
  for(const [id,key] of [['ageControls','age'],['domainControls','domain'],['viewModeControls','view_mode'],['peerControls','peer_definition']])$$(`#${id} button`).forEach(b=>b.addEventListener('click',()=>{state[key]=b.dataset.value;if(key==='age'||key==='domain')state.outcome='';normalizeFigureState();ensureRouted();render();}));
  $('#splitSelect').addEventListener('change',e=>{state.split=e.target.value;state.outcome='';normalizeFigureState();ensureRouted();render();});
  $('#outcomeSelect').addEventListener('change',e=>{state.outcome=e.target.value;normalizeFigureState();ensureRouted();render();});
  $('#methodsButton').addEventListener('click',()=>{const p=$('#methodsPanel'),open=p.hidden;p.hidden=!open;$('#methodsButton').setAttribute('aria-expanded',String(open));});
  $('#copyLink').addEventListener('click',async()=>{const url=currentShareUrl();try{await navigator.clipboard.writeText(url);$('#copyLink').textContent=tr('actions.copied');}catch{$('#copyLink').textContent=url;}});
  $('#downloadData').addEventListener('click',()=>{const f=state.currentFigure;if(f)downloadCsv(recordsFor(f.figure_id),`learning_outcomes_${state.country}_${f.figure_id}.csv`);});
  $('#downloadCountry').addEventListener('click',()=>downloadCsv(state.records,`learning_outcomes_${state.country}_visible.csv`));
  window.addEventListener('popstate',()=>location.reload());
  window.__learningOutcomesShell={state,route,parseRoute,makeRoute,stateFromSearch,localeTarget,contextFigures,availabilityFor,recordsFor,currentShareUrl};
}

init().catch(err=>{console.error(err);document.body.innerHTML=`<main style="padding:2rem;font-family:Arial,sans-serif"><h1>Dashboard shell error</h1><pre>${esc(err.message)}</pre></main>`;});
