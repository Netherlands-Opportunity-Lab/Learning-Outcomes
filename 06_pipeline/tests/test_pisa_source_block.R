source('06_pipeline/LO_PISA_SOURCE_BLOCK.R')
source('06_pipeline/LO_EXACT_ESTIMATORS.R')
source('06_pipeline/LO_APPROVED_EXTENSIONS.R')
source('06_pipeline/LO_SCOPE_DECISIONS.R')
raw<-data.frame(CNT='NLD',CNTSTUID=1:4,CNTSCHID=c(1,1,2,2),AGE=15.5,LANGTEST_COG=1,
 ESCS=1:4,PROGN=1,W_FSTUWT=1)
raw$ST004D01T<-haven::labelled(c(1,2,1,2),c(Female=1,Male=2))
raw$ST022Q01TA<-haven::labelled(c(1,2,1,2),c('Language of test'=1,'Other Language'=2))
raw$IMMIG<-haven::labelled(c(1,3,2,3),c(Native=1,'Second-Generation'=2,'First-Generation'=3))
for(r in 1:80)raw[[paste0('W_FSTURWT',r)]]<-if(r%%2)c(1.5,.5,.5,1.5) else c(.5,1.5,1.5,.5)
for(code in c('READ','MATH','SCIE'))for(p in 1:10)raw[[paste0('PV',p,code)]]<-c(300,500,600,700)+p
d<-data.frame(SOURCE_STUDENT_ID=1:4,W=1)
for(r in 1:80)d[[paste0('RW',r)]]<-raw[[paste0('W_FSTURWT',r)]]
for(code in c('READ','MATH','SCIE'))for(p in 1:10)d[[paste0('PV_',code,'_',p)]]<-raw[[paste0('PV',p,code)]]
obj<-list(meta=list(survey='PISA',year=2025,v9_country='NLD'),data=d)
tmp<-tempfile('pisa_block_');dir.create(tmp);raw_path<-file.path(tmp,'raw.sav');parent<-file.path(tmp,'old.rds')
haven::write_sav(raw,raw_path);saveRDS(obj,parent)
v<-lo_pisa_verify_source(raw_path,parent,2025,'NLD',file.path(tmp,'out'))
stopifnot(identical(v$object$data$DEMO_GENDER,c('girl','boy','girl','boy')),
 all(is.finite(v$object$data$AGE)),v$receipt$columns_checked==111,
 identical(v$object$data$DEMO_MIGRATION,c('native','first_generation','second_generation','first_generation')))
again<-lo_pisa_verify_source(raw_path,parent,2025,'NLD',file.path(tmp,'out'))
stopifnot(identical(v$receipt$canonical_sha256,again$receipt$canonical_sha256))
q<-data.frame(metric_key=c('m','p','g','mig'),survey='PISA',year='2025',country='NLD',domain='reading',
 module=c('core','core','gender','migration_generation'),stat=c('mean','p90_p10','gap','mean_score_gap'),
 group=c('total','total','girls_minus_boys','first_minus_native'),threshold='',definition='')
a<-lo_pisa_independent_selected(raw,q)
stopifnot(a$results$estimate[1]==530.5,a$results$estimate[2]==400,
 a$results$estimate[3]== -150,a$results$estimate[4]==300,
 identical(a$results$n_unweighted,c(4L,4L,4L,3L)),all(a$results$standard_error>=0),a$results$standard_error[1]>0)
bad<-obj;bad$data$RW1[1]<-99;saveRDS(bad,parent)
stopifnot(inherits(try(lo_pisa_verify_source(raw_path,parent,2025,'NLD',file.path(tmp,'bad')),silent=TRUE),'try-error'))
bad<-obj;bad$data$SOURCE_STUDENT_ID[1]<-999;saveRDS(bad,parent)
stopifnot(inherits(try(lo_pisa_verify_source(raw_path,parent,2025,'NLD',file.path(tmp,'bad')),silent=TRUE),'try-error'))
unlink(tmp,recursive=TRUE)
cat('PASS raw PISA source parity, exact IDs, labelled demographic repair, independent paired uncertainty and idempotent source preparation\n')
