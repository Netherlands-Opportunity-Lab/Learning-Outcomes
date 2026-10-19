source('06_pipeline/LO_INTERNATIONAL_SES.R')
order<-data.frame(position=1:4,source_country=c('OLD','TAP','NEW','NEW'),year=c(2015,2015,2015,2018))
available<-order[c(4,2,1,3),c('source_country','year')]
# A subset run preserves preceding country-wave RNG draws, including TWN's
# official TAP code. Adding later rows cannot reorder a certified prefix.
stopifnot(identical(lo_ses_extra_prefix(order,available,'NEW','NLD'),order),
 identical(lo_ses_extra_prefix(order,available,'TWN','NLD'),order[1:2,]),
 nrow(lo_ses_extra_prefix(order,available,'NLD','NLD'))==0L)
expanded<-rbind(order,data.frame(position=5L,source_country='LATER',year=2025))
stopifnot(identical(lo_ses_extra_prefix(expanded,available,'NEW','NLD'),order))
fails<-function(x)inherits(try(force(x),silent=TRUE),'try-error')
stopifnot(fails(lo_ses_extra_prefix(order,available[-3,],'NEW','NLD')),
 fails(lo_ses_extra_prefix(order[-1,],available,'NEW','NLD')),
 fails(lo_ses_extra_prefix(order,rbind(available,data.frame(source_country='UNKNOWN',year=2025)),'UNKNOWN','NLD')))
cat('PASS append-only SES imputation sequence, subset-run stability and missing-prefix rejection\n')
