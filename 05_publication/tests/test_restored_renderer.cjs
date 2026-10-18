// Exercise the actual renderer without a browser or source data.
const fs=require('fs'),vm=require('vm'),assert=require('node:assert/strict');
(async()=>{
 const helpers=await import('../preview_overlay/assets/explorer.mjs');
 let code=fs.readFileSync('05_publication/preview_overlay/assets/app-shell.js','utf8').replace(/^import .*;$/gm,'').split('init().catch')[0];
 const box={...helpers,document:{documentElement:{dataset:{base:''}},querySelector:()=>({textContent:'Synthetic test'})},window:{innerWidth:1200},Intl,URLSearchParams,console};
 vm.createContext(box);vm.runInContext(code,box);
 vm.runInContext(`state.locale='nl';state.country='NLD';state.countries=[{code:'NLD',nl:'Nederland',en:'Netherlands'}];
 if(seriesName({series_id:'total',series_role:'focus',country_id:'iso3:NLD'})!=='Nederland')throw Error('Focus mislabeled');
 const f={unit:'score_points',required_years:'2016;2021'};
 const rows=[{series_id:'total',estimate:550,year:2021,ci_low:null,ci_high:''},{series_id:'total',estimate:540,year:2016}];
 let svg=chart(rows,f);if(svg.includes('class="ci-line"'))throw Error('Missing interval rendered');
 if(+svg.match(/data-y-min="([^"]+)"/)[1]<530)throw Error('Missing interval affected axis');
 rows.forEach(r=>Object.assign(r,{series_role:'comparator',ci_low:1,ci_high:999}));
 svg=chart(rows,f);if(svg.includes('class="ci-line"'))throw Error('Benchmark CI rendered');
 if(+svg.match(/data-y-min="([^"]+)"/)[1]<530)throw Error('Benchmark CI affected axis');
 state.uncertainty=true;
 svg=chart(rows,f);if(svg.includes('class="ci-line"'))throw Error('Benchmark CI rendered with switch on');
 const verified=presentationRows([{series_role:'focus',series_id:'total',year:2016,estimate:540,se:10,result_hash:'a'},{series_role:'focus',series_id:'total',year:2021,estimate:550,se:5,result_hash:'b'}],f);
 svg=chart(verified,f);if((svg.match(/class="ci-line"/g)||[]).length!==2)throw Error('Focus intervals not rendered');
 if(+svg.match(/data-y-min="([^"]+)"/)[1]>520.4)throw Error('Focus interval clipped');
 state.uncertainty=false;svg=chart(verified,f);if(svg.includes('class="ci-line"'))throw Error('Toggle off still draws interval');
 state.uncertainty=true;state.rank=true;svg=chart(verified,f);if(svg.includes('class="ci-line"'))throw Error('Rank interval invented');state.rank=false;
 const nearZero=presentationRows([{series_role:'focus',series_id:'total',year:2016,estimate:.001,se:.003}],{...f,figure_id:'TR_BELOW_age10_reading',unit:'percent'});
 svg=chart(nearZero,{...f,unit:'percent'});if(+svg.match(/data-y-min="([^"]+)"/)[1]>nearZero[0].ci_low)throw Error('Normal percentage interval clipped');
 if(fmt(null)!=='—'||fmt('')!=='—')throw Error('Missing value became zero');
 `,box);
 // Export must keep the selection captured before its asynchronous font/logo
 // reads, even when the user changes country while the export is in flight.
 class Element {
  constructor(tag){this.tag=tag;this.attrs={};this.children=[];this.textContent='';}
  setAttribute(k,v){this.attrs[k]=v;}getAttribute(k){return this.attrs[k];}
  append(v){this.children.push(v);}prepend(v){this.children.unshift(v);}
  cloneNode(){return this;}
  querySelector(){const svg=new Element('svg');svg.attrs.viewBox='0 0 1120 430';return svg;}
 }
 box.document.createElement=tag=>new Element(tag);
 box.document.createElementNS=(_,tag)=>new Element(tag);
 box.AbortSignal=AbortSignal;let releaseAssets;const hold=new Promise(r=>releaseAssets=r);
 box.fetch=async path=>{await hold;return {ok:true,text:async()=>path.endsWith('.svg')?'<svg>original logo</svg>':'@font-face{font-family:Oswald;src:url(data:font/woff2;base64,AA)}'};};
 box.XMLSerializer=class{serializeToString(svg){return JSON.stringify(svg);}};
 vm.runInContext(`state.currentFigure={figure_id:'test',unit:'score_points',required_years:'2016;2021'};state.shown=[{series_id:'total',year:2016,estimate:540},{series_id:'total',year:2021,estimate:550}];saveBlob=(data,type,name)=>{exported={data,type,name};};`,box);
 const pending=vm.runInContext('downloadFigure()',box);vm.runInContext("state.country='CAN';state.uncertainty=false;",box);releaseAssets();await pending;
 const output=box.exported;assert.equal(output.name,'leerprestaties_NLD_test.svg');
 const svg=JSON.parse(output.data),metadata=JSON.parse(svg.children.find(x=>x.tag==='metadata').textContent);
 assert.equal(metadata.selection.country,'NLD');assert.equal(metadata.selection.uncertainty,true);assert.equal(metadata.display_policy.focus_only,true);assert.equal(metadata.records.length,2);
 assert.ok(svg.children.find(x=>x.tag==='style').textContent.includes('data:font/woff2'));
 assert.ok(svg.children.find(x=>x.tag==='image').attrs.href.startsWith('data:image/svg+xml'));
 assert.equal(svg.attrs.width,'1120');
 const html=fs.readFileSync('05_publication/preview_overlay/index.html','utf8');
 for(const id of ['countrySelect','subjectSelect','statisticSelect','splitSelect','compareToggle','uncertaintyToggle','referenceDialog'])assert.ok(html.includes(`id="${id}"`));
 assert.equal((html.match(/data-question=/g)||[]).length,4);
 assert.ok(!html.includes('id="ageControls"'));assert.ok(html.includes('assets/brand/leerprestaties_nl.svg'));
 const nl=JSON.parse(fs.readFileSync('05_publication/preview_overlay/locales/nl.json','utf8'));
 const en=JSON.parse(fs.readFileSync('05_publication/preview_overlay/locales/en.json','utf8'));
 assert.deepEqual(Object.keys(nl.seriesLabels).sort(),Object.keys(en.seriesLabels).sort());
 for(const key of Object.keys(nl.seriesLabels)){assert.notEqual(nl.seriesLabels[key],key);assert.notEqual(en.seriesLabels[key],key);}
 box.nl=nl;box.en=en;
 vm.runInContext(`state.locale='nl';state.dict=nl;if(groupName({series_id:'q4_minus_q1'})!=='Verschil: hoge − lage SES')throw Error('NL group label');state.locale='en';state.dict=en;if(groupName({series_id:'q4_minus_q1'})!=='Gap: high − low SES')throw Error('EN group label');if(groupName({series_id:'girl',series_label_en:'Girls + other'})!=='Girls + other')throw Error('Pooled definition overwritten');`,box);
 console.log('PASS bilingual group labels and preserved pooled definitions');
 console.log('PASS five-choice layout, original logo, missing values, benchmark uncertainty and immutable self-contained SVG export');
})().catch(e=>{console.error(e);process.exit(1)});
