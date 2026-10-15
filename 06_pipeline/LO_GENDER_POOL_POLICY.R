# Direct human decision 2026-10-15: pool Female / Other only where the
# separately observed female category is unavailable. Never relabel as Female.
lo_gender_pool_id <- function() 'FEMALE_OR_OTHER_WHEN_UNSEPARATED_20261015'
lo_gender_dependent <- function(q) {
  (q$module=='gender' & q$group%in%c('girl','girls_minus_boys')) |
    (q$module=='extension_ses_gender' & grepl('_girl$',q$group))
}
lo_gender_pooled <- function(q) grepl(lo_gender_pool_id(),q$calculation_policy,fixed=TRUE)
lo_gender_pool_tasks <- function(tasks,support) {
  contexts<-unique(support[support$survey=='PISA' & as.integer(support$year)>=2015,
    c('country','survey','year','source_path','source_sha256')])
  pooled<-character()
  for(i in seq_len(nrow(contexts))) {
    z<-contexts[i,];p<-file.path(dirname(z$source_path),'SOURCE_VERIFICATION.json')
    if(!file.exists(p))next
    proof<-jsonlite::fromJSON(p)
    if(!isTRUE(proof$gender_status%in%c('PARTIAL_SOURCE_GENDER_GIRL_UNRESOLVED','UNAVAILABLE_NO_VALID_SOURCE_GENDER')))next
    if(proof$country!=z$country || as.character(proof$year)!=z$year ||
       proof$canonical_sha256!=z$source_sha256)stop('GENDER_POOL_SOURCE_IDENTITY')
    labels<-unlist(proof$source_value_labels$MALE)
    if(!length(labels))labels<-unlist(proof$gender_alternative$labels)
    key<-tolower(trimws(names(labels)))
    if(sum(key=='female / other')!=1L||sum(key=='male')!=1L||
       labels[key=='female / other']!=0||labels[key=='male']!=1)
      stop('GENDER_POOL_SOURCE_LABELS')
    pooled<-c(pooled,paste(z$country,z$survey,z$year,sep='|'))
  }
  hit<-paste(tasks$country,tasks$survey,tasks$year,sep='|')%in%pooled & lo_gender_dependent(tasks)
  fresh<-hit & !lo_gender_pooled(tasks)
  tasks$calculation_policy[fresh]<-paste0(tasks$calculation_policy[fresh],';',lo_gender_pool_id())
  tasks$metric_key[fresh]<-paste0(tasks$metric_key[fresh],';',lo_gender_pool_id())
  if(any(lo_gender_pooled(tasks)&!hit))stop('GENDER_POOL_POLICY_WITHOUT_SOURCE_SUPPORT')
  tasks
}
lo_gender_pool_object <- function(obj,raw,q) {
  if(!any(lo_gender_pooled(q)))return(obj)
  if(obj$meta$survey!='PISA'||any(obj$data$DEMO_GENDER=='girl',na.rm=TRUE))
    stop('GENDER_POOL_SEPARATE_FEMALE_ALREADY_AVAILABLE')
  # Independently check all potentially exact fields, including a field absent
  # from an older canonical object. Do not override a newly available category.
  for(k in intersect(c('ST004D01T','ST004','ST004D01D'),names(raw))) {
    labs<-attr(raw[[k]],'labels');female<-unname(labs[tolower(trimws(names(labs)))=='female'])
    if(length(female)==1L&&any(as.numeric(raw[[k]])==female,na.rm=TRUE))
      stop('GENDER_POOL_RAW_HAS_SEPARATE_FEMALE')
  }
  if(!all(c('CNT','CNTSTUID','W_FSTUWT','MALE')%in%names(raw))||
     any(raw$CNT!=obj$meta$v9_country))stop('GENDER_POOL_RAW_IDENTITY')
  labs<-attr(raw$MALE,'labels');key<-tolower(trimws(names(labs)))
  if(sum(key=='female / other')!=1L||sum(key=='male')!=1L||
     labs[key=='female / other']!=0||labs[key=='male']!=1)stop('GENDER_POOL_RAW_LABELS')
  ids<-as.character(raw$CNTSTUID);target<-obj$data$SOURCE_STUDENT_ID
  if(anyNA(ids)||anyDuplicated(ids)||!setequal(ids,target))stop('GENDER_POOL_PUPIL_IDENTITY')
  raw<-raw[match(target,ids),,drop=FALSE]
  if(!identical(as.numeric(raw$W_FSTUWT),as.numeric(obj$data$W)))stop('GENDER_POOL_WEIGHT_IDENTITY')
  obj$data$DEMO_GENDER<-c('girl','boy')[match(as.numeric(raw$MALE),c(0,1))]
  obj$data$GENDER<-obj$data$DEMO_GENDER
  obj$meta$gender_policy<-lo_gender_pool_id()
  obj$meta$gender_definition<-'FEMALE_OR_OTHER_VS_MALE'
  obj$meta$gender_label_nl<-'Meisjes + other'
  obj$meta$gender_label_en<-'Girls + other'
  obj$meta$gender_variable<-'MALE'
  obj$meta$gender_map<-'0=Female / Other;1=Male;all other codes missing'
  obj$meta$gender_counts<-as.list(table(obj$data$DEMO_GENDER,useNA='ifany'))
  obj
}
lo_gender_pool_guard <- function(obj,q) {
  dependent<-lo_gender_dependent(q)
  marked<-lo_gender_pooled(q)
  object_pool<-identical(obj$meta$gender_policy,lo_gender_pool_id())
  if(any(marked&!dependent)||any(dependent & marked!=object_pool))stop('GENDER_POOL_TASK_OBJECT_MISMATCH')
  invisible(TRUE)
}
lo_gender_display <- function(key,group,language='nl') {
  pooled<-grepl(lo_gender_pool_id(),key,fixed=TRUE)
  label<-group
  label[pooled&group=='girl']<-if(language=='nl')'Meisjes + other'else'Girls + other'
  label[pooled&group=='girls_minus_boys']<-if(language=='nl')'Meisjes + other minus jongens'else'Girls + other minus boys'
  ses<-pooled&grepl('_girl$',group)
  label[ses]<-paste(sub('_girl$','',group[ses]),if(language=='nl')'meisjes + other'else'girls + other')
  label
}
