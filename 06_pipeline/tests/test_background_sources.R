source('06_pipeline/LO_BACKGROUND_SOURCE.R')
source('06_pipeline/LO_BACKGROUND_REFERENCE.R')
source('06_pipeline/LO_IEA_BACKGROUND.R')
source('06_pipeline/LO_COMPACT_RECOMPUTE.R')
yes<-haven::labelled(c(1,2,3,99),c('Yes'=1,'No'=2,'Do not know'=3,'Missing'=99))
stopifnot(identical(lo_background_binary(yes),c(TRUE,FALSE,NA,NA)))
bad<-yes;attr(bad,'labels')<-c('Child language'=1,'Other language'=2)
stopifnot(inherits(try(lo_background_binary(bad),silent=TRUE),'try-error'))
stopifnot(identical(lo_background_generations(c(TRUE,FALSE,FALSE,NA,FALSE),c(NA,FALSE,FALSE,TRUE,NA),c(NA,TRUE,FALSE,NA,TRUE)),
 c('native','second_generation','first_generation','native',NA_character_)))
freq<-haven::labelled(c(1,2,3,9),c('Always or almost always'=1,'Sometimes'=2,'Never'=3,'Missing'=9))
stopifnot(identical(lo_background_language(freq),c('always_or_almost_always','sometimes','never',NA_character_)))
attr(freq,'labels')[1]<-1;names(attr(freq,'labels'))[1]<-'Always'
stopifnot(inherits(try(lo_background_language(freq),silent=TRUE),'try-error'))
raw<-data.frame(IDSTUD=c('2','1'),v=c(20,10));stopifnot(identical(lo_background_join(raw,c('1','2'))$v,c(10,20)))
stopifnot(inherits(try(lo_background_join(raw,c('1','3')),silent=TRUE),'try-error'))
# One native and one migrant per school: own-group pupils are excluded from
# their peer mean. Missing pupils cannot enter the peer denominator.
d<-data.frame(W=c(1,2,1,2,9),SCHOOL=c('a','a','b','b','a'),
 MOTHER_BORN_HERE=c(TRUE,FALSE,TRUE,FALSE,NA),FATHER_BORN_HERE=c(TRUE,FALSE,TRUE,FALSE,NA))
for(i in 1:80)d[[paste0('RW',i)]]<-d$W
o<-list(data=d,meta=list(survey='PISA',year=2022L,background_mapping_status='RAW_LABELS_AND_EXACT_IDS_VERIFIED'))
q<-data.frame(metric_key='a',survey='PISA',year='2022',country='NLD',domain='all',module='migration_binary_peer',
 stat='migration_target_pct_reference_peers',group='migration',definition='MIGRATION_BOTH_PARENTS_ABROAD',peer_definition='whole_school',threshold='')
a<-lo_background_reference(o,q)$results
stopifnot(a$estimate==100,a$standard_error==0,a$n_unweighted==2)
h<-lo_compact_projection(o,q);o$data$FATHER_BORN_HERE[2]<-TRUE
stopifnot(h!=lo_compact_projection(o,q))
# Irrelevant SES and test-language columns are not fabricated to get past a hash.
o$data$SES<-1:5;o$data$TEST_LANGUAGE<-'unused';stopifnot(lo_compact_projection(o,q)==lo_compact_projection(within(o,data<-data[setdiff(names(data),c('SES','TEST_LANGUAGE'))]),q))
cat('PASS background labels, exact joins, unknown parents, self-exclusion and used-field fingerprints\n')
source('06_pipeline/MASTER_ESTIMATION_GRID.R')
source('06_pipeline/LO_DERIVE_POPULATION_BASELINES.R')
q<-data.frame(metric_key=c('core','baseline'),country='NLD',survey='PISA',year='2022',domain='reading',
 module=c('core','peer_baseline'),stat=c('total_high','high_share'),group='total',definition=c('total','high_peer_raw_sample'),
 peer_definition=c('','whole_school'),threshold='625',unit=c('proportion','percent'),calculation_policy='')
p<-lo_grid_from_tasks(q[1,]);p$estimate<-.2;p$standard_error<-.03;p$n_unweighted<-100L;p$status<-'SCIENTIFICALLY_VALIDATED'
a<-lo_derive_population_baselines(q,p)
stopifnot(nrow(a$rows)==1L,a$rows$estimate==20,a$rows$standard_error==3,a$rows$n_unweighted==100L,a$parents$cell_id=='core')
bad<-q;bad$threshold[2]<-'626';stopifnot(inherits(try(lo_derive_population_baselines(bad,p),silent=TRUE),'try-error'))
p$status<-'HOLD';stopifnot(inherits(try(lo_derive_population_baselines(q,p),silent=TRUE),'try-error'))
cat('PASS exact certified core baseline derivation and threshold mismatch rejection\n')
