source('06_pipeline/LO_PEER_REFERENCE.R')
source('06_pipeline/LO_ESTIMATION_AVAILABILITY.R')
source('06_pipeline/LO_SES_REFERENCE.R')
expect_error<-function(x)stopifnot(inherits(try(force(x),silent=TRUE),'try-error'))
d<-data.frame(W=1,SCHOOL=rep(LETTERS[1:4],each=10),PROGRAM='p',SES=1:40,
  DEMO_GENDER=rep(c('girl','boy'),20),DEMO_LANGUAGE=NA_character_)
for(r in 1:80)d[[paste0('RW',r)]]<-1
for(j in 1:10)d[[paste0('PV_READ_',j)]]<-200+d$SES+j
obj<-list(data=d,meta=list(survey='PISA',year=2025))
q<-data.frame(metric_key=c('mean_home','mean_other','gap','total'),survey='PISA',year='2025',
  module=c(rep('language_exact',3),'core'),domain='reading',stat=c('mean','mean','gap','mean'),
  group=c('test_language_home','other_language_home','other_minus_test','total'),
  definition='',peer_definition='',threshold='')
checked<-lo_estimation_availability(obj,q)
stopifnot(identical(checked$tasks$metric_key,'total'),nrow(checked$unavailable)==3L,
  all(checked$diagnostics$full_weight==0))
obj$data$DEMO_LANGUAGE<-rep(c('test_language_home','other_language_home'),20)
stopifnot(nrow(lo_estimation_availability(obj,q)$tasks)==4L)
obj$data$RW1[seq(2,40,2)]<-0
checked<-lo_estimation_availability(obj,q)
stopifnot(setequal(checked$unavailable$metric_key,c('mean_other','gap')),
  all(checked$diagnostics$reason=='EMPTY_TARGET_IN_REQUIRED_SURVEY_REPLICATE'))
obj$data<-d
s<-q[1:3,];s$module<-'ses_harmonized';s$definition<-'Cobreros_fourwave_13item_trend_comparable'
s$stat<-c('q1_mean','q4_mean','score_gap_q4_minus_q1');s$group<-c('q1','q4','q4_minus_q1')
a<-lo_pisa_ses_reference(obj,s)
empty_ses<-obj;empty_ses$data$SES<-NA_real_
absent_ses<-lo_estimation_availability(empty_ses,s)
stopifnot(nrow(absent_ses$unavailable)==3L,!nrow(absent_ses$tasks),
  all(absent_ses$diagnostics$component=='SES_SOURCE_OBSERVED'))
# Missing school identities prevent school/peer estimands, not their valid
# national siblings. Keep absent SES as the primary reason when both are absent.
missing_school<-list(data=d,meta=list(survey='PISA',year=2025))
missing_school$data$SCHOOL<-NA_character_
school_tasks<-q[c(4,4,4),];school_tasks$metric_key<-c('national','school_variance','ses_peer')
school_tasks$module<-c('core','extension_performance_school','ses_peer_exposure')
school_tasks$stat<-c('mean','between_variance_share','q1_target_pct_q4_peers')
school_tasks$peer_definition<-c('','','whole_school')
guard<-lo_estimation_availability(missing_school,school_tasks)
stopifnot(identical(guard$tasks$metric_key,'national'),
 setequal(guard$unavailable$metric_key,c('school_variance','ses_peer')),
 all(guard$unavailable$absence_reason=='NO_OBSERVED_LEARNING_ENVIRONMENT_ID'))
missing_school$data$SES<-NA_real_
guard<-lo_estimation_availability(missing_school,school_tasks)
stopifnot(guard$unavailable$absence_reason[guard$unavailable$metric_key=='ses_peer']==
 'NO_OBSERVED_ANALYTIC_TARGET_IN_REQUIRED_PV')
# Entirely missing achievement remains in the SES population for quartiles,
# but never contributes to achievement denominators. A partial PV set is invalid.
for(j in 1:10)obj$data[[paste0('PV_READ_',j)]][1]<-NA_real_
b<-lo_pisa_ses_reference(obj,s)
stopifnot(identical(b$results$n_unweighted,c(10L,9L,19L)),
  abs(b$results$estimate[1]-212)<1e-10,a$results$estimate[2]==b$results$estimate[2])
obj$data$PV_READ_1[1]<-200;expect_error(lo_pisa_ses_reference(obj,s))
# Different peer definitions and thresholds may not share fractions. Permuting
# requested cells must only permute outputs and joint covariance columns.
obj$data<-d
for(j in 1:10)obj$data[[paste0('PV_READ_',j)]]<-rep(c(300,450,650,700),10)+j
p<-q[rep(1,6),];p$metric_key<-paste0('peer',1:6);p$stat<-'mean'
p$module<-rep(c('peer_below_basic','high_proficiency_peer_exposure'),each=3)
p$group<-c('total','self_below_basic','self_at_or_above_basic','total','self_high','self_below_high')
p$threshold<-rep(c('PISA_BELOW_LEVEL2','625.61'),each=3);p$peer_definition<-'whole_school'
x<-lo_peer_independent_reference(obj,p);order<-c(5,2,4,1,6,3)
y<-lo_peer_independent_reference(obj,p[order,])
stopifnot(isTRUE(all.equal(x$results[order,],y$results,check.attributes=FALSE)),
  identical(unname(x$joint$replicate_pv[,,order]),unname(y$joint$replicate_pv)),
  identical(y$counts$cell_id,rep(p$metric_key[order],each=10)))
cat('PASS source-frame reuse: missing language, replicate-specific absence, full versus partial PVs, focal ordering and threshold separation\n')
