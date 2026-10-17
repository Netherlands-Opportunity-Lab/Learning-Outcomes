source('06_pipeline/LO_COUNTRY_TASKS.R')
t<-data.frame(country=c('NLD','NLD','OLD'),survey='PIRLS',year=c('2001','2006','2001'),
 metric_key=c('NLD|PIRLS|2001|mean','NLD|PIRLS|2006|mean','OLD|unapproved'),module='core')
s<-list(selected=c('NLD','NEW'),source_support=data.frame(country='NEW',survey='PIRLS',year='2006'))
r<-lo_country_base_tasks(t,s)
stopifnot(nrow(r)==3L,'NEW|PIRLS|2006|mean'%in%r$metric_key,
 !any(r$country=='OLD'),!any(r$country=='NEW'&r$year=='2001'),identical(r[1:2,],t[1:2,]))
cat('PASS country expansion preserves approved contracts and exact observed cycles outside old catalogue\n')
