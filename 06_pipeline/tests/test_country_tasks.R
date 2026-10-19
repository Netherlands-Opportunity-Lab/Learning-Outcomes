source('06_pipeline/LO_BALANCED_MEMBERSHIP.R')
source('06_pipeline/LO_COUNTRY_TASKS.R')
t<-expand.grid(country='NLD',survey=c('PIRLS','PISA'),year=c('2001','2006','2011'),stringsAsFactors=FALSE)
t$domain<-'reading';t$module<-'core';t$metric_key<-paste(t$country,t$survey,t$year,t$domain,'mean',sep='|')
s<-list(selected=c('NLD','NEW'),source_support=data.frame(country='NEW',survey='PISA',year=c('2006','2011')),
 cycle_detail=data.frame(country=c('NLD','NLD','NEW','NEW'),survey=c('PIRLS','PISA','PIRLS','PISA'),
 age_group=c('age10','age15','age10','age15'),domain='reading',combination_pass=c(TRUE,TRUE,FALSE,TRUE)))
# Another verified wave can fall outside this historical template; only actual
# configured years within the approved template create tasks.
r<-lo_country_base_tasks(t,s)
stopifnot(nrow(r)==8L,'NEW|PISA|2006|reading|mean'%in%r$metric_key,
 !any(r$country=='NEW' & r$survey=='PIRLS'),!any(r$country=='NEW' & r$year=='2001'),
 identical(r[seq_len(nrow(t)),],t))
neutral<-t;neutral$domain<-'all';neutral$module<-'ses_peer_exposure'
neutral$metric_key<-sub('reading','all',neutral$metric_key,fixed=TRUE)
both<-lo_country_base_tasks(rbind(t,neutral),s)
stopifnot(nrow(both)==16L,!any(both$country=='NEW' & both$survey=='PIRLS'),
 sum(both$country=='NEW' & both$domain=='all')==2L,!anyDuplicated(both$metric_key))
cat('PASS exact approved country expansion; non-admitted combinations create no tasks\n')
