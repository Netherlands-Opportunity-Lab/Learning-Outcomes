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
const s={country:'NLD',subject:'age15:reading',split:'gender',statistic:'mean_score',rank:true,compare:false,uncertainty:false,members:[],other:''};assert.deepEqual(m.readSelection(m.selectionSearch(s),{}),s);
assert.equal(m.splitKey({...f,split:'migration',figure_id:'GP_MIGRATION_LEVELS_age15_reading_ANY_PARENT_ABROAD'}),'migration_any');
assert.equal(m.statisticKey({...f,view_mode:'difference'}),'gap');
assert.deepEqual(m.referenceOption(contract,'NLD','AUT'),{allowed:true,reason:'eligible'});
assert.deepEqual(m.referenceOption(contract,'NLD','NLD'),{allowed:false,reason:'focus'});
assert.equal(m.referenceOption({status:'FOCUS_CORE_INCOMPLETE'},'NLD','AUT').reason,'focus_core');
assert.equal(m.referenceOption({status:'FOCUS_VIEW_INCOMPLETE'},'NLD','AUT').reason,'focus_view');
assert.equal(m.referenceOption({eligibility:[{country:'AUT',reason:'FAIL_DASHBOARD_6x3'}]},'NLD','AUT').reason,'admission');
assert.equal(m.referenceOption({eligibility:[{country:'AUT',reason:'MISSING_OR_INCOMPATIBLE_REQUIRED_CELLS',missing_cells:1}]},'NLD','AUT').reason,'missing');
assert.equal(m.referenceStatus({status:'NO_ELIGIBLE_REFERENCE'},'NLD',[]).reason,'coverage');
// Explicit temporary mode uses the points actually available, without
// certifying balance or changing the strict path tested above.
const tempContract={...contract,mode:'AVAILABLE_CASES_PROVISIONAL',status:'PROVISIONAL_REFERENCE_AVAILABLE',reference_policy_sha256:'b'.repeat(64)};
const avail=structuredClone(payloads);
Object.values(avail).forEach(p=>p.records.forEach(r=>r.quality_status='SCIENTIFICALLY_VALIDATED'));
avail.CAN.records=avail.CAN.records.filter(r=>!(r.year===2022&&r.series_id==='girl'));
avail.AUT.records=avail.AUT.records.filter(r=>!(r.year===2025&&r.series_id==='boy'));
avail.CAN.records=avail.CAN.records.filter(r=>!(r.year===2025&&r.series_id==='boy'));
let provisional=m.referenceRows(f,'NLD',['AUT','CAN'],avail,tempContract);
assert.equal(provisional.length,5); // both countries missing: no invented zero
let point=provisional.find(r=>r.year===2022&&r.parent_series_id==='girl');
assert.equal(point.estimate,500);assert.deepEqual(point.members,['AUT']);assert.deepEqual(point.excluded_members,['CAN']);
assert.equal(point.comparison_status,'PROVISIONAL');assert.ok(!('se' in point));
assert.deepEqual(point.parent_result_hashes,['AUT2022girl']);
assert.equal(m.breakBetween(provisional.find(r=>r.year===2018&&r.parent_series_id==='girl'),point,f),true);
let tempRank=m.rankRows(f,'mean_score','NLD',['AUT','CAN'],avail,tempContract,'CAN');
assert.equal(tempRank.find(r=>r.year===2022&&r.series_role==='focus'&&r.parent_series_id==='girl').estimate,1);
assert.equal(tempRank.find(r=>r.year===2022&&r.series_role==='focus'&&r.parent_series_id==='girl').rank_basis_n,2);
assert.ok(!tempRank.some(r=>r.year===2022&&r.series_role==='other'&&r.parent_series_id==='girl'));
assert.ok(!tempRank.some(r=>r.series_role==='comparator'));
assert.ok(tempRank.every(r=>r.se===null&&r.comparison_status==='PROVISIONAL'));
const badAvail=structuredClone(avail);badAvail.AUT.records[0].quality_status='PENDING';
assert.deepEqual(m.referenceRows(f,'NLD',['AUT','CAN'],badAvail,tempContract)[0].members,['CAN']);
badAvail.AUT.records=avail.AUT.records.concat(avail.AUT.records[0]);
assert.throws(()=>m.referenceRows(f,'NLD',['AUT','CAN'],badAvail,tempContract),/DUPLICATE_AVAILABLE_CELL/);
const pooled=structuredClone(avail);pooled.NLD.records[0].series_label_en='Girls + other';
assert.ok(!m.referenceRows({...f,split:'gender'},'NLD',['AUT','CAN'],pooled,tempContract).some(r=>r.year===2018&&r.parent_series_id==='girl'));
assert.equal(m.referenceStatus(tempContract,'NLD',[]).reason,'empty');
assert.equal(m.referenceStatus(tempContract,'NLD',['NLD']).reason,'ineligible');
assert.equal(m.referenceOption(tempContract,'NLD','AUT').reason,'provisional');
// Optionally verify every real approved figure is reachable exactly once.
if(process.argv[2]){const figures=JSON.parse(fs.readFileSync(process.argv[2],'utf8')).figures,reached=new Set();for(const subject of m.SUBJECTS)for(const split of m.choices(figures,subject,'none').splits)for(const statistic of m.choices(figures,subject,split).statistics){const fs=figures.filter(f=>m.compatible(f,subject)&&m.splitKey(f)===split&&m.statisticKey(f)===statistic);assert.equal(fs.length,1);reached.add(m.selectFigure(figures,{subject,split,statistic}).figure_id);}assert.equal(reached.size,figures.length);console.log(`PASS all ${figures.length} approved figure contracts reachable without collisions`);}
console.log('PASS exact selected references, joint completeness, no benchmark CI, ranks, ties, single other country and URL roundtrip');

// Presentation must preserve scientific inputs and never invent uncertainty
// for a benchmark, a rank, a missing standard error or an unverified group gap.
const source={series_id:'total',series_role:'focus',estimate:459.242908056442,se:4.28220491615576,result_hash:'checked-parent'};
let displayed=m.presentationRows([source],f)[0];
assert.equal(source.ci_low,undefined);assert.equal(displayed.result_hash,source.result_hash);
assert.ok(Math.abs(displayed.ci_low-450.8497864207767)<1e-10);
assert.ok(Math.abs(displayed.ci_high-467.6360296921073)<1e-10);
assert.equal(displayed.ci_parent_result_hash,'checked-parent');
for(const se of [null,'',undefined,-1])assert.equal(m.presentationRows([{...source,se}],f)[0].ci_method,undefined);
assert.equal(m.presentationRows([{...source,se:0}],f)[0].ci_low,source.estimate);
for(const role of ['comparator','other'])assert.equal(m.presentationRows([{...source,series_role:role}],f)[0].ci_method,undefined);
assert.equal(m.presentationRows([source],f,true)[0].ci_method,undefined);
const percentFigure={...f,figure_id:'TR_BELOW_age15_reading',unit:'percent'};
const rawShare={...source,estimate:.345832035168812,se:.0174346932813374};
displayed=m.presentationRows([rawShare],percentFigure)[0];
assert.ok(Math.abs(displayed.estimate-34.5832035168812)<1e-12);
assert.ok(Math.abs(displayed.se-1.74346932813374)<1e-12);
assert.equal(displayed.input_estimate,rawShare.estimate);assert.equal(displayed.input_se,rawShare.se);
assert.equal(displayed.input_unit,'proportion');assert.equal(displayed.display_scale,100);
assert.equal(displayed.ci_low,displayed.estimate-1.96*displayed.se);
assert.deepEqual(m.presentationRows([displayed],percentFigure)[0],displayed);
for(const family of ['GP_SES_BASIC','EN_PERFORMANCE_PEER','EN_PERFORMANCE_PEER_HIGH']){
 const alreadyPercent=m.presentationRows([{...source,estimate:73.139,se:1.354}],{...percentFigure,figure_id:family+'_age15_reading'})[0];
 assert.equal(alreadyPercent.estimate,73.139);assert.equal(alreadyPercent.se,1.354);
}
const refShare=m.presentationRows([{...rawShare,series_role:'comparator',se:undefined}],percentFigure)[0];
assert.equal(refShare.estimate,displayed.estimate);assert.equal(refShare.ci_low,undefined);
assert.equal(m.presentationRows([{...source,estimate:2,se:1,unit:'rank'}],f)[0].ci_method,undefined);
const enabled={...s,uncertainty:true};assert.deepEqual(m.readSelection(m.selectionSearch(enabled),{}),enabled);
assert.equal(m.readSelection('',{}).uncertainty,false);
console.log('PASS verified focus intervals, explicit units, unchanged parents, idempotence and uncertainty URL roundtrip');

assert.equal(m.presentationRows([{...source,ci_low:1,ci_high:999}],f)[0].ci_method,m.DISPLAY_POLICY.interval_method);
assert.equal(m.presentationRows([{...source,ci_low:1,ci_high:999,ci_level:.95}],f)[0].ci_method,'SUPPLIED_95_INTERVAL');
