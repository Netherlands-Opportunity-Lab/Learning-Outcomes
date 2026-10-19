source('06_pipeline/LO_ANALYSIS_SUPPORT_REVIEW.R')
local({
 d<-data.frame(W=rep(1,60),SCHOOL=rep(letters[1:6],each=10),PROGRAM='1',
   DEMO_GENDER=c(rep('girl',29),rep('boy',31)),MOTHER_BORN_HERE=TRUE,FATHER_BORN_HERE=TRUE)
 for(i in 1:10)d[[paste0('PV_MATH_',i)]]<-c(rep(400,20),rep(500,40))
 obj<-list(data=d,meta=list(survey='PISA',year=2025))
 q<-data.frame(module='gender',stat='gap',group='girls_minus_boys',domain='mathematics',definition='gender',peer_definition='',threshold='')
 z<-lo_analysis_support_counts(obj,q)
 stopifnot(nrow(z)==20L,all(z$union_n==60L),min(z$n)==29L,min(z$school_n)==3L)
 q$module<-'core';q$stat<-'total_below';q$group<-'total'
 z<-lo_analysis_support_counts(obj,q)
 stopifnot(all(z$n==60L),all(z$school_n==6L)) # Zero/nonzero estimate never determines support.
 q$module<-'peer_below_basic';q$stat<-'peer_share_below_basic';q$group<-'self_below_basic'
 q$peer_definition<-'direct_learning_environment';q$threshold<-'PISA_BELOW_LEVEL2'
 z<-lo_analysis_support_counts(obj,q)
 stopifnot(all(z$n==20L),all(z$peer_frame_n==60L),all(z$school_n==2L))
 obj$data$PV_MATH_10[21]<-400
 z<-lo_analysis_support_counts(obj,q)
 stopifnot(min(z$n)==20L,max(z$n)==21L)
 obj$data$PROGRAM[1]<-'singleton'
 z<-lo_analysis_support_counts(obj,q)
 stopifnot(min(z$n)==19L,all(z$peer_frame_n==59L))
 q$module<-'migration';q$stat<-'gap';q$group<-'migration_minus_reference'
 q$definition<-'MIGRATION_ANY_PARENT_ABROAD';q$peer_definition<-''
 obj$data$MOTHER_BORN_HERE[1]<-FALSE;obj$data$FATHER_BORN_HERE[1:2]<-NA
 z<-lo_analysis_support_counts(obj,q)
 stopifnot(all(z$union_n==59L),all(z$n[z$component=='migration']==1L))
 q$definition<-'MIGRATION_BOTH_PARENTS_ABROAD'
 z<-lo_analysis_support_counts(obj,q)
 stopifnot(all(z$union_n==59L),all(z$n[z$component=='migration']==0L))
 q$module<-'invented'
 stopifnot(inherits(try(lo_analysis_support_counts(obj,q),silent=TRUE),'try-error'))
 cat('PASS separate contrast components, pupil and school counts, each PV, peer self-exclusion, known/unknown parent predicates and strict module identity\n')
})
