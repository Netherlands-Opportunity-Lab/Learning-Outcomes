# Close completed exact receipts against independent selected-cell evidence.
# This also recovers progress after a later block failed: completed estimates
# are preserved, not recalculated because the worklist still contains them.
lo_close_verified_candidates <- function(repo,root,block_root,blocks,label) {
  stopifnot(grepl('^[A-Za-z0-9_]+$',label),length(blocks)>0L,!anyDuplicated(blocks))
  for(p in c('MASTER_ESTIMATION_GRID.R','GRID_ARCHIVE_BATCH.R','LO_EXACT_DISPATCH.R','LO_COMPACT_GRID_STORE.R'))source(file.path(repo,'06_pipeline',p))
  master<-file.path(root,'master_reconciliation');queue<-file.path(master,'SCIENTIFIC_COMPUTE_APPROVALS.csv')
  approvals<-read.csv(queue,stringsAsFactors=FALSE,na.strings=character())
  prior<-read.csv(file.path(master,'SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'),stringsAsFactors=FALSE,na.strings=character())
  if(!nrow(approvals))return(invisible(list(closed=0L,remaining=0L)))
  ref<-do.call(rbind,lapply(blocks,function(b)read.csv(file.path(block_root,b,'INDEPENDENT_RESULTS.csv'),stringsAsFactors=FALSE)))
  tasks<-do.call(rbind,lapply(blocks,function(b)read.csv(file.path(block_root,b,'EXACT_SELECTED_TASKS.csv'),colClasses='character',na.strings=character())))
  contracts<-lo_grid_from_tasks(tasks)
  if(anyDuplicated(ref$cell_id))stop('CLOSE_DUPLICATE_REFERENCE')
  con<-lo_compact_open(file.path(root,'FIXED_PRODUCTION_V1/nld_only/compact'))
  on.exit(lo_compact_close(con))
  eligible<-approvals[approvals$cell_id%in%ref$cell_id & !approvals$cell_id%in%prior$cell_id,]
  rows<-list();keep<-integer()
  for(i in seq_len(nrow(eligible))) {
    a<-eligible[i,,drop=FALSE]
    k<-match(a$cell_id,contracts$cell_id)
    if(is.na(k)||a$target_contract_sha256!=contracts$target_contract_sha256[k])stop('CLOSE_TARGET_CONTRACT_MISMATCH')
    actual<-DBI::dbGetQuery(con,'SELECT * FROM grid WHERE cell_id=?',params=list(a$cell_id))
    if(!nrow(actual))next
    if(actual$status!='COMPUTED_PENDING_VALIDATION'||actual$input_fingerprint!=a$input_fingerprint||
       actual$producer_fingerprint!=a$code_fingerprint||actual$method_id!=a$method_version)next
    r<-DBI::dbGetQuery(con,'SELECT result_sha FROM execution_receipts WHERE cell_id=?',params=list(a$cell_id))
    if(nrow(r)!=1L||r$result_sha!=digest::digest(actual,algo='sha256'))stop('CLOSE_RECEIPT_RESULT_MISMATCH')
    cert<-jsonlite::fromJSON(a$certification_path)
    stopifnot(lo_exact_sha(a$certification_path)==a$certification_sha256,
      lo_exact_sha(a$source_path)==a$source_edition_sha256,cert$status=='METHOD_SAMPLE_INPUT_CERTIFIED',a$cell_id%in%cert$cell_ids)
    for(k in c('source_edition_sha256','input_fingerprint','code_fingerprint','sample_id','method_version','weight_design','pv_rule','variance_rule'))
      if(!identical(as.character(cert[[k]]),as.character(a[[k]])))stop('CLOSE_METHOD_CERTIFICATE_MISMATCH')
    if(!is.data.frame(cert$evidence_files)||!nrow(cert$evidence_files))stop('CLOSE_MISSING_EVIDENCE')
    for(j in seq_len(nrow(cert$evidence_files)))lo_exact_assert_sha(cert$evidence_files$path[j],cert$evidence_files$sha256[j],'INDEPENDENT_EVIDENCE')
    at<-match(a$cell_id,ref$cell_id)
    if(abs(actual$estimate-ref$estimate[at])>=1e-9||abs(actual$standard_error-ref$standard_error[at])>=1e-9||actual$n_unweighted!=ref$n_unweighted[at])stop('CLOSE_INDEPENDENT_PARITY_FAILED')
    rows[[length(rows)+1L]]<-actual;keep<-c(keep,i)
  }
  if(!length(keep))return(invisible(list(closed=0L,remaining=nrow(approvals))))
  a<-eligible[keep,,drop=FALSE];actual<-do.call(rbind,rows)
  a$estimate<-actual$estimate;a$standard_error<-actual$standard_error;a$n_unweighted<-actual$n_unweighted
  a$status<-'SCIENTIFICALLY_VALIDATED';a$hold_reason<-''
  a$result_hash<-vapply(rows,digest::digest,character(1),algo='sha256')
  a<-a[setdiff(names(a),c('decision','certification_status'))]
  evidence<-unique(c(a$certification_path,unlist(lapply(blocks,function(b)file.path(block_root,b,c('INDEPENDENT_RESULTS.csv','JOINT_REFERENCE_PV_REPLICATES.rds'))))))
  certificate<-file.path(master,paste0(label,'_RESULT_CERTIFICATE.json'))
  if(file.exists(certificate))stop('CLOSE_REFUSES_CERTIFICATE_OVERWRITE')
  jsonlite::write_json(list(status='SCIENTIFICALLY_VALIDATED',cells=a,
    evidence_files=data.frame(path=evidence,sha256=vapply(evidence,lo_exact_sha,character(1))),
    scope=label,validation='Exact execution receipts plus independent PV/replicate estimates and standard errors within 1e-9 and exact N',global_scientific_freeze=FALSE),certificate,auto_unbox=TRUE,pretty=TRUE,digits=17)
  a$certification_path<-certificate;a$certification_sha256<-lo_exact_sha(certificate)
  lo_grid_verify_result_artifacts(a)
  cols<-union(names(prior),names(a))
  for(k in setdiff(cols,names(prior)))prior[[k]]<-''
  for(k in setdiff(cols,names(a)))a[[k]]<-''
  write.csv(rbind(prior[cols],a[cols]),file.path(master,'SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'),row.names=FALSE,na='')
  completed<-approvals[approvals$cell_id%in%a$cell_id,]
  write.csv(completed,file.path(master,paste0(label,'_COMPLETED_APPROVALS.csv')),row.names=FALSE,na='')
  pending<-approvals[!approvals$cell_id%in%a$cell_id,]
  write.csv(pending,queue,row.names=FALSE,na='')
  invisible(list(closed=nrow(a),remaining=nrow(pending)))
}
