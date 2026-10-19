# Source identities can be scientifically wrong despite intact file hashes.
# Corrections apply to the population/cycle, not only a filename or hash; a
# fresh download of the same regional population must not resurrect admission.
# Historical cells and certificates are retained. This is no numerical refit.
lo_population_review <- function(repo) {
  path<-file.path(repo,'06_pipeline/review_20261013/POPULATION_CORRECTIONS.json')
  if(!file.exists(path))stop('POPULATION_REVIEW_REGISTER_REQUIRED')
  z<-jsonlite::fromJSON(path,simplifyVector=TRUE)
  x<-z$corrections
  # Legacy entries cover every domain. New official qualifications may concern
  # reading/science only; never discard a valid mathematics wave with them.
  if(is.data.frame(x)) {
    if(!'domain'%in%names(x))x$domain<-'all'
    x$domain[is.na(x$domain)|!nzchar(x$domain)]<-'all'
  }
  required<-c('review_id','country','survey','year','disposition','actual_population','reason')
  if(!identical(z$schema_version,1L)||!is.data.frame(x)||
     !all(required%in%names(x))||anyNA(x[required])||
     anyDuplicated(paste(x$country,x$survey,x$year,x$domain)))stop('POPULATION_REVIEW_INVALID')
  if(any(!x$domain%in%c('all','reading','mathematics','science')))
    stop('POPULATION_REVIEW_INVALID_DOMAIN')
  contexts<-paste(x$country,x$survey,x$year)
  if(any(contexts[x$domain!='all']%in%contexts[x$domain=='all']))
    stop('POPULATION_REVIEW_OVERLAPPING_DOMAINS')
  if(any(!x$disposition%in%c('EXCLUDE_FROM_NATIONAL_SUPPORT','EXCLUDE_FROM_COMPARABLE_TREND_SUPPORT')))
    stop('POPULATION_REVIEW_UNSUPPORTED_DISPOSITION')
  attr(x,'sha256')<-digest::digest(file=path,algo='sha256')
  x
}

lo_population_review_rows <- function(x,review) {
  fields<-c('country','survey','year')
  if(!all(fields%in%names(x)))stop('POPULATION_REVIEW_CONTEXT_REQUIRED')
  key<-function(z)do.call(paste,c(z[fields],sep='|'))
  if(!'domain'%in%names(review))review$domain<-'all'
  broad<-which(review$domain=='all')
  result<-broad[match(key(x),key(review[broad,,drop=FALSE]))]
  specific<-which(review$domain!='all')
  if(length(specific)) {
    if(!'domain'%in%names(x))stop('POPULATION_REVIEW_DOMAIN_REQUIRED')
    exact<-specific[match(paste(key(x),x$domain),
      paste(key(review[specific,,drop=FALSE]),review$domain[specific]))]
    result[!is.na(exact)]<-exact[!is.na(exact)]
  }
  result
}

lo_population_filter_support <- function(x,review) {
  previous<-attr(x,'population_exclusions')
  attr(x,'population_exclusions')<-NULL;attr(x,'population_review_sha256')<-NULL
  attr(x,'population_review')<-NULL
  if(is.data.frame(previous)&&nrow(previous))x<-unique(rbind(x,previous[names(x)]))
  i<-lo_population_review_rows(x,review)
  excluded<-x[!is.na(i),,drop=FALSE]
  excluded$population_review_id<-review$review_id[i[!is.na(i)]]
  excluded$population_review_reason<-review$reason[i[!is.na(i)]]
  kept<-x[is.na(i),,drop=FALSE]
  rownames(kept)<-NULL;rownames(excluded)<-NULL
  attr(kept,'population_exclusions')<-excluded
  attr(kept,'population_review_sha256')<-attr(review,'sha256')
  attr(kept,'population_review')<-review
  kept
}

lo_population_require_national <- function(x,review) {
  bad<-!is.na(lo_population_review_rows(x,review))
  if(any(bad))stop('POPULATION_REVIEW_REJECTED_NATIONAL_RESULT: ',
    paste(unique(paste(x$country[bad],x$survey[bad],x$year[bad])),collapse='; '))
  invisible(TRUE)
}
