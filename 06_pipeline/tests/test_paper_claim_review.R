source('06_pipeline/LO_PAPER_CLAIM_REVIEW.R')
F<-cbind(c(10,11,9,10,10),c(20,21,19,20,20))
R<-array(0,c(2,5,2))
for(m in 1:5)for(k in 1:2)R[,m,k]<-F[m,k]+c(-2,2)
V<-lo_joint_covariance(F,R,.5)
# Shared sampling and PV movement cancel in a within-sample contrast. Adding
# marginal variances would invent uncertainty and is deliberately rejected.
stopifnot(abs(V[1,1]+V[2,2]-2*V[1,2])<1e-12,V[1,1]+V[2,2]>0)
R[1,1,2]<-R[1,1,2]+1
V2<-lo_joint_covariance(F,R,.5)
stopifnot(V2[1,1]+V2[2,2]-2*V2[1,2]>0)
fails<-function(x)inherits(try(x,silent=TRUE),'try-error')
stopifnot(fails(lo_joint_covariance(F,R,-.5)),
  fails(lo_joint_covariance(F,R[,1:4,],.5)))
R[1,1,1]<-NA_real_;stopifnot(fails(lo_joint_covariance(F,R,.5)))
cfg<-jsonlite::fromJSON('06_pipeline/review_20261013/PAPER_CLAIMS.json')
stopifnot(nrow(cfg$claims)==12L,sum(cfg$claims$test)==3L,
  all(grepl('PISA',cfg$claims$claim_id[cfg$claims$test])),
  all(is.finite(cfg$claims$linking_se[cfg$claims$test])),
  all(!cfg$claims$test[cfg$claims$type=='LATEST_SES_GAP']))
cat('PASS shared covariance, incomplete arrays, limited registered tests and linking error\n')
