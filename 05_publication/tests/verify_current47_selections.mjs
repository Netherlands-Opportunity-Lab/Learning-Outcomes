// Actual exported country/figure selections through the shared NL/EN runtime.
// No source data, estimates, publication or user preferences are modified.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [repoArg,siteArg,outputArg]=process.argv.slice(2);
assert(repoArg&&siteArg&&outputArg,'Usage: node verify_current47_selections.mjs repo site proof.json');
const repo=path.resolve(repoArg),site=path.resolve(siteArg);
const hash=p=>createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const read=p=>JSON.parse(fs.readFileSync(p,'utf8'));
const manifest=read(path.join(site,'BUILD_SHA256_MANIFEST.json'));
const hashes=new Map(manifest.map(r=>[r.path,r.sha256]));
const consumed={};
function asset(name) {
  const p=path.join(site,name),h=hash(p);
  assert.equal(h,hashes.get(name),'Changed dashboard asset: '+name);
  consumed[name]=h;return read(p);
}
const runtime='05_publication/preview_overlay/assets/explorer.mjs';
assert.equal(hash(path.join(repo,runtime)),hash(path.join(site,'assets/explorer.mjs')));
const E=await import(pathToFileURL(path.join(repo,runtime)).href);
const figures=asset('data/figure_registry.json').figures;
const countries=asset('data/common42.json');
const expected=read(path.join(repo,'04_products_or_release/current47/data/RESEARCH_PRODUCT_DATA.json')).provenance.countries;
assert.deepEqual(countries.map(x=>x.code).sort(),[...expected].sort());
const index=asset('data/explorer_references.json');
assert.equal(index.policy,'FULL_FOCUS_COMBINATION_PLUS_JOINT_VIEW_SUPPORT_MIN3');
const payloads={},availability={},references={};
for(const c of countries) {
  payloads[c.code]=asset(`data/countries/${c.code}.json`);
  availability[c.code]=asset(`data/availability/${c.code}.json`).figures;
  references[c.code]=asset(index.country_files[c.code]).figures;
}
const reachable=new Set(),selectionKeys=[];
for(const subject of E.SUBJECTS) {
  for(const split of E.choices(figures,subject,'none').splits) {
    for(const statistic of E.choices(figures,subject,split).statistics) {
      const selection={country:'NLD',subject,split,statistic,rank:false,compare:true,uncertainty:true,members:null,other:''};
      const matches=figures.filter(f=>E.compatible(f,subject)&&E.splitKey(f)===split&&E.statisticKey(f)===statistic);
      assert.equal(matches.length,1,'Ambiguous dropdown selection');
      const figure=E.selectFigure(figures,selection);
      assert.equal(figure.figure_id,matches[0].figure_id);
      assert.deepEqual(E.readSelection(E.selectionSearch(selection),{}),selection);
      reachable.add(figure.figure_id);selectionKeys.push({subject,split,statistic,figure_id:figure.figure_id});
    }
  }
}
assert.deepEqual([...reachable].sort(),figures.map(f=>f.figure_id).sort(),'Unreachable approved figure');
let contracts=0,displayPoints=0,missingPositions=0,referencePoints=0,rankPoints=0;
const views=[];
for(const c of countries) {
  const grouped=new Map();
  for(const r of payloads[c.code].records) {
    if(r.series_role==='comparator')continue;
    if(!grouped.has(r.figure_id))grouped.set(r.figure_id,[]);
    grouped.get(r.figure_id).push(r);
  }
  for(const base of figures) {
    const contract=references[c.code].find(r=>r.figure_id===base.figure_id);
    const av=availability[c.code].find(r=>r.figure_id===base.figure_id);
    assert(contract&&av);assert.equal(contract.focus,c.code);
    const f=E.focusFigure(base,contract),raw=grouped.get(f.figure_id)||[];
    const shown=E.displayableRows(raw,f,av),missing=E.list(av.missing_points);
    assert.equal(shown.length,av.available_points,`${c.code}/${f.figure_id}: displayed count`);
    assert.equal(shown.length+missing.length,av.required_points,`${c.code}/${f.figure_id}: missing positions`);
    for(const m of missing)assert(m.reason_nl&&m.reason_en,'Unexplained missing position');
    const members=E.list(contract.default_members);
    assert(!members.includes(c.code));assert(!E.provisional(contract));
    let refs=[];
    if(E.referenceStatus(contract,c.code,members).ok) {
      assert(E.completeRows(raw,f));
      refs=E.referenceRows(f,c.code,members,payloads,contract);
      for(const r of refs) {
        assert.equal(r.se,undefined);assert.equal(r.ci_low,undefined);
        assert.deepEqual([...r.members].sort(),[...members].sort());
      }
      const stat=E.statisticKey(base);
      if(E.RANK_RULES[stat]&&!E.splitKey(base).startsWith('peers:')) {
        const ranks=E.rankRows(f,stat,c.code,members,payloads,contract);
        assert(ranks.every(r=>r.series_role!=='comparator'&&r.se===null&&r.ci_low===null));
        rankPoints+=ranks.length;
      }
    }
    const display=E.presentationRows([...shown,...refs],f,false);
    assert(display.every(r=>Number.isFinite(E.number(r.estimate))));
    views.push({country:c.code,figure_id:f.figure_id,display_state:av.display_state,
      required_points:av.required_points,displayed:shown.length,missing:missing.length,
      reference_status:contract.status,default_members:members});
    contracts++;displayPoints+=shown.length;missingPositions+=missing.length;referencePoints+=refs.length;
  }
}
const proof={status:'ALL_EXPORTED_SELECTIONS_CHECKED',countries:expected,figure_contracts:figures.length,
  dropdown_selections:selectionKeys.length,country_figure_contracts:contracts,
  displayed_focus_points:displayPoints,explicit_missing_positions:missingPositions,
  default_reference_points:referencePoints,rank_focus_points:rankPoints,
  candidate_manifest_sha256:hash(path.join(site,'BUILD_SHA256_MANIFEST.json')),
  runtime_sha256:hash(path.join(repo,runtime)),consumed_assets:consumed,selectionKeys,views,
  no_pupil_computation:true,browser_testing_separate:true};
fs.writeFileSync(outputArg,JSON.stringify(proof,null,2)+'\n');
console.log(JSON.stringify({status:proof.status,countries:expected.length,figure_contracts:figures.length,
  dropdown_selections:selectionKeys.length,country_figure_contracts:contracts,
  displayed_focus_points:displayPoints,explicit_missing_positions:missingPositions,default_reference_points:referencePoints}));
