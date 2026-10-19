# Repair a missing provenance edge, without altering either historical source.
# This proves equal cohorts, design and PV columns; it does not authorize a
# gender recode or substitute proof of the numerical gender estimators.
lo_review_gender_source_projection <- function(child,parent,country,year,out) {
  if(country!='NLD'||as.integer(year)!=2025L)stop('PROJECTION_REVIEW_NOT_REGISTERED')
  a<-readRDS(child);b<-readRDS(parent)
  if(!identical(names(a$data),names(b$data))||nrow(a$data)!=nrow(b$data))stop('PROJECTION_SCHEMA_OR_SAMPLE_CHANGED')
  changed<-names(b$data)[!vapply(names(b$data),function(k)identical(a$data[[k]],b$data[[k]]),logical(1))]
  if(!setequal(changed,c('GENDER','DEMO_GENDER')))stop('PROJECTION_UNREVIEWED_FIELD_CHANGE')
  retained<-setdiff(names(b$data),changed)
  if(!all(c('STUDENT','SOURCE_STUDENT_ID','SCHOOL','W',paste0('RW',1:80))%in%retained)||
     sum(grepl('^PV_(READ|MATH|SCIE)_[0-9]+$',retained))!=30L)stop('PROJECTION_DESIGN_OR_PV_MISSING')
  if(anyDuplicated(a$data$SOURCE_STUDENT_ID)||anyNA(a$data$SOURCE_STUDENT_ID))stop('PROJECTION_PUPIL_IDENTIFIERS')
  cert<-list(schema_version=1L,status='EXACT_COHORT_DESIGN_PV_PROJECTION_VERIFIED',
    country=country,survey='PISA',year=as.character(year),n=nrow(a$data),
    child_sha256=digest::digest(file=child,algo='sha256'),parent_sha256=digest::digest(file=parent,algo='sha256'),
    changed_columns=sort(changed),retained_columns=retained,all_other_columns_identical=TRUE,
    retained_values_sha256=digest::digest(a$data[retained],algo='sha256'),
    original_order_and_identifiers_identical=TRUE,
    scope='Historical boys-only mean certificate; gender recode and numeric parity remain in its original evidence. No girls-only result is created.',
    allowed_method='PISA2025_NLD_LABELLED_MALE_ONLY_OFFICIAL_PARITY_V1')
  jsonlite::write_json(list(schema_version=1L,projections=list(cert)),out,auto_unbox=TRUE,pretty=TRUE,digits=17)
  invisible(cert)
}
