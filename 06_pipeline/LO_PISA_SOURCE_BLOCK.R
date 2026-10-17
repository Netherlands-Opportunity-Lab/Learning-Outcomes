# Bounded source verification for the modern PISA public-use student files.
# Only the country selector is read globally; all scientific fields are read
# for the exact country row ranges. This does not select countries for a run.
lo_pisa_source_sha <- local({
  cache<-new.env(parent=emptyenv())
  function(path) {
    key<-normalizePath(path,winslash='/');info<-file.info(path)
    signature<-list(size=info$size,mtime=as.numeric(info$mtime),ctime=as.numeric(info$ctime))
    if(exists(key,cache,inherits=FALSE)) {
      old<-get(key,cache);if(identical(old$signature,signature))return(old$sha256)
    }
    value<-digest::digest(file=path,algo='sha256')
    assign(key,list(signature=signature,sha256=value),cache);value
  }
})
lo_pisa_label_code <- function(x,accepted) {
  labels<-attr(x,"labels");key<-tolower(trimws(names(labels)))
  # Reviewed 2025 labels spell out the OECD parent/student birthplace rule.
  expanded<-c(
    "native students (at least one parent born in country of test)"="native students",
    "second-generation students (student born in country of test but parent(s) born in another country)"="second-generation students",
    "first-generation students (student and parent(s) born in another country"="first-generation students")
  ix<-match(key,names(expanded));key[!is.na(ix)]<-unname(expanded[ix[!is.na(ix)]])
  found<-unique(unname(labels[key%in%accepted]))
  if(length(found)!=1L)stop("PISA_SOURCE_LABEL_NOT_UNAMBIGUOUS: ",paste(accepted,collapse="/"))
  found
}
lo_pisa_country_rows <- function(path,country,fields,user_na=FALSE) {
  partitions<-getOption('lo.pisa.partitions',list())[[normalizePath(path,winslash='/')]]
  if(!is.null(partitions)&&!user_na) {
    at<-which(partitions$files$country==country)
    if(length(at)!=1L||partitions$raw_sha256!=lo_pisa_source_sha(path))stop('PISA_PARTITION_SOURCE_CHANGED')
    f<-partitions$files[at,]
    if(!file.exists(f$path)||digest::digest(file=f$path,algo='sha256')!=f$sha256)stop('PISA_PARTITION_CHANGED')
    raw<-readRDS(f$path)
    if(nrow(raw)!=f$n||any(raw$CNT!=country)||!all(c('CNT',fields)%in%names(raw)))stop('PISA_PARTITION_IDENTITY_FAILED')
    return(raw[unique(c('CNT',fields))])
  }
  header<-haven::read_sav(path,n_max=0)
  if(!all(c("CNT",fields)%in%names(header)))stop("PISA_REQUIRED_RAW_FIELDS_MISSING")
  index<-getOption('lo.pisa.row_indices',list())[[normalizePath(path,winslash='/')]]
  if(is.null(index))selector<-as.character(haven::read_sav(path,col_select="CNT")$CNT)else {
    if(!identical(index$raw_sha256,lo_pisa_source_sha(path))||
       length(index$selector)!=index$n||anyNA(index$selector))stop('PISA_ROW_INDEX_SOURCE_CHANGED')
    selector<-index$selector
  }
  at<-which(selector==country)
  if(!length(at))stop("PISA_COUNTRY_NOT_IN_RAW_SOURCE")
  blocks<-split(at,cumsum(c(TRUE,diff(at)!=1L)))
  raw<-do.call(rbind,lapply(blocks,function(i)haven::read_sav(path,
    col_select=tidyselect::all_of(unique(c("CNT",fields))),skip=min(i)-1L,n_max=length(i),user_na=user_na)))
  if(nrow(raw)!=length(at)||any(raw$CNT!=country))stop("PISA_RAW_COUNTRY_ROW_SELECTION_FAILED")
  raw
}
lo_pisa_value_counts <- function(x) {
  # Named JSON lists lose an NA category name (it became a fictitious code 3).
  # Explicit records preserve actual missingness and original numeric codes.
  t<-table(as.character(as.numeric(x)),useNA='always')
  data.frame(value=ifelse(is.na(names(t)),'NA',names(t)),n=as.integer(t))
}
lo_pisa_source_gender <- function(raw) {
  # User's selected standard: ST004D01T, Female=1 / Male=2. Check labels AND
  # observations. Older ST004 and the documented D recode are explicit fallbacks,
  # never a row-wise imputation. ST430 is not used as a substitute construct.
  chosen<-NULL; audit<-list()
  for(k in intersect(c('ST004D01T','ST004','ST004D01D'),names(raw))) {
    female<-lo_pisa_label_code(raw[[k]],'female');male<-lo_pisa_label_code(raw[[k]],'male')
    if(k%in%c('ST004D01T','ST004') && !identical(as.numeric(c(female,male)),c(1,2)))
      stop('PISA_STANDARD_GENDER_CODE_CONFLICT: ',k)
    v<-c('girl','boy')[match(as.numeric(raw[[k]]),c(female,male))]
    audit[[k]]<-list(girls=sum(v=='girl',na.rm=TRUE),boys=sum(v=='boy',na.rm=TRUE),
      unresolved=sum(is.na(v)),counts=lo_pisa_value_counts(raw[[k]]))
    if(!is.null(chosen) && any(!is.na(v)&!is.na(chosen$values)&v!=chosen$values))
      stop('PISA_GENDER_FIELDS_CONFLICT: ',chosen$variable,' / ',k)
    if(is.null(chosen) && any(!is.na(v)))chosen<-list(values=v,variable=k,
      status='SOURCE_VALUE_LABEL_VERIFIED',map=paste0(female,'=girl;',male,'=boy'))
  }
  if(!is.null(chosen)) {chosen$audit<-audit;return(chosen)}
  if('MALE'%in%names(raw)) {
    male<-lo_pisa_label_code(raw$MALE,'male')
    v<-ifelse(!is.na(raw$MALE)&as.numeric(raw$MALE)==male,'boy',NA_character_)
    if(any(!is.na(v)))return(list(values=v,variable='MALE',
      status='PARTIAL_SOURCE_GENDER_GIRL_UNRESOLVED',map=paste0(male,'=boy;other codes not assigned to girls'),audit=audit))
  }
  list(values=rep(NA_character_,nrow(raw)),variable='NONE_VERIFIED',
    status='UNRESOLVED_SOURCE_GENDER_MAPPING',map='No verified mapping',audit=audit)
}
lo_pisa_canonical_from_raw <- function(raw,year,country) {
  codes<-c("READ","MATH","SCIE")
  from<-c("W_FSTUWT",paste0("W_FSTURWT",1:80),unlist(lapply(codes,function(k)paste0("PV",1:10,k))))
  to<-c("W",paste0("RW",1:80),unlist(lapply(codes,function(k)paste0("PV_",k,"_",1:10))))
  if(!all(c("CNT","CNTSTUID",from)%in%names(raw))||any(raw$CNT!=country))stop("PISA_RAW_CANONICAL_FIELDS_INVALID")
  d<-data.frame(SOURCE_STUDENT_ID=as.character(raw$CNTSTUID),stringsAsFactors=FALSE)
  for(j in seq_along(from))d[[to[j]]]<-as.numeric(raw[[from[j]]])
  list(data=d,meta=list(survey="PISA",year=as.integer(year),v9_country=country,
    preparation="DIRECT_FROM_OFFICIAL_PUF_WITHOUT_LEGACY_CACHE"))
}
lo_pisa_verify_source <- function(raw_path,canonical_path,year,country,output_dir) {
  if(!year%in%c(2015L,2018L,2022L,2025L))stop("PISA_SOURCE_CYCLE_NOT_REVIEWED")
  codes<-c("READ","MATH","SCIE")
  pvs<-unlist(lapply(codes,function(k)paste0("PV",1:10,k)))
  partition<-getOption('lo.pisa.partitions',list())[[normalizePath(raw_path,winslash='/')]]
  header_names<-if(is.null(partition))names(haven::read_sav(raw_path,n_max=0))else partition$fields
  gender_fields<-intersect(c('ST004D01T','ST004','ST004D01D','MALE'),header_names)
  fields<-c("CNTSTUID","CNTSCHID","AGE",gender_fields,"ST022Q01TA","LANGTEST_COG",
    "IMMIG","ESCS","PROGN","W_FSTUWT",paste0("W_FSTURWT",1:80),pvs)
  raw<-lo_pisa_country_rows(raw_path,country,fields)
  obj<-if(is.null(canonical_path))lo_pisa_canonical_from_raw(raw,year,country)else readRDS(canonical_path)
  d<-obj$data
  if(obj$meta$survey!="PISA" || as.integer(obj$meta$year)!=year ||
     obj$meta$v9_country!=country || !"SOURCE_STUDENT_ID"%in%names(d))stop("PISA_CANONICAL_IDENTITY_MISMATCH")
  ids<-as.character(raw$CNTSTUID);target<-as.character(d$SOURCE_STUDENT_ID)
  if(anyNA(ids)||anyNA(target)||anyDuplicated(ids)||anyDuplicated(target)||!setequal(ids,target))
    stop("PISA_RAW_AND_CANONICAL_PUPIL_SETS_DIFFER")
  raw<-raw[match(target,ids),,drop=FALSE]
  canonical<-c("W",paste0("RW",1:80),unlist(lapply(codes,function(k)paste0("PV_",k,"_",1:10))))
  original<-c("W_FSTUWT",paste0("W_FSTURWT",1:80),pvs)
  checks<-data.frame(canonical=canonical,original=original,equal=FALSE)
  for(j in seq_along(canonical))checks$equal[j]<-canonical[j]%in%names(d) &&
    identical(as.numeric(d[[canonical[j]]]),as.numeric(raw[[original[j]]]))
  if(!all(checks$equal))stop("PISA_RAW_WEIGHT_OR_PV_MISMATCH")
  gender<-lo_pisa_source_gender(raw)
  same<-lo_pisa_label_code(raw$ST022Q01TA,c("language of test","language of the test"))
  other<-lo_pisa_label_code(raw$ST022Q01TA,"other language")
  native<-lo_pisa_label_code(raw$IMMIG,c("native","native student","native students"))
  second<-lo_pisa_label_code(raw$IMMIG,c("second-generation","second-generation student","second-generation students","second generation"))
  first<-lo_pisa_label_code(raw$IMMIG,c("first-generation","first-generation student","first-generation students","first generation"))
  decode<-function(x,values,labels)labels[match(as.numeric(x),values)]
  # Restore fields from the original labelled variables, never from unchecked
  # numeric conventions or a stale success flag in the legacy cache.
  d$AGE<-as.numeric(raw$AGE);d$DEMO_GENDER<-gender$values
  d$GENDER<-d$DEMO_GENDER
  d$DEMO_LANGUAGE<-decode(raw$ST022Q01TA,c(same,other),c("test_language_home","other_language_home"))
  d$DEMO_MIGRATION<-decode(raw$IMMIG,c(native,second,first),c("native","second_generation","first_generation"))
  d$TEST_LANGUAGE<-as.character(haven::as_factor(raw$LANGTEST_COG,levels="labels"))
  d$SES<-as.numeric(raw$ESCS);d$SCHOOL<-as.character(raw$CNTSCHID);d$PROGRAM<-as.character(raw$PROGN)
  if(any(!is.finite(d$W)|d$W<=0)||any(!is.finite(as.matrix(d[paste0("RW",1:80)]))) ||
     any(as.matrix(d[paste0("RW",1:80)])<0))stop("PISA_INVALID_DESIGN_WEIGHTS")
  meta<-obj$meta
  meta$gender_variable<-gender$variable
  meta$gender_status<-gender$status
  meta$gender_map<-gender$map
  meta$age_status<-"RAW_AGE_RESTORED_BY_EXACT_STUDENT_ID"
  meta$language_definition<-"ASSESSMENT_LANGUAGE_RELATIVE_HOME_USE"
  meta$language_mapping_status<-"SOURCE_LABELS_AND_STUDENT_IDS_VERIFIED"
  meta$ses_construct_id<-"OECD_OFFICIAL_ESCS"
  meta$source_country_code<-country;meta$v9_country<-country
  meta$repair_parent_sha256<-if(is.null(canonical_path))"NONE_DIRECT_FROM_RAW_SOURCE"else digest::digest(file=canonical_path,algo="sha256")
  meta$repair_raw_sha256<-lo_pisa_source_sha(raw_path)
  meta$language_weighted_coverage<-sum(d$W[!is.na(d$DEMO_LANGUAGE)])/sum(d$W)
  meta$demographic_definitions<-data.frame(dimension=c("GENDER","LANGUAGE","MIGRATION"),
    variable=c(gender$variable,"ST022Q01TA","IMMIG"),
    definition=c("Source-labelled gender","Home relative to assessment language","OECD native/second/first generation"),
    weighted_coverage=vapply(d[c("DEMO_GENDER","DEMO_LANGUAGE","DEMO_MIGRATION")],function(x)sum(d$W[!is.na(x)])/sum(d$W),numeric(1)))
  obj<-list(data=d,meta=meta)
  dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
  output<-file.path(output_dir,paste0("canonical_PISA_",year,"_",country,"_verified.rds"))
  if(file.exists(output)) {
    if(!identical(readRDS(output),obj))output<-sub("[.]rds$",paste0("_",substr(digest::digest(obj,algo="sha256"),1,16),".rds"),output)
  }
  if(file.exists(output)) {
    if(!identical(readRDS(output),obj))stop("PISA_REPAIR_REFUSES_CHANGED_EXISTING_OUTPUT")
  } else saveRDS(obj,output,compress=FALSE)
  write.csv(checks,file.path(output_dir,"RAW_COLUMN_PARITY.csv"),row.names=FALSE)
  receipt<-list(status="RAW_SAMPLE_AND_FIELDS_VERIFIED",survey="PISA",year=year,country=country,
    exact_pupil_set=TRUE,n=nrow(d),columns_checked=nrow(checks),
    raw_sha256=meta$repair_raw_sha256,parent_sha256=meta$repair_parent_sha256,
    canonical_sha256=digest::digest(file=output,algo="sha256"),canonical_filename=basename(output),
    gender_status=meta$gender_status,gender_field_audit=gender$audit,
    gender_alternative=if("MALE"%in%names(raw))list(variable="MALE",counts=lo_pisa_value_counts(raw$MALE),
      labels=as.list(attr(raw$MALE,"labels")),equivalent_to_girl_boy=FALSE,
      reason="Female / Other is not the approved female group; do not silently substitute constructs")else NULL,
    field_mapping=c(AGE="AGE",DEMO_GENDER=gender$variable,DEMO_LANGUAGE="ST022Q01TA",DEMO_MIGRATION="IMMIG",SES="ESCS",SCHOOL="CNTSCHID",PROGRAM="PROGN"),
    source_value_labels=lapply(raw[c(gender_fields,"ST022Q01TA","IMMIG")],function(x)as.list(attr(x,"labels"))),
    population="All country records from the official age-target student public-use file",
    source_url=paste0("https://www.oecd.org/en/data/datasets/pisa-",year,"-database.html"),
    coverage=meta$demographic_definitions,not_certified=c("Harmonized Cobreros SES","actual classrooms","trend linking","publication rights"))
  receipt$field_mapping<-as.list(receipt$field_mapping)
  jsonlite::write_json(receipt,file.path(output_dir,"SOURCE_VERIFICATION.json"),auto_unbox=TRUE,pretty=TRUE,digits=17)
  list(object=obj,raw=raw,path=normalizePath(output,winslash="/"),receipt=receipt)
}

# Independent reference implementation: raw values, raw labelled groups and
# supplied weights; no calls to production estimators, group mapping or pooling.
lo_pisa_independent_selected <- function(raw,q) {
  if(!nrow(q)||any(q$survey!="PISA")||length(unique(q$year))!=1L||
     any(!q$module%in%c("core","gender","language_exact","migration_generation","extension_performance_school")))
    stop("PISA_INDEPENDENT_UNREVIEWED_TASK")
  m<-if(as.integer(q$year[1])<=2012L)5L else 10L
  low<-c(reading=407.47,mathematics=420.07,science=409.54)
  high<-c(reading=625.61,mathematics=606.99,science=633.33)
  code<-c(reading="READ",mathematics="MATH",science="SCIE")
  w<-as.matrix(raw[c("W_FSTUWT",paste0("W_FSTURWT",1:80))])
  if(any(!is.finite(w))||any(w<0)||any(colSums(w)<=0))stop("PISA_REFERENCE_INVALID_WEIGHTS")
  sex<-rep(NA_real_,nrow(raw));sexmap<-c(girl=-1,boy=-2)
  selected_gender<-FALSE
  for(field in intersect(c('ST004D01T','ST004','ST004D01D'),names(raw))) {
    values<-as.numeric(raw[[field]])
    mapping<-c(girl=lo_pisa_label_code(raw[[field]],'female'),boy=lo_pisa_label_code(raw[[field]],'male'))
    if(field%in%c('ST004D01T','ST004') && !identical(as.numeric(mapping),c(1,2)))
      stop('PISA_REFERENCE_STANDARD_GENDER_CODE_CONFLICT')
    if(selected_gender) {
      previous<-match(sex,sexmap);current<-match(values,mapping)
      if(any(!is.na(previous)&!is.na(current)&previous!=current))stop('PISA_REFERENCE_GENDER_FIELDS_CONFLICT')
    } else if(any(values%in%mapping)) {sex<-values;sexmap<-mapping;selected_gender<-TRUE}
  }
  pooled_contract<-grepl('FEMALE_OR_OTHER_WHEN_UNSEPARATED_20261015',q$calculation_policy,fixed=TRUE)
  if(any(pooled_contract)) {
    if(any(sex==sexmap[['girl']],na.rm=TRUE)||!'MALE'%in%names(raw))stop('PISA_REFERENCE_POOL_NOT_APPLICABLE')
    labels<-attr(raw$MALE,'labels');label_names<-tolower(trimws(names(labels)))
    if(sum(label_names=='female / other')!=1L||sum(label_names=='male')!=1L||
       unname(labels[label_names=='female / other'])!=0||unname(labels[label_names=='male'])!=1)
      stop('PISA_REFERENCE_POOL_LABELS')
    dependent<-(q$module=='gender'&q$group%in%c('girl','girls_minus_boys'))
    if(any(dependent!=pooled_contract))stop('PISA_REFERENCE_POOL_CONTRACT')
    sex<-ifelse(as.numeric(raw$MALE)==0,sexmap[['girl']],
      ifelse(as.numeric(raw$MALE)==1,sexmap[['boy']],NA_real_))
  }
  if(all(is.na(sex))&&'MALE'%in%names(raw)) {
    male_code<-lo_pisa_label_code(raw$MALE,'male')
    sex[!is.na(raw$MALE)&as.numeric(raw$MALE)==male_code]<-sexmap[['boy']]
  }
  language<-as.numeric(raw$ST022Q01TA);mig<-as.numeric(raw$IMMIG)
  langmap<-c(test_language_home=lo_pisa_label_code(raw$ST022Q01TA,c("language of test","language of the test")),other_language_home=lo_pisa_label_code(raw$ST022Q01TA,"other language"))
  migmap<-c(native=lo_pisa_label_code(raw$IMMIG,c("native","native student","native students")),first_generation=lo_pisa_label_code(raw$IMMIG,c("first-generation","first-generation student","first-generation students","first generation")),second_generation=lo_pisa_label_code(raw$IMMIG,c("second-generation","second-generation student","second-generation students","second generation")))
  full<-matrix(NA_real_,m,nrow(q),dimnames=list(NULL,q$metric_key))
  reps<-array(NA_real_,c(80,m,nrow(q)),dimnames=list(NULL,NULL,q$metric_key));counts<-integer(nrow(q))
  mean_w<-function(y,z){ok<-is.finite(y)&is.finite(z)&z>0;sum(y[ok]*z[ok])/sum(z[ok])}
  quant<-function(y,z,p){ok<-is.finite(y)&is.finite(z)&z>0;a<-y[ok];b<-z[ok];o<-order(a);a<-a[o];b<-b[o];a[which(cumsum(b)>=p*sum(b))[1]]}
  quantile_cache<-new.env(parent=emptyenv())
  selected_quantiles<-function(domain,Y) {
    if(exists(domain,quantile_cache,inherits=FALSE))return(get(domain,quantile_cache))
    stats<-unique(q$stat[q$domain==domain&q$stat%in%c('p10','p50','p90','p90_p10')])
    probs<-sort(unique(unlist(lapply(stats,function(s)if(s=='p90_p10')c(.1,.9)else as.numeric(sub('p','',s))/100))))
    answer<-setNames(lapply(probs,function(p)matrix(NA_real_,m,81)),as.character(probs))
    for(j in seq_len(m)) {
      order_y<-order(Y[,j])
      for(r in 1:81) {
        o<-order_y[w[order_y,r]>0];weight<-w[o,r];cumulative<-cumsum(weight)
        for(p in probs)answer[[as.character(p)]][j,r]<-Y[o[which(cumulative>=p*sum(weight))[1]],j]
      }
    }
    result<-setNames(lapply(stats,function(s)if(s=='p90_p10')answer[['0.9']]-answer[['0.1']]else answer[[as.character(as.numeric(sub('p','',s))/100)]]),stats)
    assign(domain,result,quantile_cache);result
  }
  for(k in seq_len(nrow(q))) {
    task<-q[k,];if(!task$domain%in%names(code))stop("PISA_UNKNOWN_DOMAIN")
    y<-as.matrix(raw[paste0("PV",seq_len(m),code[[task$domain]])])
    if(any(!is.finite(y)))stop("PISA_REFERENCE_INCOMPLETE_PVS")
    include<-rep(TRUE,nrow(raw));contrast<-NULL
    if(task$module=="gender") {
      if(task$stat=="gap") {if(task$group!="girls_minus_boys")stop("PISA_GENDER_CONTRAST");include<-sex==sexmap['girl'];contrast<-sex==sexmap['boy']}
      else include<-sex==sexmap[[task$group]]
    }
    if(task$module=="language_exact") {
      if(task$stat=="gap") {if(task$group!="other_minus_test")stop("PISA_LANGUAGE_CONTRAST");include<-language==langmap['other_language_home'];contrast<-language==langmap['test_language_home']}
      else include<-language==langmap[[task$group]]
    }
    if(task$module=="migration_generation") {
      if(task$stat=="mean_score_gap") {
        focus<-switch(task$group,first_minus_native="first_generation",second_minus_native="second_generation",stop("PISA_MIGRATION_CONTRAST"))
        include<-mig==migmap[[focus]];contrast<-mig==migmap['native']
      } else include<-mig==migmap[[task$group]]
    }
    include[is.na(include)]<-FALSE;if(!is.null(contrast))contrast[is.na(contrast)]<-FALSE
    counts[k]<-sum((include|if(is.null(contrast))FALSE else contrast)&w[,1]>0)
    cluster<-if(task$module=='extension_performance_school')as.character(raw$CNTSCHID)else NULL
    mat<-matrix(NA_real_,m,81)
    linear<-task$module!='extension_performance_school'&&task$stat%in%c('mean','mean_score','gap','mean_score_gap','total_below','total_high')
    if(linear) {
      values<-y
      if(task$module=='core'&&task$stat%in%c('total_below','total_high')) {
        cutoff<-if(task$stat=='total_below')low[[task$domain]]else high[[task$domain]]
        if(!identical(as.numeric(task$threshold),cutoff))stop('PISA_REFERENCE_THRESHOLD_MISMATCH')
        values<-if(task$stat=='total_below')1*(y<cutoff)else 1*(y>=cutoff)
      }
      means<-function(group){weights<-w*group;sweep(crossprod(values,weights),2,colSums(weights),'/')}
      mat<-means(include);if(!is.null(contrast))mat<-mat-means(contrast)
    }else if(task$stat%in%c('p10','p50','p90','p90_p10'))mat<-selected_quantiles(task$domain,y)[[task$stat]]
    else for(j in seq_len(m))for(r in 1:81) {
      value<-y[,j];weight<-w[,r];s<-task$stat
      if(task$module=="core" && s%in%c("total_below","total_high")) {
        cutoff<-if(s=="total_below")low[[task$domain]] else high[[task$domain]]
        if(!identical(as.numeric(task$threshold),cutoff))stop("PISA_REFERENCE_THRESHOLD_MISMATCH")
        value<-if(s=="total_below")1*(value<cutoff) else 1*(value>=cutoff)
      }
      mat[j,r]<-if(task$module=="extension_performance_school") {
        if(s!="between_variance_share")stop("PISA_REFERENCE_UNKNOWN_SCHOOL_STAT")
        ok<-!is.na(cluster)&weight>0;v<-value[ok];wt<-weight[ok];school<-cluster[ok]
        mu<-sum(v*wt)/sum(wt);sw<-as.numeric(rowsum(wt,school,reorder=FALSE));sy<-as.numeric(rowsum(wt*v,school,reorder=FALSE))
        100*sum(sw*(sy/sw-mu)^2)/sum(wt*(v-mu)^2)
      } else if(!is.null(contrast))mean_w(value,weight*include)-mean_w(value,weight*contrast)
      else if(s%in%c("mean","mean_score","total_below","total_high"))mean_w(value,weight*include)
      else if(s%in%c("p10","p50","p90"))quant(value,weight,as.numeric(sub('p','',s))/100)
      else if(s=="p90_p10")quant(value,weight,.9)-quant(value,weight,.1)
      else stop("PISA_REFERENCE_UNKNOWN_STAT")
    }
    if(any(!is.finite(mat)))stop("PISA_REFERENCE_INCOMPLETE_ESTIMATION: ",task$metric_key,
      "; N=",counts[k],"; nonfinite PV/weight positions=",paste(which(!is.finite(mat),arr.ind=TRUE)[1,],collapse=","))
    full[,k]<-mat[,1];reps[,,k]<-t(mat[,-1])
  }
  variance<-vapply(seq_len(nrow(q)),function(k)mean(rowSums((t(reps[,,k])-full[,k])^2)/20)+(1+1/m)*var(full[,k]),numeric(1))
  list(results=data.frame(cell_id=q$metric_key,estimate=colMeans(full),standard_error=sqrt(variance),n_unweighted=counts),
    joint=list(cell_ids=q$metric_key,full_pv=full,replicate_pv=reps,factor=1/20,pv_count=m,
      method="Within-PV Fay-BRR plus Rubin between-PV variance; paired columns retain joint uncertainty"))
}
