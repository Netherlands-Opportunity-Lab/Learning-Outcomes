source('06_pipeline/LO_PEER_REFERENCE.R')
source('06_pipeline/LO_ESTIMATION_AVAILABILITY.R')
source('06_pipeline/LO_INTERNATIONAL_BACKGROUND.R')
source('06_pipeline/LO_SOURCE_UNAVAILABILITY.R')
source('06_pipeline/MASTER_ESTIMATION_GRID.R')
expect_error<-function(expr)stopifnot(inherits(try(force(expr),silent=TRUE),'try-error'))
d<-data.frame(W=rep(1,4),SCHOOL=c('A','A','B','B'),CLASS=c('1','1','2','2'),JKZONE=c(1,1,2,2),JKREP=c(0,1,0,1))
for(j in 1:80)d[[paste0('RW',j)]]<-1
for(j in 1:5)d[[paste0('PV_READ_',j)]]<-c(400,650,300,500)
q<-data.frame(metric_key=c('total','low','above'),country='ZZZ',survey='PISA',year='2009',module='peer_below_basic',stat='mean',
 domain='reading',definition='',peer_definition='whole_school',threshold='PISA_BELOW_LEVEL2',group=c('total','self_below_basic','self_at_or_above_basic'),
 contract_figure_id='EN_PERFORMANCE_PEER_age15_reading',unit='percent',calculation_policy='',stringsAsFactors=FALSE)
obj<-list(data=d,meta=list(survey='PISA',year=2009))
ok<-lo_estimation_availability(obj,q)
stopifnot(nrow(ok$tasks)==3L,!nrow(ok$unavailable),lo_peer_independent_reference(obj,q)$results$estimate[2]==0)
# An absent focal category in one PV cannot become a zero estimate or drop a PV.
obj$data$PV_READ_3<-600
bad<-lo_estimation_availability(obj,q)
stopifnot(identical(bad$unavailable$metric_key,'low'),bad$diagnostics$pv==3L,bad$diagnostics$n_full_target==0,
 nrow(bad$tasks)==2L,lo_peer_independent_reference(obj,bad$tasks)$joint$pv_count==5L)
expect_error(lo_peer_independent_reference(obj,q))
# One replicate alone can make a conditional estimand undefined.
obj$data<-d;obj$data$RW1<-c(0,1,0,1)
repbad<-lo_estimation_availability(obj,q)
stopifnot('low'%in%repbad$unavailable$metric_key,any(repbad$diagnostics$reason=='EMPTY_TARGET_IN_REQUIRED_SURVEY_REPLICATE'))
# Invalid data/design/codes are errors, never certified scientific absence.
obj$data<-d;obj$data$W[1]<--1;expect_error(lo_estimation_availability(obj,q))
obj$data<-d;obj$data$RW80<-NULL;expect_error(lo_estimation_availability(obj,q))
obj$data<-d;obj$data$DEMO_MIGRATION<-c('native','native','first_generation',NA)
m<-q[1:2,];m$module<-'migration_generation';m$group<-c('second_generation','second_minus_native');m$stat<-c('mean','gap');m$metric_key<-c('second','gap');m$threshold<-''
stopifnot(nrow(lo_estimation_availability(obj,m)$unavailable)==2L)
obj$data$DEMO_MIGRATION[1]<-'unreviewed';expect_error(lo_estimation_availability(obj,m))
# A real zero percent of migrant peers is estimable when targets exist.
obj$data<-d;obj$data$MOTHER_BORN_HERE<-c(FALSE,TRUE,TRUE,TRUE);obj$data$FATHER_BORN_HERE<-TRUE
b<-q[1,,drop=FALSE];b$module<-'migration_binary_peer';b$definition<-'MIGRATION_ANY_PARENT_ABROAD';b$domain<-'all'
stopifnot(nrow(lo_estimation_availability(obj,b)$tasks)==1L)
# Missing group evidence is durable, exact, idempotent, and cannot approve a result.
obj$data<-d;obj$data$PV_READ_3<-600
tmp<-tempfile('availability_');dir.create(tmp)
parent<-file.path(tmp,'canonical.rds');saveRDS(obj,parent)
kept<-lo_record_estimation_availability('.',tmp,obj,q,parent)
reg<-file.path(tmp,'master_reconciliation/SOURCE_UNAVAILABLE_CELLS.csv')
before<-digest::digest(file=reg,algo='sha256')
again<-lo_record_estimation_availability('.',tmp,obj,q,parent)
stopifnot(identical(kept,again),before==digest::digest(file=reg,algo='sha256'))
g<-lo_grid_from_tasks(q);checked<-lo_source_unavailability(g,reg)
stopifnot(nrow(checked)==nrow(g),checked$status[2]=='UNAVAILABLE_VERIFIED_ANALYTIC_SAMPLE',
 !any(checked$status=='SCIENTIFICALLY_VALIDATED'))
conflict<-g;conflict$status[2]<-'SCIENTIFICALLY_VALIDATED';expect_error(lo_source_unavailability(conflict,reg))
saveRDS(list(changed=TRUE),parent);expect_error(lo_source_unavailability(g,reg))
unlink(tmp,recursive=TRUE)
cat('PASS exact partial-block availability; zero vs undefined; every PV/replicate; source/code integrity and idempotence\n')
