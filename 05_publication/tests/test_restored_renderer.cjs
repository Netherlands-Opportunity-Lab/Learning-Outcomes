// No browser or data service needed: exercise the actual rendering functions.
const fs=require('fs'),vm=require('vm'),assert=require('node:assert/strict');
let code=fs.readFileSync('05_publication/preview_overlay/assets/app-shell.js','utf8');
code=code.replace(/^import .*;$/m,'').split('init().catch')[0];
const box={document:{documentElement:{dataset:{base:''}},querySelector:()=>null},window:{innerWidth:1200},DEFAULTS:{},Intl,URLSearchParams,console};
vm.createContext(box);vm.runInContext(code,box);
vm.runInContext(`
state.locale='nl';state.dict={figure:{chartAria:'{title}'}};
const absent=[{estimate:550,year:2021,ci_low:null,ci_high:''},{estimate:540,year:2016}];
const axis=axisDomain(absent,{unit:'score_points'});
if(axis.lo<530)throw Error('Absent intervals incorrectly extended the axis to zero');
if(chartHtml(absent,{unit:'score_points'}).includes('class="ci-line"'))throw Error('Absent interval rendered');
const benchmark=[{estimate:550,year:2021,ci_low:1,ci_high:999,series_role:'comparator'}];
if(chartHtml(benchmark,{unit:'score_points'}).includes('class="ci-line"'))throw Error('Benchmark interval rendered');
if(axisDomain(benchmark,{unit:'score_points'}).lo<540)throw Error('Benchmark interval affected axis');
if(fmtNumber(null)!=='—'||fmtNumber('')!=='—')throw Error('Missing values became zero');
`,box);
const html=fs.readFileSync('05_publication/preview_overlay/index.html','utf8');
assert.equal((html.match(/class="question-card"/g)||[]).length,4);
assert.ok(html.includes('id="explorer" hidden'));
assert.ok(html.includes('class="breadcrumb"'));
assert.ok(!html.includes('guided-builder'));
assert.ok(fs.existsSync('05_publication/preview_overlay/assets/router.mjs'));
console.log('PASS restored October layout, missing intervals and no benchmark CI');
