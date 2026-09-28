'use strict';
// Uses frozen aggregates. No rank, panel, pupil-level or contrast estimation.
const defaults={country:'iso3:NLD',age:'both',view:'performance_level',tab:'country',locale:'nl',domain:'reading',panel:'',year:'all',metric:'mean',group:'all',variant:'preferred',ses:'national'};
const S={...defaults,meta:null,rows:[],rendered:[],cache:new Map(),loadId:0};
const $=s=>document.querySelector(s),esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const t=(a,b)=>S.locale==='nl'?a:b,finite=v=>v!==null&&v!==undefined&&v!==''&&Number.isFinite(Number(v));
const fmt=(v,d=1)=>finite(v)?new Intl.NumberFormat(S.locale==='nl'?'nl-NL':'en-GB',{maximumFractionDigits:d,minimumFractionDigits:d}).format(+v):'—';
const canUse=r=>['conditional','descriptive'].includes(r.status)&&finite(r.estimate);
const name=id=>{const c=S.meta.countries.find(x=>x.country_id===id);return c?(S.locale==='nl'?c.country_name_nl:c.country_name_en):id;};
const labels={mean:['Gemiddelde score','Mean score'],low:['Onder de prestatiedrempel','Below achievement threshold'],top:['Topprestaties','Top performers'],p10:['P10','P10'],p50:['Mediaan','Median'],p90:['P90','P90'],p90_p10:['P90 min P10','P90 minus P10'],sd:['Standaarddeviatie','Standard deviation'],mean_change:['Gepubliceerde scoreverandering','Published score change'],low_change:['Gepubliceerde verandering lage prestaties','Published low-performance change'],academic_school:['Prestaties tussen scholen','Achievement between schools'],social_school:['Sociale rang tussen scholen','Social rank between schools'],academic_class:['Prestaties tussen klassen totaal','Achievement between classes total'],social_class:['Sociale rang tussen klassen totaal','Social rank between classes total'],language_sorting:['Taalscheiding tussen scholen','Language sorting between schools'],migration_sorting:['Migratiescheiding tussen scholen','Migration sorting between schools'],home_language_other_share:['Andere thuistaal binnen migratiegroepen','Other home language within migrant groups'],share:['Groepsaandeel','Group share']};
const groups={total:['Alle leerlingen','All students'],q1:['Laagste kwartiel Q1','Bottom quarter Q1'],q2:['Tweede kwartiel Q2','Second quarter Q2'],q3:['Derde kwartiel Q3','Third quarter Q3'],q4:['Hoogste kwartiel Q4','Top quarter Q4'],q4_minus_q1:['Verschil Q4 min Q1','Difference Q4 minus Q1'],girl:['Meisjes','Girls'],boy:['Jongens','Boys'],boy_minus_girl:['Jongens min meisjes','Boys minus girls'],immigrant:['Met migratieachtergrond','Immigrant background'],non_immigrant:['Zonder migratieachtergrond','Non-immigrant background'],immigrant_minus_non:['Met min zonder migratieachtergrond','Immigrant minus non-immigrant'],first_generation:['Eerste generatie','First generation'],second_generation:['Tweede generatie','Second generation'],always:['Altijd toetstaal thuis','Always test language at home'],almost:['Bijna altijd toetstaal thuis','Almost always test language at home'],sometimes:['Soms toetstaal thuis','Sometimes test language at home'],never:['Nooit toetstaal thuis','Never test language at home'],always_almost:['Altijd of bijna altijd Nederlands','Always or almost always Dutch'],sometimes_never:['Soms of nooit Nederlands','Sometimes or never Dutch']};
const label=x=>labels[x]?t(...labels[x]):x.replaceAll('_',' '),gl=x=>groups[x]?t(...groups[x]):x.replaceAll('_',' ');
const notice=x=>`<div class="notice">${x}</div>`;
const table=(heads,rows)=>`<div class="table-wrap"><table><thead><tr>${heads.map(x=>`<th scope="col">${x}</th>`).join('')}</tr></thead><tbody>${rows.join('')}</tbody></table></div>`;
const card=(title,body,sub='')=>`<article class="card span12"><h3>${title}</h3><p class="sub">${sub}</p>${body}</article>`;
const interval=r=>finite(r.ci_low)&&finite(r.ci_high)?`${fmt(r.ci_low)} ${t('tot','to')} ${fmt(r.ci_high)}`:'—';
function normalize(r){
 const x={...r};let stat=x.stat,group=x.group||'total',factor=1,complement=false;
 if(stat==='overall_mean'||stat==='mean_score')stat='mean';
 if(stat==='overall_baseline'||stat==='proficiency_baseline'){stat='low';complement=true;}
 if(stat==='overall_top')stat='top';
 if(stat==='score_gap'){stat='mean';group='q4_minus_q1';x.family='ses';}
 const q=/^(q[14])_(mean|baseline|top)$/.exec(stat);if(q){group=q[1];stat=q[2]==='baseline'?'low':q[2];complement=q[2]==='baseline';x.family='ses';}
 const g=/^gender_(girl|boy|boy_minus_girl)_(mean|low|top)$/.exec(stat);if(g){group=g[1];stat=g[2];x.family='gender';}
 if(x.stat.includes('sorting_share')){stat=x.stat.startsWith('academic')?(x.stat.includes('classroom')?'academic_class':'academic_school'):(x.stat.includes('classroom')?'social_class':'social_school');x.spec=x.stat.includes('modal')?'modal-ISCED':'all-target';if(x.stat.includes('raw'))stat='raw_social';}
 if(x.stat==='theil_h')stat=x.family;
 if(x.unit?.startsWith('proportion'))factor=100;
 if(complement){if(finite(x.estimate))x.estimate=(factor===100?100:100)-factor*x.estimate;const lo=x.ci_low,hi=x.ci_high;x.ci_low=finite(hi)?100-factor*hi:null;x.ci_high=finite(lo)?100-factor*lo:null;}
 else for(const k of ['estimate','ci_low','ci_high'])if(finite(x[k]))x[k]*=factor;
 if(finite(x.se))x.se*=factor;
 if(factor===100||complement)x.unit=group.includes('minus')?'percentage_points':'percent';
 x.transform=complement?'100 minus source baseline (percentage scale)':factor===100?'100 × source proportion':'identity';
 if(x.id.startsWith('official_timss_language:')||x.id.startsWith('official_pirls_language:')){x.family='language';x.variant='official';}
 x.metric=stat;x.group=group;return x;
}
async function json(p){const r=await fetch(p);if(!r.ok)throw new Error(`${r.status}: ${p}`);return r.json();}
function expandCountry(a){if(Array.isArray(a))return a;if(a.format!=='column-dictionary-v1')throw Error('Unsupported country data contract');const rows=Array.from({length:a.length},()=>({}));for(const [k,c]of Object.entries(a.columns))c.indices.forEach((j,i)=>{if(j>=0)rows[i][k]=c.values[j]});return rows;}
async function country(id){if(!S.cache.has(id))S.cache.set(id,json(`product_data/countries/${id.replaceAll(':','_')}.json`).then(a=>expandCountry(a).map(normalize)));return S.cache.get(id);}
function options(node,rows,value){node.innerHTML=rows.map(([v,n])=>`<option value="${esc(v)}">${esc(n)}</option>`).join('');if(rows.some(x=>x[0]===value))node.value=value;else if(rows.length)node.value=rows[0][0];return node.value;}
function families(){return {performance_level:['levels'],distribution:['distribution'],group_differences_social:['ses'],group_differences_gender:['gender'],school_sorting:['sorting'],group_differences_migration_language:['language','migration','language_sorting','migration_sorting']}[S.view]||[];}
function phaseOK(r){return S.age==='both'||(S.age==='age15'?r.survey==='PISA':['PIRLS','TIMSS'].includes(r.survey));}
function initialRows(rows){return rows.filter(r=>phaseOK(r)&&(r.domain===(S.domain==='math'?'mathematics':S.domain)||r.domain==='background')&&families().includes(r.family));}
function preferred(rows){
 if(S.variant!=='preferred')return rows.filter(r=>r.variant===S.variant);
 return rows.filter(r=>{
  if(['language_sorting','migration_sorting'].includes(r.family))return r.variant==='rc1';
  if(r.family==='language')return r.variant==='official';
  if(r.family==='sorting')return r.variant==='sorting_specs';
  if(r.survey==='PISA')return r.variant==='official';
  if(r.survey==='PIRLS')return r.family==='gender'?r.variant==='official':r.variant==='rc1'&&!r.id.startsWith('data/COMPARABLE_MEANS');
  return r.variant==='v6';
 });
}
function selectedRows(rows){
 let r=preferred(initialRows(rows));
 if(S.view==='group_differences_social')r=r.filter(x=>S.ses==='international'?x.definition==='international_ESCS':x.definition!=='international_ESCS');
 return r;
}
function rankWaveMeta(p,w){
 const wave=String(w),id=p.panel_id||'';
 if(wave==='age10')return {survey:'PIRLS',year:'2021',label:'PIRLS 2021 · '+t('groep 6 / vierde leerjaar','fourth grade')};
 if(wave==='age15')return {survey:'PISA',year:'2025',label:'PISA 2025 · '+t('15 jaar','age 15')};
 const survey=(wave.match(/PISA|PIRLS|TIMSS/)||id.match(/PISA|PIRLS|TIMSS/)||[''])[0],year=(wave.match(/\d{4}/)||[''])[0];
 return {survey,year,label:survey+' '+year};
}
function rankPhaseOK(p,w){const x=rankWaveMeta(p,w);return S.age==='both'||(S.age==='age15'?x.survey==='PISA':['PIRLS','TIMSS'].includes(x.survey));}
function panelApplicable(p){
 const id=p.panel_id||'',dom=S.domain==='math'?'mathematics':S.domain,m=p.metric||'';
 if(!(id.toLowerCase().includes(dom.toLowerCase())||S.domain==='reading'&&!/TIMSS|mathematics|science/.test(id)))return false;
 const map={mean:['mean','overall_mean','reading'],low:['low_total'],p90_p10:['p90_p10_total'],academic_school:['academic_school_share','academic_school_sorting_share'],social_school:['social_rank_school_share','social_rank_school_sorting_share']};
 if(S.view==='phase')return /CURRENT|common_age/.test(id+' '+p.type)&&m==='mean';
 if(S.view==='group_differences_social')return S.ses==='national'&&['mean_q1','mean_q4','mean_q4_minus_q1','social_score_gap','social_proficiency_gap'].includes(m);
 if(S.view==='school_sorting')return (map[S.metric]||[]).includes(m);
 if(['group_differences_gender','group_differences_migration_language','quality','story'].includes(S.view))return false;
 return (map[S.metric]||[]).includes(m);
}
function refreshFilters(){
 $('#sesGroup').hidden=S.view!=='group_differences_social';
 $('#panelGroup').hidden=S.tab!=='international'&&S.view!=='phase';
 for(const id of ['metricGroup','groupGroup','yearGroup','variantGroup'])$('#'+id).hidden=['story','quality','phase'].includes(S.view);
 let rows=selectedRows(S.rows),metrics=[...new Set(rows.map(r=>r.metric))].filter(x=>labels[x]);
 const preferredOrder=['mean','low','top','mean_change','low_change','p10','p50','p90','p90_p10','sd','academic_school','social_school','academic_class','social_class','language_sorting','migration_sorting','home_language_other_share','share'];
 metrics.sort((a,b)=>preferredOrder.indexOf(a)-preferredOrder.indexOf(b));
 S.metric=options($('#metricSelect'),metrics.map(x=>[x,label(x)]),S.metric);
 rows=rows.filter(r=>r.metric===S.metric);let yrs=[...new Set(rows.map(r=>r.year))].sort((a,b)=>+a-+b);
 S.year=options($('#yearSelect'),[['all',t('Alle meetjaren','All survey years')],...yrs.map(x=>[x,x])],S.year);
 S.group=options($('#groupSelect'),[['all',t('Alle groepen en verschillen','All groups and differences')],...[...new Set(rows.map(r=>r.group))].map(x=>[x,gl(x)])],S.group);
 let pp=Object.values(S.meta.panels).filter(panelApplicable).filter(p=>S.ranks.some(r=>r.panel_id===p.panel_id&&rankPhaseOK(p,r.wave)));
 if(S.view==='phase')pp=pp.filter(p=>/CURRENT|LATEST|latest|PIRLS2021_PISA2025/.test(p.panel_id));
 pp.sort((a,b)=>Number(!a.panel_id.includes('CURRENT'))-Number(!b.panel_id.includes('CURRENT'))||Number(a.panel_id.includes('STRICT'))-Number(b.panel_id.includes('STRICT')));
 S.panel=options($('#panelSelect'),pp.map(p=>[p.panel_id,`${p.panel_id} (N=${p.n})`]),S.panel);
}
function selectedWithGroups(rows){
 let r=selectedRows(rows).filter(x=>x.metric===S.metric&&(S.year==='all'||x.year===S.year));
 if(S.group==='all'&&S.ses==='international'&&S.view==='group_differences_social')r=r.filter(x=>!/^d\d+$/.test(x.group));
 if(S.group!=='all'){
  const related={q4_minus_q1:['q1','q4'],boy_minus_girl:['boy','girl'],immigrant_minus_non:['immigrant','non_immigrant']};
  const ids=[S.group,...(related[S.group]||[])];r=r.filter(x=>ids.includes(x.group));
 }
 return r;
}
function resultTable(rows){
 S.rendered.push(...rows);
 return table([t('Jaar / groep','Year / group'),t('Schatting','Estimate'),'SE',t('95%-interval','95% interval'),t('Status en bron','Status and source')],rows.map(r=>`<tr><td>${esc(r.start_year?`${r.start_year}–${r.year}`:r.year)}<br>${esc(gl(r.group))}${r.spec?'<br>'+esc(r.spec):''}</td><td>${canUse(r)?fmt(r.estimate):'—'}</td><td>${canUse(r)?fmt(r.se,2):'—'}</td><td>${canUse(r)?interval(r):'—'}</td><td class="source">${esc(r.status)}<br><span class="raw-id">${esc(r.id)}</span><br>${esc(r.source)} ${esc(r.table)} ${esc(r.cell)}<details><summary>${t('Definitie en beperking','Definition and limitation')}</summary>${esc(r.definition)}<br>${esc(r.population)}<br>${esc(r.note)}<br>${esc(r.method)}${r.sample?'<br>'+esc(JSON.stringify(r.sample)):''}</details></td></tr>`));
}
function chart(rows){
 const usable=rows.filter(canUse);if(!usable.length)return '';
 const W=920,H=355,p={l:78,r:26,t:25,b:55},series=new Map();
 for(const r of rows){const key=[r.group,r.spec||'',r.definition,r.edition,r.variant,r.start_year].join('|');if(!series.has(key))series.set(key,[]);series.get(key).push(r);}
 const years=[...new Set(rows.map(r=>+r.year).filter(Number.isFinite))].sort((a,b)=>a-b),values=usable.flatMap(r=>[r.estimate,r.ci_low,r.ci_high].filter(finite).map(Number));
 let lo=Math.min(...values),hi=Math.max(...values),gap=hi-lo||10;lo-=gap*.12;hi+=gap*.12;
 const xa=years[0],xb=years.at(-1),sx=x=>p.l+(x-xa)/(xb-xa||1)*(W-p.l-p.r),sy=y=>p.t+(hi-y)/(hi-lo)*(H-p.t-p.b);
 const colors=['#315D8A','#77618C','#267F7C','#93670D','#AA4D35','#657A47','#303D4A'];let svg='',legend='';
 for(let i=0;i<5;i++){let y=lo+(hi-lo)*i/4;svg+=`<path d="M${p.l},${sy(y)}H${W-p.r}" stroke="#DBE0E2"/><text x="${p.l-10}" y="${sy(y)+5}" text-anchor="end">${fmt(y,lo>-1&&hi<1?2:0)}</text>`;}
 let k=0;for(const vals of series.values()){
  vals.sort((a,b)=>+a.year-+b.year);const r0=vals[0],fixed={q1:'#A87900',q2:'#657A47',q3:'#267F7C',q4:'#755A99',girl:'#755A99',boy:'#315D8A',total:'#315D8A',non_immigrant:'#8B949C',immigrant:'#315D8A'},color=r0.spec==='modal-ISCED'?'#A87900':fixed[r0.group]||colors[k%colors.length],label=gl(r0.group)+(r0.spec?' · '+r0.spec:'')+(r0.start_year?' · '+r0.start_year+'–'+r0.year:'');k++;
  legend+=`<span style="--series:${color}">${esc(label)}</span>`;let path='',pen=false;
  for(const r of vals){if(!canUse(r)){pen=false;continue;}let x=sx(+r.year);if(years.length===1)x=p.l+(k)/(series.size+1)*(W-p.l-p.r);const y=sy(r.estimate);
   path+=(pen?' L':'M')+x+','+y;pen=true;
   if(finite(r.ci_low)&&finite(r.ci_high))svg+=`<path d="M${x},${sy(r.ci_low)}V${sy(r.ci_high)}M${x-4},${sy(r.ci_low)}h8M${x-4},${sy(r.ci_high)}h8" fill="none" stroke="${color}"/>`;
   svg+=`<circle cx="${x}" cy="${y}" r="4.5" fill="${color}"><title>${esc(label)} ${r.year}: ${fmt(r.estimate)}; SE ${fmt(r.se,2)}; ${esc(r.id)}</title></circle>`;
  }
  if(years.length>1)svg+=`<path d="${path}" stroke="${color}" stroke-width="2.5" fill="none"/>`;
 }
 svg+=years.map(y=>`<text x="${years.length===1?W/2:sx(y)}" y="${H-20}" text-anchor="middle">${y}</text>`).join('');
 const unit=usable[0].unit==='percent'?'%':usable[0].unit==='percentage_points'?t('procentpunt','percentage points'):usable[0].unit==='score_points'?`${usable[0].survey} ${t('scorepunten','score points')}`:usable[0].unit;
 return `<p class="mini">${esc(unit)}</p><svg class="chart" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" role="img" aria-label="${esc(label(S.metric))}"><title>${esc(label(S.metric))}</title>${svg}</svg><div class="chart-legend">${legend}</div>`;
}
function familyNote(){
 const notes={performance_level:['PISA onder niveau 2; PIRLS/TIMSS onder 475. De drempels en toetsschalen zijn niet gelijk.','PISA below Level 2; PIRLS/TIMSS below 475. Thresholds and scales are not equivalent.'],distribution:['Prestatiepercentielen zijn geen sociale groepen. Iedere survey en ieder vak heeft een eigen schaal.','Achievement percentiles are not social groups. Each survey and subject has its own scale.'],group_differences_social:['Nationale groepen gebruiken de verdeling binnen het land; internationale ESCS-groepen delen grenzen tussen landen. Boeken thuis en ESCS meten verschillende achtergrondconstructen. Bekijk groepsniveaus naast de kloof.','National groups use the distribution within each country; international ESCS groups share cross-country cutpoints. Books at home and ESCS measure different background constructs. Read group levels alongside gaps.'],group_differences_gender:['Categorieën volgen de bron. Officiële cijfers vervangen foutief gecodeerde eigen groepen. Verschillen zijn beschrijvend; een ontbrekend veld is geen nul.','Categories follow the source. Official results replace miscoded project groups. Differences are descriptive; a missing field is not zero.'],school_sorting:['School- en totale klasvariantie zijn verschillende maten. Trek ze niet af als een binnen-schoolcomponent. Beide schoolspecificaties blijven behouden; een causale selectieclaim is niet mogelijk. De sociale maat is geen onafhankelijke uitkomst per vak.','School variance and total class variance are different measures. Do not subtract them as a within-school component. Both school specifications are retained; no causal selection claim is supported. The social measure is not independent across subjects.'],group_differences_migration_language:['Taalomgeving en migratieachtergrond zijn afzonderlijke dimensies. Een andere thuistaal bewijst geen onvoldoende taalbeheersing. Theil H is geen prestatievariantie. Deze analyses behouden hun verdiepingsstatus.','Home language and migration background are separate dimensions. Another home language does not imply poor language proficiency. Theil H is not achievement variance. These analyses retain their supplementary status.']};return notes[S.view]?t(...notes[S.view]):'';
}
function countryView(){
 const rows=selectedWithGroups(S.rows),keys=new Map();
 for(const r of rows){const key=[r.survey,r.edition,r.variant,r.definition,r.unit,r.start_year,r.group.includes('minus')?'gap':'level'].join('|');if(!keys.has(key))keys.set(key,[]);keys.get(key).push(r);}
 if(!rows.length)return notice(t('Geen vrijgegeven uitkomst voor deze combinatie. Voor zelfstandige PISA-prestaties naar thuistaal en voor diverse basisschool-migratiegroepen is de benodigde vergelijkbare tabel nog niet afgerond. Dit is geen nuluitkomst. Probeer een andere uitkomst of raadpleeg de dekking.','No released result for this combination. Standalone PISA achievement by home language and several primary-school migration groups remain unresolved. This is not a zero result. Choose another outcome or consult coverage.'));
 let html=notice(esc(familyNote()));
 for(const rr of keys.values()){
  const r=rr[0],supp=rr.filter(canUse),caveats=[...new Set(rr.map(x=>x.note).filter(Boolean))];
  const definition=r.survey==='PISA'?t('15 jaar, onderwijsdoelpopulatie','Age 15, enrolled target population'):t('Vierde formele leerjaar; Nederland groep 6','Fourth formal grade; Netherlands groep 6');
  html+=card(`${esc(r.survey)} · ${esc(label(S.metric))}`,`<div class="result-status">${t('Voorwaardelijke / beschrijvende analyse','Conditional / descriptive analysis')}</div>${supp.length?chart(rr):notice(t('Deze bron bevat uitsluitend ontbrekende of geblokkeerde records. Er wordt geen resultaatfiguur getoond.','This source contains only missing or blocked records. No result chart is shown.'))}<p class="mini">${t('Puntintervallen waar beschikbaar. Geen impliciete toets van veranderingen.','Point intervals where available. No implied test of changes.')} ${rr.some(x=>canUse(x)&&!finite(x.se))?t('Bij één of meer punten is de SE niet vrijgegeven of niet gepubliceerd.','One or more points have no released or published SE.'):''}</p><details open><summary>${t('Waarden onzekerheid en bronregels','Values uncertainty and source records')} (${rr.length})</summary>${resultTable(rr)}</details><details><summary>${t('Beperkingen van deze bron','Limitations of this source')}</summary>${caveats.map(x=>'<p>'+esc(x)+'</p>').join('')}</details>`,`${definition}. ${esc(r.edition)}. ${esc(r.definition)}.`);
 }
 return html;
}
function panelInfo(p){return `<details open class="panel-members"><summary>${t('Landenpanel','Country panel')} N=${esc(p.n)}</summary><p>${esc(p.panel_id)}</p><p>${esc(p.admission_rule||p.inclusion_rule||p.purpose||'')}</p><p>${esc(p.quality_rule||p.exclusion_rule||'')}</p><p>${(p.member_ids||[]).map(x=>esc(name(x))).join('; ')}</p><p>${esc(p.use_note||'')}</p></details>`;}
function internationalView(){
 const p=S.meta.panels[S.panel];if(!p)return notice(t('Voor deze vergelijking is geen passend vastgelegd panel beschikbaar.','No applicable registered panel is available for this comparison.'));
 let rs=S.ranks.filter(r=>r.panel_id===S.panel);const waves=[...new Set(rs.map(r=>r.wave))];
 let html=notice(t('Alle rangen en intervallen zijn vooraf vastgelegd voor het volledige benoemde panel. Filteren of een ander focusland kiezen verandert de rang niet. Overlappende rangintervallen zijn geen formele toets op rangverschillen.','All ranks and intervals are frozen for the complete named panel. Filtering or choosing another focus country does not change ranks. Overlapping rank intervals do not formally test rank differences.'))+panelInfo(p);
 if(!(p.member_ids||[]).includes(S.country))html+=notice(t('Het gekozen land behoort niet tot dit panel. De volledige panelresultaten blijven zichtbaar; er wordt geen rang voor dit land geconstrueerd.','The selected country is not a member of this panel. Full panel results remain visible; no rank is constructed for this country.'));
 for(const wave of waves){const waveMeta=rankWaveMeta(p,wave);if(S.year!=='all'&&waveMeta.year!==S.year)continue;if(!rankPhaseOK(p,wave))continue;const a=rs.filter(r=>r.wave===wave).sort((x,y)=>+x.point_rank-+y.point_rank);S.rendered.push(...a);const gap=/gap|minus_q1/.test(p.metric||p.panel_id);const warnings=[...new Set(a.map(x=>x.use_note).filter(Boolean))];html+=warnings.map(x=>notice(esc(x))).join('');html+=card(`${esc(waveMeta.label)} · ${esc(p.metric||'mean')}`,table([t('Stelsel','System'),t('Schatting','Estimate'),'SE',t('Rang','Rank'),t('Ranginterval','Rank interval')],a.map(r=>`<tr class="${r.country_id===S.country?'selected-row':''}"><td>${esc(name(r.country_id))}</td><td>${fmt(r.estimate)}</td><td>${fmt(r.se,2)}</td><td>${fmt(r.point_rank,0)} / ${esc(r.n)}</td><td>${fmt(r.rank_best,0)}–${fmt(r.rank_worst,0)}</td></tr>`)),t(gap?'Rang 1 = kleinste getekende kloof; bekijk ook de groepsniveaus onder Landontwikkeling.':p.rank_direction==='lowest'?'Rang 1 = kleinste waarde van de benoemde maat. Dit is geen algemene kwaliteitsrang.':p.rank_direction==='highest'?'Rang 1 = hoogste prestatieniveau binnen dit volledige panel.':'Rangrichting niet gecontroleerd; geen rangclaim.',p.rank_direction==='lowest'?'Rank 1 is the smallest value of the named measure; this is not an overall quality ranking. Read group levels alongside gaps.':'Rank 1 is the highest achievement level within the complete panel.'));}
 return html;
}
function qualityView(){const r=S.quality.filter(x=>x.country_id===S.country&&phaseOK(x));S.rendered.push(...r);return notice(t('Steekproef-SE omvat geen volledige onzekerheid door uitsluiting of non-respons. Ontbrekende kwaliteitsvelden betekenen onbekend.','Sampling SE does not include all uncertainty from exclusion or non-response. Missing quality fields mean unknown.'))+table(['Survey',t('Jaar','Year'),t('Uitsluiting %','Exclusion %'),t('Schoolrespons vóór %','School response before %'),t('Na vervanging %','After replacement %'),t('Leerlingrespons %','Student response %'),t('Bronwaarschuwing','Source warning')],r.map(x=>`<tr><td>${esc(x.survey)}</td><td>${esc(x.year)}</td><td>${fmt(x.overall_exclusion_rate_pct)}</td><td>${fmt(x.school_response_before_pct)}</td><td>${fmt(x.school_response_after_pct)}</td><td>${fmt(x.student_response_pct)}</td><td class="source">${esc(x.caveat_ids)}</td></tr>`));}
function storyView(){
 if(S.country!=='iso3:NLD')return notice(t('Deze verhaallijn is inhoudelijk beoordeeld voor Nederland. Kies Landontwikkeling of Internationale vergelijking voor de gegevens van het gekozen land.','This narrative was reviewed for the Netherlands. Choose Country trends or International comparison for the selected country.'));
 return notice(t('De Nederlandse verhaallijn volgt het gecontroleerde presentatieregister. Verdieping behoudt de oorspronkelijke appendixstatus. Brongegevens zijn Nederlandstalig.','The Netherlands narrative follows the reviewed presentation register. Supplementary analyses retain appendix status. Source figures are in Dutch.'))+S.curated.slides.filter(x=>x.charts.length||x.tables.length).map(s=>{const id='G'+String(s.number).padStart(2,'0');return card(esc(s.title),`<p class="result-status">${s.main?t('Beleidsdeck hoofdinhoud, met bronbeperkingen','Policy deck main content, with source limitations'):t('Verdieping met oorspronkelijke appendixstatus','Supplement retaining original appendix status')}</p><img class="figure-preview" src="product_figures/${id}.svg" alt="${esc(s.title)}" loading="lazy"><p><a href="product_figures/${id}.svg" download>SVG</a> · <a href="product_figures/${id}_data.csv" download>CSV</a></p><details><summary>${t('Bron en interpretatie','Source and interpretation')}</summary><p>${esc(s.caveat)}</p><p>${esc(s.source)}</p><p>${esc(s.register_ids.join(', '))}</p></details>`,esc(s.subtitle));}).join('');
}
function phaseView(){
 let html=notice(t('Dit zijn systeemvergelijkingen, geen gevolgde cohorten. PIRLS 2021 en TIMSS 2023 worden ieder afzonderlijk naast PISA 2025 gezet. Scorepunten en achtergrondconstructen zijn niet identiek. TIMSS-jaarkoppelingen worden niet uit PIRLS afgeleid.','These are system comparisons, not followed cohorts. PIRLS 2021 and TIMSS 2023 are each compared separately with PISA 2025. Score scales and background constructs differ. TIMSS pairings are not inferred from PIRLS.'))+internationalView();
 const inst=S.institutions.filter(r=>Object.values(r).some(v=>v===S.country||v===name(S.country)||v==='Netherlands'&&S.country==='iso3:NLD'));
 html+=card(t('Institutionele context','Institutional context'),inst.length?inst.map(r=>`<p>${t('Eerste plaatsing van de meerderheid in verschillende programma’s rond','First majority placement into different programmes around')} ${esc(r.first_majority_placement_age)} ${t('jaar','years')}.</p><p>${esc(r.definition)}</p><p><a href="${esc(r.url)}">${esc(r.source)}, ${esc(r.table)}</a></p>`).join(''):notice(t('Geen gecontroleerde institutionele rij gekoppeld voor dit stelsel. Dit betekent niet dat de informatie nergens bestaat.','No reviewed institutional record is linked for this system. This does not imply the information does not exist.')),t('OECD werkdocument 289, 2023. Beschrijvende bronsnapshot; geen getoetste verklaring van de uitkomsten.','OECD Working Paper 289, 2023. Descriptive source snapshot; not a tested explanation of outcomes.'));return html;
}
function localize(){
 document.documentElement.lang=S.locale;document.querySelectorAll('[data-nl]').forEach(e=>e.textContent=e.dataset[S.locale]);
 const pairs={countryLabel:['Land of onderwijssysteem','Country or education system'],ageLabel:['Onderwijsfase','Education phase'],questionLabel:['Onderwerp','Topic'],domainLabel:['Vak','Subject'],localeLabel:['Taal','Language'],panelLabel:['Vastgelegd landenpanel','Registered country panel'],yearLabel:['Meetjaar','Survey year'],metricLabel:['Uitkomst','Outcome'],groupLabel:['Groep','Group'],variantLabel:['Bron en kwaliteitsvariant','Source and quality variant'],sesLabel:['Sociale indeling','Social grouping'],countryTab:['Landontwikkeling','Country trends'],internationalTab:['Internationale vergelijking','International comparison'],downloadView:['Download alle getoonde rijen CSV','Download all displayed rows CSV'],downloadSvg:['Download eerste grafiek SVG','Download first chart SVG'],copyLink:['Kopieer filterlink','Copy filter link'],resetFilters:['Filters terugzetten','Reset filters'],methodTitle:['Hoe lees je dit','How to read this']};
 for(const [id,v]of Object.entries(pairs))$('#'+id).textContent=t(...v);
 options($('#countrySelect'),S.meta.countries.map(c=>[c.country_id,name(c.country_id)]).sort((a,b)=>a[1].localeCompare(b[1])),S.country);
 const variants={preferred:['Passende bron per survey','Appropriate source per survey'],official:['Officiële tabellen','Official tables'],v6:['V6 technisch gecontroleerd','V6 technically reviewed'],rc1:['RC1 bewaarde leesanalyse','RC1 preserved reading analysis'],sorting_specs:['Beide schoolspecificaties','Both school specifications']};
 for(const o of $('#variantSelect').options)if(variants[o.value])o.textContent=t(...variants[o.value]);
 $('#countryTitle').textContent=name(S.country);$('#heroText').textContent=t('Lezen, rekenen en science. Fasen en toetsschalen blijven gescheiden.','Reading, mathematics and science. Education phases and test scales remain separate.');$('#releaseBadge').textContent='PRODUCTEN_20260927_S4';
 $('#countryTab').classList.toggle('active',S.tab==='country');$('#internationalTab').classList.toggle('active',S.tab==='international');$('#countryTab').setAttribute('aria-selected',String(S.tab==='country'));$('#internationalTab').setAttribute('aria-selected',String(S.tab==='international'));
 $('#methodText').textContent=t('Beschikbare gecontroleerde aggregaten. Iedere lijn behoudt één broneditie en definitie. Niveaus, kloven en veranderingen hebben hun eigen onzekerheid. Geen nieuwe leerlingberekeningen.','Available reviewed aggregates. Each line retains one source edition and definition. Levels, gaps and changes each have their own uncertainty. No new student-level estimation.');
}
function url(){const q=new URLSearchParams();for(const k of Object.keys(defaults))q.set(k,S[k]);history.replaceState(null,'','?'+q);}
async function render(){
 const ticket=++S.loadId;$('#content').dataset.ready='loading';$('#content').innerHTML='<p class="loading">'+t('Gegevens laden…','Loading data…')+'</p>';
 try{S.rows=await country(S.country);if(ticket!==S.loadId)return;localize();refreshFilters();S.rendered=[];
 $('#statusStrip').innerHTML=S.country==='iso3:NLD'?notice(t('Nederland: uitsluiting en non-respons begrenzen de interpretatie. De intervallen dekken die mogelijke vertekening niet volledig.','Netherlands: exclusions and non-response limit interpretation. Intervals do not fully cover potential bias.')):'';
 let html=S.view==='quality'?qualityView():S.view==='story'?storyView():S.view==='phase'?phaseView():S.tab==='international'?internationalView():countryView();
 $('#content').innerHTML=html;$('#content').dataset.ready='true';$('#downloadSvg').disabled=!$('#content svg.chart');url();window.__dashboard={state:S,selectedWithGroups,canUse,normalize};
 }catch(e){$('#content').innerHTML=notice(t('Het gegevensbestand kon niet worden geladen: ','The data file could not be loaded: ')+esc(e.message));$('#content').dataset.ready='error';console.error(e);}
}
function download(text,type,filename){const url=URL.createObjectURL(new Blob([text],{type})),a=document.createElement('a');a.href=url;a.download=filename;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
function csvExport(){const rows=S.rendered,keys=[...new Set(rows.flatMap(x=>Object.keys(x)))],quote=v=>'"'+(typeof v==='object'&&v!==null?JSON.stringify(v):String(v??'')).replaceAll('"','""')+'"';download('\uFEFF'+[keys.map(quote).join(','),...rows.map(r=>keys.map(k=>quote(r[k])).join(','))].join('\r\n'),'text/csv;charset=utf-8','onderwijs_'+S.country.replace(':','_')+'_'+S.view+'.csv');}
async function init(){
 const q=new URLSearchParams(location.search);for(const k of Object.keys(defaults))if(q.has(k))S[k]=q.get(k);
 [S.meta,S.ranks,S.curated,S.institutions,S.quality]=await Promise.all(['metadata','ranks','curated','institutions','quality'].map(x=>json('product_data/'+x+'.json')));
 if(!S.meta.countries.some(x=>x.country_id===S.country))S.country=defaults.country;
 const selects={countrySelect:'country',ageSelect:'age',questionSelect:'view',domainSelect:'domain',localeSelect:'locale',panelSelect:'panel',yearSelect:'year',metricSelect:'metric',groupSelect:'group',variantSelect:'variant',sesSelect:'ses'};
 options($('#countrySelect'),S.meta.countries.map(c=>[c.country_id,name(c.country_id)]).sort((a,b)=>a[1].localeCompare(b[1])),S.country);
 for(const [id,key]of Object.entries(selects)){if($('#'+id).querySelector(`option[value="${CSS.escape(S[key])}"]`))$('#'+id).value=S[key];$('#'+id).addEventListener('change',()=>{S[key]=$('#'+id).value;if(['view','domain','age','variant','ses'].includes(key)){S.metric='mean';S.group='all';S.year='all';if(key!=='age')S.panel='';}render();});}
 $('#countryTab').onclick=()=>{S.tab='country';render();};$('#internationalTab').onclick=()=>{S.tab='international';render();};$('#resetFilters').onclick=()=>{Object.assign(S,defaults);for(const [id,k]of Object.entries(selects))$('#'+id).value=S[k];render();};$('#downloadView').onclick=csvExport;
 $('#downloadSvg').onclick=()=>{const svg=$('#content svg.chart');if(svg)download(svg.outerHTML,'image/svg+xml','onderwijs_figuur.svg');};
 $('#copyLink').onclick=async()=>{try{await navigator.clipboard.writeText(location.href);$('#copyLink').textContent=t('Link gekopieerd','Link copied');}catch{$('#copyLink').textContent=location.href;}};
 await render();
}
init().catch(e=>{$('#content').textContent=t('Laden mislukt: ','Loading failed: ')+e.message;console.error(e);});
