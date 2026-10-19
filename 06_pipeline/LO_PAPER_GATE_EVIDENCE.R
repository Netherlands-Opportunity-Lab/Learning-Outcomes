# A PASS label is not scientific evidence. Each reviewed Q01-Q08 receipt binds
# the exact current targets and approved result file, and checks its attachments.
# This verifier does not write PASS receipts or authorize added analysis scope.
lo_paper_gate_evidence <- function(received,tasks,approval_csv,policy_sha=NULL,repo=NULL,
                                   checked=new.env(parent=emptyenv())) {
  passed<-received[received$status=='PASS',,drop=FALSE]
  if(!nrow(passed))return(character())
  fields<-c('requirement_id','evidence_path','evidence_sha256')
  if(!all(fields%in%names(passed)))stop('PAPER_GATE_HASH_BOUND_EVIDENCE_REQUIRED')
  targets<-lo_grid_from_tasks(tasks)[c('cell_id','target_contract_sha256')]
  targets<-targets[order(targets$cell_id),];rownames(targets)<-NULL
  target_sha<-digest::digest(targets,algo='sha256')
  if(!file.exists(approval_csv))stop('PAPER_GATE_APPROVED_RESULTS_REQUIRED')
  results_sha<-digest::digest(file=approval_csv,algo='sha256')
  for(i in seq_len(nrow(passed))) {
    row<-passed[i,];p<-row$evidence_path
    if(!file.exists(p)||digest::digest(file=p,algo='sha256')!=row$evidence_sha256)stop('PAPER_GATE_RECEIPT_CHANGED')
    cert<-jsonlite::fromJSON(p)
    if(!is.null(cert$evidence_manifest_path)) {
      if(is.null(repo)||!exists('lo_science_manifest_verify',mode='function'))stop('PAPER_GATE_REVIEW_VERIFIER_REQUIRED')
      lo_science_manifest_verify(cert$evidence_manifest_path,cert$evidence_manifest_sha256,repo,checked)
    }
    if(!is.null(policy_sha)&&!identical(cert$policy_sha256,policy_sha))stop('PAPER_GATE_CURRENT_SCOPE_POLICY_REQUIRED')
    if(!identical(cert$status,'PASS')||!identical(cert$requirement_id,row$requirement_id)||
      !identical(cert$target_sha256,target_sha)||!identical(cert$approval_sha256,results_sha)||
      is.null(cert$assessment)||!nzchar(cert$assessment)||
      !is.data.frame(cert$evidence_files)||!nrow(cert$evidence_files)||
      !all(c('path','sha256')%in%names(cert$evidence_files)))stop('PAPER_GATE_RECEIPT_IDENTITY_OR_SCOPE')
    for(j in seq_len(nrow(cert$evidence_files))) {
      f<-cert$evidence_files[j,]
      key<-paste(f$path,f$sha256)
      if(!exists(key,checked,inherits=FALSE)) {
        if(!file.exists(f$path)||digest::digest(file=f$path,algo='sha256')!=f$sha256)stop('PAPER_GATE_PROOF_CHANGED')
        assign(key,TRUE,checked)
      }
    }
  }
  passed$requirement_id
}
