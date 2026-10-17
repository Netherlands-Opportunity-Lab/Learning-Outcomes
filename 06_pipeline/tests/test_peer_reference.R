source('06_pipeline/LO_PEER_REFERENCE.R')
d<-data.frame(W=rep(1,4),SCHOOL=c('A','A','B','B'),CLASS=c('1','1','2','2'),JKZONE=c(1,1,2,2),JKREP=c(0,1,0,1))
# Use PISA BRR with identical test replicates to isolate self-exclusion and PV
# uncertainty. The two-unit four-pupil fixture has hand-computable answers.
for(j in 1:80)d[[paste0('RW',j)]]<-1
for(j in 1:5)d[[paste0('PV_READ_',j)]]<-c(400,650,300,500)
q<-data.frame(metric_key=c('total','low','above'),survey='PISA',year='2009',module='peer_below_basic',
 domain='reading',peer_definition='whole_school',threshold='PISA_BELOW_LEVEL2',group=c('total','self_below_basic','self_at_or_above_basic'))
obj<-list(data=d,meta=list(survey='PISA',year=2009))
a<-lo_peer_independent_reference(obj,q)
stopifnot(identical(a$results$estimate,c(50,0,100)),all(a$results$standard_error==0),all(a$results$n_unweighted==4),
 identical(a$counts$n_target,c(rep(4L,5),rep(2L,10))))
obj$data$PV_READ_2[1]<-600
b<-lo_peer_independent_reference(obj,q)
stopifnot(all(b$results$n_unweighted==4),identical(b$counts$n_target[6:10],c(2L,1L,2L,2L,2L)),b$results$standard_error[1]>0)
obj$data$SCHOOL<-letters[1:4]
stopifnot(inherits(try(lo_peer_independent_reference(obj,q),silent=TRUE),'try-error'))
cat('PASS independent weighted peer self-exclusion, joint PV variation, separate focal counts and singleton rejection\n')
