source('06_pipeline/MASTER_ESTIMATION_GRID.R')
source('06_pipeline/LO_INTERNATIONAL_WORKLIST.R')
q<-data.frame(metric_key=c('source','home','language'),country='AAA',survey='PIRLS',year=2021,
 domain='reading',module=c('core','extension_home_ses','language_frequency_binary'),stat='mean',
 group=c('total','lower','always_almost'),definition=c('total','IEA_OFFICIAL_HOME_SES_CYCLE_SPECIFIC','frequency_always_almost_vs_sometimes_never'),
 peer_definition='',threshold='',unit='score_points',calculation_policy='')
g<-lo_grid_from_tasks(q);g$status<-c('SCIENTIFICALLY_VALIDATED','UNAVAILABLE_HOME_QUESTIONNAIRE_NOT_ADMINISTERED','TARGET_NOT_YET_ADJUDICATED')
x<-lo_international_worklist(q,g)
stopifnot(identical(x$tasks$metric_key,c('source','language')),identical(x$excluded$cell_id,'home'))
g$status[2]<-'HOLD_SOURCE_MAPPING_REVIEW'
stopifnot(identical(lo_international_worklist(q,g)$tasks,x$tasks))
bad<-q;bad$threshold[1]<-'475'
fails<-function(x)inherits(tryCatch({force(x);NULL},error=function(e)e),'error')
stopifnot(fails(lo_international_worklist(bad,g)),fails(lo_international_worklist(q,g[-1,])),
 fails(lo_international_worklist(q,rbind(g,g[1,]))))
cat('PASS exact saved international worklist; proven absent appendix cannot block available language; changed targets rejected\n')
