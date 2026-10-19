# A17: a small, explicitly registered set of Dutch paper claims. This is a
# retrospective claim register, not a preregistration and not a test generator.
# Only saved certified aggregate PV/replicate arrays are read; no pupil rerun.
lo_joint_covariance <- function(full,replicates,factor) {
  full<-as.matrix(full);M<-nrow(full);K<-ncol(full)
  if(M<2L || length(dim(replicates))!=3L ||
     !identical(as.integer(dim(replicates)[2:3]),as.integer(c(M,K))) ||
     any(!is.finite(full))||any(!is.finite(replicates))||
     length(factor)!=1L||!is.finite(factor)||factor<=0)stop('CLAIM_JOINT_ARRAY_INVALID')
  within<-matrix(0,K,K)
  for(m in seq_len(M)) {
    d<-sweep(matrix(replicates[,m,],ncol=K),2L,full[m,],'-')
    within<-within+factor*crossprod(d)/M
  }
  within+(1+1/M)*stats::cov(full)
}

lo_paper_claim_review <- function(repo,root,grid,out) {
  sha<-function(p)digest::digest(file=p,algo='sha256')
  config_path<-file.path(repo,'06_pipeline/review_20261013/PAPER_CLAIMS.json')
  config<-jsonlite::fromJSON(config_path)
  if(config$registration_type!='RETROSPECTIVE_BEFORE_PAPER_WRITING'||nrow(config$claims)!=12L||
     anyDuplicated(config$claims$claim_id))stop('CLAIM_REGISTER_CHANGED_REVIEW_REQUIRED')
  proofs<-list();parent_rows<-list();rows<-list()
  verified<-new.env(parent=emptyenv())
  verify<-function(p,h) {
    key<-paste(p,h,sep='|')
    if(!exists(key,verified,inherits=FALSE)) {
      if(!file.exists(p)||sha(p)!=h)stop('CLAIM_EVIDENCE_BYTES_CHANGED: ',basename(p))
      assign(key,TRUE,verified);proofs[[length(proofs)+1L]]<<-data.frame(path=p,sha256=h)
    }
  }
  cell<-function(id,claim) {
    z<-grid[grid$cell_id==id,,drop=FALSE]
    if(nrow(z)!=1L||z$status!='SCIENTIFICALLY_VALIDATED')stop('CLAIM_UNCERTIFIED_PARENT')
    verify(z$certification_path,z$certification_sha256)
    top<-jsonlite::fromJSON(z$certification_path)
    c<-top$cells[top$cells$cell_id==id,,drop=FALSE]
    if(nrow(c)!=1L||c$result_hash!=z$result_hash||c$target_contract_sha256!=z$target_contract_sha256)
      stop('CLAIM_PARENT_CERTIFICATE_MISMATCH')
    verify(c$certification_path,c$certification_sha256)
    method<-jsonlite::fromJSON(c$certification_path)
    parent_rows[[length(parent_rows)+1L]]<<-data.frame(claim_id=claim,cell_id=id,
      result_hash=z$result_hash,target_contract_sha256=z$target_contract_sha256,
      source_sha256=z$source_edition_sha256,method_certificate_sha256=c$certification_sha256,
      input_fingerprint=z$input_fingerprint,code_fingerprint=z$code_fingerprint)
    list(row=z,method=method)
  }
  for(i in seq_len(nrow(config$claims))) {
    q<-config$claims[i,];a<-cell(q$parent_a,q$claim_id);b<-cell(q$parent_b,q$claim_id)
    v<-as.numeric(b$row$estimate)-as.numeric(a$row$estimate)
    link<-q$linking_se;covariance<-0;gap_check<-NA_real_;joint_sha<-''
    if(q$type=='LATEST_SES_GAP') {
      gap<-cell(q$gap_cell,q$claim_id)
      af<-a$method$evidence_files;bf<-b$method$evidence_files;gf<-gap$method$evidence_files
      selected<-af[basename(af$path)=='JOINT_REFERENCE_PV_REPLICATES.rds',,drop=FALSE]
      if(nrow(selected)!=1L || !selected$sha256%in%bf$sha256 || !selected$sha256%in%gf$sha256)
        stop('CLAIM_JOINT_COVARIANCE_NOT_BOUND_TO_ALL_PARENTS')
      verify(selected$path,selected$sha256);joint_sha<-selected$sha256;j<-readRDS(selected$path)
      ids<-c(q$parent_a,q$parent_b,q$gap_cell);at<-match(ids,j$cell_ids)
      if(anyNA(at)||anyDuplicated(j$cell_ids))stop('CLAIM_JOINT_CELL_IDENTITY')
      F<-j$full_pv[,at,drop=FALSE];R<-j$replicate_pv[,,at,drop=FALSE]
      T<-lo_joint_covariance(F,R,j$factor)
      if(max(abs(F[,2]-F[,1]-F[,3]))>1e-9 ||
         max(abs(R[,,2]-R[,,1]-R[,,3]))>1e-9)stop('CLAIM_GAP_NOT_JOINT_CONTRAST')
      contrast<-c(-1,1,0);variance<-as.numeric(t(contrast)%*%T%*%contrast)
      se<-sqrt(variance);covariance<-T[1,2]
      gap_check<-max(abs(v-as.numeric(gap$row$estimate)),abs(se-as.numeric(gap$row$standard_error)),
                     abs(se-sqrt(T[3,3])))
      if(gap_check>1e-8)stop('CLAIM_GAP_NUMERICAL_PARITY_FAILED')
    }else if(q$type=='LONG_TERM_MEAN_CHANGE') {
      if(a$row$survey!=b$row$survey||a$row$domain!=b$row$domain||a$row$country!='NLD'||b$row$country!='NLD')
        stop('CLAIM_TREND_INCOMPATIBLE_POPULATIONS')
      # Independently drawn repeated cross-sections. IEA intervals below follow
      # its reported sampling/PV convention and explicitly omit unquantified
      # long-period linking uncertainty; never describe these as total-error CIs.
      sampling<-as.numeric(a$row$standard_error)^2+as.numeric(b$row$standard_error)^2
      se<-sqrt(sampling+if(is.finite(link))link^2 else 0)
      if(a$row$survey=='PISA'&&(!is.finite(link)||link<=0))stop('CLAIM_PISA_LINKING_REQUIRED')
    }else stop('CLAIM_UNAPPROVED_TYPE')
    evidence<-config$evidence[config$evidence$id==q$uncertainty_evidence,,drop=FALSE]
    if(nrow(evidence)!=1L)stop('CLAIM_OFFICIAL_UNCERTAINTY_EVIDENCE_REQUIRED')
    verify(file.path(root,'scientific_review_20261019/official',evidence$file),evidence$sha256)
    p<-if(isTRUE(q$test))2*pnorm(-abs(v/se)) else NA_real_
    rows[[length(rows)+1L]]<-data.frame(claim_id=q$claim_id,type=q$type,
      survey=a$row$survey,domain=a$row$domain,start_year=a$row$year,end_year=b$row$year,
      estimate=v,standard_error=se,ci_low=v-qnorm(.975)*se,ci_high=v+qnorm(.975)*se,
      uncertainty_scope=q$uncertainty_scope,linking_se=link,joint_covariance=covariance,
      joint_array_sha256=joint_sha,max_joint_contrast_difference=gap_check,
      formal_test=q$test,p_value=p,claim_text=q$claim_text,quality_note=q$quality_note,
      evidence_id=q$uncertainty_evidence,stringsAsFactors=FALSE)
  }
  z<-do.call(rbind,rows);z$p_holm<-NA_real_
  test<-which(z$formal_test);z$p_holm[test]<-p.adjust(z$p_value[test],method='holm')
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  write.csv(z,file.path(out,'PAPER_CLAIM_RESULTS.csv'),row.names=FALSE,na='')
  write.csv(do.call(rbind,parent_rows),file.path(out,'PAPER_CLAIM_DEPENDENCIES.csv'),row.names=FALSE)
  jsonlite::write_json(list(status='REGISTERED_CLAIMS_AND_JOINT_COVARIANCE_VERIFIED',
    claim_count=nrow(z),formal_tests=length(test),multiplicity='HOLM_THREE_PISA_LONG_TERM_MEAN_CLAIMS',
    limitations=config$limitations,registration_sha256=sha(config_path),
    review_code_sha256=sha(file.path(repo,'06_pipeline/LO_PAPER_CLAIM_REVIEW.R')),
    result_sha256=sha(file.path(out,'PAPER_CLAIM_RESULTS.csv')),
    dependencies_sha256=sha(file.path(out,'PAPER_CLAIM_DEPENDENCIES.csv')),
    evidence_files=do.call(rbind,proofs)),file.path(out,'PAPER_CLAIM_REVIEW.json'),
    pretty=TRUE,auto_unbox=TRUE,na='null',digits=17)
  invisible(z)
}
