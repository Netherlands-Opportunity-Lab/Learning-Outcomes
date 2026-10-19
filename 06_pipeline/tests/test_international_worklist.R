source('06_pipeline/MASTER_ESTIMATION_GRID.R')
source('06_pipeline/LO_INTERNATIONAL_WORKLIST.R')
manifest<-data.frame(country=c('ALB','YEM','BRA'),survey=c('PISA','TIMSS','PISA'))
stopifnot(identical(lo_ses_application_country_keys('ALB',manifest),c('ALB','YEM')),
 identical(lo_ses_application_country_keys(c('YEM','ALB'),manifest),c('ALB','YEM')))
# Removing the non-PISA candidate must not rescore unchanged PISA rows; an
# unselected PISA candidate must not enter the application on that pretext.
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

local({
  root<-tempfile('guard_');dir.create(root);on.exit(unlink(root,recursive=TRUE),add=TRUE)
  repo<-file.path(root,'repo');state<-file.path(root,'FIXED_PRODUCTION_V1/all_required')
  dir.create(state,recursive=TRUE)
  names<-c('SCOPE_APPROVALS.csv','COUNTRY_PRODUCTION_APPROVALS.csv',
    'review_20261013/POPULATION_CORRECTIONS.json','LO_COUNTRY_TASKS.R','LO_COUNTRY_REGISTRY.R',
    'LO_SCOPE_DECISIONS.R','LO_APPROVED_EXTENSIONS.R','LO_GENDER_POOL_POLICY.R',
    'LO_INTERNATIONAL_WORKLIST.R','MASTER_ESTIMATION_GRID.R','LO_POPULATION_REVIEW.R',
    'LO_BALANCED_MEMBERSHIP.R','LO_RUN_CONFIG.R')
  for(n in names) {p<-file.path(repo,'06_pipeline',n);dir.create(dirname(p),recursive=TRUE,showWarnings=FALSE);file.copy(file.path('06_pipeline',n),p)}
  path<-file.path(state,'PRIVATE_MASTER_GRID.csv');write.csv(g,path,row.names=FALSE)
  manifest<-file.path(state,'FIXED_INPUT_MANIFEST.json')
  jsonlite::write_json(list(scope='all_required',grid_sha256=digest::digest(file=path,algo='sha256')),manifest,auto_unbox=TRUE)
  x<-lo_international_worklist(q,g)
  guard<-lo_international_certification_guard(repo,root,'all_required',x)
  stopifnot(isTRUE(guard(q[c(1,3),],'all_required')),fails(guard(q,'all_required')),
    fails(guard(bad[1,],'all_required')),fails(guard(q[1,],'nld_only')))
  writeLines('changed policy',file.path(repo,'06_pipeline/SCOPE_APPROVALS.csv'))
  stopifnot(fails(guard(q[1,],'all_required')))
  g$target_contract_sha256[1]<-'changed';write.csv(g,path,row.names=FALSE)
  stopifnot(fails(lo_international_certification_guard(repo,root,'all_required',x)))
})
cat('PASS cached exact approval guard rejects changed scope, targets, policy, absent cells and audit bytes\n')
