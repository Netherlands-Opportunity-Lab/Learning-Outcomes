source('06_pipeline/LO_POPULATION_REVIEW.R')
source('06_pipeline/LO_BALANCED_MEMBERSHIP.R')
r<-lo_population_review('.')
x<-expand.grid(country=c('CAN','NLD'),age_group=c('age10','age15'),
  domain=c('reading','mathematics','science'),year=c('2001','2011','2016'),stringsAsFactors=FALSE)
x$survey<-ifelse(x$age_group=='age15','PISA',ifelse(x$domain=='reading','PIRLS','TIMSS'))
for(k in setdiff(lo_balance_columns(),names(x)))x[[k]]<-'none'
x$outcome<-'mean_score';x$split_group<-'total';x$unit<-'score_points'
before<-lo_support_eligibility(x,c('CAN','NLD'))$countries
stopifnot(all(before$dashboard_eligible))
y<-lo_population_filter_support(x,r)
stopifnot(identical(y,lo_population_filter_support(y,r)))
after<-lo_support_eligibility(y,c('CAN','NLD'))
stopifnot(all(after$countries$dashboard_eligible),
  !after$detail$combination_pass[after$detail$country=='CAN' & after$detail$survey=='PIRLS'],
  all(after$detail$combination_pass[after$detail$country=='CAN' & after$detail$survey!='PIRLS']),
  nrow(attr(y,'population_exclusions'))==1L,nrow(x)==36L,nrow(y)==35L)
# A different file hash cannot turn the same regional population into Canada.
x$source_sha256<-paste(rep('f',64),collapse='')
stopifnot(nrow(lo_population_filter_support(x,r))==35L,
  inherits(try(lo_population_require_national(x,r),silent=TRUE),'try-error'),
  isTRUE(lo_population_require_national(y,r)))
source('06_pipeline/LO_COUNTRY_TASKS.R')
historical<-data.frame(country='NLD',survey='PISA',domain='reading',year=c('2009','2012','2015','2018'),
  metric_key=paste('NLD|PISA',c('2009','2012','2015','2018'),'reading',sep='|'))
support<-x[x$country=='NLD' & x$survey=='PISA' & x$domain=='reading',]
support<-support[c(1,2,3,3),];support$country<-'AUT';support$year<-historical$year
filtered<-lo_population_filter_support(support,r)
stopifnot(nrow(filtered)==3L)
retained<-lo_country_base_tasks(historical,list(selected='AUT',source_support=filtered))
stopifnot(nrow(retained)==4L,'AUT|PISA|2009|reading'%in%retained$metric_key)
# Polish third-grade waves cannot be added to later fourth-grade waves to
# reach the three-wave admission threshold, regardless of generic file labels.
pol<-expand.grid(country='POL',age_group=c('age10','age15'),
 domain=c('reading','mathematics','science'),year=c('2006','2011','2016','2021'),stringsAsFactors=FALSE)
pol$survey<-ifelse(pol$age_group=='age15','PISA',ifelse(pol$domain=='reading','PIRLS','TIMSS'))
for(k in setdiff(lo_balance_columns(),names(pol)))pol[[k]]<-'none'
pol$outcome<-'mean_score';pol$split_group<-'total';pol$unit<-'score_points'
stopifnot(lo_support_eligibility(pol,'POL')$countries$dashboard_eligible)
reviewed_pol<-lo_population_filter_support(pol,r)
pol_admission<-lo_support_eligibility(reviewed_pol,'POL')
stopifnot(pol_admission$countries$dashboard_eligible,
 !pol_admission$detail$combination_pass[pol_admission$detail$survey=='PIRLS'],
 nrow(reviewed_pol[reviewed_pol$survey=='PIRLS',])==2L)
cat('PASS population/comparability correction, retained qualified trend anchors, per-combination admission and changed-download regression\n')
