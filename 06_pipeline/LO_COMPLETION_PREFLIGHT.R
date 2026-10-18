# Read-only preparation for the existing finalizer. A running producer may
# advance the master; reject a mixed snapshot instead of reporting false totals.
# Counts are bookkeeping, not a substitute for scientific certificate review.
lo_completion_preflight <- function(repo,root,scope,out) {
  source(file.path(repo,'06_pipeline/LO_SOURCE_UNAVAILABILITY.R'),local=environment())
  source(file.path(repo,'06_pipeline/LO_APPROVED_EXTENSIONS.R'),local=environment())
  state<-file.path(root,'FIXED_PRODUCTION_V1',scope)
  paths<-c(grid=file.path(state,'PRIVATE_MASTER_GRID.csv'),
    approved=file.path(root,'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'),
    absent=file.path(root,'master_reconciliation/SOURCE_UNAVAILABLE_CELLS.csv'),
    remote=file.path(root,'.remote_checkpoints/VERIFIED_INDEX.rds'))
  if(!all(file.exists(paths[c('grid','approved')])))stop('PREFLIGHT_CURRENT_GRID_REQUIRED')
  paths<-paths[file.exists(paths)]
  hash<-function(p)digest::digest(file=p,algo='sha256')
  before<-vapply(paths,hash,character(1))
  g<-read.csv(paths['grid'],stringsAsFactors=FALSE,na.strings=character())
  a<-read.csv(paths['approved'],stringsAsFactors=FALSE,na.strings=character())
  required<-c('cell_id','target_contract_sha256','status')
  numeric<-c('estimate','standard_error','n_unweighted')
  provenance<-c('result_hash','certification_sha256','input_fingerprint','code_fingerprint')
  if(!all(required%in%names(g))||!all(c(required,numeric,provenance)%in%names(a)))stop('PREFLIGHT_GRID_SCHEMA')
  if(anyDuplicated(g$cell_id)||anyDuplicated(a$cell_id))stop('PREFLIGHT_DUPLICATE_CELLS')
  if(!'module'%in%names(g))g$module<-g$subgroup_variable
  a<-a[a$cell_id%in%g$cell_id,,drop=FALSE]
  at<-match(a$cell_id,g$cell_id)
  if(any(a$target_contract_sha256!=g$target_contract_sha256[at])||any(a$status!='SCIENTIFICALLY_VALIDATED'))stop('PREFLIGHT_TARGET_OR_STATUS_MISMATCH')
  if(any(!is.finite(as.matrix(a[numeric])))||any(a$standard_error<0)||any(a$n_unweighted<=0)||
    any(!grepl('^[a-f0-9]{64}$',as.matrix(a[provenance]))))stop('PREFLIGHT_INVALID_VALUE_OR_PROVENANCE')
  # Revalidate registered absences against the original contracts; do not treat
  # old saved audit labels as new evidence or remove them from target support.
  g$status<-'TARGET_NOT_YET_ADJUDICATED';g$hold_reason<-''
  if('absent'%in%names(paths))g<-lo_source_unavailability(g,paths['absent'])
  extensions<-lo_extension_availability(g)
  extensions<-extensions[extensions$status%in%c('OFFICIAL_SCALE_NOT_IN_EARLIER_CYCLE','UNAVAILABLE_HOME_QUESTIONNAIRE_NOT_ADMINISTERED'),,drop=FALSE]
  unavailable_extension<-g$module=='extension_home_ses'&paste(g$country,g$survey,g$year)%in%paste(extensions$country,extensions$survey,extensions$year)
  g$status[unavailable_extension]<-'UNAVAILABLE_VERIFIED_EXTENSION'
  absent<-startsWith(g$status,'UNAVAILABLE_')
  if(any(g$cell_id[absent]%in%a$cell_id))stop('PREFLIGHT_RESULT_ABSENCE_CONFLICT')
  done<-g$cell_id%in%a$cell_id
  missing<-g[!done&!absent,,drop=FALSE]
  remote<-if('remote'%in%names(paths))readRDS(paths['remote'])else list(keys=character())
  keys<-paste(a$cell_id,a$result_hash,a$certification_sha256,sep='::')
  unbacked<-sum(!keys%in%remote$keys)
  absence_backed<-!('absent'%in%names(paths))||before['absent']%in%remote$absence_registry_sha256
  after<-vapply(paths,hash,character(1))
  if(!identical(before,after))stop('PREFLIGHT_SNAPSHOT_CHANGED_RETRY_AFTER_CURRENT_BLOCK')
  fields<-intersect(c('country','survey','year','module'),names(missing))
  gaps<-if(nrow(missing)&&length(fields))aggregate(list(cells=rep(1L,nrow(missing))),missing[fields],sum)else data.frame()
  summary<-list(scope=scope,targets=nrow(g),recorded_validated=nrow(a),
    evidenced_unavailable=sum(absent),remaining=nrow(missing),certified_cells_not_in_remote_index=unbacked,
    absence_registry_in_remote_index=absence_backed,
    input_sha256=as.list(before),snapshot='STABLE_READ_ONLY',
    computation_accounted_for=nrow(missing)==0L,
    storage_accounted_for=unbacked==0L&&absence_backed,
    scientific_release='NOT_ESTABLISHED_BY_PREFLIGHT_Q01_Q08_AND_PRODUCT_GATES_STILL_REQUIRED')
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  write.csv(gaps,file.path(out,'REMAINING_BY_CONTEXT.csv'),row.names=FALSE,na='')
  jsonlite::write_json(summary,file.path(out,'COMPLETION_PREFLIGHT.json'),pretty=TRUE,auto_unbox=TRUE,digits=17)
  invisible(summary)
}
