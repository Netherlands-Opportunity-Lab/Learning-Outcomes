# Source repair is explicit, ID-joined and content-addressed. Never infer a
# language mapping from numeric codes without its actual source value labels.
lo_repair_pisa2022_rows <- function(obj,raw) {
  if(!identical(obj$meta$survey,"PISA")||as.integer(obj$meta$year)!=2022L)
    stop("REPAIR_REQUIRES_PISA_2022")
  cols<-c("CNT","CNTSTUID","AGE","ST022Q01TA","LANGTEST_COG","W_FSTUWT")
  if(!all(cols%in%names(raw))||!"SOURCE_STUDENT_ID"%in%names(obj$data))stop("REPAIR_REQUIRED_SOURCE_FIELDS_MISSING")
  labs<-attr(raw$ST022Q01TA,"labels")
  same<-unname(labs[tolower(names(labs))=="language of the test"])
  other<-unname(labs[tolower(names(labs))=="other language"])
  if(length(same)!=1L||length(other)!=1L||same==other)stop("REPAIR_LANGUAGE_LABELS_NOT_VERIFIED")
  raw<-raw[as.character(raw$CNT)==obj$meta$v9_country,,drop=FALSE]
  ids<-as.character(raw$CNTSTUID);target<-as.character(obj$data$SOURCE_STUDENT_ID)
  if(anyNA(ids)||anyDuplicated(ids)||anyDuplicated(target)||!setequal(ids,target))stop("REPAIR_STUDENT_POPULATION_MISMATCH")
  raw<-raw[match(target,ids),,drop=FALSE]
  if(any(!is.finite(raw$W_FSTUWT))||any(abs(as.numeric(raw$W_FSTUWT)-obj$data$W)>1e-8))
    stop("REPAIR_PRIMARY_WEIGHT_MISMATCH")
  age<-as.numeric(raw$AGE);age[!is.finite(age)|age>=9990]<-NA_real_
  lang<-as.numeric(raw$ST022Q01TA)
  obj$data$AGE<-age
  obj$data$DEMO_LANGUAGE<-ifelse(lang==same,"test_language_home",ifelse(lang==other,"other_language_home",NA_character_))
  obj$data$TEST_LANGUAGE<-as.character(haven::as_factor(raw$LANGTEST_COG,levels="labels"))
  obj$meta$age_status<-"RAW_AGE_RESTORED_BY_EXACT_STUDENT_ID"
  obj$meta$language_definition<-"ASSESSMENT_LANGUAGE_RELATIVE_HOME_USE"
  obj$meta$language_mapping_status<-"SOURCE_LABELS_AND_STUDENT_IDS_VERIFIED"
  obj$meta$language_weighted_coverage<-sum(obj$data$W[!is.na(obj$data$DEMO_LANGUAGE)])/sum(obj$data$W)
  if(is.data.frame(obj$meta$demographic_definitions)) {
    ix<-obj$meta$demographic_definitions$dimension=="LANGUAGE"
    obj$meta$demographic_definitions$weighted_coverage[ix]<-obj$meta$language_weighted_coverage
    obj$meta$demographic_definitions$category[ix]<-"other_language_home;test_language_home"
    obj$meta$demographic_definitions$definition[ix]<-"Home language relative to individual assessment language; verified ST022Q01TA labels"
  }
  obj
}
lo_repair_pisa2022_source <- function(canonical_path,raw_path,output_path,raw_sha256) {
  if(file.exists(output_path))stop("REPAIR_REFUSES_TO_OVERWRITE")
  if(digest::digest(file=raw_path,algo="sha256")!=raw_sha256)stop("REPAIR_RAW_EDITION_CHANGED")
  obj<-readRDS(canonical_path)
  fields<-c("CNT","CNTSTUID","AGE","ST022Q01TA","LANGTEST_COG","W_FSTUWT")
  raw<-haven::read_sav(raw_path,col_select=tidyselect::all_of(fields))
  repaired<-lo_repair_pisa2022_rows(obj,raw)
  repaired$meta$repair_parent_sha256<-digest::digest(file=canonical_path,algo="sha256")
  repaired$meta$repair_raw_sha256<-raw_sha256
  dir.create(dirname(output_path),recursive=TRUE,showWarnings=FALSE)
  saveRDS(repaired,output_path,compress=FALSE)
  invisible(repaired$meta)
}
lo_exact_language_groups <- function(obj) {
  g<-obj$data$DEMO_LANGUAGE
  if(!identical(obj$meta$survey,"PISA") ||
     !identical(obj$meta$language_definition,"ASSESSMENT_LANGUAGE_RELATIVE_HOME_USE") ||
     !identical(obj$meta$language_mapping_status,"SOURCE_LABELS_AND_STUDENT_IDS_VERIFIED") ||
     length(g)!=nrow(obj$data) || any(!is.na(g)&!g%in%c("test_language_home","other_language_home")))
    return(list(ok=FALSE,reason="EXACT_SOURCE_LANGUAGE_MAPPING_REQUIRED"))
  list(ok=TRUE,group=g,reference="test_language_home",contrast="other_language_home",
    definition="home language relative to this pupil's assessment language; not Dutch versus non-Dutch")
}
