# Install scope-specific receipts only from a completed, hash-bound scientific
# review. Caller holds the master writer lock. This never estimates pupil data.
lo_science_check_files <- function(files,checked=new.env(parent=emptyenv())) {
  if(!is.data.frame(files)||!nrow(files)||!all(c('path','sha256')%in%names(files)))
    stop('SCIENCE_REVIEW_ATTACHMENT_SCHEMA')
  for(i in seq_len(nrow(files))) {
    p<-files$path[i];h<-files$sha256[i];key<-paste(p,h)
    if(!exists(key,checked,inherits=FALSE)) {
      if(!grepl('^[a-f0-9]{64}$',h)||!file.exists(p)||digest::digest(file=p,algo='sha256')!=h)
        stop('SCIENCE_REVIEW_ATTACHMENT_CHANGED: ',basename(p))
      assign(key,TRUE,checked)
    }
  }
  invisible(checked)
}

lo_science_manifest_verify <- function(path,hash,repo,checked=new.env(parent=emptyenv())) {
  lo_science_check_files(data.frame(path=path,sha256=hash),checked)
  z<-jsonlite::fromJSON(path,simplifyVector=TRUE)
  if(!identical(z$schema_version,1L)||
     !identical(z$status,'REVIEWED_SCIENTIFIC_BASIS_WITH_EXPLICIT_LIMITATIONS')||
     !is.data.frame(z$reviews)||!setequal(z$reviews$requirement_id,sprintf('Q%02d',1:8))||
     anyDuplicated(z$reviews$requirement_id)||any(!nzchar(z$reviews$assessment)))
    stop('SCIENCE_REVIEW_MANIFEST_INVALID')
  bindings<-z$runtime_bindings
  if(!is.data.frame(bindings)||!nrow(bindings)||
     any(grepl('(^/|^[A-Za-z]:|[.][.]|\\\\)',bindings$path)))stop('SCIENCE_REVIEW_REPO_BINDING_INVALID')
  bindings$path<-file.path(repo,bindings$path)
  lo_science_check_files(bindings,checked)
  lo_science_check_files_batch(repo,z$evidence_files,dirname(path),checked)
  lo_science_check_files(data.frame(path=z$reviews$report_path,sha256=z$reviews$report_sha256),checked)
  z
}

lo_science_check_files_batch <- function(repo,files,temp_dir,checked) {
  keys<-paste(files$path,files$sha256)
  missing<-!vapply(keys,exists,logical(1),envir=checked,inherits=FALSE)
  todo<-unique(files[missing,c('path','sha256'),drop=FALSE])
  if(!nrow(todo))return(invisible(checked))
  if(nrow(todo)<128L)return(lo_science_check_files(todo,checked))
  p<-tempfile('evidence_hashes_',tmpdir=temp_dir,fileext='.csv')
  on.exit(if(file.exists(p))unlink(p),add=TRUE)
  write.csv(todo,p,row.names=FALSE,na='')
  py<-Sys.getenv('LO_PYTHON','python')
  script<-file.path(repo,'06_pipeline/LO_EVIDENCE_HASHES.py')
  output<-suppressWarnings(system2(py,shQuote(c(script,'--table',p)),stdout=TRUE,stderr=TRUE))
  status<-attr(output,'status')
  if(!is.null(status)&&status!=0L)stop('SCIENCE_REVIEW_BATCH_ATTACHMENT_CHANGED: ',paste(tail(output,2L),collapse=' '))
  result<-jsonlite::fromJSON(paste(output,collapse='\n'))
  if(result$status!='EXACT_ATTACHMENT_BYTES_VERIFIED'||result$files!=nrow(todo)||
     result$table_sha256!=digest::digest(file=p,algo='sha256'))stop('SCIENCE_REVIEW_BATCH_IDENTITY')
  for(key in paste(todo$path,todo$sha256))assign(key,TRUE,checked)
  invisible(checked)
}

lo_scientific_review_install <- function(repo,root,tasks,approval_csv,state) {
  path<-file.path(root,'scientific_review_20261019/SCIENTIFIC_REVIEW_MANIFEST.json')
  if(!file.exists(path))return(invisible(NULL))
  hash<-digest::digest(file=path,algo='sha256')
  checked<-new.env(parent=emptyenv())
  z<-lo_science_manifest_verify(path,hash,repo,checked)
  approval_sha<-digest::digest(file=approval_csv,algo='sha256')
  if(!identical(z$approval_sha256,approval_sha))stop('SCIENCE_REVIEW_NEW_OR_CHANGED_RESULTS_REQUIRE_REVIEW')
  lo_science_check_files(data.frame(path=z$target_contracts_path,sha256=z$target_contracts_sha256),checked)
  reviewed<-read.csv(z$target_contracts_path,colClasses='character',na.strings=character())
  current<-lo_grid_from_tasks(tasks)[c('cell_id','target_contract_sha256')]
  current<-current[order(current$cell_id),];rownames(current)<-NULL
  i<-match(current$cell_id,reviewed$cell_id)
  if(anyNA(i)||anyDuplicated(reviewed$cell_id)||
     any(current$target_contract_sha256!=reviewed$target_contract_sha256[i]))
    stop('SCIENCE_REVIEW_NEW_OR_CHANGED_TARGET_REQUIRES_REVIEW')
  target_sha<-digest::digest(current,algo='sha256')
  policy<-jsonlite::fromJSON(file.path(repo,'06_pipeline/review_20261013/PAPER_QA_CURRENT.json'))$requirements
  policy_sha<-digest::digest(policy,algo='sha256')
  out<-file.path(root,'master_reconciliation/scientific_review_receipts',paste0(substr(hash,1,16),'_',substr(target_sha,1,16)))
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  receipts<-lapply(seq_len(nrow(z$reviews)),function(i) {
    r<-z$reviews[i,]
    cert<-list(schema_version=2L,status='PASS',requirement_id=r$requirement_id,
      assessment=r$assessment,applicability=r$applicability,
      target_sha256=target_sha,approval_sha256=approval_sha,policy_sha256=policy_sha,
      evidence_manifest_path=normalizePath(path,winslash='/'),evidence_manifest_sha256=hash,
      evidence_files=data.frame(path=r$report_path,sha256=r$report_sha256))
    p<-file.path(out,paste0(r$requirement_id,'.json'))
    encoded<-jsonlite::toJSON(cert,auto_unbox=TRUE,pretty=TRUE,na='null')
    if(file.exists(p)) {
      if(!identical(jsonlite::fromJSON(p),jsonlite::fromJSON(encoded)))stop('SCIENCE_REVIEW_IMMUTABLE_RECEIPT_CHANGED')
    }else writeLines(encoded,p,useBytes=TRUE)
    data.frame(requirement_id=r$requirement_id,status='PASS',
      evidence_path=normalizePath(p,winslash='/'),evidence_sha256=digest::digest(file=p,algo='sha256'))
  })
  source(file.path(repo,'06_pipeline/LO_ATOMIC_CHECKPOINT.R'),local=environment())
  dest<-file.path(root,'master_reconciliation/SCIENTIFIC_PAPER_GATES.csv')
  rows<-do.call(rbind,receipts)
  if(!file.exists(dest)||!identical(read.csv(dest,stringsAsFactors=FALSE),rows))lo_atomic_csv(rows,dest)
  # The comparison adapter consumes actual reviewed cell mappings, not a PASS
  # label or merely the count of scientifically validated results.
  map_path<-file.path(root,'scientific_review_20261019/Q06_mapping_final/BALANCE_AVAILABLE.csv')
  map<-read.csv(map_path,colClasses='character',na.strings=character())
  balance_cert<-list(schema_version=2L,status='COMPARABILITY_CERTIFIED',
    assessment=z$reviews$assessment[z$reviews$requirement_id=='Q06'],
    evidence_files=z$evidence_files,cells=data.frame(cell_id=map$cell_id,
      balance_key=lo_balance_key(map),result_hash=map$result_hash))
  bp<-file.path(out,'BALANCE_COMPARABILITY.json')
  encoded<-jsonlite::toJSON(balance_cert,auto_unbox=TRUE,pretty=FALSE,na='null')
  if(file.exists(bp)) {
    if(!identical(jsonlite::fromJSON(bp),jsonlite::fromJSON(encoded)))stop('BALANCE_IMMUTABLE_REVIEW_CHANGED')
  }else writeLines(encoded,bp,useBytes=TRUE)
  bc<-map[c('cell_id',lo_balance_columns())]
  bc$verification_path<-normalizePath(bp,winslash='/')
  bc$verification_sha256<-digest::digest(file=bp,algo='sha256')
  dest<-file.path(root,'master_reconciliation/BALANCE_CELL_CONTRACTS.csv')
  if(!file.exists(dest)||!identical(read.csv(dest,colClasses='character',na.strings=character()),bc))lo_atomic_csv(bc,dest)
  jsonlite::write_json(list(status='SCIENTIFIC_REVIEW_RECEIPTS_INSTALLED',review_manifest_sha256=hash,
    target_sha256=target_sha,approval_sha256=approval_sha,policy_sha256=policy_sha,
    reviewed_targets=nrow(reviewed),current_targets=nrow(current),requirements=8L,
    no_pupil_recalculation=TRUE),file.path(state,'SCIENTIFIC_REVIEW_BINDING.json'),pretty=TRUE,auto_unbox=TRUE)
  attr(rows,'checked_files')<-checked
  cat('SCIENTIFIC_REVIEW_BOUND: Q01-Q08; ',nrow(current),' exact targets; no pupil recalculation\n',sep='')
  invisible(rows)
}
