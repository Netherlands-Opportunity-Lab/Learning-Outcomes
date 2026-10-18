import assert from 'node:assert/strict';
import fs from 'node:fs';
import * as m from '../preview_overlay/assets/explorer.mjs';
const f={figure_id:'TR_MEAN_age15_reading',age:'age15',domain:'reading',survey:'PISA',question:'trends',split:'none',outcome:'mean_score',required_years:'2018;2022;2025',expected_series:'girl;boy',unit:'score_points'};
const rows=(country,base)=>[2018,2022,2025].flatMap(year=>['girl','boy'].map((group,i)=>({figure_id:f.figure_id,country_id:'iso3:'+country,series_id:group,series_role:'focus',year,estimate:base+i,result_hash:country+year+group,source_id:'test',ci_low:base-1,ci_high:base+3,se:1})));
const payloads={NLD:{records:rows('NLD',510)},AUT:{records:rows('AUT',500)},CAN:{records:rows('CAN',520)}};
const contract={status:'BALANCED_REFERENCE_AVAILABLE',eligible_members:['AUT','CAN'],default_members:['AUT'],evidence_sha256:'a'.repeat(64)};
assert.ok(Number.isNaN(m.number(null)));assert.ok(Number.isNaN(m.number('')));assert.equal(m.number(0),0);
assert.ok(m.completeRows(payloads.NLD.records,f));assert.ok(!m.completeRows(payloads.NLD.records.slice(1),f));assert.ok(!m.completeRows([...payloads.NLD.records,payloads.NLD.records[0]],f));
// Individual checked points survive missing waves; comparisons still require
// the unchanged complete year x group grid tested below.
const partial=payloads.NLD.records.slice(1).map(r=>({...r,quality_status:'SCIENTIFICALLY_VALIDATED'}));
assert.equal(m.displayableRows(partial,f,{display_state:'PARTIAL'}).length,5);
assert.equal(m.displayableRows(partial,f,{display_state:'PLACEHOLDER'}).length,0);
assert.equal(m.displayableRows([{...partial[0],quality_status:'PENDING'}],f,{display_state:'PARTIAL'}).length,0);
assert.equal(m.displayableRows([{...partial[0],year:2020}],f,{display_state:'PARTIAL'}).length,0);
assert.throws(()=>m.displayableRows([...partial,partial[0]],f,{display_state:'PARTIAL'}),/DUPLICATE_DISPLAY_CELL/);
assert.equal(m.breakBetween({year:2018},{year:2022},f),false);
assert.equal(m.breakBetween({year:2018},{year:2025},f),true);
assert.equal(m.breakBetween({year:2018},{year:2022,series_break_before:true},f),true);
let average=m.referenceRows(f,'NLD',['AUT','CAN'],payloads,contract);
assert.equal(average[0].estimate,510);assert.equal(average.length,6);assert.ok(average.every(r=>!('se'in r)&&!('ci_low'in r)));
assert.equal(m.referenceRows(f,'NLD',['CAN'],payloads,contract)[0].estimate,520);
assert.throws(()=>m.referenceRows(f,'NLD',[],payloads,contract),/EMPTY/);
assert.throws(()=>m.referenceRows(f,'NLD',['NLD'],payloads,contract),/INELIGIBLE/);
assert.throws(()=>m.referenceRows(f,'NLD',['AUT','AUT'],payloads,contract),/INELIGIBLE/);
const broken=structuredClone(payloads);broken.CAN.records.pop();assert.throws(()=>m.referenceRows(f,'NLD',['AUT','CAN'],broken,contract),/INCOMPLETE/);
let rank=m.rankRows(f,'mean_score','NLD',['AUT','CAN'],payloads,contract,'CAN');
assert.equal(rank[0].estimate,2);assert.equal(rank.length,12);assert.equal(rank[6].estimate,1);assert.ok(rank.every(r=>r.se===null&&r.ci_low===null));assert.ok(!rank.some(r=>r.series_role==='comparator'));
const ties=structuredClone(payloads);ties.CAN.records=rows('CAN',510);rank=m.rankRows(f,'mean_score','NLD',['AUT','CAN'],ties,contract);assert.equal(rank[0].estimate,1.5);
rank=m.rankRows(f,'below_basic','NLD',['AUT','CAN'],payloads,contract);assert.equal(rank[0].estimate,2);
assert.throws(()=>m.rankRows(f,'mean_score','NLD',['AUT'],payloads,contract,'CAN'),/OTHER_NOT_IN_REFERENCE/);
const s={country:'NLD',subject:'age15:reading',split:'gender',statistic:'mean_score',rank:true,compare:false,members:[],other:''};assert.deepEqual(m.readSelection(m.selectionSearch(s),{}),s);
assert.equal(m.splitKey({...f,split:'migration',figure_id:'GP_MIGRATION_LEVELS_age15_reading_ANY_PARENT_ABROAD'}),'migration_any');
assert.equal(m.statisticKey({...f,view_mode:'difference'}),'gap');
assert.deepEqual(m.referenceOption(contract,'NLD','AUT'),{allowed:true,reason:'eligible'});
assert.deepEqual(m.referenceOption(contract,'NLD','NLD'),{allowed:false,reason:'focus'});
assert.equal(m.referenceOption({status:'FOCUS_CORE_INCOMPLETE'},'NLD','AUT').reason,'focus_core');
assert.equal(m.referenceOption({status:'FOCUS_VIEW_INCOMPLETE'},'NLD','AUT').reason,'focus_view');
assert.equal(m.referenceOption({eligibility:[{country:'AUT',reason:'FAIL_DASHBOARD_6x3'}]},'NLD','AUT').reason,'admission');
assert.equal(m.referenceOption({eligibility:[{country:'AUT',reason:'MISSING_OR_INCOMPATIBLE_REQUIRED_CELLS',missing_cells:1}]},'NLD','AUT').reason,'missing');
assert.equal(m.referenceStatus({status:'NO_ELIGIBLE_REFERENCE'},'NLD',[]).reason,'coverage');
// Optionally verify every real approved figure is reachable exactly once.
if(process.argv[2]){const figures=JSON.parse(fs.readFileSync(process.argv[2],'utf8')).figures,reached=new Set();for(const subject of m.SUBJECTS)for(const split of m.choices(figures,subject,'none').splits)for(const statistic of m.choices(figures,subject,split).statistics){const fs=figures.filter(f=>m.compatible(f,subject)&&m.splitKey(f)===split&&m.statisticKey(f)===statistic);assert.equal(fs.length,1);reached.add(m.selectFigure(figures,{subject,split,statistic}).figure_id);}assert.equal(reached.size,figures.length);console.log(`PASS all ${figures.length} approved figure contracts reachable without collisions`);}
console.log('PASS exact selected references, joint completeness, no benchmark CI, ranks, ties, single other country and URL roundtrip');
