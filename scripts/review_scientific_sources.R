# Inspect only source inputs and certified aggregate dependencies in a frozen
# grid. Existing estimators/START.R remain the sole production entry points.
# Rscript scripts/review_scientific_sources.R <repo> <root> <review-work>
(function() {
  args<-commandArgs(TRUE);stopifnot(length(args)==3L)
  repo<-normalizePath(args[1],winslash='/');root<-normalizePath(args[2],winslash='/')
  work<-normalizePath(args[3],winslash='/')
  path<-file.path(work,'REVIEWED_MASTER_GRID.csv')
  before<-digest::digest(file=path,algo='sha256')
  grid<-read.csv(path,colClasses='character',na.strings=character(),check.names=FALSE)
  stopifnot(!anyDuplicated(grid$cell_id),all(grid$status=='SCIENTIFICALLY_VALIDATED'|startsWith(grid$status,'UNAVAILABLE_')))
  for(n in c('LO_SES_COVERAGE_REVIEW.R','LO_FROZEN_SES_REVIEW.R','LO_PAPER_CLAIM_REVIEW.R'))source(file.path(repo,'06_pipeline',n))
  q1<-lo_ses_coverage_review(repo,grid,file.path(work,'Q01'))
  cat('Q01 ',q1$status,'; mismatches=',q1$count_mismatches,'\n',sep='');flush.console()
  q35<-lo_frozen_ses_review(repo,root,grid,file.path(work,'Q03_Q05'))
  cat('Q03_Q05 ',q35$status,'; sources=',q35$canonical_sources_checked,'\n',sep='');flush.console()
  dir.create(file.path(work,'Q08'),recursive=TRUE,showWarnings=FALSE)
  lo_paper_claim_review(repo,root,grid,file.path(work,'Q08'))
  q8<-jsonlite::fromJSON(file.path(work,'Q08/PAPER_CLAIM_REVIEW.json'))
  cat('Q08 ',q8$status,'\n',sep='');flush.console()
  stopifnot(digest::digest(file=path,algo='sha256')==before,
    q1$count_mismatches==0L,q35$scored_canonical_max_difference<=1e-12,
    q8$status=='REGISTERED_CLAIMS_AND_JOINT_COVARIANCE_VERIFIED')
})()
