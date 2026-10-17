lo_pilot <- function(bundle,cfg,out) {
 if(!dir.exists(cfg$root))stop('Projectmap ontbreekt: ',cfg$root)
 if(!identical(cfg$country,'NLD')||cfg$survey!='PISA'||cfg$year!=2018L||cfg$domain!='mathematics')
   stop('Deze integratieversie is begrensd tot de vastgelegde Nederlandse proef.')
 lo_engine_boot(bundle,cfg,file.path(cfg$state_root,'engine'),synthetic=FALSE)
 # Re-read the original cache selection each run; an old private copy must not hide input changes.
 prior<-get('RDS_FILES',.GlobalEnv)
 prior<-prior[!startsWith(tolower(normalizePath(prior,winslash='/',mustWork=FALSE)),paste0(tolower(normalizePath(cfg$state_root,winslash='/',mustWork=FALSE)),'/'))]
 assign('RDS_FILES',prior,.GlobalEnv)
 private_cache<-file.path(out,'input_cache');dir.create(private_cache,recursive=TRUE,showWarnings=FALSE)
 assign('CACHE',private_cache,.GlobalEnv)
 # Read existing country cache only; never prepare a complete raw international wave.
 reads<-list()
 assign('readRDS',function(file,...){
  z<-base::readRDS(file,...)
  reads[[length(reads)+1L]]<<-data.frame(path=normalizePath(file,winslash='/'),sha256=digest::digest(file=file,algo='sha256'),bytes=file.info(file)$size)
  z
 },.GlobalEnv)
 obj<-tryCatch(get('find_canonical',.GlobalEnv)('PISA',2018L,c('W')),
  finally=rm('readRDS',envir=.GlobalEnv))
 if(length(reads))write.csv(do.call(rbind,reads),file.path(out,'PILOT_SOURCE_FILES.csv'),row.names=FALSE)
 if(is.null(obj))stop('Geen bestaande geldige NLD/PISA/2018-cache gevonden. Geen grote bronrun gestart.')
 if(length(get('pv_names',.GlobalEnv)(obj$data,'mathematics'))!=10L)stop('PISA 2018 vereist voor deze proef alle tien wiskunde-PVs.')
 q<-read.csv(file.path(bundle,'PILOT_TASKS.csv'),colClasses='character',na.strings=character(),check.names=FALSE)
 q<-lo_tasks_prepare(q,obj,bundle)
 write.csv(q,file.path(out,'PILOT_TASKS.csv'),row.names=FALSE)
 write.csv(data.frame(survey='PISA',year=2018,country='NLD',n_rows=nrow(obj$data),input_fingerprint=q$input_fingerprint[1]),file.path(out,'PILOT_INPUT.csv'),row.names=FALSE)
 store<-file.path(cfg$state_root,'local_pilot_store')
 first<-lo_execute(q,store,function(t)lo_compute_one(obj,t))
 second<-lo_execute(q,store,function(t)stop('Identieke herhaalrun mag geen estimator aanroepen.'))
 if(second$computed!=0L||nrow(first$results)!=nrow(q))stop('Lokale hervatproef faalt.')
 write.csv(first$operations,file.path(out,'PILOT_FIRST_RUN.csv'),row.names=FALSE)
 write.csv(second$operations,file.path(out,'PILOT_REPEAT.csv'),row.names=FALSE)
 write.csv(second$results,file.path(out,'PILOT_RESULTS.csv'),row.names=FALSE)
 invisible(TRUE)
}
lo_worker_main <- function(bundle,cfgpath,out) {
 cfg<-dget(cfgpath);dir.create(out,recursive=TRUE,showWarnings=FALSE)
 required<-c('digest','DBI','RSQLite','arrow')
 missing<-required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
 if(length(missing))stop('Benodigde R-packages ontbreken: ',paste(missing,collapse=', '))
 for(f in c('REPAIRS.R','EXTENSIONS.R','store.R','engine.R','tests.R','app.R'))
   source(file.path(bundle,f),local=.GlobalEnv,encoding='UTF-8')
 stage<-'integratietests';ok<-FALSE;err<-''
 tryCatch({
  testdir<-tempfile('tests_',tmpdir=out);dir.create(testdir)
  checks<-tryCatch(lo_integration_tests(bundle,cfg,testdir),finally={
   if(file.exists(file.path(testdir,'INTEGRATION_TESTS.csv')))file.copy(file.path(testdir,'INTEGRATION_TESTS.csv'),file.path(out,'INTEGRATION_TESTS.csv'),overwrite=TRUE)
  })
  file.copy(file.path(testdir,'INTEGRATION_TESTS.csv'),file.path(out,'INTEGRATION_TESTS.csv'),overwrite=TRUE)
  if(cfg$mode=='pilot'){
   stage<-'lokale begrensde proef';lo_pilot(bundle,cfg,out)
  } else if(cfg$mode!='selftest')stop('Gebruik mode pilot of selftest; volledige productie is nog niet vrijgegeven.')
  ok<-TRUE
 },error=function(e){err<<-conditionMessage(e)})
 writeLines(c(paste0('STATUS=',if(ok)'PASS'else'FAIL'),paste0('STAGE=',stage),paste0('DETAIL=',err),
   'CENTRAL_PROJECT_STORAGE_CHANGED=FALSE','LONG_PRODUCTION_STARTED=FALSE',
   'FULL_SCIENTIFIC_SCOPE_RELEASED=FALSE',
   'NEXT=Beoordeel deze ketenproef; centrale migratie en overige wetenschappelijke modules blijven aparte open vrijgavepunten.'),file.path(out,'UITKOMST.txt'))
 writeLines(capture.output(sessionInfo()),file.path(out,'SESSION_INFO.txt'))
 cat(paste(readLines(file.path(out,'UITKOMST.txt')),collapse='\n'),'\n')
 invisible(ok)
}
