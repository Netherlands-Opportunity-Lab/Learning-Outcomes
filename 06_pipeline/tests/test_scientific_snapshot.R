# A reviewer must not obtain a completed-scope snapshot from an unfinished or
# changed grid, or while a producer owns the scientific writer lock.
(function() {
  repo<-normalizePath('.',winslash='/')
  tmp<-tempfile('scientific_snapshot_');dir.create(tmp)
  on.exit(unlink(tmp,recursive=TRUE),add=TRUE)
  root<-file.path(tmp,'root');state<-file.path(root,'FIXED_PRODUCTION_V1/all_required')
  dir.create(state,recursive=TRUE);tasks<-file.path(tmp,'tasks.csv')
  write.csv(data.frame(metric_key='exact'),tasks,row.names=FALSE)
  path<-file.path(state,'PRIVATE_MASTER_GRID.csv')
  grid<-data.frame(cell_id='exact',status='TARGET_NOT_YET_ADJUDICATED')
  write.csv(grid,path,row.names=FALSE)
  run<-function(expected) {
    result<-suppressWarnings(system2(file.path(R.home('bin'),'Rscript'),
      shQuote(c(file.path(repo,'scripts/prepare_scientific_review_snapshot.R'),repo,root,
        file.path(tmp,'review'),paste(rep('a',40),collapse=''),tasks,tmp)),stdout=TRUE,stderr=TRUE))
    stopifnot(!is.null(attr(result,'status')),attr(result,'status')!=0L,
      any(grepl(expected,result,fixed=TRUE)),
      !file.exists(file.path(tmp,'review/SCIENTIFIC_REVIEW_MANIFEST.json')))
  }
  run('SCIENTIFIC_SNAPSHOT_REQUIRES_ALL_SELECTED_TARGETS_ACCOUNTED_FOR')
  grid$status<-'SCIENTIFICALLY_VALIDATED';write.csv(grid,path,row.names=FALSE)
  jsonlite::write_json(list(grid_sha256='changed'),file.path(state,'FIXED_INPUT_MANIFEST.json'),auto_unbox=TRUE)
  run('is not TRUE')
  source(file.path(repo,'06_pipeline/LO_PROCESS_LOCK.R'))
  lock<-lo_process_lock(file.path(root,'master_reconciliation/.SCIENTIFIC_MASTER_WRITER.lck'))
  on.exit(lo_process_unlock(lock),add=TRUE,after=FALSE)
  run('PRODUCTION_WRITER_ALREADY_ACTIVE')
  lo_process_unlock(lock);lock<-NULL
  cat('PASS scientific snapshot rejects incomplete grid, changed audit bytes and an active writer\n')
})()
