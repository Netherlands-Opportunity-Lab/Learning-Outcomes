# Configure the existing START.R route for an isolated source replication.
# This is a launcher and post-run comparison, never a second estimator.
lo_start_fresh_source_replication <- function(settings_path, preview=FALSE) {
  stopifnot(requireNamespace('jsonlite',quietly=TRUE),requireNamespace('digest',quietly=TRUE))
  settings<-jsonlite::fromJSON(settings_path)
  needed<-c('repository','code_commit','output_root','configuration_path',
    'configuration_sha256','source_bindings','source_bindings_sha256',
    'author_repository','drive_config','drive_config_sha256','python','git',
    'reference_grid','reference_grid_sha256','minimum_free_bytes')
  if(!all(needed%in%names(settings)))stop('FRESH_SETTINGS_INCOMPLETE')
  sha<-function(path)digest::digest(file=path,algo='sha256')
  for(pair in list(c('configuration_path','configuration_sha256'),
                  c('source_bindings','source_bindings_sha256'),
                  c('drive_config','drive_config_sha256'))) {
    if(sha(settings[[pair[1]]])!=settings[[pair[2]]])stop('FRESH_SETTINGS_BYTES_CHANGED: ',pair[1])
  }
  repo<-normalizePath(settings$repository,winslash='/',mustWork=TRUE)
  root<-normalizePath(settings$output_root,winslash='/',mustWork=FALSE)
  path_key<-function(x)if(.Platform$OS.type=='windows')tolower(x)else x
  rk<-path_key(root);pk<-path_key(repo)
  if(rk==pk||startsWith(pk,paste0(rk,'/'))||startsWith(rk,paste0(pk,'/'))||
     startsWith(path_key(normalizePath(settings$reference_grid,winslash='/',mustWork=TRUE)),paste0(rk,'/')))
    stop('FRESH_OUTPUT_OVERLAPS_REPOSITORY_OR_REFERENCE')
  cfg<-jsonlite::fromJSON(settings$configuration_path)
  approved<-jsonlite::fromJSON(file.path(repo,
    '06_pipeline/review_20261013/release47_20261020/RELEASE_PHASE_DECISION.json'))
  if(cfg$scope!='all_required'||!setequal(cfg$selection$countries,approved$current_countries)||
     any(cfg$selection$countries%in%approved$deferred_countries))
    stop('FRESH_RUN_MUST_USE_EXACT_CURRENT47_SELECTION')
  bindings<-read.csv(settings$source_bindings,colClasses='character',na.strings=character())
  if(!all(c('sha256','path')%in%names(bindings))||!nrow(bindings)||
     anyDuplicated(bindings$sha256)||!all(file.exists(bindings$path)))
    stop('FRESH_SOURCE_BINDINGS_INCOMPLETE')
  drive<-jsonlite::fromJSON(settings$drive_config)
  if(drive$data_visibility!='PRIVATE_ACCOUNT_ONLY'||!grepl('/fresh-current47-',drive$remote,fixed=TRUE)||
     path_key(normalizePath(drive$local_results_root,winslash='/',mustWork=FALSE))!=rk)
    stop('FRESH_RUN_REQUIRES_SEPARATE_PRIVATE_CHECKPOINT_DESTINATION')
  check_git<-function(path) {
    value<-system2(settings$git,shQuote(c('-C',path,'rev-parse','HEAD')),stdout=TRUE,stderr=TRUE)
    if(length(value)!=1L||!is.null(attr(value,'status')))stop('FRESH_GIT_IDENTITY_UNAVAILABLE')
    value
  }
  if(check_git(repo)!=settings$code_commit)stop('FRESH_PINNED_CODE_COMMIT_DIFFERS')
  if(check_git(settings$author_repository)!='1da4b26097e84e732973af672355a1c3103d5d33')
    stop('FRESH_AUTHOR_COMMIT_DIFFERS')
  source(file.path(repo,'06_pipeline/LO_PRODUCTION_SPACE.R'),local=environment())
  free<-min(lo_production_free_bytes(dirname(root)),lo_production_free_bytes(tempdir()))
  cat('Fresh replication: ',length(approved$current_countries),' countries; ',
      nrow(bindings),' source files located; deferred36 excluded.\n',sep='')
  cat('Free disk: ',round(free/1024^3,2),' GiB; initial conservative budget: ',
      round(settings$minimum_free_bytes/1024^3,2),' GiB.\n',sep='')
  if(preview)return(invisible(list(ready_for_space=is.finite(free)&&free>=settings$minimum_free_bytes,
    free_bytes=free,required_bytes=settings$minimum_free_bytes,estimations_run=0L)))
  if(!is.finite(free)||free<settings$minimum_free_bytes)
    stop('FRESH_RUN_SPACE_BUDGET_NOT_MET; no source production started')
  contract<-list(settings_sha256=sha(settings_path),source_commit=settings$code_commit)
  marker<-file.path(root,'FRESH_RUN_CONTRACT.json')
  if(dir.exists(root)&&!file.exists(marker))stop('FRESH_OUTPUT_IS_NOT_AN_EMPTY_NEW_RUN')
  if(file.exists(marker)) {
    if(!identical(jsonlite::fromJSON(marker),contract))stop('FRESH_RESUME_CONTRACT_CHANGED')
  } else {
    dir.create(root,recursive=TRUE)
    jsonlite::write_json(contract,marker,auto_unbox=TRUE,pretty=TRUE)
  }
  vars<-c('PATH','LO_REPO_ROOT','LO_REPRODUCE_COMMIT','LO_FIXED_ROOT','LO_RUN_CONFIG',
    'LO_SOURCE_BINDINGS','LO_COBREROS_ROOT','LO_DRIVE_SYNC_CONFIG','LO_PYTHON',
    'LO_RUN_OUTPUT','LO_START_ACTION','LO_FRESH_REPLICATION','LO_GITHUB_RESULTS',
    'LO05_BUNDLE','LO_SCOPE')
  previous<-Sys.getenv(vars,unset=NA_character_)
  on.exit({
    Sys.unsetenv(vars[is.na(previous)])
    do.call(Sys.setenv,as.list(previous[!is.na(previous)]))
  },add=TRUE)
  Sys.unsetenv(c('LO05_BUNDLE','LO_SCOPE'))
  Sys.setenv(PATH=paste(dirname(settings$git),Sys.getenv('PATH'),sep=.Platform$path.sep),
    LO_REPO_ROOT=repo,LO_REPRODUCE_COMMIT=settings$code_commit,
    LO_FIXED_ROOT=root,LO_RUN_CONFIG=settings$configuration_path,
    LO_SOURCE_BINDINGS=settings$source_bindings,LO_COBREROS_ROOT=settings$author_repository,
    LO_DRIVE_SYNC_CONFIG=settings$drive_config,LO_PYTHON=settings$python,
    LO_RUN_OUTPUT=file.path(root,'runner_logs'),LO_START_ACTION='produce-approved',
    LO_FRESH_REPLICATION='1',LO_GITHUB_RESULTS='off')
  prior_options<-options(lo.pipeline.functions_only=FALSE)
  on.exit(options(prior_options),add=TRUE)
  source(file.path(repo,'START.R'),local=new.env(parent=.GlobalEnv),encoding='UTF-8')
  # Read expected values only AFTER the independent production has completed.
  if(sha(settings$reference_grid)!=settings$reference_grid_sha256)
    stop('FRESH_REFERENCE_CHANGED; retain new results for review')
  state<-file.path(root,'FIXED_PRODUCTION_V1/all_required')
  manifest<-jsonlite::fromJSON(file.path(state,'FIXED_INPUT_MANIFEST.json'))
  if(manifest$sha256$fresh_source_replication!='ENABLED')stop('FRESH_MODE_NOT_RECORDED')
  reference<-read.csv(settings$reference_grid,colClasses='character',na.strings=character())
  actual<-read.csv(file.path(state,'PRIVATE_MASTER_GRID.csv'),colClasses='character',na.strings=character())
  if(anyDuplicated(actual$cell_id)||!setequal(reference$cell_id,actual$cell_id))
    stop('FRESH_TARGET_IDENTITIES_DIFFER; no result overwrite')
  actual<-actual[match(reference$cell_id,actual$cell_id),,drop=FALSE]
  valid<-reference$status=='SCIENTIFICALLY_VALIDATED'
  difference<-function(column)abs(as.numeric(actual[[column]][valid])-as.numeric(reference[[column]][valid]))
  est<-difference('estimate');se<-difference('standard_error')
  actual_n<-as.numeric(actual$n_unweighted[valid]);reference_n<-as.numeric(reference$n_unweighted[valid])
  n_ok<-is.finite(actual_n)&is.finite(reference_n)&actual_n==reference_n
  missing_equal<-actual$hold_reason[!valid]==reference$hold_reason[!valid]
  ok<-all(actual$status==reference$status)&&all(is.finite(est))&&all(is.finite(se))&&
    all(est<=1e-9)&&all(se<=1e-9)&&all(n_ok)&&all(missing_equal)
  proof<-list(status=if(ok)'FULL_SELECTED_GRID_NUMERICAL_PARITY_PASS'else'FULL_SELECTED_GRID_PARITY_REQUIRES_REVIEW',
    source_commit=settings$code_commit,configuration_sha256=settings$configuration_sha256,
    reference_grid_sha256=settings$reference_grid_sha256,
    actual_grid_sha256=sha(file.path(state,'PRIVATE_MASTER_GRID.csv')),
    targets=nrow(actual),validated_reference_cells=sum(valid),
    max_estimate_difference=max(est),max_se_difference=max(se),
    n_mismatches=sum(!n_ok),status_mismatches=sum(actual$status!=reference$status),
    absence_reason_mismatches=sum(!missing_equal),
    full_scientific_release_automatically_approved=FALSE,
    remaining_review='Rebind scientific review, joint derivations and product evidence to the new run before closing step 3.')
  jsonlite::write_json(proof,file.path(root,'FULL_SOURCE_REPLICATION_PARITY.json'),
    auto_unbox=TRUE,pretty=TRUE,digits=17)
  if(!ok)stop('FRESH_PARITY_REQUIRES_REVIEW; both runs are preserved')
  cat('Full source grid agrees within 1e-9, with exact N/status/absence reasons.\n',
      'Results are in the separate private Drive checkpoint. No existing release was replaced.\n',
      'The final evidence binding still requires review; deferred36 remain stopped.\n',sep='')
  invisible(proof)
}
