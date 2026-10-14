# The fixed stage executes the saved approved worklist; no broad fallback.
lo_fixed_produce <- function(bundle,scope_info,tasks,out,native_run=FALSE,grid=NULL) {
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  result<-data.frame(scope=scope_info$scope,selected_contracts=nrow(tasks),
    native_execution="PREVIEW_ONLY",scientific_release="NOT_AUTOMATICALLY_VALIDATED")
  if(native_run) {
    if(is.null(grid))stop("EXACT_GRID_REQUIRED")
    repo<-Sys.getenv("LO_REPO_ROOT",unset="")
    if(!nzchar(repo))stop("EXACT_REPO_ROOT_REQUIRED")
    source(file.path(repo,"06_pipeline","LO_COMPACT_RECOMPUTE.R"),local=environment(),encoding="UTF-8")
    root<-normalizePath(file.path(out,"..",".."),winslash="/",mustWork=TRUE)
    run<-lo_compact_run(bundle,repo,scope_info,tasks,root,grid=grid)
    result$native_execution<-run$status
    result$approved_cells<-run$required_active_cells
    result$new_candidates<-run$new_rows_written
    result$reused_candidates<-run$reused_rows
    result$held_cells<-run$holds_this_attempt
  }
  write.csv(result,file.path(out,"PRODUCTION_SCOPE_STATUS.csv"),row.names=FALSE)
  invisible(result)
}
