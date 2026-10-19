# Freeze a completed grid for scientific review, without changing production.
# Rscript scripts/prepare_scientific_review_snapshot.R <repo> <root> <work> <result-commit> <exact-tasks.csv> <source-bundle>
# A separate version directory preserves every preceding scope's evidence.
(function() {
  args<-commandArgs(TRUE);stopifnot(length(args)==6L,grepl('^[a-f0-9]{40}$',args[4]))
  repo<-normalizePath(args[1],winslash='/');root<-normalizePath(args[2],winslash='/')
  bundle<-normalizePath(args[6],winslash='/');Sys.setenv(LO_REPO_ROOT=repo)
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
  # The finalizer requires a completed Q review. Build its review input from
  # sealed results with the SAME existing aggregate exporter, without waiting
  # for that finalizer's not-yet-reviewed product checkpoint (a dependency loop).
  # This does not run an estimator, install a gate or create a public candidate.
  for(f in c('GRID_ARCHIVE_BATCH.R','LO_SCOPE_DECISIONS.R','LO_POPULATION_REVIEW.R','LO_GENDER_POOL_POLICY.R','LO_FINAL_GUIDED_EXPORT.R','LO_ANALYSIS_SUPPORT_REVIEW.R','LO_ANALYSIS_SUPPORT_POLICY.R'))
    source(file.path(repo,'06_pipeline',f))
  approval_path<-file.path(root,'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv')
  approval_sha<-sha(approval_path)
  all_approved<-read.csv(approval_path,stringsAsFactors=FALSE,na.strings=character(),check.names=FALSE)
  approved<-all_approved[all_approved$cell_id%in%grid$cell_id[grid$status=='SCIENTIFICALLY_VALIDATED'],,drop=FALSE]
  stopifnot(setequal(approved$cell_id,grid$cell_id[grid$status=='SCIENTIFICALLY_VALIDATED']),
    all(approved$result_hash==grid$result_hash[match(approved$cell_id,grid$cell_id)]))
  started<-proc.time()[3];stopifnot(isTRUE(lo_grid_verify_result_artifacts(approved)))
  verification<-list(status='ACTUAL_RESULT_SOURCE_METHOD_CERTIFICATES_REVERIFIED',
    rows=nrow(approved),approval_sha256=approval_sha,reviewed_grid_sha256=sha(file.path(state,'PRIVATE_MASTER_GRID.csv')),
    elapsed_seconds=unname(proc.time()[3]-started),no_pupil_calculation=TRUE,
    review_code_sha256=sha(file.path(repo,'06_pipeline/GRID_ARCHIVE_BATCH.R')),
    snapshot_code_sha256=sha(file.path(repo,'scripts/prepare_scientific_review_snapshot.R')))
  support_out<-file.path(work,'Q01_ANALYSIS_SUPPORT')
  support_review<-lo_analysis_support_review(repo,tasks,grid,support_out)
  if(support_review$n_mismatches!=0L)stop('SCIENTIFIC_SNAPSHOT_ANALYSIS_SUPPORT_COUNT_MISMATCH')
  support<-read.csv(file.path(support_out,'ANALYSIS_SUPPORT.csv'),stringsAsFactors=FALSE,na.strings=character())
  restricted<-lo_population_review_rows(tasks,lo_population_review(repo))
  approved<-approved[!approved$cell_id%in%tasks$metric_key[!is.na(restricted)],,drop=FALSE]
  temporary<-tempfile('review_export_',tmpdir=work);dir.create(temporary)
  on.exit(unlink(temporary,recursive=TRUE),add=TRUE)
  matched_support<-lo_analysis_support_match(repo,tasks,approved,support)
  guided<-lo_guided_grid_export(bundle,tasks,approved,temporary,scope_decisions=lo_read_scope_decisions(repo),analysis_support=matched_support)
  stopifnot(nrow(guided)==1L,guided$mapping_holds==0L,guided$validated_input_cells==nrow(approved))
  export_path<-file.path(temporary,'PRIVATE_GUIDED_VALIDATED_ROWS.csv');export<-read(export_path)
  stopifnot(all(export$cell_id%in%approved$cell_id),approval_sha==sha(approval_path))
  inputs<-c(
    'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'='master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv',
    'master_reconciliation/SOURCE_UNAVAILABLE_CELLS.csv'='master_reconciliation/SOURCE_UNAVAILABLE_CELLS.csv',
    'master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv'='master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv',
    'product_export/PRIVATE_TASKS.csv'='international/EXACT_ALL_REQUIRED_TASKS.csv',
    'public_inputs/dashboard_cells.csv'='PRIVATE_REVIEW_EXPORT_OVERRIDE',
    'public_inputs/COUNTRY_SOURCE_ELIGIBILITY.csv'='FIXED_PRODUCTION_V1/all_required/COUNTRY_SOURCE_ELIGIBILITY.csv',
    'product_export/FIXED_INPUT_MANIFEST.json'='FIXED_PRODUCTION_V1/all_required/FIXED_INPUT_MANIFEST.json')
  snapshot<-file.path(work,'snapshot');dir.create(snapshot,recursive=TRUE,showWarnings=FALSE)
  sources<-file.path(root,unname(inputs))
  sources[names(inputs)=='product_export/PRIVATE_TASKS.csv']<-tasks_path
  sources[names(inputs)=='public_inputs/dashboard_cells.csv']<-export_path
  before<-setNames(vapply(sources,sha,character(1)),names(inputs))
  copy_exact<-function(from,to) {
    dir.create(dirname(to),recursive=TRUE,showWarnings=FALSE)
    if(file.exists(to)) {if(sha(to)!=sha(from))stop('IMMUTABLE_SNAPSHOT_CHANGED: ',basename(to))}
    else if(!file.copy(from,to,overwrite=FALSE))stop('SNAPSHOT_COPY_FAILED')
    stopifnot(sha(to)==sha(from))
  }
  for(i in seq_along(inputs))copy_exact(sources[i],file.path(snapshot,names(inputs)[i]))
  copy_exact(file.path(state,'PRIVATE_MASTER_GRID.csv'),file.path(work,'REVIEWED_MASTER_GRID.csv'))
  for(name in c('PRIVATE_APPROVED_EXTENSION_ROWS.csv','PRIVATE_GUIDED_MAPPING_HOLDS.csv','GUIDED_EXPORT_SUMMARY.csv'))
    copy_exact(file.path(temporary,name),file.path(snapshot,'product_export',name))
  stopifnot(identical(before,setNames(vapply(sources,sha,character(1)),names(inputs))))
  write_immutable<-function(value,path) {
    if(file.exists(path))stopifnot(identical(jsonlite::fromJSON(path,simplifyVector=FALSE),
      jsonlite::fromJSON(jsonlite::toJSON(value,auto_unbox=TRUE),simplifyVector=FALSE)))
    else jsonlite::write_json(value,path,pretty=TRUE,auto_unbox=TRUE)
  }
  proof<-list(export_sha256=sha(file.path(snapshot,'public_inputs/dashboard_cells.csv')),
    source_grid_sha256=sha(file.path(work,'REVIEWED_MASTER_GRID.csv')),
    approved_registry_sha256=approval_sha,validated_input_cells=nrow(approved),mapping_holds=0L,
    exporter_sha256=sha(file.path(repo,'06_pipeline/LO_FINAL_GUIDED_EXPORT.R')),
    figure_contract_sha256=sha(file.path(bundle,'FIGURE_SERIES_CONTRACT_20261002.csv')),
    population_policy_sha256=sha(file.path(repo,'06_pipeline/review_20261013/POPULATION_CORRECTIONS.json')),
    analysis_support_sha256=sha(file.path(support_out,'ANALYSIS_SUPPORT.csv')),
    support_policy_sha256=sha(file.path(repo,'06_pipeline/review_20261013/ANALYSIS_SUPPORT_POLICY.json')),
    quality_restricted_rows=guided$quality_restricted_rows,
    reuse='EXACT_SEALED_RESULTS_THROUGH_EXISTING_EXPORTER_NO_ESTIMATION',result_commit=args[4])
  write_immutable(proof,file.path(snapshot,'product_export/SNAPSHOT_EXPORT_EVIDENCE.json'))
  write_immutable(list(inputs=as.list(before),result_commit=args[4],stable=TRUE,
    snapshot_script_sha256=sha(file.path(repo,'scripts/prepare_scientific_review_snapshot.R'))),file.path(snapshot,'SNAPSHOT.json'))
  verification_path<-file.path(work,'RESULT_ARTIFACT_VERIFICATION.json')
  if(file.exists(verification_path)) {
    old<-jsonlite::fromJSON(verification_path)
    stopifnot(old$approval_sha256==verification$approval_sha256,
      old$reviewed_grid_sha256==verification$reviewed_grid_sha256,
      old$snapshot_code_sha256==verification$snapshot_code_sha256)
  }else jsonlite::write_json(verification,verification_path,pretty=TRUE,auto_unbox=TRUE)
  cat('IMMUTABLE_SCIENTIFIC_SNAPSHOT: ',nrow(grid),' targets; ',nrow(export),' product rows; no pupil recalculation\n',sep='')
})()
