# The saved, audited grid remains authoritative for international producers.
# An unavailable appendix cell must not block unrelated background statistics.
lo_international_worklist <- function(tasks,grid) {
  if(!all(c('cell_id','status','target_contract_sha256')%in%names(grid)) ||
     anyDuplicated(grid$cell_id))stop('INTERNATIONAL_WORKLIST_INVALID_GRID')
  exact<-lo_grid_from_tasks(tasks);i<-match(exact$cell_id,grid$cell_id)
  if(anyNA(i)||any(exact$target_contract_sha256!=grid$target_contract_sha256[i]))
    stop('INTERNATIONAL_WORKLIST_UNAPPROVED_OR_CHANGED_TASK')
  skip<-startsWith(grid$status[i],'UNAVAILABLE_')|grid$status[i]=='HOLD_SOURCE_MAPPING_REVIEW'
  list(tasks=tasks[!skip,,drop=FALSE],excluded=grid[i[skip],,drop=FALSE])
}
