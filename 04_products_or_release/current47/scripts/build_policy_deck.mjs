// Update the user-designated October policy deck from certified aggregate data.
// Native scatter charts preserve proportional survey-year spacing. Their
// worksheet/display values use 14 significant digits; the research data retain
// full precision. Vertical two-point series encode the point-specific
// design/PV confidence limits; no generic chart "standard error" is substituted.
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
process.on('uncaughtException',error=>{console.error(error.stack||String(error));process.exit(1);});

const [repoArg,dataArg,templateArg,outArg,fontsArg]=process.argv.slice(2);
if(!fontsArg)throw Error('Usage: node build_policy_deck.mjs repo research-data template output fonts');
const repo=path.resolve(repoArg),out=path.resolve(outArg);
const runtime=process.env.LO_NODE_MODULES;
const skill=process.env.LO_PRESENTATIONS_SKILL;
if(!runtime||!skill||!process.env.LO_PYTHON)throw Error('Set documented artifact-tool runtime and skill paths');
process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES=runtime;
const require=createRequire(path.join(runtime,'@oai/artifact-tool/package.json'));
const {FontLibrary}=require('skia-canvas');
for(const [family,file] of [['Oswald','font2.ttf'],['Oswald Medium','font3.ttf'],['Oswald Light','font1.ttf']])
  FontLibrary.use(family,[path.join(fontsArg,file)]);
const {FileBlob,PresentationFile}=await import(pathToFileURL(path.join(runtime,'@oai/artifact-tool/dist/artifact_tool.mjs')));
const {finalizePresentation}=await import(pathToFileURL(path.join(skill,'container_tools/artifact_tool_utils.mjs')));
const E=await import(pathToFileURL(path.join(repo,'05_publication/preview_overlay/assets/explorer.mjs')));
const model=JSON.parse(await fs.readFile(dataArg,'utf8'));
const tables=JSON.parse(await fs.readFile(path.join(path.dirname(dataArg),'RESEARCH_TABLES.json'),'utf8'));
const brand=JSON.parse(await fs.readFile(path.join(repo,'05_publication/preview_overlay/assets/brand/brand_tokens.json'),'utf8'));
const C=brand.colors;
const expectedTemplate=model.provenance.source_deck_sha256;
if(createHash('sha256').update(await fs.readFile(templateArg)).digest('hex')!==expectedTemplate)throw Error('Design reference changed');
await fs.mkdir(path.join(out,'renders'),{recursive:true});
await fs.mkdir(path.join(out,'draft'),{recursive:true});
await fs.mkdir(path.join(out,'final'),{recursive:true});
const deck=await PresentationFile.importPptx(await FileBlob.load(templateArg));
if(deck.slides.items.length!==21)throw Error('Expected the original 21-slide policy deck');
const originals=[...deck.slides.items],used=new Set(),ordered=[];
for(const spec of model.slides) {
  const source=originals[spec.source_slide-1];
  const slide=used.has(spec.source_slide)?source.duplicate():source;
  used.add(spec.source_slide); ordered.push(slide);
}
// moveTo uses the documented zero-based collection position.
for(const [i,slide] of ordered.entries())slide.moveTo(i);
if(deck.slides.items.length!==model.slides.length)throw Error('Unexpected slide count');
const logo=await fs.readFile(path.join(repo,'05_publication/preview_overlay/assets/brand/leerprestaties_nl.svg'),'utf8');
const figureById=new Map(model.panels.map(p=>[p.id,p]));
const receipts=[];

function clear(slide) {
  for(const collection of [slide.shapes,slide.images,slide.charts,slide.tables])
    for(const item of [...collection.items]) {
      if(typeof item.delete==='function')item.delete();
      else collection.deleteById(item.id);
    }
  slide.background.fill=C.background;
}
function text(slide,value,x,y,w,h,size=22,color=C.text,weight='regular',align='left') {
  const s=slide.shapes.add({geometry:'textbox',position:{left:x,top:y,width:w,height:h},
    fill:'none',line:{fill:'none'}});
  s.text=value;
  s.text.style={typeface:weight==='medium'?'Oswald Medium':weight==='light'?'Oswald Light':'Oswald',
    fontSize:size,color,insets:0,alignment:align,verticalAlignment:'top',autoFit:'none'};
  return s;
}
function line(slide,x,y,w,color,dash='solid') {
  return slide.shapes.add({geometry:'line',position:{left:x,top:y,width:w,height:0},
    line:{fill:color,width:2,style:dash}});
}
function footer(slide,spec,notes) {
  text(slide,notes,36,638,1120,58,16,C.muted);
  text(slide,String(spec.number),1201,670,42,25,16,C.muted,'light','right');
}
function color(series,index) {
  const s=series.toLowerCase();
  if(s.includes('comparator')||s.startsWith('reference:')||s.startsWith('population_'))return C.context_dark;
  if(s==='q1'||s.includes('q1_target'))return C.ses_line[0];
  if(s==='q4'||s.includes('q4_target'))return C.ses_line[4];
  if(s==='girl'||s==='self_high'||s==='self_below_basic')return C.ses_line[4];
  if(s==='boy'||s==='total')return C.netherlands_focus;
  return [C.netherlands_focus,C.ses_line[4],C.ses_line[2],C.ses_line[0]][index%4];
}
function domainTitle(p) {
  const domain=({reading:'Lezen',mathematics:p.age==='age10'?'Rekenen':'Wiskunde',science:'Natuurwetenschappen',all:p.survey})[p.domain];
  return `${domain} · ${p.age==='age10'?'groep 6':'15 jaar'}`;
}
function chooseRows(p,spec) {
  return p.rows.filter(r=>(spec.comparison||r.series_role!=='comparator')&&
    (!spec.series||spec.series.includes(r.series_id)));
}
function range(rows,unit) {
  const values=rows.flatMap(r=>{
    const y=Number(r.estimate),se=Number(r.standard_error);
    return Number.isFinite(se)&&r.series_role!=='comparator'?[y-1.96*se,y+1.96*se]:[y];
  }).filter(Number.isFinite);
  if(!values.length)return {min:0,max:1,majorUnit:.25};
  let lo=Math.min(...values),hi=Math.max(...values);
  if(unit==='percent')lo=Math.min(0,lo);
  const span=Math.max(hi-lo,unit==='percent'?5:10),raw=span/4;
  const power=10**Math.floor(Math.log10(raw));
  const step=[1,2,2.5,5,10].map(v=>v*power).find(v=>v>=raw);
  lo=Math.floor((lo-.04*span)/step)*step;
  hi=Math.ceil((hi+.04*span)/step)*step;
  if(unit==='percent'&&Math.min(...values)>=0)lo=0;
  return {min:lo,max:hi,majorUnit:step};
}
function segments(rows,p) {
  const out=[];let part=[],prior=null;
  for(const r of [...rows].sort((a,b)=>Number(a.year)-Number(b.year))) {
    if(E.breakBetween(prior,r,{required_years:p.years.join(';')})&&part.length){out.push(part);part=[];}
    part.push(r);prior=r;
  }
  if(part.length)out.push(part);
  return out;
}
function drawPanel(slide,p,spec,box) {
  const rows=chooseRows(p,spec);
  text(slide,domainTitle(p),box.x,box.y,box.w,28,23,C.text,'medium');
  text(slide,p.unit==='percent'?'Percentage':'Scorepunten',box.x,box.y+30,box.w,23,16,C.muted);
  if(!rows.length) {
    text(slide,'Geen bruikbare reeks beschikbaar',box.x+20,box.y+box.h/2-12,box.w-40,55,22,C.muted);
    return {figure_ids:[p.id],plotted_points:0,missing:true};
  }
  const groups=[...new Set(rows.map(r=>r.series_id+'|'+r.label))],native=[];
  for(const [index,key] of groups.entries()) {
    const rr=rows.filter(r=>r.series_id+'|'+r.label===key),id=rr[0].series_id,cc=color(id,index);
    for(const chunk of segments(rr,p))native.push({name:chunk[0].label,
      xValues:chunk.map(r=>Number(r.year)),values:chunk.map(r=>Number(r.estimate)),
      line:{fill:cc,width:2,style:rr[0].series_role==='comparator'||id.startsWith('population_')?'dash':'solid'},
      marker:{symbol:rr[0].series_role==='comparator'?'square':'circle',size:5,fill:cc}});
    for(const r of rr) {
      const se=Number(r.standard_error);
      if(r.series_role==='comparator'||r.standard_error==null||r.standard_error===''||!Number.isFinite(se))continue;
      native.push({name:`95%-interval ${r.label}, ${r.year}`,
        xValues:[Number(r.year),Number(r.year)],
        values:[Number(r.estimate)-1.96*se,Number(r.estimate)+1.96*se],
        line:{fill:cc,width:.8},marker:{symbol:'none'}});
    }
  }
  const min=Math.min(...p.years),max=Math.max(...p.years);
  // Embedded Excel worksheets support 15 significant digits. Keep 14 in the
  // presentation cache/workbook; exact binary64 research values stay in the
  // immutable aggregate files and point lineage, never rounded upstream.
  for(const series of native)series.values=series.values.map(v=>Number(v.toPrecision(14)));
  slide.charts.add('scatter',{position:{left:box.x,top:box.y+54,width:box.w,height:box.h-60},
    series:native,scatterOptions:{style:'lineWithMarkers'},hasLegend:false,displayBlanksAs:'gap',
    chartFill:C.background,plotAreaFill:C.background,chartLine:{fill:'none'},plotAreaLine:{fill:'none'},
    xAxis:{min:min-.35,max:max+.35,majorUnit:max-min>16?5:3,numberFormatCode:'0',
      textStyle:{typeface:'Oswald',fontSize:15,fill:C.muted},line:{fill:C.grid,width:1}},
    yAxis:{...range(rows,p.unit),numberFormatCode:'0',textStyle:{typeface:'Oswald',fontSize:15,fill:C.muted},
      majorGridlines:{fill:C.grid,width:.7},line:{fill:'none'}}
  });
  return {figure_ids:[p.id],plotted_points:rows.length,
    native_series:native,cell_ids:rows.map(r=>r.cell_id||r.parent_cell_ids||null),
    references:spec.comparison?p.default_reference:[],
    full_anchor:p.years,excluded_years_or_groups:p.availability?.missing_cells||null};
}
function mergeDistribution(ids) {
  const groups=new Map();
  for(const id of ids) {
    const p=figureById.get(id),key=p.age+':'+p.domain;
    if(!groups.has(key))groups.set(key,{...p,id:key,rows:[],source_ids:[]});
    const g=groups.get(key),quantile=id.includes('P10')?'p10':id.includes('P50')?'p50':'p90';
    g.source_ids.push(id);
    g.rows.push(...p.rows.filter(r=>r.series_role!=='comparator').map(r=>({...r,series_id:quantile,
      label:{p10:'Tiende percentiel',p50:'Mediaan',p90:'Negentigste percentiel'}[quantile]})));
  }
  return [...groups.values()];
}
function legends(slide,panels,spec) {
  const found=new Map();
  for(const p of panels)for(const r of chooseRows(p,spec))
    if(!found.has(r.series_id+'|'+r.label))found.set(r.series_id+'|'+r.label,{id:r.series_id,label:r.label});
  const values=[...found];
  const cols=values.length<=3?values.length:3;
  for(const [i,[key,{id,label}]] of values.entries()) {
    const x=36+(i%cols)*(1200/cols),y=588+Math.floor(i/cols)*24;
    line(slide,x,y+11,27,color(id,i),id.startsWith('population_')||id.startsWith('reference:')?'dash':'solid');
    text(slide,label,x+36,y,1200/cols-44,25,18,C.text);
  }
}
function table(slide,columns,rows,x,y,widths,fontsize=20) {
  const t=slide.tables.add({rows:rows.length+1,columns:columns.length,left:x,top:y,
    width:widths.reduce((a,b)=>a+b,0),height:48*(rows.length+1),columnWidths:widths});
  // Table APIs are validated independently before a final product is accepted.
  for(const [ri,row] of [columns,...rows].entries())for(const [ci,value] of row.entries()) {
    const cell=t.getCell(ri,ci);
    cell.value=String(value);
    cell.text.style={typeface:ri===0?'Oswald Medium':'Oswald',fontSize:fontsize,color:C.text,insets:8};
    cell.fill=ri===0?'#EDEEF9':C.background;
  }
  return t;
}
for(const [i,spec] of model.slides.entries()) {
  const slide=deck.slides.items[i];clear(slide);
  const note=[];
  if(spec.kind==='cover') {
    slide.images.add({svg:logo,position:{left:50,top:45,width:370,height:102},alt:'Leerprestaties',fit:'contain'});
    text(slide,spec.title,50,230,1145,100,68,C.text,'medium');
    text(slide,'Ontwikkeling, verschillen en leeromgevingen',53,352,1110,60,38,C.muted);
    text(slide,'PIRLS · TIMSS · PISA\nInternationaal vierde leerjaar / Nederlandse groep 6 en 15-jarigen',53,450,1100,100,27,C.text);
    footer(slide,spec,'Kansenlab · Onderzoeksversie oktober 2026 · Herhaalde dwarsdoorsneden; geen causale of individuele cohortanalyse.');
  } else if(spec.kind==='coverage') {
    text(slide,spec.title,36,24,1195,60,38,C.text,'medium');
    text(slide,'SES-constructen worden per studie afzonderlijk geïnterpreteerd',36,100,1180,40,27,C.muted);
    table(slide,['Studie','Leeftijd','Basismaat','Meetjaren'],
      [['PIRLS','Groep 6','Boeken thuis; gewogen kwartielen','2001, 2006, 2011, 2016, 2021'],
       ['TIMSS','Groep 6','Boeken thuis; gewogen kwartielen','2003, 2007, 2011, 2015, 2019, 2023'],
       ['PISA','15 jaar','Cobreros; viergolvenmodel','2015, 2018, 2022, 2025'],
       ['Home-SES','Groep 6','Afzonderlijke appendixschaal','NL: PIRLS 2021; geen oudervragenlijst TIMSS 2023']],36,182,[150,160,385,505],23);
    text(slide,'Ontbrekende antwoorden veranderen de analysegroep. Gewogen en ongewogen aantallen, uitgesloten groepen en bronvoorbehouden staan per meetjaar in de bijbehorende tabellen.',36,460,1160,96,27);
    footer(slide,spec,'Bron: Q01, Q02 en Q07. Home-SES wordt niet aan oudere thuisschalen vastgemaakt. Kwartielen worden binnen land en meetjaar bepaald.');
  } else {
    text(slide,spec.title,36,24,1205,58,38,C.text,'medium');
    let panels=spec.kind==='distribution'?mergeDistribution(spec.panels):
      spec.kind==='high_ses_appendix'?tables.high_ses_panels:spec.panels.map(id=>figureById.get(id));
    if(panels.some(p=>!p)||panels.length>6||!panels.length)throw Error('Unexpected panel contract slide '+spec.number);
    const twoRows=panels.length>3,columns=panels.length===2?2:3;
    const w=(1200-(columns-1)*24)/columns,h=twoRows?230:435;
    for(const [j,p] of panels.entries()) {
      const proof=drawPanel(slide,p,spec,{x:36+(j%columns)*(w+24),y:100+Math.floor(j/columns)*241,w,h});
      if(p.source_ids)proof.figure_ids=p.source_ids;
      note.push(proof);
    }
    legends(slide,panels,spec);
    let foot='Bron: OECD PISA / IEA PIRLS en TIMSS; eigen gewogen schattingen. Verticale lijnen: 95%-onzekerheidsmarge, inclusief plausible values en steekproefontwerp.';
    if(spec.comparison)foot+=' Vergelijkingsgroep: vaste passende rijke landen per paneel, ieder even zwaar; Nederland uitgesloten.';
    if(spec.source_slide>=4&&spec.source_slide<=10)foot+=' SES: boeken thuis bij groep 6; viergolven-Cobreros bij PISA. Verschillende constructen.';
    if(spec.source_slide===11)foot+=' Afzonderlijke meisjes waar beschikbaar; de gepoolde categorie “Meisjes + other” blijft zichtbaar onderscheiden.';
    if(spec.source_slide>=16&&spec.source_slide<=20)foot+=' Peers: zonder de leerling zelf, binnen klas (IEA) of onderwijsprogramma binnen school (PISA); geen causaal peereffect.';
    footer(slide,spec,foot);
  }
  slide.speakerNotes.text=JSON.stringify({source_slide:spec.source_slide,approval:spec.approval||'CHOSEN_BASE',
    result_basis:model.provenance,panels:note,
    sources:['https://www.oecd.org/en/about/programmes/pisa/pisa-data.html','https://pirls2021.org/','https://timss2023.org/'],
    uncertainty:'Intervals are pointwise sampling/PV intervals. Overlap is not a test of change. Only the registered paper contrasts include their applicable additional linking error.',
    data_dependency_file:'PRODUCT_POINT_LINEAGE.json'},null,2);
  receipts.push({slide:i+1,title:spec.title,source_slide:spec.source_slide,panels:note});
  const png=await slide.export({format:'png',scale:2});
  await fs.writeFile(path.join(out,'renders',`slide-${String(i+1).padStart(2,'0')}.png`),new Uint8Array(await png.arrayBuffer()));
}
const candidate=path.join(out,'draft','Learning_Outcomes_current47.pptx');
await (await PresentationFile.exportPptx(deck)).save(candidate);
const finalPath=path.join(out,'final','Leerprestaties_beleid_current47.pptx');
await finalizePresentation({
  workspaceDir:out,candidatePath:candidate,finalPath,
  pythonExecutable:process.env.LO_PYTHON,
  integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),
  layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),
  layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-heading-fit'],
  explicitTotalSlideCount:model.slides.length,
  requiredNativeChartOwnerSlides:model.slides.filter(s=>!['cover','coverage'].includes(s.kind)).map(s=>s.number),
  fontPolicy:{basis:'user_request',families:['Oswald','Oswald Medium','Oswald Light']},
  materializeLiteralChartWorkbooks:true,verifyArtifactToolImport:true,
  receiptPath:path.join(out,'draft','FINALIZER_RECEIPT.json')
});
await fs.writeFile(path.join(out,'POLICY_DECK_TRACE.json'),JSON.stringify({provenance:model.provenance,slides:receipts},null,2)+'\n');
console.log('POLICY_DECK_NATIVE_CHARTS_BUILT',model.slides.length,finalPath);
