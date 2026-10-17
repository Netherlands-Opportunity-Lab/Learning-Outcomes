# Explicit value-label mapping and exact-ID joins. A missing parent or a
# nonresponse code is never silently treated as native or born abroad.
lo_background_binary <- function(x,yes=c('yes','country of test'),no=c('no','other country')) {
 labs<-attr(x,'labels');labels<-tolower(trimws(names(labs)))
 a<-unname(labs[labels%in%yes]);b<-unname(labs[labels%in%no])
 if(length(a)!=1L||length(b)!=1L||a==b)stop('BACKGROUND_BINARY_LABEL_NOT_VERIFIED')
 v<-as.numeric(x);ifelse(v==a,TRUE,ifelse(v==b,FALSE,NA))
}
lo_background_join <- function(raw,ids,id='IDSTUD') {
 key<-as.character(raw[[id]])
 if(length(key)!=nrow(raw)||anyNA(key)||anyDuplicated(key)||anyDuplicated(ids))stop('BACKGROUND_AMBIGUOUS_PUPIL_ID')
 at<-match(as.character(ids),key)
 if(anyNA(at)||!setequal(key,as.character(ids)))stop('BACKGROUND_PUPIL_SET_MISMATCH')
 raw[at,,drop=FALSE]
}
lo_background_language <- function(x) {
 labs<-attr(x,'labels');s<-tolower(names(labs))
 mapped<-rep(NA_character_,length(labs))
 mapped[grepl('always',s)&!grepl('almost',s)]<-'always'
 mapped[grepl('almost',s)&!grepl('always or almost',s)]<-'almost_always'
 mapped[grepl('always or almost',s)]<-'always_or_almost_always'
 mapped[grepl('sometimes',s)]<-'sometimes';mapped[grepl('never',s)]<-'never'
 if(!all(c('sometimes','never')%in%mapped)||!any(mapped%in%c('always_or_almost_always','almost_always')))stop('BACKGROUND_FREQUENCY_SPLIT_NOT_COMPARABLE')
 mapped[match(as.numeric(x),as.numeric(labs))]
}
lo_background_generations <- function(mother,father,self) {
 # Native means at least one parent born in the country. First/second
 # generation require BOTH parents born abroad and known pupil birthplace.
 ifelse(mother|father,'native',ifelse(!mother&!father&self,'second_generation',
   ifelse(!mother&!father&!self,'first_generation',NA_character_)))
}
