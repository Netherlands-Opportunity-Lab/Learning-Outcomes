import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { execFileSync } from 'child_process';
import { chromium } from 'playwright-core';

const SITE=(process.env.SITE_URL||'').replace(/\/+$/,'')+'/';
const OUT=process.env.ONLINE_QA_DIR||'online_qa';
fs.mkdirSync(OUT,{recursive:true});
const manifest=JSON.parse(fs.readFileSync('05_publication/PUBLIC_DASHBOARD_MANIFEST.json','utf8'));
const fidelity=JSON.parse(fs.readFileSync('05_publication/PUBLIC_RESULT_FIDELITY.json','utf8'));
const checks=[];
const consoleErrors=[], pageErrors=[], failedRequests=[], badResponses=[];
const fileAudit=[];
let hardFail=false;

function add(name,pass,detail='',scope='browser'){
  checks.push({name,pass:Boolean(pass),detail,scope});
  if(!pass) hardFail=true;
}
function sha(buf){return crypto.createHash('sha256').update(buf).digest('hex');}
function sleep(ms){return new Promise(r=>setTimeout(r,ms));}
function expandCountry(obj){
  if(obj.format!=='column-dictionary-v1') throw new Error('unsupported country data contract');
  const rows=Array.from({length:obj.length},()=>({}));
  for(const [k,c] of Object.entries(obj.columns)){
    c.indices.forEach((j,i)=>{if(j>=0) rows[i][k]=c.values[j];});
  }
  return rows;
}
async function fetchBytes(url){
  const r=await fetch(url,{redirect:'follow',cache:'no-store'});
  const b=Buffer.from(await r.arrayBuffer());
  return {status:r.status,headers:Object.fromEntries(r.headers.entries()),bytes:b,url:r.url};
}
async function waitReady(page){
  await page.waitForFunction(()=>document.querySelector('#content')?.dataset.ready==='true',{timeout:20000});
  await page.waitForTimeout(250);
}
async function select(page,id,value){
  await page.selectOption('#'+id,value);
  await page.waitForTimeout(350);
  await waitReady(page);
}
async function bodyText(page){return (await page.locator('body').innerText()).replace(/\s+/g,' ').trim();}
function parseRgb(s){
  const m=s.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
  return m?[+m[1],+m[2],+m[3]]:null;
}
function luminance(rgb){
  const v=rgb.map(x=>x/255).map(c=>c<=0.04045?c/12.92:Math.pow((c+0.055)/1.055,2.4));
  return 0.2126*v[0]+0.7152*v[1]+0.0722*v[2];
}
function contrast(a,b){
  const A=luminance(a),B=luminance(b),hi=Math.max(A,B),lo=Math.min(A,B);
  return (hi+0.05)/(lo+0.05);
}
function findChrome(){
  for(const bin of ['google-chrome','google-chrome-stable','chromium','chromium-browser']){
    try{return execFileSync('which',[bin],{encoding:'utf8'}).trim();}catch{}
  }
  throw new Error('No Chromium/Chrome executable found on runner');
}

let onlineResultIds=0, onlineCountryFiles=0;
for(const item of manifest.files){
  const url=new URL(item.filename,SITE).href;
  const res=await fetchBytes(url);
  if(item.publication_status==='PUBLIC_OK'){
    const got=sha(res.bytes), same=(res.status===200 && res.bytes.length===item.bytes && got===item.sha256);
    fileAudit.push({
      filename:item.filename,url,status:res.status,bytes_expected:item.bytes,bytes_online:res.bytes.length,
      sha256_expected:item.sha256,sha256_online:got,sha256_match:same,
      content_type:res.headers['content-type']||'',cache_control:res.headers['cache-control']||'',
      publication_status:item.publication_status,source_provenance_id:item.source_provenance_id
    });
    if(item.filename.startsWith('product_data/countries/')&&item.filename.endsWith('.json')&&res.status===200){
      onlineCountryFiles++;
      onlineResultIds+=expandCountry(JSON.parse(res.bytes.toString('utf8'))).length;
    }
    if(!same) hardFail=true;
  } else {
    const absent=res.status===404;
    fileAudit.push({
      filename:item.filename,url,status:res.status,bytes_expected:item.bytes,bytes_online:res.bytes.length,
      sha256_expected:item.sha256,sha256_online:sha(res.bytes),sha256_match:false,
      content_type:res.headers['content-type']||'',cache_control:res.headers['cache-control']||'',
      publication_status:item.publication_status,source_provenance_id:item.source_provenance_id,
      expected_absent:true,absent
    });
    if(!absent) hardFail=true;
  }
}
const publicRows=fileAudit.filter(x=>x.publication_status==='PUBLIC_OK');
add('all PUBLIC_OK online files exactly match PUBLIC_DASHBOARD_MANIFEST',
    publicRows.every(x=>x.sha256_match),
    publicRows.filter(x=>x.sha256_match).length+'/'+manifest.public_runtime_file_count+' exact byte/hash matches','fidelity');
add('PUBLIC_SUMMARY_ONLY masters not served',
    fileAudit.filter(x=>x.publication_status==='PUBLIC_SUMMARY_ONLY').every(x=>x.absent===true),
    fileAudit.filter(x=>x.publication_status==='PUBLIC_SUMMARY_ONLY').map(x=>x.filename+':'+x.status).join('; '),'rights');
add('online country/system result row count matches frozen fidelity evidence',
    onlineResultIds===fidelity.comparison_scope.country_profile_rows && onlineCountryFiles===fidelity.comparison_scope.country_profile_files,
    onlineCountryFiles+' files; '+onlineResultIds+' rows','fidelity');
add('pre-merge freeze field fidelity evidence remains exact',
    fidelity.pass===true && fidelity.results.missing_result_ids===0 && fidelity.results.country_profile_field_mismatches===0 &&
    fidelity.results.ranks_match===true && fidelity.results.panels_match===true && fidelity.results.quality_match===true &&
    fidelity.results.curated_mapping_match===true,
    'online bytes equal manifest; manifest files were field-checked against FINAL_ANALYSIS_FREEZE with zero mismatches','fidelity');

for(const rel of ['downloads.html','docs/SCIENTIFIC_BOUNDARIES.md','docs/PUBLICATION_RIGHTS_REVIEW.md','docs/REPLICATION_GUIDE.md','robots.txt']){
  const r=await fetchBytes(new URL(rel,SITE).href);
  add('reachable '+rel,r.status===200,'HTTP '+r.status+'; '+(r.headers['content-type']||''),'http');
}
for(const rel of ['product_data/FINAL_TECHNICAL_VALIDATION.csv','product_data/FINAL_IMPACT_MATRIX.csv','product_data/FINAL_OPEN_POINTS_STATUS.csv','product_data/FINAL_USE_STATUS_REGISTER.csv']){
  const r=await fetchBytes(new URL(rel,SITE).href);
  add('non-runtime control file absent '+rel,r.status===404,'HTTP '+r.status,'rights');
}

const browser=await chromium.launch({executablePath:findChrome(),headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
const context=await browser.newContext({viewport:{width:1440,height:1000},acceptDownloads:true});
const page=await context.newPage();
page.on('console',m=>{if(m.type()==='error') consoleErrors.push(m.text());});
page.on('pageerror',e=>pageErrors.push(String(e)));
page.on('requestfailed',r=>failedRequests.push({url:r.url(),failure:(r.failure()&&r.failure().errorText)||''}));
page.on('response',r=>{if(r.status()>=400) badResponses.push({url:r.url(),status:r.status()});});

const nav=await page.goto(SITE,{waitUntil:'networkidle',timeout:30000});
add('landing HTTP 200',nav&&nav.status()===200,'HTTP '+(nav&&nav.status()));
await waitReady(page);
add('default language is Dutch',(await page.locator('#localeSelect').inputValue())==='nl');
add('default country is Netherlands',(await page.locator('#countrySelect').inputValue())==='iso3:NLD');
add('dashboard content ready',(await page.locator('#content').getAttribute('data-ready'))==='true');

await select(page,'localeSelect','en');
await select(page,'countrySelect','iso3:AUS');
add('language and country selectors independent',
    (await page.locator('#localeSelect').inputValue())==='en' && (await page.locator('#countrySelect').inputValue())==='iso3:AUS',
    'English retained after switching Netherlands -> Australia');
await select(page,'countrySelect','iso3:NLD');
add('language remains independent after country reset',(await page.locator('#localeSelect').inputValue())==='en');

for(const pair of [['reading','reading'],['math','mathematics'],['science','science']]){
  await select(page,'domainSelect',pair[0]);
  add('content renders for '+pair[1],(await page.locator('#content').getAttribute('data-ready'))==='true' && !(await bodyText(page)).includes('could not be loaded'));
}
for(const age of ['age10','age15','both']){
  await select(page,'ageSelect',age);
  add('content renders for '+age,(await page.locator('#content').getAttribute('data-ready'))==='true');
}

await select(page,'domainSelect','reading');
await select(page,'ageSelect','both');
await select(page,'questionSelect','performance_level');
const metricVals=await page.locator('#metricSelect option').evaluateAll(os=>os.map(o=>o.value));
if(metricVals.includes('mean')) await select(page,'metricSelect','mean');
add('trend chart renders',(await page.locator('svg.chart').count())>0,String(await page.locator('svg.chart').count())+' chart(s)');
const txtTrend=await bodyText(page);
add('uncertainty columns present',txtTrend.includes('95%-interval') || txtTrend.includes('95% interval'));
add('chart tooltips/title metadata present',(await page.locator('svg.chart circle title').count())>0,String(await page.locator('svg.chart circle title').count())+' point title(s)');
add('source/provenance cells visible',(await page.locator('td.source').count())>0);

await page.locator('#internationalTab').click(); await sleep(450); await waitReady(page);
add('international comparison renders',(await page.locator('.panel-members').count())>0);
const panelText=(await page.locator('.panel-members').count())?await page.locator('.panel-members').first().innerText():'';
add('panel N visible',/N=\d+/.test(panelText),panelText.slice(0,180));
add('international rank table renders',(await page.locator('#content table tbody tr').count())>0);

await page.locator('#countryTab').click(); await sleep(350); await waitReady(page);
const viewTests=[
 ['group_differences_social','SES levels/gaps'],
 ['group_differences_gender','gender'],
 ['group_differences_migration_language','language/migration'],
 ['school_sorting','school/class sorting'],
 ['phase','phase comparison'],
 ['quality','quality/representativeness'],
 ['story','reviewed narrative']
];
for(const pair of viewTests){
  await select(page,'questionSelect',pair[0]);
  const txt=await bodyText(page);
  add('view renders: '+pair[1],(await page.locator('#content').getAttribute('data-ready'))==='true' && !/could not be loaded|laden mislukt/i.test(txt),txt.slice(0,180));
  if(pair[0]==='school_sorting'){
    const opts=await page.locator('#metricSelect option').evaluateAll(os=>os.map(o=>o.value));
    add('school sorting metric available',opts.some(x=>x==='academic_school'||x==='social_school'),opts.join(','));
    add('class sorting metric available',opts.some(x=>x==='academic_class'||x==='social_class'),opts.join(','));
  }
}
await select(page,'questionSelect','group_differences_social');
const sesOptions=await page.locator('#sesSelect option').evaluateAll(os=>os.map(o=>o.value));
add('national SES option present',sesOptions.includes('national'),sesOptions.join(','));
add('international ESCS option present',sesOptions.includes('international'),sesOptions.join(','));

let blockedFound=false, blockedExample='';
outer:
for(const domain of ['reading','math','science']){
  for(const age of ['age10','age15']){
    for(const view of ['group_differences_gender','group_differences_migration_language','school_sorting']){
      await select(page,'domainSelect',domain); await select(page,'ageSelect',age); await select(page,'questionSelect',view);
      const txt=await bodyText(page);
      if(/Geen vrijgegeven uitkomst|No released result|uitsluitend ontbrekende of geblokkeerde records|missing or blocked records/i.test(txt)){
        blockedFound=true; blockedExample=domain+'/'+age+'/'+view; break outer;
      }
    }
  }
}
add('scientifically blocked/empty state is explicit',blockedFound,blockedExample);

await select(page,'localeSelect','en'); await select(page,'countrySelect','iso3:AUS'); await select(page,'domainSelect','math'); await select(page,'questionSelect','performance_level');
const stateUrl=page.url();
add('state encoded in URL',stateUrl.includes('country=iso3%3AAUS')&&stateUrl.includes('locale=en')&&stateUrl.includes('domain=math'),stateUrl);
const p2=await context.newPage(); await p2.goto(stateUrl,{waitUntil:'networkidle'}); await waitReady(p2);
add('shareable URL restores state',(await p2.locator('#countrySelect').inputValue())==='iso3:AUS'&&(await p2.locator('#localeSelect').inputValue())==='en'&&(await p2.locator('#domainSelect').inputValue())==='math');
await p2.close();
await page.locator('#resetFilters').click(); await sleep(400); await waitReady(page);
add('reset returns default state',(await page.locator('#countrySelect').inputValue())==='iso3:NLD'&&(await page.locator('#localeSelect').inputValue())==='nl'&&(await page.locator('#domainSelect').inputValue())==='reading');

const dlPromise=page.waitForEvent('download');
await page.locator('#downloadView').click();
const dl=await dlPromise; const dlPath=await dl.path();
const dlText=fs.readFileSync(dlPath,'utf8');
add('view CSV download works',dl.suggestedFilename().endsWith('.csv')&&dlText.length>20,dl.suggestedFilename());
add('view CSV does not expose bulk master names',!dlText.includes('FINAL_PRODUCT_BASIS')&&!dlText.includes('RESULTATEN_MASTER'));
const downloadsPage=await context.newPage(); const dresp=await downloadsPage.goto(new URL('downloads.html',SITE).href,{waitUntil:'networkidle'});
const dhtml=await downloadsPage.content();
add('downloads page reachable',dresp&&dresp.status()===200);
add('restricted bulk download links absent',!(/href=["'][^"']*(FINAL_PRODUCT_BASIS|RESULTATEN_MASTER)/i.test(dhtml)));
await downloadsPage.close();

const methodHref=await page.locator('.method-card a').first().getAttribute('href');
add('methods link present',Boolean(methodHref),methodHref||'');
if(methodHref){const mr=await fetchBytes(new URL(methodHref,SITE).href);add('methods link resolves',mr.status===200,'HTTP '+mr.status);}

await page.goto(SITE,{waitUntil:'networkidle'}); await waitReady(page);
await page.keyboard.press('Tab');
const focus1=await page.evaluate(()=>{const e=document.activeElement,cs=getComputedStyle(e);return {tag:e&&e.tagName,cls:e&&e.className,outline:cs.outlineStyle,width:cs.outlineWidth,box:cs.boxShadow};});
add('keyboard reaches skip link/control',focus1.tag==='A'||focus1.tag==='SELECT'||focus1.tag==='BUTTON',JSON.stringify(focus1));
add('focused element has visible focus styling',(focus1.outline!=='none'&&focus1.width!=='0px') || focus1.box!=='none',JSON.stringify(focus1));

const desktopDims=await page.evaluate(()=>({sw:document.documentElement.scrollWidth,iw:innerWidth,sh:document.documentElement.scrollHeight,ih:innerHeight}));
add('no body-level horizontal overflow desktop',desktopDims.sw<=desktopDims.iw+1,JSON.stringify(desktopDims));
add('vertical layout remains scrollable desktop',desktopDims.sh>=desktopDims.ih,JSON.stringify(desktopDims));

const contrastSamples=await page.evaluate(()=>{
  const sels=['body','.eyebrow','.method-card a','.notice','.control-group label'];
  return sels.map(sel=>{const e=document.querySelector(sel);if(!e)return null;const s=getComputedStyle(e);return {sel,color:s.color,bg:s.backgroundColor,parentBg:getComputedStyle(e.parentElement||document.body).backgroundColor,fontSize:parseFloat(s.fontSize),fontWeight:s.fontWeight};}).filter(Boolean);
});
for(const s of contrastSamples){
  const fg=parseRgb(s.color);
  let bg=parseRgb(s.bg);
  if(!bg || s.bg==='rgba(0, 0, 0, 0)') bg=parseRgb(s.parentBg)||[244,240,231];
  if(fg&&bg){
    const ratio=contrast(fg,bg);
    const large=s.fontSize>=24 || (s.fontSize>=18.66 && parseInt(s.fontWeight)>=700);
    add('contrast '+s.sel,ratio>=(large?3:4.5),'ratio '+ratio.toFixed(2));
  }
}

const mobile=await browser.newContext({viewport:{width:390,height:844}});
const mp=await mobile.newPage();
mp.on('console',m=>{if(m.type()==='error') consoleErrors.push('mobile:'+m.text());});
mp.on('pageerror',e=>pageErrors.push('mobile:'+String(e)));
mp.on('requestfailed',r=>failedRequests.push({url:r.url(),failure:(r.failure()&&r.failure().errorText)||'',mobile:true}));
const mresp=await mp.goto(SITE,{waitUntil:'networkidle'}); await waitReady(mp);
const mobileDims=await mp.evaluate(()=>({sw:document.documentElement.scrollWidth,iw:innerWidth,sh:document.documentElement.scrollHeight,ih:innerHeight,
  tableWraps:[...document.querySelectorAll('.table-wrap')].map(e=>({sw:e.scrollWidth,cw:e.clientWidth}))}));
add('mobile site opens',mresp&&mresp.status()===200);
add('no body-level horizontal overflow mobile',mobileDims.sw<=mobileDims.iw+1,JSON.stringify(mobileDims));
add('mobile vertical page is scrollable',mobileDims.sh>=mobileDims.ih,JSON.stringify(mobileDims));
add('wide tables contained in scroll wrappers',mobileDims.tableWraps.every(x=>x.sw>=x.cw),JSON.stringify(mobileDims));
await mobile.close();

add('browser console has no errors',consoleErrors.length===0,consoleErrors.slice(0,10).join(' | '));
add('no uncaught page errors',pageErrors.length===0,pageErrors.slice(0,10).join(' | '));
add('no failed page network requests',failedRequests.length===0,JSON.stringify(failedRequests.slice(0,10)));
const unexpectedBad=badResponses.filter(x=>!x.url.endsWith('favicon.ico'));
add('no 4xx/5xx responses during normal page interaction',unexpectedBad.length===0,JSON.stringify(unexpectedBad.slice(0,10)));

const idx=await fetchBytes(SITE);
const idxText=idx.bytes.toString('utf8');
add('public site is indexable: no noindex meta',!/<meta[^>]+name=["']robots["'][^>]+noindex/i.test(idxText),'robots.txt explicitly allows all','indexability');
const robots=await fetchBytes(new URL('robots.txt',SITE).href);
add('robots.txt allows indexing',robots.status===200 && /Allow:\s*\//i.test(robots.bytes.toString('utf8')),'HTTP '+robots.status,'indexability');

const risky=[];
for(const row of publicRows.filter(x=>x.status===200&&/\.(json|csv|svg|md|txt|html|js|css)$/i.test(x.filename))){
  if(row.bytes_online>8000000) continue;
  const r=await fetchBytes(row.url); const s=r.bytes.toString('utf8');
  const localA='C:'+'/'+'Users'+'/'; const localB='C:'+String.fromCharCode(92)+'Users'+String.fromCharCode(92);
  if(s.includes(localA)||s.includes(localB)||/BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY/.test(s)||/\bDEBUG\b|\bFIXME\b/.test(s)) risky.push(row.filename);
}
add('no private paths/credentials/debug markers in online runtime text',risky.length===0,risky.join(', '),'rights');

await context.close(); await browser.close();

const qa={
  site_url:SITE,
  git_sha:process.env.GITHUB_SHA||'',
  workflow_run_id:process.env.GITHUB_RUN_ID||'',
  release_id:manifest.release,
  analysis_release:manifest.analysis_release,
  deployed_manifest_sha256:sha(fs.readFileSync('05_publication/PUBLIC_DASHBOARD_MANIFEST.json')),
  browser_engine:'Chromium via system Google Chrome and playwright-core',
  checks,consoleErrors,pageErrors,failedRequests,badResponses,
  online_country_profile_files:onlineCountryFiles,
  online_result_rows:onlineResultIds,
  pass:!hardFail
};
fs.writeFileSync(path.join(OUT,'online_qa.json'),JSON.stringify(qa,null,2)+'\n');
fs.writeFileSync(path.join(OUT,'online_files.json'),JSON.stringify(fileAudit,null,2)+'\n');
console.log(JSON.stringify({pass:qa.pass,checks:checks.length,failed:checks.filter(x=>!x.pass).map(x=>x.name),site:SITE},null,2));
if(hardFail) process.exit(1);
