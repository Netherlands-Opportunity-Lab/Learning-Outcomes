# Freeze a completed grid for scientific review, without changing production.
# Rscript scripts/prepare_scientific_review_snapshot.R <repo> <root> <work> <result-commit> <exact-tasks.csv>
# A separate version directory preserves every preceding scope's evidence.
(function() {
  args<-commandArgs(TRUE);stopifnot(length(args)==5L,grepl('^[a-f0-9]{40}$',args[4]))
  repo<-normalizePath(args[1],winslash='/');root<-normalizePath(args[2],winslash='/')
  work<-args[3];dir.create(work,recursive=TRUE,showWarnings=FALSE)
  work<-normalizePath(work,winslash='/');state<-file.path(root,'FIXED_PRODUCTION_V1/all_required')
  source(file.path(repo,'06_pipeline/LO_PROCESS_LOCK.R'))
  lock<-lo_process_lock(file.path(root,'master_reconciliation/.SCIENTIFIC_MASTER_WRITER.lck'))
  on.exit(lo_process_unlock(lock),add=TRUE)
  sha<-function(p)digest::digest(file=p,algo='sha256')
  read<-function(p)read.csv(p,colClasses='character',na.strings=character(),check.names=FALSE)
  grid<-read(file.path(state,'PRIVATE_MASTER_GRID.csv'))
  if(anyDuplicated(grid$cell_id)||any(grid$status!='SCIENTIFICALLY_VALIDATED'&!startsWith(grid$status,'UNAVAILABLE_')))
    stop('SCIENTIFIC_SNAPSHOT_REQUIRES_ALL_SELECTED_TARGETS_ACCOUNTED_FOR')
  fixed<-jsonlite::fromJSON(file.path(state,'FIXED_INPUT_MANIFEST.json'))
  stopifnot(sha(file.path(state,'PRIVATE_MASTER_GRID.csv'))==fixed$grid_sha256)
  tasks_path<-normalizePath(args[5],winslash='/');tasks<-read(tasks_path)
  stopifnot(!anyDuplicated(tasks$metric_key),setequal(tasks$metric_key,grid$cell_id))
  source(file.path(repo,'06_pipeline/MASTER_ESTIMATION_GRID.R'))
  target<-lo_grid_from_tasks(tasks)
  stopifnot(all(target$target_contract_sha256==grid$target_contract_sha256[match(target$cell_id,grid$cell_id)]))
  guided<-read(file.path(state,'GUIDED_EXPORT_SUMMARY.csv'))
  stopifnot(nrow(guided)==1L,as.integer(guided$mapping_holds)==0L,
    as.integer(guided$validated_input_cells)==sum(grid$status=='SCIENTIFICALLY_VALIDATED'))
  export<-read(file.path(state,'PRIVATE_GUIDED_VALIDATED_ROWS.csv'))
  stopifnot(all(export$cell_id%in%grid$cell_id[grid$status=='SCIENTIFICALLY_VALIDATED']))
  # Read-back the existing exporter checkpoint; a stale preview is not proof.
  checkpoint<-jsonlite::fromJSON(file.path(state,'FINAL_EXPORT_CHECKPOINT_guided_mapping.json'))
  stopifnot(isTRUE(checkpoint$evidence_freshly_verified))
  for(n in names(checkpoint$output_sha256))stopifnot(sha(file.path(state,n))==checkpoint$output_sha256[[n]])
  inputs<-c(
    'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'='master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv',
    'master_reconciliation/SOURCE_UNAVAILABLE_CELLS.csv'='master_reconciliation/SOURCE_UNAVAILABLE_CELLS.csv',
    'master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv'='master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv',
    'product_export/PRIVATE_TASKS.csv'='international/EXACT_ALL_REQUIRED_TASKS.csv',
    'public_inputs/dashboard_cells.csv'='FIXED_PRODUCTION_V1/all_required/PRIVATE_GUIDED_VALIDATED_ROWS.csv',
    'public_inputs/COUNTRY_SOURCE_ELIGIBILITY.csv'='FIXED_PRODUCTION_V1/all_required/COUNTRY_SOURCE_ELIGIBILITY.csv',
    'product_export/FIXED_INPUT_MANIFEST.json'='FIXED_PRODUCTION_V1/all_required/FIXED_INPUT_MANIFEST.json',
    'product_export/FINAL_EXPORT_CHECKPOINT_guided_mapping.json'='FIXED_PRODUCTION_V1/all_required/FINAL_EXPORT_CHECKPOINT_guided_mapping.json')
  snapshot<-file.path(work,'snapshot');dir.create(snapshot,recursive=TRUE,showWarnings=FALSE)
  sources<-file.path(root,unname(inputs))
  sources[names(inputs)=='product_export/PRIVATE_TASKS.csv']<-tasks_path
  before<-setNames(vapply(sources,sha,character(1)),names(inputs))
  copy_exact<-function(from,to) {
    dir.create(dirname(to),recursive=TRUE,showWarnings=FALSE)
    if(file.exists(to)) {if(sha(to)!=sha(from))stop('IMMUTABLE_SNAPSHOT_CHANGED: ',basename(to))}
    else if(!file.copy(from,to,overwrite=FALSE))stop('SNAPSHOT_COPY_FAILED')
    stopifnot(sha(to)==sha(from))
  }
  for(i in seq_along(inputs))copy_exact(sources[i],file.path(snapshot,names(inputs)[i]))
  copy_exact(file.path(state,'PRIVATE_MASTER_GRID.csv'),file.path(work,'REVIEWED_MASTER_GRID.csv'))
  stopifnot(identical(before,setNames(vapply(sources,sha,character(1)),names(inputs))))
  write_immutable<-function(value,path) {
    if(file.exists(path))stopifnot(identical(jsonlite::fromJSON(path,simplifyVector=FALSE),
      jsonlite::fromJSON(jsonlite::toJSON(value,auto_unbox=TRUE),simplifyVector=FALSE)))
    else jsonlite::write_json(value,path,pretty=TRUE,auto_unbox=TRUE)
  }
  proof<-list(export_sha256=sha(file.path(snapshot,'public_inputs/dashboard_cells.csv')),
    source_grid_sha256=sha(file.path(work,'REVIEWED_MASTER_GRID.csv')),
    run_export_checkpoint_sha256=sha(file.path(snapshot,'product_export/FINAL_EXPORT_CHECKPOINT_guided_mapping.json')),
    reuse='EXACT_COMPLETED_FINALIZE_EXPORT_NO_ESTIMATION',result_commit=args[4])
  write_immutable(proof,file.path(snapshot,'product_export/SNAPSHOT_EXPORT_EVIDENCE.json'))
  write_immutable(list(inputs=as.list(before),result_commit=args[4],stable=TRUE,
    snapshot_script_sha256=sha(file.path(repo,'scripts/prepare_scientific_review_snapshot.R'))),file.path(snapshot,'SNAPSHOT.json'))
  cat('IMMUTABLE_SCIENTIFIC_SNAPSHOT: ',nrow(grid),' targets; ',nrow(export),' product rows; no pupil recalculation\n',sep='')
})()
