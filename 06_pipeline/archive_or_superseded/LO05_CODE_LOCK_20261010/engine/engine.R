lo_engine_boot <- function(bundle,cfg,work,synthetic=FALSE) {
 options(pisa.fast.functions_only=TRUE,pisa.completion.functions_only=TRUE,
   pisa.slide.root=cfg$root,pisa.slide.engine=file.path(bundle,'BACKEND.R'),pisa.fast.countries='NLD')
 source(file.path(bundle,'V11.R'),local=.GlobalEnv,encoding='UTF-8')
 if(exists('.lo36_original_compute',envir=.GlobalEnv,inherits=FALSE))rm('.lo36_original_compute',envir=.GlobalEnv)
 if(synthetic){
  # Load the actual named estimators without running the legacy entry point.
  expressions<-parse(file.path(bundle,'BACKEND.R'))
  for(n in c('rc2_replicate_design','rc2_repweight','rc2_pool','rc2_num','rc2_bind')){
   defs<-Filter(function(x)is.call(x)&&as.character(x[[1]])%in%c('<-','=')&&is.symbol(x[[2]])&&as.character(x[[2]])==n,as.list(expressions))
   if(!length(defs))stop('Enginefunctie ontbreekt: ',n)
   eval(defs[[1]],.GlobalEnv)
  }
  assign('rc2_pool_engine_v8',get('rc2_pool',.GlobalEnv),.GlobalEnv)
  eval(parse(text=get('V10_BACKEND_FUNCTIONS',.GlobalEnv)),.GlobalEnv)
  assign('pv_names',function(d,domain)c('PV1','PV2'),.GlobalEnv)
  assign('weighted_mean',function(y,w){ok<-is.finite(y)&is.finite(w)&w>0;sum(y[ok]*w[ok])/sum(w[ok])},.GlobalEnv)
 }else{
  vars<-list(ROOT=cfg$root,DOWNLOADS=dirname(cfg$root),BASE=work,CACHE=file.path(work,'cache'),
   TASK_DIR=file.path(work,'cache/tasks'),STATE_DIR=file.path(work,'cache/state'),OUT=work,LOG=file.path(work,'ENGINE_LOG.txt'),
   ACTIVE_COUNTRY='NLD',ALLOW_RAW_FALLBACK=FALSE,AUTO_INSTALL_R_PACKAGES=FALSE,
   AUTO_PREPARE_COBREROS_REPO=FALSE,V10_BACKEND_READY=FALSE,V9_CALIBRATION=NULL,V9_CALIBRATION_ERROR=NULL,V9_LEGACY_SES=NULL)
  list2env(vars,.GlobalEnv)
  for(n in c('V9_TIMSS_SOURCE_CACHE','V9_PISA_ABSENT','V9_PISA_ERRORS','V9_PISA_WAVE_ERRORS','V10_HARMONIZED_RESULTS','V10_QUARTILE_BASELINE_RESULTS'))
   assign(n,new.env(parent=emptyenv()),.GlobalEnv)
  for(p in c(work,vars$CACHE,vars$TASK_DIR,vars$STATE_DIR))dir.create(p,recursive=TRUE,showWarnings=FALSE)
  get('v10_init_backend',.GlobalEnv)()
 }
 lo36_install_compute(.GlobalEnv,lo35_compute_extensions)
 invisible(TRUE)
}
lo_fixture <- function(){
 d<-data.frame(W=rep(1,4),DEMO_GENDER=c('girl','girl','boy','boy'),PV1=c(400,600,300,500),PV2=c(420,620,340,540))
 for(i in 1:80)d[[paste0('RW',i)]]<-if(i%%2)c(1.5,.5,1.5,.5)else c(.5,1.5,.5,1.5)
 list(data=d,meta=list(survey='PISA',year=2018L))
}
lo_input_hash <- function(obj,q) {
 # Only variables used by this pilot's core/gender estimators; no references/style.
 pv<-get('pv_names',.GlobalEnv)(obj$data,q$domain[1])
 fields<-unique(c('W',paste0('RW',1:80),pv,if(any(q$module=='gender'))intersect(c('DEMO_GENDER','GENDER'),names(obj$data))))
 if(!all(fields%in%names(obj$data))||!length(pv))stop('Benodigde pilotvariabelen ontbreken.')
 # Hash columns separately to avoid constructing one enormous string.
 h<-vapply(fields,function(n)lo36_fp(obj$data[[n]]),character(1));names(h)<-fields
 lo36_fp(list(schema='pilot-analysis-columns-v1',columns=h,survey=obj$meta$survey,year=obj$meta$year))
}
lo_tasks_prepare <- function(q,obj,bundle) {
 groups<-split(seq_len(nrow(q)),q$module)
 input<-character(nrow(q))
 for(ix in groups)input[ix]<-lo_input_hash(obj,q[ix,,drop=FALSE])
 code<-lo36_fp(unname(vapply(file.path(bundle,c('V11.R','BACKEND.R','REPAIRS.R','EXTENSIONS.R')),function(p)digest::digest(file=p,algo='sha256'),character(1))))
 q$input_fingerprint<-input
 keys<-c('country','survey','year','domain','module','stat','group','definition','peer_definition','threshold','unit','calculation_policy')
 q$science_fingerprint<-vapply(seq_len(nrow(q)),function(i)lo36_science_fp(as.list(q[i,keys,drop=FALSE]),input[i],code),character(1))
 q$action<-'COMPUTE';q
}
lo_compute_one <- function(obj,q)get('v10_compute',.GlobalEnv)(obj,q)
