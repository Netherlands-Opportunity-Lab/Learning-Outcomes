args<-commandArgs(TRUE);root<-normalizePath(args[1],winslash='/',mustWork=TRUE);mode<-args[2]
source('06_pipeline/LO_PROCESS_LOCK.R')
if(mode=='legacy') {
  lock<-lo_process_lock(file.path(root,'results/master_reconciliation/.SCIENTIFIC_MASTER_WRITER.lck'))
}else {
  lock<-lo_startup_lock(file.path(root,'git-common'),file.path(root,'results'))
}
if(mode%in%c('hold','legacy')) {
  jsonlite::write_json(list(pid=Sys.getpid()),file.path(root,'ready.json'),auto_unbox=TRUE)
  repeat Sys.sleep(1)
}else {
  # Represents the first checkout mutation. A competitor must never reach it.
  writeLines('checkout update allowed',file.path(root,'checkout-updated'))
  lo_process_unlock(lock)
}
