source('06_pipeline/LO_SES_REFERENCE.R')
d<-data.frame(SES=1:40,W=1,SCHOOL='A',PROGRAM='p',DEMO_GENDER=rep(c('girl','boy'),20))
for(r in 1:80)d[[paste0('RW',r)]]<-1
for(p in 1:10)d[[paste0('PV_READ_',p)]]<-200+d$SES+p
obj<-list(data=d,meta=list(survey='PISA',year=2025,v9_country='NLD'))
q<-data.frame(metric_key=paste0('r',1:8),survey='PISA',year='2025',country='NLD',
 module=c(rep('ses_harmonized',3),'extension_ses_gender','extension_ses_school','peer_baseline',rep('ses_peer_exposure',2)),
 domain=c(rep('reading',4),rep('all',4)),definition='Cobreros_fourwave_13item_trend_comparable',
 stat=c('q1_mean','q4_mean','score_gap_q4_minus_q1','mean','between_variance_share','q1_share','q1_target_pct_q4_peers','q4_target_pct_q1_peers'),
 group=c('q1','q4','q4_minus_q1','q1_girl','total','total','q1_target_pct_q4_peers','q4_target_pct_q1_peers'),
 threshold='',peer_definition=c(rep('',4),'school','whole_school','whole_school','whole_school'))
set.seed(12);old<-.Random.seed
a<-lo_pisa_ses_reference(obj,q)
stopifnot(identical(old,.Random.seed),all(abs(a$results$estimate-c(211.5,241.5,30,211.5,0,27.5,100*9/39,100*11/39))<1e-10),
 identical(a$results$n_unweighted,c(11L,9L,20L,6L,40L,40L,11L,9L)),
 abs(a$results$standard_error[1]-sqrt(1.1*var(1:10)))<1e-12,
 a$results$standard_error[3]==0)
# Missing SES cannot alter other pupils' groups, exposure or denominator.
extra<-d[1,,drop=FALSE];extra$SES<-NA_real_;extra$W<-100
obj$data<-rbind(d,extra)
b<-lo_pisa_ses_reference(obj,q)
stopifnot(identical(a$results,b$results))
q$stat[6]<-'unreviewed'
stopifnot(inherits(try(lo_pisa_ses_reference(obj,q),silent=TRUE),'try-error'))
cat('PASS independent SES reference: paired PV/BRR, quartile boundaries, N and missingness\n')
