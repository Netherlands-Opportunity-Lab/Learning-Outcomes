source('06_pipeline/LO_EXACT_ESTIMATORS.R')
set.seed(81);n<-80L;Y<-matrix(rnorm(n*5,500,80),n,5)
W<-matrix(runif(n*4,.1,2),n,4);W[1:4,3]<-0
d<-data.frame(W=W[,1],GROUP=rep(c('reference','migration',NA,'reference'),length.out=n))
for(j in 1:5)d[[paste0('PV_READ_',j)]]<-Y[,j]
o<-list(data=d,meta=list(survey='synthetic',year=2016))
rc2_num<-as.numeric;pv_names<-function(d,domain)grep('^PV',names(d),value=TRUE)
rc2_replicate_design<-function(...)list(w=W[,1],n=3L,factor=.5)
rc2_repweight<-function(des,r)W[,r+1L]
v10_migration<-function(obj,definition)obj$data$GROUP
v10_language<-function(obj,...)obj$data$GROUP
migration_groups<-function(obj)list(ok=TRUE,group=obj$data$GROUP)
captured<-NULL
rc2_pool<-function(full,reps,factor) {
 captured<<-list(full=full,reps=reps)
 m<-nrow(full)
 se<-vapply(seq_len(ncol(full)),function(k)sqrt(mean(colSums((reps[,,k]-rep(full[,k],each=nrow(reps)))^2)*factor)+(1+1/m)*var(full[,k])),numeric(1))
 list(estimate=colMeans(full),se=se)
}
q<-data.frame(metric_key=c('reference','migration','gap'),domain='reading',module='migration',
 definition='defined',peer_definition='',stat=c('mean','mean','gap'),group=c('reference','migration','migration_minus_reference'))
oracle<-function(groups,pairs) {
 a<-array(NA_real_,c(5,4,3));wm<-function(y,w,g){ok<-is.finite(y)&is.finite(w)&w>0&!is.na(g)&g;sum(y[ok]*w[ok])/sum(w[ok])}
 for(j in 1:5)for(r in 1:4) {
  a[j,r,1]<-wm(Y[,j],W[,r],groups==pairs[1])
  a[j,r,2]<-wm(Y[,j],W[,r],groups==pairs[2])
  a[j,r,3]<-a[j,r,2]-a[j,r,1]
 }
 a
}
for(m in c('migration','language_exact','language_frequency_binary','migration_generation')) {
 z<-q;z$module<-m
 pair<-switch(m,migration=c('reference','migration'),language_exact=c('test_language_home','other_language_home'),
  language_frequency_binary=c('always','never'),migration_generation=c('native','first_generation'))
 o$data$GROUP<-rep(c(pair,NA,pair[1]),length.out=n)
 z$group<-c(pair,'gap')
 if(m=='language_frequency_binary')z$group<-c('always_almost','sometimes_never','sometimes_never_minus_always_almost')
 if(m=='migration_generation'){z$stat<-c('mean_score','mean_score','mean_score_gap');z$group[3]<-'first_minus_native'}
 expected<-oracle(o$data$GROUP,pair)
 for(chunk in c(1L,3L,16L)) {
  a<-lo_exact_background_linear(o,z,chunk)
  stopifnot(max(abs(captured$full-expected[,1,]))<1e-10,
    max(abs(captured$reps-aperm(expected[,-1,,drop=FALSE],c(2,1,3))))<1e-10)
 }
}
q$stat[1]<-'unapproved'
stopifnot(inherits(try(lo_exact_background_linear(o,q),silent=TRUE),'try-error'))
cat('PASS chunk-invariant background PV/replicate values and joint migration/language/generation contrasts\n')
