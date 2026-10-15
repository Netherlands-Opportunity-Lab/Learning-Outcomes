# Deposit certified aggregate results on the development branch. This is a
# research review snapshot, never a dashboard deployment or publication freeze.
# Private paths, pupil records and full private run records are not exported.
lo_github_results_build <- function(repo,root,scope) {
  if(!scope%in%c('nld_only','nld_plus_19','all_required'))stop('RESULT_SYNC_SCOPE')
  for(p in c('jsonlite','digest','DBI','RSQLite'))if(!requireNamespace(p,quietly=TRUE))stop('Missing ',p)
  source(file.path(repo,'06_pipeline/GRID_ARCHIVE_BATCH.R'),local=environment())
  source(file.path(repo,'06_pipeline/LO_RUN_CONFIG.R'),local=environment())
  source(file.path(repo,'06_pipeline/LO_PROCESS_LOCK.R'),local=environment())
  state<-file.path(root,'FIXED_PRODUCTION_V1',scope)
  lock<-lo_process_lock(file.path(state,'.FIXED_PRODUCTION_WRITER.lck'),file.path(state,'FIXED_PRODUCTION_OPERATION.lock'))
  on.exit(lo_process_unlock(lock),add=TRUE)
  read<-function(p)read.csv(p,stringsAsFactors=FALSE,na.strings=character(),check.names=FALSE)
  grid<-read(file.path(state,'PRIVATE_MASTER_GRID.csv'))
  certified<-read(file.path(root,'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'))
  selected<-grid$cell_id[grid$status=='SCIENTIFICALLY_VALIDATED']
  a<-certified[match(selected,certified$cell_id),,drop=FALSE]
  if(!nrow(a)||anyNA(a$cell_id)||anyDuplicated(a$cell_id))stop('RESULT_SYNC_CERTIFIED_IDENTITY')
  lo_grid_verify_result_artifacts(a)
  con<-DBI::dbConnect(RSQLite::SQLite(),file.path(state,'compact/COMPACT_MASTER_GRID.sqlite'),flags=RSQLite::SQLITE_RO)
  on.exit(DBI::dbDisconnect(con),add=TRUE)
  d<-DBI::dbGetQuery(con,'SELECT * FROM grid ORDER BY cell_id')
  d<-d[match(selected,d$cell_id),,drop=FALSE]
  if(anyNA(d$cell_id)||any(d$input_fingerprint!=a$input_fingerprint)||any(d$producer_fingerprint!=a$code_fingerprint))stop('RESULT_SYNC_STALE_RESULT')
  for(k in c('estimate','standard_error','n_unweighted'))
    if(any(!is.finite(d[[k]]))||any(abs(d[[k]]-as.numeric(a[[k]]))>1e-10))stop('RESULT_SYNC_NUMERICAL_MISMATCH')
  # Explicit allowlist: adding columns to a private registry cannot expose them.
  keep<-c('cell_id','survey','country','year','domain','module','stat','subgroup','definition','unit','peer_environment','threshold','estimate','standard_error','n_unweighted','input_fingerprint','producer_fingerprint','method_id')
  out<-d[keep]
  out$n_definition<-ifelse(out$module%in%c('peer_below_basic','high_proficiency_peer_exposure'),
    'ANALYTIC_PEER_FRAME_WITH_SEPARATE_PV_TARGET_COUNTS','EXACT_ANALYTIC_SAMPLE_FOR_CELL')
  out$reproduction_entrypoint<-'06_pipeline/LO_FIXED_PRODUCERS.R::lo_fixed_produce'
  if('derivation_receipts'%in%DBI::dbListTables(con)) {
    derived_ids<-DBI::dbGetQuery(con,'SELECT cell_id FROM derivation_receipts')$cell_id
    out$reproduction_entrypoint[out$cell_id%in%derived_ids]<-'06_pipeline/LO_DERIVE_POPULATION_BASELINES.R::lo_derive_population_baselines'
  }
  extra<-c('sample_id','population_id','weight_design','pv_rule','variance_rule','linking_rule','target_contract_sha256','source_edition_sha256','result_hash','certification_sha256','peer_denominator_verified','self_exclusion_verified','joint_pv_replicate_status')
  for(k in extra)if(k%in%names(a))out[[k]]<-a[[k]]
  out$status<-'SCIENTIFICALLY_VALIDATED_RESEARCH_REVIEW'
  out<-out[order(out$cell_id),,drop=FALSE]
  status<-grid[order(grid$cell_id),c('cell_id','status')]
  cfg<-lo_run_config(scope)
  audited<-jsonlite::fromJSON(file.path(state,'FIXED_INPUT_MANIFEST.json'))
  if(!identical(lo_run_config_hash(cfg),lo_run_config_hash(audited$configuration)))stop('RESULT_SYNC_CONFIG_NOT_AUDITED')
  stage<-file.path(state,'GITHUB_REVIEW_EXPORT');dir.create(stage,recursive=TRUE,showWarnings=FALSE)
  safe<-function(x) {
    txt<-jsonlite::toJSON(x,auto_unbox=TRUE,na='null',digits=NA)
    if(grepl('([A-Za-z]:[/\\\\]|/Users/|/home/|@|Bearer |access_token)',txt,perl=TRUE))stop('RESULT_SYNC_PRIVATE_CONTENT')
    invisible(TRUE)
  }
  write_csv<-function(x,name) {
    safe(x);p<-file.path(stage,name);old<-options(digits=17);on.exit(options(old))
    # Explicit 17 significant digits; write.table's numeric formatting is not a
    # sufficient round-trip guarantee for every double.
    for(k in names(x))if(is.numeric(x[[k]]))x[[k]]<-ifelse(is.na(x[[k]]),'',sprintf('%.17g',x[[k]]))
    write.table(x,p,sep=',',row.names=FALSE,col.names=TRUE,quote=TRUE,na='',eol='\n',fileEncoding='UTF-8')
  }
  write_csv(out,'results.csv');write_csv(status,'target_status.csv')
  receipts<-DBI::dbGetQuery(con,'SELECT cell_id,execution_sha,result_sha FROM execution_receipts ORDER BY cell_id,execution_sha')
  write_csv(receipts[receipts$cell_id%in%selected,,drop=FALSE],'execution_receipts.csv')
  if('derivation_receipts'%in%DBI::dbListTables(con)) {
    parents<-DBI::dbGetQuery(con,'SELECT * FROM derivation_receipts ORDER BY cell_id')
    write_csv(parents[parents$cell_id%in%selected,,drop=FALSE],'derivations.csv')
  } else write_csv(data.frame(cell_id=character(),parent_cell_id=character(),parent_result_sha256=character(),multiplier=numeric()),'derivations.csv')
  # Preserve the actual historical code/configuration fingerprints rather than
  # assigning the export commit to calculations made by older producers.
  runs<-list();links<-list()
  for(p in sort(list.files(file.path(state,'RUN_RECORDS'),pattern='[.]json$',full.names=TRUE))) {
    z<-jsonlite::fromJSON(p,simplifyVector=TRUE)
    if(!is.data.frame(z$results)||!nrow(z$results))next
    hit<-z$results[z$results$cell_id%in%selected,,drop=FALSE];if(!nrow(hit))next
    id<-sub('[.]json$','',basename(p));hit$run_record_sha256<-id
    links[[length(links)+1L]]<-hit
    runs[[id]]<-z[intersect(c('schema_version','stage','outcome','timestamp_utc','configuration','configuration_sha256','git_commit','code_sha256','R_version','platform','packages','result_set_sha256'),names(z))]
  }
  if(length(links)) {
    links<-do.call(rbind,links)
    ids<-links$run_record_sha256
    produced<-vapply(ids,function(id)identical(runs[[id]]$stage,'produce'),logical(1))
    stamps<-vapply(ids,function(id)runs[[id]]$timestamp_utc,character(1))
    links<-links[order(!produced,stamps,ids),,drop=FALSE]
    links<-links[!duplicated(paste(links$cell_id,links$result_version_sha256)),,drop=FALSE]
    links<-links[order(links$cell_id,links$result_version_sha256),,drop=FALSE]
    runs<-runs[sort(unique(links$run_record_sha256))]
    write_csv(links,'result_run_links.csv')
  } else write_csv(data.frame(cell_id=character(),result_version_sha256=character(),run_record_sha256=character()),'result_run_links.csv')
  safe(runs);jsonlite::write_json(runs,file.path(stage,'run_provenance.json'),auto_unbox=TRUE,pretty=TRUE,digits=NA,na='null')
  # Script roles are explicit; fingerprints are bound per result and run above.
  scripts<-data.frame(role=c('entrypoint','dispatch','core_and_peer_production','approved_extensions','SES_calibration','background_verification','SES_verification','baseline_derivation','product_export'),
    script=c('START.R','06_pipeline/LO_COMPACT_RECOMPUTE.R','06_pipeline/LO_COMPACT_RECOMPUTE.R','06_pipeline/LO_EXACT_ESTIMATORS.R','06_pipeline/LO_COBREROS_PREPARE.R','06_pipeline/LO_BACKGROUND_REFERENCE.R','06_pipeline/LO_SES_REFERENCE.R','06_pipeline/LO_DERIVE_POPULATION_BASELINES.R','06_pipeline/LO_FINAL_GUIDED_EXPORT.R'))
  scripts$export_checkout_sha256<-vapply(file.path(repo,scripts$script),function(p)digest::digest(file=p,algo='sha256'),character(1))
  write_csv(scripts,'scripts.csv')
  artifacts<-sort(setdiff(list.files(stage),c('manifest.json','README.md')))
  manifest<-list(schema_version=1L,scope=scope,configuration=cfg,audited_input_sha256=audited$sha256,
    configuration_sha256=lo_run_config_hash(cfg),validated_rows=nrow(out),target_rows=nrow(grid),
    status_counts=as.list(table(grid$status)),publication_status='RESEARCH_REVIEW_NOT_PRODUCT_RELEASE',
    raw_or_pupil_data_included=FALSE,producer_identity='Per-cell producer_fingerprint and linked historical run records; export checkout is not producer identity',
    historical_producer_code='06_pipeline/archive_or_superseded/LO05_CODE_LOCK_20261010/SOURCE_CODE_ORIGINAL_VS_PUBLIC_SHA256.csv',
    files=data.frame(file=artifacts,sha256=unname(vapply(file.path(stage,artifacts),function(p)digest::digest(file=p,algo='sha256'),character(1))),bytes=file.info(file.path(stage,artifacts))$size,row.names=NULL))
  safe(manifest);jsonlite::write_json(manifest,file.path(stage,'manifest.json'),auto_unbox=TRUE,pretty=TRUE,digits=NA)
  writeLines(c('# Certified aggregate research snapshot',
    'Generated by `06_pipeline/LO_GITHUB_RESULTS.R` after the existing approved production protocol.',
    '`results.csv` contains exact cell identities, estimates, standard errors, N and source/input/producer/result/certificate fingerprints. Full numeric precision is retained.',
    '`target_status.csv` retains unavailable and unresolved targets. Only certified values enter results.csv.',
    '`scripts.csv` identifies producer and verifier roles; its hashes describe the export checkout. Historical producer file hashes and settings are in run_provenance.json, linked by result_run_links.csv. A later audit can observe older results; an observation is not a new calculation.',
    '`execution_receipts.csv` links actual exact executions to result hashes; measured pilot results may lack a controller receipt. `derivations.csv` records exact parent cells.',
    'Values are national aggregates, with no pupil or school records, local paths or credentials. Certificates and joint replicate evidence remain in the verified private archive.',
    'This development-branch research snapshot is not a product release or a claim that country admission, the paper, rights review or full external replication is complete.'),file.path(stage,'README.md'),useBytes=TRUE)
  invisible(stage)
}

lo_github_results_deposit <- function(repo,root,scope,push=TRUE) {
  git<-Sys.which('git');if(!nzchar(git))stop('RESULT_SYNC_GIT_UNAVAILABLE')
  run<-function(args) {
    z<-suppressWarnings(system2(git,shQuote(c('-C',repo,args)),stdout=TRUE,stderr=TRUE))
    rc<-attr(z,'status');if(!is.null(rc)&&rc!=0L)stop('RESULT_SYNC_GIT_FAILED: ',paste(tail(z,8),collapse='\n'))
    as.character(z)
  }
  branch<-'feat/reproducible-storage-and-cleanup-20261010'
  if(!identical(run(c('branch','--show-current')),branch))stop('RESULT_SYNC_WRONG_BRANCH')
  remote<-run(c('remote','get-url','origin'))
  if(length(remote)!=1L||!grepl('^(https://github[.]com/|git@github[.]com:|ssh://git@github[.]com/)Netherlands-Opportunity-Lab/Learning-Outcomes([.]git)?$',remote))stop('RESULT_SYNC_WRONG_REMOTE')
  if(length(run(c('diff','--cached','--name-only'))))stop('RESULT_SYNC_EXISTING_STAGED_CHANGES')
  relative<-paste0('04_results/review/',scope)
  dirty<-run(c('diff','--name-only'))
  if(any(!startsWith(dirty,paste0(relative,'/'))))stop('RESULT_SYNC_UNCOMMITTED_CODE')
  stage<-lo_github_results_build(repo,root,scope)
  dest<-file.path(repo,relative);dir.create(dest,recursive=TRUE,showWarnings=FALSE)
  files<-list.files(stage,full.names=TRUE)
  if(!all(file.copy(files,dest,overwrite=TRUE)))stop('RESULT_SYNC_COPY_FAILED')
  run(c('add','--',paste0(relative,'/',basename(files))))
  changed<-run(c('diff','--cached','--name-only'))
  if(length(changed)) {
    if(any(!changed%in%paste0(relative,'/',basename(files))))stop('RESULT_SYNC_UNEXPECTED_STAGED_PATH')
    run(c('-c','user.name=Learning Outcomes runner','-c','user.email=learning-outcomes-runner@users.noreply.github.com',
      'commit','-m',paste('Record certified aggregate results and provenance:',scope),'--only','--',paste0(relative,'/',basename(files))))
  }
  if(push) {
    # No force, rebase or silent merge. If remote advanced, retain the local
    # commit and report a pending upload. Finished numerical work is durable.
    run(c('push','origin',paste0('HEAD:refs/heads/',branch)))
    head<-run(c('rev-parse','HEAD'));remote_head<-strsplit(run(c('ls-remote','origin',paste0('refs/heads/',branch))),'\t')[[1]][1]
    if(!identical(head,remote_head))stop('RESULT_SYNC_REMOTE_VERIFY_FAILED')
    cat('GITHUB_RESULTS_VERIFIED: ',head,'; ',relative,'\n',sep='')
  }
  invisible(list(changed=length(changed)>0,commit=run(c('rev-parse','HEAD')),path=relative))
}
