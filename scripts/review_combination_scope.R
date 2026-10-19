# Read-only impact proof against real, hash-verified sources and the previously
# reviewed grid. This is not a producer and never rewrites the scientific master.
args<-commandArgs(TRUE);stopifnot(length(args)==3L)
repo<-normalizePath(args[1],winslash='/');root<-normalizePath(args[2],winslash='/')
bundle<-normalizePath(args[3],winslash='/')
out<-file.path(root,'scientific_review_20261019/combination_scope');dir.create(out,showWarnings=FALSE)
read<-function(p)read.csv(p,colClasses='character',na.strings=character(),check.names=FALSE)
sha<-function(p)digest::digest(file=p,algo='sha256')
modules<-c('LO_BALANCED_MEMBERSHIP.R','LO_COUNTRY_REGISTRY.R','LO_COUNTRY_TASKS.R',
 'MASTER_ESTIMATION_GRID.R','LO_SCOPE_DECISIONS.R','LO_APPROVED_EXTENSIONS.R','LO_GENDER_POOL_POLICY.R')
for(n in modules)source(file.path(repo,'06_pipeline',n))
support_path<-file.path(root,'master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv')
support<-lo_read_source_support(support_path,repo)
original<-read(file.path(bundle,'engine/TASKS.csv'))
old_path<-file.path(root,'scientific_review_20261019/REVIEWED_MASTER_GRID.csv')
old<-read(old_path);decisions<-lo_read_scope_decisions(repo)
summary<-list()
for(mode in c('nld_only','nld_plus_19','all_required')) {
  scope<-lo_runtime_scope(bundle,original,mode,support)
  lo_runtime_scope_evidence(scope,file.path(out,mode))
  base<-lo_country_base_tasks(original,scope)
  low<-lo_scoped_low_peer_tasks(base,decisions)
  base<-lo_scope_active_tasks(base,decisions)
  ext<-lo_gender_pool_tasks(lo_extension_tasks(base,decisions),support)
  tasks<-rbind(lo_gender_pool_tasks(base,support),lo_scope_active_tasks(ext,decisions),low)
  stopifnot(!anyDuplicated(tasks$metric_key))
  grid<-lo_grid_from_tasks(tasks)
  i<-match(grid$cell_id,old$cell_id)
  same<-!is.na(i) & grid$target_contract_sha256==old$target_contract_sha256[i]
  same[is.na(same)]<-FALSE
  # This is evidence reuse eligibility, not a newly signed result certificate.
  status<-rep('NEW_OR_CHANGED_TARGET_REQUIRES_REVIEW',nrow(grid))
  status[same]<-old$status[i[same]]
  current<-data.frame(cell_id=grid$cell_id,country=grid$country,survey=grid$survey,
    year=grid$year,domain=grid$domain,status=status,prior_result_hash=old$result_hash[i],
    target_contract_sha256=grid$target_contract_sha256)
  write.csv(current,file.path(out,paste0(mode,'_TARGET_REUSE.csv')),row.names=FALSE,na='')
  if(mode=='all_required')write.csv(tasks,file.path(out,'EXACT_ALL_REQUIRED_TASKS.csv'),row.names=FALSE)
  summary[[mode]]<-list(countries=scope$dashboard,admitted_combinations=sum(scope$cycle_detail$combination_pass &
    scope$cycle_detail$country%in%scope$selected),targets=nrow(grid),
    prior_validated=sum(status=='SCIENTIFICALLY_VALIDATED'),
    prior_documented_unavailable=sum(startsWith(status,'UNAVAILABLE_')),
    new_or_changed_targets=sum(!same),
    source_qualified_but_unavailable=sum(same & status!='SCIENTIFICALLY_VALIDATED' & !startsWith(status,'UNAVAILABLE_')),
    target_reuse_sha256=sha(file.path(out,paste0(mode,'_TARGET_REUSE.csv'))))
}
proof<-list(schema_version=1,status='REAL_SOURCE_AND_EXISTING_TARGET_IMPACT_VERIFIED_NOT_NEW_FINALIZATION',
  policy='COUNTRY_AGE_DOMAIN_MIN3_FULL_FOCUS_COMBINATION_AND_JOINT_VIEW',
  decision_sha256=sha(file.path(repo,'06_pipeline/review_20261013/BALANCE_USER_DECISION_20261019.json')),
  sources_sha256=sha(support_path),historical_review_grid_sha256=sha(old_path),
  original_task_catalogue_sha256=sha(file.path(bundle,'engine/TASKS.csv')),
  code_sha256=setNames(lapply(modules,function(n)sha(file.path(repo,'06_pipeline',n))),modules),
  review_script_sha256=sha(file.path(repo,'scripts/review_combination_scope.R')),modes=summary,
  pupil_recalculation=FALSE,production_master_modified=FALSE,
  limitation='Additional source candidates are not yet certified by this report. Existing target evidence must still pass the ordinary current audit/finalizer.')
jsonlite::write_json(proof,file.path(out,'COMBINATION_SCOPE_IMPACT.json'),auto_unbox=TRUE,pretty=TRUE)
cat(jsonlite::toJSON(summary,auto_unbox=TRUE,pretty=TRUE),'\n')
