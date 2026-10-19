# The saved, audited grid remains authoritative for international producers.
# An unavailable appendix cell must not block unrelated background statistics.
lo_ses_application_country_keys <- function(selected,manifest) {
  if(!all(c('country','survey')%in%names(manifest)))stop('SES_CONTEXT_MANIFEST_REQUIRED')
  # Legacy SES cache keys included non-PISA countries. They have no source rows
  # in this estimator and cannot affect calibration, imputation or saved scores.
  # Keep these inert keys when an IEA-only admission changes; do not re-score
  # millions of unchanged PISA pupils, or add an unselected PISA country.
  no_pisa<-setdiff(unique(manifest$country),unique(manifest$country[manifest$survey=='PISA']))
  sort(unique(c(selected,no_pisa)))
}

lo_international_worklist <- function(tasks,grid) {
  if(!all(c('cell_id','status','target_contract_sha256')%in%names(grid)) ||
     anyDuplicated(grid$cell_id))stop('INTERNATIONAL_WORKLIST_INVALID_GRID')
  exact<-lo_grid_from_tasks(tasks);i<-match(exact$cell_id,grid$cell_id)
  if(anyNA(i)||any(exact$target_contract_sha256!=grid$target_contract_sha256[i]))
    stop('INTERNATIONAL_WORKLIST_UNAPPROVED_OR_CHANGED_TASK')
  skip<-startsWith(grid$status[i],'UNAVAILABLE_')|grid$status[i]=='HOLD_SOURCE_MAPPING_REVIEW'
  list(tasks=tasks[!skip,,drop=FALSE],excluded=grid[i[skip],,drop=FALSE],
       contracts=grid[i[!skip],c('cell_id','target_contract_sha256'),drop=FALSE])
}

# One immutable in-process approval context per audited run. Certification
# checks each requested contract and fresh policy/code bytes, rather than
# rebuilding every country's complete task catalogue for each small block.
lo_international_certification_guard <- function(repo,root,scope,worklist) {
  state<-file.path(root,'FIXED_PRODUCTION_V1',scope)
  manifest_path<-file.path(state,'FIXED_INPUT_MANIFEST.json')
  grid_path<-file.path(state,'PRIVATE_MASTER_GRID.csv')
  sha<-function(p)digest::digest(file=p,algo='sha256')
  manifest<-jsonlite::fromJSON(manifest_path)
  if(manifest$scope!=scope||sha(grid_path)!=manifest$grid_sha256)stop('CERTIFICATION_SAVED_AUDIT_CHANGED')
  grid<-read.csv(grid_path,colClasses='character',na.strings=character())
  contracts<-worklist$contracts
  if(!is.data.frame(contracts)||anyDuplicated(contracts$cell_id))stop('CERTIFICATION_CONTRACT_CONTEXT_INVALID')
  at<-match(contracts$cell_id,grid$cell_id)
  if(anyNA(at)||any(contracts$target_contract_sha256!=grid$target_contract_sha256[at])||
     any(startsWith(grid$status[at],'UNAVAILABLE_')|grid$status[at]=='HOLD_SOURCE_MAPPING_REVIEW'))
    stop('CERTIFICATION_CONTEXT_NOT_IN_AUDIT')
  paths<-file.path(repo,'06_pipeline',c('SCOPE_APPROVALS.csv','COUNTRY_PRODUCTION_APPROVALS.csv',
    'review_20261013/POPULATION_CORRECTIONS.json','LO_COUNTRY_TASKS.R','LO_COUNTRY_REGISTRY.R',
    'LO_SCOPE_DECISIONS.R','LO_APPROVED_EXTENSIONS.R','LO_GENDER_POOL_POLICY.R',
    'LO_INTERNATIONAL_WORKLIST.R','MASTER_ESTIMATION_GRID.R','LO_POPULATION_REVIEW.R',
    'LO_BALANCED_MEMBERSHIP.R','LO_RUN_CONFIG.R'))
  paths<-c(paths,manifest_path,grid_path)
  source_paths<-file.path(root,c('master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv',
    'international/SOURCE_RUN_MANIFEST.csv','international/HOME_SOURCE_MANIFEST.csv'))
  paths<-c(paths,source_paths[file.exists(source_paths)])
  cfg<-Sys.getenv('LO_RUN_CONFIG','');if(nzchar(cfg))paths<-c(paths,cfg)
  expected<-vapply(paths,sha,character(1))
  allowed<-setNames(contracts$target_contract_sha256,contracts$cell_id)
  rm(grid,contracts,worklist)
  function(requested,requested_scope) {
    if(!identical(scope,requested_scope)||!identical(vapply(paths,sha,character(1)),expected))
      stop('CERTIFICATION_POLICY_OR_AUDIT_CHANGED')
    want<-lo_grid_from_tasks(requested)
    hashes<-unname(allowed[want$cell_id])
    if(anyNA(hashes)||anyDuplicated(want$cell_id)||any(hashes!=want$target_contract_sha256))
      stop('CERTIFICATION_TASK_NOT_EXACTLY_APPROVED')
    invisible(TRUE)
  }
}
