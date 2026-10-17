# Source-free subprocess fixture. The Python parent force-kills this R process;
# no R on.exit handler or simulated exception performs the recovery.
args<-commandArgs(trailingOnly=TRUE);work<-args[1];mode<-args[2]
for(p in c('MASTER_ESTIMATION_GRID.R','LO_SCOPE_DECISIONS.R','LO_COMPACT_GRID_STORE.R',
 'LO_COMPACT_RECOMPUTE.R','LO_EXACT_DISPATCH.R','LO_PROCESS_LOCK.R'))source(file.path('06_pipeline',p))
sha<-function(x)paste(rep(x,64),collapse='')
if(mode=='setup') {
 dir.create(work,recursive=TRUE,showWarnings=FALSE)
 tasks<-data.frame(metric_key=c('first','second'),country='NLD',survey='PISA',year='2022',
  domain=c('mathematics','reading'),module='core',stat='mean',group='total',definition='score',
  peer_definition='',threshold='',unit='score_points',calculation_policy='',
  contract_figure_id=c('TR_MEAN_age15_mathematics','TR_MEAN_age15_reading'))
 src<-file.path(work,'canonical.rds')
 saveRDS(list(data=data.frame(x=1:3),meta=list(survey='PISA',year='2022',v9_country='NLD')),src)
 evidence<-file.path(work,'method.txt');writeLines('Synthetic method',evidence)
 grid<-lo_grid_from_tasks(tasks);grid$status<-'COMPUTE_REQUIRED_AFTER_METHOD_GATE'
 grid$source_path<-src;grid$source_edition_sha256<-lo_exact_sha(src)
 grid$input_fingerprint<-sha('a');grid$code_fingerprint<-sha('b')
 grid$sample_id<-'synthetic';grid$method_version<-'synthetic'
 grid$weight_design<-'synthetic';grid$pv_rule<-'synthetic';grid$variance_rule<-'synthetic'
 fields<-c('sample_id','method_version','weight_design','pv_rule','variance_rule',
  'source_edition_sha256','input_fingerprint','code_fingerprint')
 cert<-c(list(status='METHOD_SAMPLE_INPUT_CERTIFIED',cell_ids=tasks$metric_key),as.list(grid[1,fields]))
 cert$evidence_files<-data.frame(path=evidence,sha256=lo_exact_sha(evidence))
 cp<-file.path(work,'certificate.json');jsonlite::write_json(cert,cp,auto_unbox=TRUE)
 grid$certification_path<-cp;grid$certification_sha256<-lo_exact_sha(cp)
 saveRDS(list(tasks=tasks,grid=grid),file.path(work,'fixture.rds'))
 quit(save='no')
}
pause_for_kill<-function() {
 jsonlite::write_json(list(pid=Sys.getpid()),file.path(work,'kill.ready'),auto_unbox=TRUE)
 Sys.sleep(120)
 stop('Parent failed to kill fixture')
}
run<-function() {
 outer<-lo_process_lock(file.path(work,'.FIXED_PRODUCTION_WRITER.lck'))
 on.exit(lo_process_unlock(outer))
 f<-readRDS(file.path(work,'fixture.rds'))
 backend<-list(code_sha=sha('b'),read=readRDS,projection=function(obj,q)sha('a'),
  estimate=function(obj,q) {
   cat(q$metric_key,'\n',file=file.path(work,'calculations.txt'),append=TRUE,sep='')
   q$estimate<-500;q$se<-2
   if(mode=='kill_during_estimate'&&'second'%in%q$metric_key)pause_for_kill()
   q
  },count=function(obj,q)rep(3L,nrow(q)))
 lo_exact_dispatch('.',work,list(scope='nld_only',selected='NLD'),f$tasks,f$grid,
   file.path(work,'compact'),backend)
}
if(mode=='kill_during_transaction') {
 original_put<-lo_compact_put
 lo_compact_put<-function(con,rows,...) {
  result<-original_put(con,rows,...)
  if('second'%in%rows$cell_id)pause_for_kill()
  result
 }
}
result<-run()
jsonlite::write_json(result,file.path(work,paste0(mode,'.json')),auto_unbox=TRUE,pretty=TRUE)
