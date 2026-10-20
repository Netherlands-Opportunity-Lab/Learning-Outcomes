// Reconstruct presentation/paper figures from the certified dashboard aggregate
// contract. This is a product build, never an estimator or a country selector.
import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';

const [repoArg,candidateArg,outArg]=process.argv.slice(2);
if(!repoArg||!candidateArg||!outArg)throw Error('Usage: node build_research_data.mjs repo candidate-directory output-directory');
const repo=path.resolve(repoArg),site=path.resolve(candidateArg),out=path.resolve(outArg);
const read=async p=>JSON.parse(await fs.readFile(p,'utf8'));
const sha=async p=>createHash('sha256').update(await fs.readFile(p)).digest('hex');
const phasePath=path.join(repo,'06_pipeline/review_20261013/release47_20261020/RELEASE_PHASE_DECISION.json');
const phase=await read(phasePath);
const E=await import(pathToFileURL(path.join(site,'assets/explorer.mjs')).href);
const policyPath=path.join(site,'data/reference_policy.json');
const policy=await read(policyPath).catch(error=>{if(error.code==='ENOENT')return null;throw error;});
if(policy&&(policy.mode==='AVAILABLE_CASES_PROVISIONAL'||policy.full_period_balance_required===false))
  throw Error('Research products require the certified, strict reference policy');
const assets=await read(path.join(site,'BUILD_SHA256_MANIFEST.json'));
for(const f of assets){
  const p=path.resolve(site,f.path);
  if(!p.startsWith(site+path.sep)||await sha(p)!==f.sha256)throw Error('Changed candidate asset '+f.path);
}
const countries=await read(path.join(site,'data/common42.json'));
if(countries.length!==47)throw Error('Expected explicit current47 product selection');
const countryTranslations={};
for(const lang of ['nl','en'])
 countryTranslations[lang]=(await read(path.join(site,`locales/${lang}.json`))).countryNames||{};
const figures=(await read(path.join(site,'data/figure_registry.json'))).figures;
const referenceIndex=await read(path.join(site,'data/explorer_references.json'));
const qa=await read(path.join(site,'GUIDED_QA.json'));
if(referenceIndex.policy!=='FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3'||
   qa.reference_policy_sha256!=='STRICT_BALANCE_DEFAULT')
  throw Error('Research products require the actual strict candidate export');
const contracts=referenceIndex.country_files?.NLD?
  (await read(path.join(site,referenceIndex.country_files.NLD))).figures:
  referenceIndex.figures.filter(v=>v.focus==='NLD');
const payloads={};
for(const c of countries)payloads[c.code]=await read(path.join(site,`data/countries/${c.code}.json`));
const availability=(await read(path.join(site,'data/availability/NLD.json'))).figures;
const observations=[],panels=[],dependencies=[],rankTables=[];
const title={reading:'Lezen',mathematics:'Rekenen/wiskunde',science:'Natuurwetenschappen',all:'Leeromgeving'};
const labels={
 total:'Nederland',q1:'Onderste kwart SES',q4:'Bovenste kwart SES',q4_minus_q1:'Q4 min Q1',
 girl:'Meisjes',boy:'Jongens',girls_minus_boys:'Meisjes min jongens',
 always_almost:'Altijd/bijna altijd toetstaal',sometimes_never:'Soms/nooit toetstaal',
 test_language_home:'Toetstaal thuis',other_language_home:'Andere thuistaal',
 reference:'Geen ouder in buitenland geboren',migration:'Minstens één ouder in buitenland geboren',
 native:'Geen migratieachtergrond',first_generation:'Eerste generatie',second_generation:'Tweede generatie',
 first_minus_native:'Eerste min zonder migratieachtergrond',second_minus_native:'Tweede min zonder migratieachtergrond',
 q1_target_pct_q4_peers:'Bij Q1: aandeel Q4-peers',q4_target_pct_q1_peers:'Bij Q4: aandeel Q1-peers',
 population_q1_share:'Landelijk aandeel Q1',population_q4_share:'Landelijk aandeel Q4',
 less_often_target_pct_always_almost_peers:'Bij soms/nooit: aandeel altijd/bijna altijd',
 other_language_target_pct_test_language_home_peers:'Bij andere thuistaal: aandeel toetstaal',
 population_test_language_share:'Landelijk aandeel toetstaal',
 first_generation_target_pct_native_peers:'Bij eerste generatie',second_generation_target_pct_native_peers:'Bij tweede generatie',
 self_below_basic:'Zelf onder basisniveau',self_at_or_above_basic:'Zelf op/boven basisniveau',
 self_below_high:'Zelf onder hoge drempel',self_high:'Zelf hoog vaardig',
 population_high_share:'Landelijk aandeel hoog vaardig'
};
function asArray(x){return x==null?[]:Array.isArray(x)?x:[x];}
function niceLabel(r){
 const explicit=r.series_label_nl;
 if(explicit&&explicit!==r.series_id&&/meisjes|female|girls/i.test(explicit)&&
    /other|overig|anders|gepoold/i.test(explicit))return explicit;
 return labels[r.series_id]||explicit||r.series_id;
}
for(const base of figures){
 const contract=contracts.find(v=>v.figure_id===base.figure_id);
 if(!contract)throw Error('Missing Netherlands reference contract '+base.figure_id);
 const f=E.focusFigure(base,contract);
 const all=payloads.NLD.records.filter(r=>r.figure_id===base.figure_id&&r.series_role!=='comparator');
 const av=availability.find(a=>a.figure_id===base.figure_id);
 const focus=E.displayableRows(all,f,av);
 const members=asArray(contract.default_members);
 let refs=[];
 if(E.referenceStatus(contract,'NLD',members).ok&&E.completeRows(all,f))
   refs=E.referenceRows(f,'NLD',members,payloads,contract);
 const displayed=E.presentationRows([...focus,...refs],f,false);
 const model={
  id:f.figure_id,title:title[f.domain]||f.domain,survey:f.survey,age:f.age,domain:f.domain,
  years:E.words(f.required_years).map(Number),expected_series:E.words(f.expected_series),
  unit:displayed[0]?.display_unit||displayed[0]?.unit||f.unit,split:f.split,
  outcome:f.outcome,peer_definition:f.peer_definition,availability:av,
  default_reference:members,reference_status:E.referenceStatus(contract,'NLD',members),
  rows:displayed.map(r=>({...r,standard_error:r.se??null,
    label:r.series_role==='comparator'?'Vergelijkingsgroep':
      f.peer_definition!=='none'&&r.series_id==='total'?'Alle leerlingen':niceLabel(r)}))
 };
 // Figure points retain their exact primitive/derived result identities.
 // No rounding or invented intervals is permitted in this data layer.
 for(const r of model.rows){
  observations.push({figure_id:f.figure_id,...r});
  const ids=r.series_role==='comparator'?members.map(c=>{
    const parent=payloads[c].records.find(p=>p.figure_id===f.figure_id&&
      Number(p.year)===Number(r.year)&&p.series_id===r.parent_series_id&&p.series_role!=='comparator');
    if(!parent?.cell_id)throw Error('Missing exact reference parent');
    return parent.cell_id;
  }):asArray(r.cell_id||r.parent_cell_ids||r.member_cell_ids);
  dependencies.push({product_figure_id:f.figure_id,series_id:r.series_id,year:r.year,
    cell_ids:ids,result_hash:r.result_hash||'',derivation:r.series_role==='comparator'?
      'EXISTING_CERTIFIED_EQUAL_COUNTRY_REFERENCE':'EXISTING_CERTIFIED_PRESENTATION_TRANSFORM',
    members:r.series_role==='comparator'?members:[],full_source_record:r});
 }
 if(f.figure_id.startsWith('TR_MEAN_')||f.figure_id.startsWith('GP_SES_GAP_')){
  const rankTable={figure_id:f.figure_id,full_year_anchor:model.years,
    basis:['NLD',...members],status:model.reference_status,rows:[]};
  if(model.reference_status.ok&&E.completeRows(all,f)){
   const statistic=f.figure_id.startsWith('GP_SES_GAP_')?'gap':'mean_score';
   const result=[...E.rankRows(f,statistic,'NLD',members,payloads,contract),
     ...members.flatMap(c=>E.rankRows(f,statistic,'NLD',members,payloads,contract,c).filter(r=>r.series_role==='other'))];
   rankTable.rows=result.filter(r=>Number(r.year)===Math.max(...model.years));
   rankTable.rules=E.RANK_RULES[statistic];
  }
  rankTables.push(rankTable);
 }
 panels.push(model);
}
const six=family=>['age10','age15'].flatMap(age=>['reading','mathematics','science'].map(domain=>{
 const id=`${family}_${age}_${domain}`;
 if(!panels.some(p=>p.id===id))throw Error('Missing approved figure '+id);
 return id;
}));
const three=(family,age)=>six(family).filter(id=>id.includes('_'+age+'_'));
const families=prefix=>panels.filter(p=>p.id.startsWith(prefix)&&p.peer_definition==='direct_learning_environment').map(p=>p.id);
const slides=[
 {source_slide:1,title:'Nederlandse leerprestaties',kind:'cover',panels:[]},
 {source_slide:2,title:'Gemiddelde scores door de tijd',panels:six('TR_MEAN'),comparison:true},
 {source_slide:3,title:'De onderkant, het midden en de bovenkant',kind:'distribution',panels:[...six('DS_P10'),...six('DS_P50'),...six('DS_P90')]},
 {source_slide:4,title:'Gemiddelde score naar sociale achtergrond in groep 6',panels:three('GP_SES_LEVELS','age10')},
 {source_slide:5,title:'Verschil tussen het bovenste en onderste kwart in groep 6',panels:three('GP_SES_GAP','age10')},
 {source_slide:6,title:'Onder basisniveau naar sociale achtergrond in groep 6',panels:three('GP_SES_BASIC','age10')},
 {source_slide:7,title:'Gemiddelde score naar trendvergelijkbare SES',panels:three('GP_SES_LEVELS','age15')},
 {source_slide:8,title:'Scoreverschil naar trendvergelijkbare SES',panels:three('GP_SES_GAP','age15')},
 {source_slide:9,title:'Onder basisniveau naar trendvergelijkbare SES',panels:three('GP_SES_BASIC','age15')},
 {source_slide:11,title:'Gemiddelde score naar geslacht',panels:six('GP_GENDER_LEVELS')},
 {source_slide:12,title:'Gemiddelde score naar taalgebruik thuis',panels:six('GP_LANGUAGE_LEVELS')},
 {source_slide:13,title:'Gemiddelde score naar migratieachtergrond',panels:panels.filter(p=>p.id.startsWith('GP_MIGRATION_LEVELS_')&&p.id.endsWith('_ANY_PARENT_ABROAD')).map(p=>p.id)},
 {source_slide:14,title:'Gemiddelde score naar migratiegeneratie',panels:six('GP_MIGRATION_LEVELS')},
 {source_slide:15,title:'Scoreverschillen naar migratiegeneratie',panels:six('GP_MIGRATION_GAP')},
 {source_slide:16,title:'Lage SES: aandeel peers uit het bovenste kwart',panels:families('EN_SES_PEER_'),series:['q1_target_pct_q4_peers','population_q4_share']},
 {source_slide:17,title:'Hoge SES: aandeel peers uit het onderste kwart',panels:families('EN_SES_PEER_'),series:['q4_target_pct_q1_peers','population_q1_share']},
 {source_slide:18,title:'Thuistaal en de samenstelling van de leeromgeving',panels:families('EN_LANGUAGE_PEER_')},
 {source_slide:19,title:'Migratiegeneraties en peers zonder migratieachtergrond',panels:families('EN_MIGRATION_PEER_').filter(id=>!id.endsWith('_ANY_PARENT_ABROAD')&&!id.endsWith('_BOTH_PARENTS_ABROAD'))},
 {source_slide:20,approval:'A01',title:'Peers onder basisniveau naar eigen vaardigheidsniveau',panels:families('EN_PERFORMANCE_PEER_').filter(id=>!id.startsWith('EN_PERFORMANCE_PEER_HIGH_'))},
 {source_slide:20,approval:'A03',title:'Hoog vaardige peers naar eigen vaardigheidsniveau',panels:families('EN_PERFORMANCE_PEER_HIGH_')},
 {source_slide:21,title:'Dekking van de Nederlandse SES-reeks',kind:'coverage',panels:[]},
 {source_slide:10,approval:'A02',title:'Bijlage Hoog vaardigheidsniveau naar SES',kind:'high_ses_appendix',panels:[]}
];
for(const [i,s] of slides.entries())s.number=i+1;
await fs.mkdir(out,{recursive:true});
const provenance={
 schema_version:1,result_scope:'CURRENT47_DEFERRED36_EXCLUDED',countries:countries.map(c=>c.code),
 result_manifest_sha256:await sha(path.join(repo,'04_results/review/all_required/manifest.json')),
 scientific_manifest_sha256:await sha(path.join(repo,'06_pipeline/review_20261013/scientific_review/SCIENTIFIC_REVIEW_MANIFEST.json')),
 candidate_manifest_sha256:await sha(path.join(site,'BUILD_SHA256_MANIFEST.json')),
 phase_sha256:await sha(phasePath),explorer_sha256:await sha(path.join(site,'assets/explorer.mjs')),
 source_deck:'BR_POLICY_21_20261001',source_deck_sha256:'cea8dc8a42c3e63e435c16ef13ea6cc1b634f5ca4d95af8c29dafba7397631ac',
 slide_count_change:'22 slides: retain the original narrative, split source slide 20 into separately approved low/high peer outcomes (A01/A03), move source slide 10 to the appendix (A02). No additional analysis family.',
 sources_are_aggregate_only:true,precision:'Full binary64 aggregate precision; display rounding only'
};
await fs.writeFile(path.join(out,'RESEARCH_PRODUCT_DATA.json'),JSON.stringify({provenance,slides,panels,rankTables,labels,country_names:Object.fromEntries(countries.map(c=>[c.code,{nl:countryTranslations.nl[c.code]||c.nl,en:countryTranslations.en[c.code]||c.en}]))},null,2)+'\n');
await fs.writeFile(path.join(out,'PRODUCT_POINT_LINEAGE.json'),JSON.stringify({provenance,dependencies},null,2)+'\n');
console.log('RESEARCH_PRODUCT_DATA',panels.length,'approved figure contracts;',observations.length,'display points;',slides.length,'slides; no pupil calculation');
