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
