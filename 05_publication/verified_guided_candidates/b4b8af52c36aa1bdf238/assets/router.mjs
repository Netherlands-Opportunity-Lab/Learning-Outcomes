export const QUESTIONS=['trends','distribution','gaps','environment'];
export const DEFAULTS={locale:'nl',country:'NLD',question:null,age:'age10',domain:'reading',outcome:'mean_score',split:'none',peer_definition:'direct_learning_environment',view_mode:'levels'};
export const STATE_KEYS=['age','domain','outcome','split','peer_definition','view_mode'];

export function parseRoute(pathname){
  const p=String(pathname||'').replace(/\\/g,'/').split('/').filter(Boolean);
  const li=p.findIndex(x=>x==='nl'||x==='en');
  if(li<0)return {...DEFAULTS,locale:'nl',country:'NLD',question:null,valid:true};
  const locale=p[li];
  if(p.length===li+1)return {...DEFAULTS,locale,country:'NLD',question:null,valid:true};
  if(p[li+1]==='country'&&p[li+2]&&QUESTIONS.includes(p[li+3])&&p.length===li+4){
    return {...DEFAULTS,locale,country:p[li+2].toUpperCase(),question:p[li+3],valid:true};
  }
  return {...DEFAULTS,locale,country:'NLD',question:null,valid:false};
}

export function makeRoute(base='',locale='nl',country='NLD',question=null){
  const prefix=base||'';
  return question?`${prefix}${locale}/country/${country}/${question}/`:`${prefix}${locale}/`;
}

export function stateFromSearch(search,state={...DEFAULTS}){
  const out={...state};
  const q=new URLSearchParams(String(search||'').replace(/^\?/,''));
  for(const k of STATE_KEYS)if(q.has(k))out[k]=q.get(k);
  return out;
}

export function stateSearch(state){
  const q=new URLSearchParams();
  for(const k of STATE_KEYS)if(state[k]!==undefined&&state[k]!==null&&state[k]!=='')q.set(k,state[k]);
  const s=q.toString();return s?`?${s}`:'';
}

export function localeTarget({base='',locale,country,question,search='',hash=''}){
  return makeRoute(base,locale,country,question)+(search||'')+(hash||'');
}
