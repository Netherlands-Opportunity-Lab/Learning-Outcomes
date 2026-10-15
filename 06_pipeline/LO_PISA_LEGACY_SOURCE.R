# Streaming official fixed-width sources: retain only the requested country's
# rows in memory. The SAS control file is parsed as data and never executed.
lo_pisa_sas_columns <- function(path) {
  lines<-readLines(path,warn=FALSE,encoding='UTF-8')
  at<-regexec('^\\s*([A-Za-z][A-Za-z0-9_]*)\\s+([0-9]+)\\s*-\\s*([0-9]+)\\s*;?\\s*$',lines,perl=TRUE)
  hits<-regmatches(lines,at);hits<-hits[lengths(hits)==4L]
  if(!length(hits))stop('PISA_SAS_COLUMN_DICTIONARY_EMPTY')
  x<-data.frame(name=toupper(vapply(hits,`[`,character(1),2)),start=as.integer(vapply(hits,`[`,character(1),3)),end=as.integer(vapply(hits,`[`,character(1),4)))
  if(anyDuplicated(x$name)||any(x$start<1|x$end<x$start))stop('PISA_SAS_COLUMN_DICTIONARY_INVALID')
  x
}
lo_pisa_sas_labels <- function(path,format) {
  text<-paste(readLines(path,warn=FALSE,encoding='UTF-8'),collapse='\n')
  pattern<-paste0('(?is)\\bvalue\\s+',format,'\\s+(.*?);')
  at<-regexec(pattern,text,perl=TRUE);z<-regmatches(text,at)[[1]]
  if(length(z)!=2L)stop('PISA_SAS_VALUE_FORMAT_NOT_FOUND: ',format)
  matches<-regmatches(z[2],gregexpr('([0-9]+)\\s*=\\s*"([^"]*)"',z[2],perl=TRUE))[[1]]
  codes<-as.numeric(sub('^([0-9]+).*','\\1',matches));labels<-sub('^[^"]*"([^"]*)".*','\\1',matches)
  if(!length(codes)||anyNA(codes)||anyDuplicated(codes))stop('PISA_SAS_VALUE_FORMAT_INVALID')
  stats::setNames(codes,labels)
}
lo_pisa_fixed_country_rows <- function(path,dictionary,country,fields,chunk_rows=5000L) {
  ix<-match(unique(c('CNT',fields)),dictionary$name);if(anyNA(ix))stop('PISA_SAS_REQUIRED_COLUMN_MISSING')
  spec<-dictionary[ix,];selector<-spec[spec$name=='CNT',]
  con<-file(path,'rt');on.exit(close(con));parts<-list();scanned<-0L
  index<-getOption('lo.pisa.byte_indices',list())[[normalizePath(path,winslash='/')]]
  if(!is.null(index)) {
    if(!identical(index$raw_sha256,if(exists('lo_pisa_source_sha',mode='function'))lo_pisa_source_sha(path)else digest::digest(file=path,algo='sha256'))||
       file.info(path)$size!=index$bytes)stop('PISA_BYTE_INDEX_SOURCE_CHANGED')
    close(con);con<-file(path,'rb')
    selected<-index$blocks[index$blocks$country==country,,drop=FALSE]
    if(!nrow(selected))stop('PISA_COUNTRY_ABSENT_FROM_TEXT_SOURCE')
    for(i in seq_len(nrow(selected))) {
      seek(con,where=selected$byte_offset[i],origin='start')
      lines<-readLines(con,n=selected$rows[i],warn=FALSE)
      if(length(lines)!=selected$rows[i]||any(trimws(substr(lines,selector$start,selector$end))!=country)||
         any(nchar(lines,type='bytes')<max(spec$end)))stop('PISA_BYTE_INDEX_ROW_MISMATCH')
      values<-lapply(seq_len(nrow(spec)),function(j)trimws(substr(lines,spec$start[j],spec$end[j])))
      names(values)<-spec$name;parts[[length(parts)+1L]]<-as.data.frame(values,stringsAsFactors=FALSE)
    }
    x<-do.call(rbind,parts);attr(x,'source_rows_scanned')<-sum(index$blocks$rows);return(x)
  }
  repeat {
    lines<-readLines(con,n=chunk_rows,warn=FALSE);if(!length(lines))break
    scanned<-scanned+length(lines);chosen<-trimws(substr(lines,selector$start,selector$end))==country
    if(!any(chosen))next
    lines<-lines[chosen];if(any(nchar(lines,type='bytes')<max(spec$end)))stop('PISA_SAS_TRUNCATED_SOURCE_ROW')
    values<-lapply(seq_len(nrow(spec)),function(j)trimws(substr(lines,spec$start[j],spec$end[j])))
    names(values)<-spec$name;parts[[length(parts)+1L]]<-as.data.frame(values,stringsAsFactors=FALSE)
  }
  if(!length(parts))stop('PISA_COUNTRY_ABSENT_FROM_TEXT_SOURCE')
  x<-do.call(rbind,parts);attr(x,'source_rows_scanned')<-scanned;x
}
lo_pisa_prepare_legacy <- function(path,control,year,country,output_dir) {
  if(length(country)!=1L||!grepl('^[A-Z]{3}$',country)||!year%in%c(2003,2006,2009,2012))stop('PISA_LEGACY_COUNTRY_CYCLE_NOT_REVIEWED')
  sex<-if(year==2003)'ST03Q01'else 'ST04Q01'
  language<-switch(as.character(year),'2003'='ST16Q01','2006'='ST12Q01','2009'='ST19Q01','2012'='ST25Q01')
  code<-if(year==2003)c('READ','MATH')else c('READ','MATH','SCIE')
  pv<-unlist(lapply(code,function(k)paste0('PV',1:5,k)))
  fields<-c('SCHOOLID','STIDSTD','AGE','PROGN','IMMIG','ESCS',sex,language,'W_FSTUWT',paste0('W_FSTR',1:80),pv,if(year==2003)paste0('ST15Q0',1:3))
  dictionary<-lo_pisa_sas_columns(control);raw<-lo_pisa_fixed_country_rows(path,dictionary,country,fields)
  scanned<-attr(raw,'source_rows_scanned');ids<-paste(raw$SCHOOLID,raw$STIDSTD,sep='::')
  if(anyDuplicated(ids)||any(!nzchar(raw$SCHOOLID)|!nzchar(raw$STIDSTD)))stop('PISA_LEGACY_PUPIL_IDENTITY')
  numeric<-setdiff(names(raw),c('CNT','SCHOOLID','STIDSTD','PROGN'))
  for(n in numeric)raw[[n]]<-suppressWarnings(as.numeric(raw[[n]]))
  if(any(!is.finite(as.matrix(raw[c('W_FSTUWT',paste0('W_FSTR',1:80),pv)])))||
     any(raw$W_FSTUWT<=0)||any(as.matrix(raw[pv])>=9997)||any(as.matrix(raw[paste0('W_FSTR',1:80)])<0))stop('PISA_LEGACY_DESIGN_OR_PV_INVALID')
  gender_labels<-lo_pisa_sas_labels(control,switch(as.character(year),'2003'='ST0301F','2009'='ST04F','ST04Q01F'))
  language_labels<-lo_pisa_sas_labels(control,switch(as.character(year),'2003'='ST1601F','2009'='ST19F',paste0(language,'F')))
  # Harmonize only after checking actual dictionary value labels.
  female<-unname(gender_labels[tolower(gender_labels |> names())=='female'])
  male<-unname(gender_labels[tolower(gender_labels |> names())=='male'])
  langnames<-tolower(names(language_labels));same<-unname(language_labels[grepl('test',langnames)&!grepl('other',langnames)])
  other<-unname(language_labels[grepl('other',langnames)])
  stopifnot(length(female)==1L,length(male)==1L,length(same)==1L,length(other)>=1L)
  raw$ST004D01T<-haven::labelled(ifelse(raw[[sex]]==female,1,ifelse(raw[[sex]]==male,2,NA_real_)),c(Female=1,Male=2))
  raw$ST022Q01TA<-haven::labelled(ifelse(raw[[language]]==same,1,ifelse(raw[[language]]%in%other,2,NA_real_)),c('Language of test'=1,'Other language'=2))
  mig_labels<-lo_pisa_sas_labels(control,if(year%in%c(2003,2006))'IMMIG'else 'IMMIGF')
  migration_note<-'Verified native / second / first generation source labels'
  if(year==2003) {
    # Original 2003 terminology differs. Verify its numerical interpretation
    # against student and parent birthplace rather than relabelling by guess.
    mom<-raw$ST15Q02;dad<-raw$ST15Q03;self<-raw$ST15Q01
    expected<-ifelse(mom==1|dad==1,1,ifelse(mom==2&dad==2&self==1,2,ifelse(mom==2&dad==2&self==2,3,NA_real_)))
    valid<-raw$IMMIG%in%1:3&is.finite(expected)
    if(!any(valid)||any(raw$IMMIG[valid]!=expected[valid]))stop('PISA_2003_GENERATION_BIRTHPLACE_CONTRADICTION')
    migration_note<-'2003 codes 2 and 3 verified against student/parent birthplace; current terms second and first generation, respectively'
  }else {
    labs<-tolower(names(mig_labels)[match(1:3,as.numeric(mig_labels))])
    if(!identical(labs,c('native','second-generation','first-generation')))stop('PISA_LEGACY_MIGRATION_LABELS')
  }
  raw$IMMIG<-haven::labelled(ifelse(raw$IMMIG%in%1:3,raw$IMMIG,NA_real_),c(Native=1,'Second-generation'=2,'First-generation'=3))
  raw$CNTSCHID<-raw$SCHOOLID;raw$CNTSTUID<-ids
  for(j in 1:80)raw[[paste0('W_FSTURWT',j)]]<-raw[[paste0('W_FSTR',j)]]
  d<-data.frame(SOURCE_STUDENT_ID=ids,STUDENT=ids,SCHOOL=raw$SCHOOLID,PROGRAM=raw$PROGN,AGE=raw$AGE,W=raw$W_FSTUWT,
    DEMO_GENDER=c('girl','boy')[match(raw$ST004D01T,1:2)],DEMO_LANGUAGE=c('test_language_home','other_language_home')[match(raw$ST022Q01TA,1:2)],
    DEMO_MIGRATION=c('native','second_generation','first_generation')[match(raw$IMMIG,1:3)],SES=raw$ESCS,stringsAsFactors=FALSE)
  d$SES[!is.finite(d$SES)|abs(d$SES)>=9997]<-NA_real_;d$GENDER<-d$DEMO_GENDER
  for(j in 1:80)d[[paste0('RW',j)]]<-raw[[paste0('W_FSTR',j)]]
  for(k in code)for(j in 1:5)d[[paste0('PV_',k,'_',j)]]<-raw[[paste0('PV',j,k)]]
  obj<-list(data=d,meta=list(survey='PISA',year=as.integer(year),v9_country=country,source_country_code=country,
    preparation='STREAMED_OFFICIAL_FIXED_WIDTH_WITH_SAS_DICTIONARY',gender_variable=sex,gender_status='SOURCE_VALUE_LABEL_VERIFIED',
    language_definition='ASSESSMENT_LANGUAGE_RELATIVE_HOME_USE',language_mapping_status='SOURCE_LABELS_AND_STUDENT_IDS_VERIFIED',
    ses_construct_id='OECD_OFFICIAL_ESCS',migration_mapping_note=migration_note,
    repair_raw_sha256=if(exists('lo_pisa_source_sha',mode='function'))lo_pisa_source_sha(path)else digest::digest(file=path,algo='sha256'),control_sha256=digest::digest(file=control,algo='sha256')))
  dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
  out<-file.path(output_dir,paste0('canonical_PISA_',year,'_',country,'_',substr(digest::digest(obj,algo='sha256'),1,16),'.rds'))
  if(!file.exists(out))saveRDS(obj,out,compress=FALSE)else stopifnot(identical(readRDS(out),obj))
  receipt<-list(status='RAW_SAMPLE_AND_FIELDS_VERIFIED',survey='PISA',year=year,country=country,n=nrow(d),source_rows_scanned=scanned,
    raw_sha256=obj$meta$repair_raw_sha256,control_sha256=obj$meta$control_sha256,canonical_filename=basename(out),canonical_sha256=digest::digest(file=out,algo='sha256'),
    population=paste('All',country,'records in the official PISA age-target public-use student file'),pv_count=5L,
    source_url=paste0('https://www.oecd.org/en/data/datasets/pisa-',year,'-database.html'),migration_note=migration_note,
    source_labels=list(gender=as.list(gender_labels),language=as.list(language_labels),migration=as.list(mig_labels)),
    not_certified=c('Harmonized SES','actual classrooms','trend linking','release'))
  jsonlite::write_json(receipt,file.path(output_dir,'SOURCE_VERIFICATION.json'),auto_unbox=TRUE,pretty=TRUE,digits=17)
  list(raw=raw,object=obj,path=normalizePath(out,winslash='/'),receipt=receipt)
}
