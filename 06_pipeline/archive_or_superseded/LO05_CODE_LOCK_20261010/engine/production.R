# Incremental production from explicit product tasks; no Cartesian expansion.
lo5_read <- function(p) read.csv(p,colClasses='character',na.strings=character(),check.names=FALSE)
lo5_write <- function(x,p) write.csv(x,p,row.names=FALSE,na='')
lo5_candidates <- function(q) q$survey=='PISA' & q$module%in%c('core','gender')
lo5_keys <- c('country','survey','year','domain','module','stat','group','definition','peer_definition','threshold','unit','calculation_policy')
lo5_validate <- function(obj,q) {
 d<-obj$data
 if(!is.data.frame(d)||!nrow(d))stop('EMPTY_CANONICAL')
 if(!identical(as.character(obj$meta$v9_country),q$country[1])||
    !identical(as.character(obj$meta$survey),q$survey[1])||
    !identical(as.character(obj$meta$year),q$year[1]))stop('CANONICAL_IDENTITY_MISMATCH')
 pp<-pv_names(d,q$domain[1]);expected<-if(as.integer(q$year[1])>=2015L)10L else 5L
 if(length(pp)!=expected)stop('PV_COUNT_MISMATCH: expected ',expected,', found ',length(pp))
 need<-c('W',paste0('RW',1:80),pp)
 if(!all(need%in%names(d)))stop('REQUIRED_ANALYSIS_COLUMNS_MISSING')
 if(!all(vapply(d[need],is.numeric,logical(1))))stop('ANALYSIS_COLUMNS_NOT_NUMERIC')
 if(any(!is.finite(d$W))||any(d$W<=0))stop('INVALID_FULL_WEIGHTS')
 rw<-as.matrix(d[paste0('RW',1:80)])
 if(any(!is.finite(rw))||any(rw<0)||any(colSums(rw)<=0))stop('INVALID_REPLICATE_WEIGHTS')
 if(any(!is.finite(as.matrix(d[pp]))))stop('INCOMPLETE_PVS_REQUIRES_SAMPLE_REVIEW')
 if(any(q$module=='gender')){
  # Only explicit canonical labels, never infer numeric sex codes here.
  if(!'DEMO_GENDER'%in%names(d)||any(!is.na(d$DEMO_GENDER)&!d$DEMO_GENDER%in%c('girl','boy')))stop('GENDER_MAPPING_REQUIRES_REVIEW')
  for(g in c('girl','boy'))if(!any(d$DEMO_GENDER==g,na.rm=TRUE))stop('EMPTY_GENDER_GROUP')
 }
 invisible(TRUE)
}
lo5_cache <- function(root,country,year) {
 roots<-file.path(root,c('27_dashboard_multicountry_v9/cache','26_dashboard_fast_resumable/cache','23_slide_only_completion/cache','22_completion_final_v8/cache','20_rc2_domains/cache','21_completion_repair_v7/cache'))
 name<-sprintf('canonical_PISA_%s_%s.rds',year,country)
 p<-unique(unlist(lapply(roots[dir.exists(roots)],function(r)list.files(r,pattern=paste0('^',name,'$'),recursive=TRUE,full.names=TRUE))))
 if(!length(p))stop('CANONICAL_CACHE_ABSENT: ',name)
 hashes<-vapply(p,function(f)digest::digest(file=f,algo='sha256'),character(1))
 if(length(unique(hashes))!=1L)stop('CANONICAL_CACHE_CONFLICT: ',name)
 list(path=p[1],sha256=unname(hashes[1]),object=readRDS(p[1]))
}
lo5_prepare <- function(q,obj,bundle,source_sha='',con=NULL,memo=new.env(parent=emptyenv())) {
 lo5_validate(obj,q)
 input<-character()
 if(!is.null(con)) {
  DBI::dbExecute(con,'CREATE TABLE IF NOT EXISTS analysis_inputs (source_sha TEXT,domain TEXT,module TEXT,rules TEXT,input_fp TEXT,PRIMARY KEY(source_sha,domain,module,rules))')
  old<-DBI::dbGetQuery(con,'SELECT input_fp FROM analysis_inputs WHERE source_sha=? AND domain=? AND module=? AND rules=?',params=list(source_sha,q$domain[1],q$module[1],'pilot-analysis-columns-v1'))
  if(nrow(old))input<-old$input_fp
 }
 if(!length(input)){
  fields<-unique(c('W',paste0('RW',1:80),pv_names(obj$data,q$domain[1]),if(q$module[1]=='gender')intersect(c('DEMO_GENDER','GENDER'),names(obj$data))))
  h<-vapply(fields,function(n){if(!exists(n,memo,inherits=FALSE))assign(n,lo36_fp(obj$data[[n]]),memo);get(n,memo,inherits=FALSE)},character(1));names(h)<-fields
  input<-lo36_fp(list(schema='pilot-analysis-columns-v1',columns=h,survey=obj$meta$survey,year=obj$meta$year))
  if(!is.null(con))DBI::dbExecute(con,'INSERT INTO analysis_inputs VALUES (?,?,?,?,?)',params=list(source_sha,q$domain[1],q$module[1],'pilot-analysis-columns-v1',input))
 }
 code<-lo36_fp(unname(vapply(file.path(bundle,c('V11.R','BACKEND.R','REPAIRS.R','EXTENSIONS.R')),function(p)digest::digest(file=p,algo='sha256'),character(1))))
 q$input_fingerprint<-input
 q$science_fingerprint<-vapply(seq_len(nrow(q)),function(i)lo36_science_fp(as.list(q[i,lo5_keys,drop=FALSE]),input,code),character(1))
 q$action<-'COMPUTE';q
}
lo5_import_pilot <- function(bundle,s) {
 x<-read.csv(file.path(bundle,'VERIFIED_PILOT_RESULTS.csv'),stringsAsFactors=FALSE)
 if(nrow(x)!=6L||anyDuplicated(x$metric_key))stop('INVALID_VERIFIED_PILOT')
 # Import only into an empty new registry; never retire an existing/newer result.
 if(DBI::dbGetQuery(s$con,'SELECT COUNT(*) AS n FROM results')$n==0L)lo_store_put(s,x)
}
lo5_archive_legacy <- function(bundle,s) {
 # Legacy rows are preserved separately; no invalid is_current promotion or conflict averaging.
 if(!DBI::dbExistsTable(s$con,'legacy_review')){
  x<-lo5_read(file.path(bundle,'LEGACY_REVIEW.csv'))
  DBI::dbWithTransaction(s$con,{DBI::dbWriteTable(s$con,'legacy_review',x);DBI::dbExecute(s$con,'CREATE UNIQUE INDEX legacy_keys ON legacy_review(metric_key)')})
 }
}
lo5_run <- function(bundle,cfg,out) {
 for(n in c('digest','DBI','RSQLite','arrow','data.table','zip'))if(!requireNamespace(n,quietly=TRUE))stop('Package ontbreekt: ',n)
 for(f in c('REPAIRS.R','EXTENSIONS.R','store.R','engine.R'))source(file.path(bundle,f),local=.GlobalEnv,encoding='UTF-8')
 if(!cfg$mode%in%c('plan','execute'))stop('mode moet plan of execute zijn')
 if(!dir.exists(cfg$root))stop('Projectmap ontbreekt: ',cfg$root)
 if(cfg$workers!=1L)stop('Deze opslagroute ondersteunt één schrijver/worker.')
 all<-lo5_read(file.path(bundle,'TASKS.csv'))
 if(anyDuplicated(all$metric_key)||any(v10_dummy<-all$metric_key==''))stop('INVALID_TASK_REGISTER')
 q<-all; q$action<-'HOLD';q$reason<-'ADAPTER_OR_SCIENTIFIC_VALIDATION_NOT_YET_RELEASED'
 q$science_fingerprint<-q$input_fingerprint<-q$source_path<-q$source_sha256<-''
 q$storage_status<-'NOT_ASSESSED';q$scientific_status<-'NOT_VALIDATED';q$publication_status<-'NOT_RELEASED'
 eligible<-lo5_candidates(q)
 selected<-q$country%in%cfg$countries & q$year%in%as.character(cfg$waves) & q$domain%in%cfg$domains
 q$reason[eligible&!selected]<-'OUTSIDE_CONFIG_SELECTION_RETAINED_IN_FULL_SCOPE'
 ids<-which(eligible&selected);q$action[ids]<-'REVIEW';q$reason[ids]<-'LOCAL_INPUT_CHECK_PENDING'
 # One long-lived SQLite writer. Per-task commits; mirrors exported per country-wave.
 s<-lo_store_open(file.path(cfg$output,'registry_v5'));on.exit({if(DBI::dbIsValid(s$con))lo_store_close(s)},add=TRUE)
 lo_store_export(s);lo5_import_pilot(bundle,s);lo5_archive_legacy(bundle,s);lo_store_export(s)
 lo_engine_boot(bundle,cfg,file.path(cfg$output,'engine'),synthetic=FALSE)
 # The boot loads code only; production reads exact canonical inputs and never prepares raw files.
 units<-split(ids,paste(q$country[ids],q$year[ids],sep='|'))
 ncompute<-0L;nreuse<-0L
 planfile<-file.path(out,'PRODUCTIEPLAN.csv')
 for(unit in units){
  country<-q$country[unit[1]];year<-q$year[unit[1]]
  cat('Productie: ',country,' PISA ',year,'\n',sep='');flush.console()
  cache<-tryCatch(lo5_cache(cfg$root,country,year),error=function(e)e)
  if(inherits(cache,'error')){q$action[unit]<-'HOLD';q$reason[unit]<-conditionMessage(cache);lo5_write(q,planfile);next}
  # Shared columns hashed once per domain/module; identical tasks computed only once.
  batches<-split(unit,paste(q$domain[unit],q$module[unit],sep='|'));memo<-new.env(parent=emptyenv())
  for(ix in batches){
   prepared<-tryCatch(lo5_prepare(q[ix,,drop=FALSE],cache$object,bundle,cache$sha256,s$con,memo),error=function(e)e)
   if(inherits(prepared,'error')){q$action[ix]<-'HOLD';q$reason[ix]<-conditionMessage(prepared);next}
   q$source_path[ix]<-cache$path;q$source_sha256[ix]<-cache$sha256
   q$science_fingerprint[ix]<-prepared$science_fingerprint;q$input_fingerprint[ix]<-prepared$input_fingerprint
   current<-DBI::dbGetQuery(s$con,'SELECT metric_key,science_fingerprint FROM results WHERE is_current=1')
   k<-match(prepared$metric_key,current$metric_key)
   reuse<-!is.na(k)&prepared$science_fingerprint==current$science_fingerprint[k];reuse[is.na(reuse)]<-FALSE
   q$action[ix[reuse]]<-'REUSE';q$reason[ix[reuse]]<-'EXACT_SCIENTIFIC_AND_INPUT_IDENTITY';q$storage_status[ix[reuse]]<-'CURRENT'
   nreuse<-nreuse+sum(reuse)
   todo<-which(!reuse);q$action[ix[todo]]<-'COMPUTE';q$reason[ix[todo]]<-'VALID_CANONICAL_INPUT_AND_RELEASED_ESTIMATOR'
   if(cfg$mode=='execute'&&length(todo)){
    # Keep each result durable; isolate failures so independent tasks proceed.
    for(j in todo){
     row<-prepared[j,,drop=FALSE]
     z<-tryCatch({
      z<-lo_compute_one(cache$object,row)
      z$science_fingerprint<-row$science_fingerprint;z$input_fingerprint<-row$input_fingerprint
      z$scientific_status<-'COMPUTED_PENDING_VALIDATION';z$publication_status<-'NOT_RELEASED'
      lo_store_put(s,z);z
     },error=function(e)e)
     at<-ix[j]
     if(inherits(z,'error')){q$action[at]<-'HOLD';q$reason[at]<-conditionMessage(z)}else{
      ncompute<-ncompute+1L;q$storage_status[at]<-'CURRENT';q$scientific_status[at]<-'COMPUTED_PENDING_VALIDATION';q$reason[at]<-'COMPUTED_AND_COMMITTED'
     }
    }
   }
  }
  lo_store_export(s);lo5_write(q,planfile)
  rm(cache);gc(FALSE)
 }
 lo_store_export(s);lo5_write(q,planfile)
 frames<-lo_store_frames(s);lo5_write(frames$current,file.path(out,'CURRENT_RESULTS.csv'))
 counts<-as.data.frame(table(q$action),stringsAsFactors=FALSE);names(counts)<-c('action','n');lo5_write(counts,file.path(out,'AANTALLEN.csv'))
 file.copy(file.path(bundle,'ADDITIONAL_REQUIREMENTS.csv'),file.path(out,'OPEN_PAPER_REQUIREMENTS.csv'),overwrite=TRUE)
 lo5_write(q[q$action%in%c('HOLD','REVIEW'),],file.path(out,'OPEN_TARGETS.csv'))
 fp<-lo36_fp(q[c('metric_key','action','reason','science_fingerprint')])
 lo_store_close(s)
 if(DBI::dbIsValid(s$con)||DBI::dbIsValid(s$lockcon))stop('WRITER_CONNECTION_NOT_CLOSED')
 writeLines(c('STATUS=COMPLETED_RELEASED_BATCH',paste0('MODE=',cfg$mode),paste0('COMPUTED=',ncompute),paste0('REUSED=',nreuse),paste0('PLAN_FINGERPRINT=',fp),
  'RELEASED_SCOPE=PISA_CORE_GENDER_EXISTING_CANONICAL_CACHE',
  'FULL_SCOPE_COMPLETED=FALSE','OLD_CENTRAL_STORAGE_MODIFIED=FALSE',
  'NEXT=Valideer geproduceerde batch; integreer overige modules en centrale promotie met behoud van open taken.'),file.path(out,'UITKOMST.txt'))
 invisible(q)
}
