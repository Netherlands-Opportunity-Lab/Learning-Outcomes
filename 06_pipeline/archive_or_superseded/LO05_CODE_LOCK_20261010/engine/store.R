# One writer; SQLite is authoritative; Parquet mirrors recover after interrupted export.
lo_store_open <- function(path) {
 dir.create(path,recursive=TRUE,showWarnings=FALSE)
 lock<-file.path(path,'WRITER_MUTEX.sqlite')
 lockcon<-DBI::dbConnect(RSQLite::SQLite(),lock,synchronous=NULL)
 tryCatch({DBI::dbExecute(lockcon,'PRAGMA journal_mode=PERSIST');DBI::dbExecute(lockcon,'CREATE TABLE IF NOT EXISTS mutex (id INTEGER PRIMARY KEY)');DBI::dbExecute(lockcon,'BEGIN EXCLUSIVE')},error=function(e){DBI::dbDisconnect(lockcon);stop('Er is al een actieve schrijver: ',lock)})
 con<-tryCatch(DBI::dbConnect(RSQLite::SQLite(),file.path(path,'PROJECT_RESULTS_REGISTRY.sqlite')),
   error=function(e){DBI::dbExecute(lockcon,'ROLLBACK');DBI::dbDisconnect(lockcon);stop(e)})
 DBI::dbExecute(con,'PRAGMA journal_mode=PERSIST')
 DBI::dbExecute(con,'PRAGMA synchronous=FULL')
 DBI::dbExecute(con,'CREATE TABLE IF NOT EXISTS meta (id INTEGER PRIMARY KEY, revision INTEGER NOT NULL, exported INTEGER NOT NULL)')
 DBI::dbExecute(con,'INSERT OR IGNORE INTO meta VALUES (1,0,-1)')
 DBI::dbExecute(con,paste('CREATE TABLE IF NOT EXISTS results (record_version_id TEXT PRIMARY KEY,',
  'metric_key TEXT NOT NULL, science_fingerprint TEXT NOT NULL, input_fingerprint TEXT NOT NULL,',
  'estimate REAL NOT NULL,se REAL NOT NULL,ci_low REAL NOT NULL,ci_high REAL NOT NULL,',
  'scientific_status TEXT NOT NULL,publication_status TEXT NOT NULL,is_current INTEGER NOT NULL)'))
 DBI::dbExecute(con,'CREATE UNIQUE INDEX IF NOT EXISTS unique_current ON results(metric_key) WHERE is_current=1')
 list(path=path,con=con,lock=lock,lockcon=lockcon)
}
lo_store_close <- function(s){
 tryCatch({if(DBI::dbIsValid(s$con))DBI::dbDisconnect(s$con)},finally={
  if(DBI::dbIsValid(s$lockcon)){DBI::dbExecute(s$lockcon,'ROLLBACK');DBI::dbDisconnect(s$lockcon)}
 })
 invisible(TRUE)
}
lo_store_frames <- function(s) {
 h<-DBI::dbGetQuery(s$con,'SELECT * FROM results ORDER BY record_version_id')
 list(current=h[h$is_current==1L,,drop=FALSE],history=h)
}
lo_frame_equal <- function(a,b) {
 if(!setequal(names(a),names(b))||nrow(a)!=nrow(b))return(FALSE)
 a<-a[order(a$record_version_id),names(b),drop=FALSE];b<-b[order(b$record_version_id),,drop=FALSE]
 rownames(a)<-rownames(b)<-NULL
 isTRUE(all.equal(a,b,check.attributes=FALSE,tolerance=0))
}
lo_atomic_replace <- function(stage,target) {
 old<-paste0(target,'.previous')
 if(file.exists(old))unlink(old)
 if(file.exists(target)&&!file.rename(target,old))stop('Kan vorig proefbestand niet behouden.')
 if(!file.rename(stage,target)){
  if(file.exists(old))file.rename(old,target)
  stop('Kan proefbestand niet publiceren.')
 }
}
lo_store_export <- function(s,interrupt_after_current=FALSE) {
 m<-DBI::dbGetQuery(s$con,'SELECT * FROM meta WHERE id=1');frames<-lo_store_frames(s)
 paths<-file.path(s$path,c('CURRENT_RESULTS.parquet','RESULT_HISTORY.parquet'))
 if(m$revision==m$exported){
  if(!all(file.exists(paths)))stop('Gepubliceerde proefbestanden ontbreken; geen stille overschrijving.')
  for(i in 1:2)if(!lo_frame_equal(frames[[i]],as.data.frame(arrow::read_parquet(paths[i], mmap=FALSE))))
    stop('Gepubliceerde proefopslag gewijzigd of beschadigd; wijzigingen behouden.')
  return(invisible(FALSE))
 }
 for(i in 1:2){
  stage<-paste0(paths[i],'.stage');arrow::write_parquet(frames[[i]],stage)
  if(!lo_frame_equal(frames[[i]],as.data.frame(arrow::read_parquet(stage, mmap=FALSE))))stop('Parquet roundtrip mislukt.')
  lo_atomic_replace(stage,paths[i])
  if(i==1L&&interrupt_after_current)stop('TEST_INTERRUPTION_AFTER_CURRENT')
 }
 DBI::dbExecute(s$con,'UPDATE meta SET exported=revision WHERE id=1')
 invisible(TRUE)
}
lo_store_put <- function(s,x) {
 fields<-c('metric_key','science_fingerprint','input_fingerprint','estimate','se','ci_low','ci_high','scientific_status','publication_status')
 if(!all(fields%in%names(x))||anyDuplicated(x$metric_key)||!nrow(x))stop('Ongeldig resultaatcontract.')
 if(any(!is.finite(as.matrix(x[c('estimate','se','ci_low','ci_high')])) )||any(x$se<0))stop('Ongeldige payload.')
 x<-x[,fields,drop=FALSE]
 x$record_version_id<-vapply(seq_len(nrow(x)),function(i)lo36_fp(as.list(x[i,,drop=FALSE])),character(1))
 x$is_current<-1L
 changed<-FALSE
 DBI::dbWithTransaction(s$con,{
  for(i in seq_len(nrow(x))){
   r<-x[i,,drop=FALSE]
   old<-DBI::dbGetQuery(s$con,'SELECT * FROM results WHERE metric_key=? AND is_current=1',params=list(r$metric_key))
   if(nrow(old)&&old$record_version_id==r$record_version_id)next
   if(nrow(old)&&old$science_fingerprint==r$science_fingerprint)stop('Verschillende payload bij identieke wetenschap/input; conflict niet overschrijven.')
   DBI::dbExecute(s$con,'UPDATE results SET is_current=0 WHERE metric_key=?',params=list(r$metric_key))
   exists<-DBI::dbGetQuery(s$con,'SELECT record_version_id FROM results WHERE record_version_id=?',params=list(r$record_version_id))
   if(nrow(exists))DBI::dbExecute(s$con,'UPDATE results SET is_current=1 WHERE record_version_id=?',params=list(r$record_version_id))
   else DBI::dbAppendTable(s$con,'results',r)
   changed<-TRUE
  }
  if(changed)DBI::dbExecute(s$con,'UPDATE meta SET revision=revision+1 WHERE id=1')
 })
 invisible(changed)
}
lo_execute <- function(tasks,store,compute,interrupt_after=Inf) {
 if(anyDuplicated(tasks$metric_key)||!all(tasks$action%in%c('REUSE','COMPUTE')))stop('Ongeldige taakkeuze.')
 s<-lo_store_open(store);on.exit(lo_store_close(s));lo_store_export(s)
 operations<-list();ncompute<-0L
 for(i in seq_len(nrow(tasks))){
  q<-tasks[i,,drop=FALSE]
  old<-DBI::dbGetQuery(s$con,'SELECT * FROM results WHERE metric_key=? AND science_fingerprint=? AND is_current=1',params=list(q$metric_key,q$science_fingerprint))
  if(nrow(old))op<-'REUSE' else {
   if(q$action=='REUSE')stop('Hergebruik aangevraagd maar exact resultaat ontbreekt.')
   z<-compute(q)
   if(nrow(z)!=1L||z$metric_key!=q$metric_key)stop('Estimator veranderde de taakidentiteit.')
   z$science_fingerprint<-q$science_fingerprint;z$input_fingerprint<-q$input_fingerprint
   z$scientific_status<-'COMPUTED_PENDING_VALIDATION';z$publication_status<-'NOT_RELEASED'
   lo_store_put(s,z);ncompute<-ncompute+1L;op<-'COMPUTE'
   if(ncompute>=interrupt_after)stop('TEST_INTERRUPTION_AFTER_SQL_COMMIT')
  }
  operations[[i]]<-data.frame(metric_key=q$metric_key,operation=op)
 }
 lo_store_export(s)
 list(operations=do.call(rbind,operations),computed=ncompute,results=lo_store_frames(s)$current)
}
