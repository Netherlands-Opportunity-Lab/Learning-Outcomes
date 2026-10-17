# Kernel-owned locks are released even when R is killed or the machine restarts.
# The small lock file deliberately stays on disk: deleting it could allow two
# processes to lock different inodes and write the same grid concurrently.
lo_process_lock <- function(path,legacy_path=NULL) {
  if(!requireNamespace('filelock',quietly=TRUE))
    stop('PROCESS_LOCK_DEPENDENCY_MISSING: restore the recorded renv.lock')
  if(!is.null(legacy_path) && (file.exists(legacy_path)||dir.exists(legacy_path)))
    stop('LEGACY_LOCK_REQUIRES_OWNER_CHECK: ',legacy_path)
  dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
  handle<-filelock::lock(path,exclusive=TRUE,timeout=0)
  if(is.null(handle))stop('PRODUCTION_WRITER_ALREADY_ACTIVE: ',basename(path))
  handle
}
lo_process_unlock <- function(handle) {
  if(!is.null(handle))filelock::unlock(handle)
  invisible(NULL)
}

# Protect the checkout before Git can update code that an active R worker may
# load lazily. The master probe also detects workers started before this guard.
lo_startup_lock <- function(git_common_dir,root) {
  held<-lo_process_lock(file.path(git_common_dir,'LO_ACTIVE_RUN.lck'))
  success<-FALSE
  on.exit(if(!success)lo_process_unlock(held),add=TRUE)
  probe<-lo_process_lock(file.path(root,'master_reconciliation','.SCIENTIFIC_MASTER_WRITER.lck'))
  lo_process_unlock(probe)
  success<-TRUE;held
}
