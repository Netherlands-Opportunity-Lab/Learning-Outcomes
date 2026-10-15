# Existing approved background definitions applied to explicit national raw
# fields. Missing groups stay in the grid with evidence; no proxy substitution.
lo_international_absence <- function(repo,root,q,reason,evidence,classification='SOURCE_UNAVAILABLE_VERIFIED') {
  if(!nrow(q))return(invisible(NULL))
  source(file.path(repo,'06_pipeline/MASTER_ESTIMATION_GRID.R'))
  source(file.path(repo,'06_pipeline/LO_ATOMIC_CHECKPOINT.R'))
  g<-lo_grid_from_tasks(q);cells<-g[c('cell_id','target_contract_sha256')];cells$reason<-reason
  evidence<-unique(normalizePath(evidence,winslash='/',mustWork=TRUE))
  ef<-data.frame(path=evidence,sha256=vapply(evidence,function(p)digest::digest(file=p,algo='sha256'),character(1)))
  cert<-list(status=classification,cells=cells,evidence_files=ef)
  dir<-file.path(root,'international','absence');dir.create(dir,recursive=TRUE,showWarnings=FALSE)
  p<-file.path(dir,paste0(digest::digest(cert,algo='sha256'),'.json'))
  if(!file.exists(p))jsonlite::write_json(cert,p,auto_unbox=TRUE,pretty=TRUE,digits=17)
  cells$evidence_path<-p;cells$evidence_sha256<-digest::digest(file=p,algo='sha256');cells$classification<-classification
  path<-file.path(root,'master_reconciliation/SOURCE_UNAVAILABLE_CELLS.csv')
  old<-read.csv(path,colClasses='character',na.strings=character())
  for(k in setdiff(names(cells),names(old)))old[[k]]<-''
  for(k in setdiff(names(old),names(cells)))cells[[k]]<-''
  lo_atomic_csv(rbind(old[!old$cell_id%in%cells$cell_id,],cells[names(old)]),path)
  invisible(cells)
}

lo_international_background <- function(repo,obj,q,row,out,home_path='') {
  for(f in c('LO_BACKGROUND_SOURCE.R','LO_BACKGROUND_REFERENCE.R','LO_IEA_BACKGROUND.R','LO_PISA_LEGACY_SOURCE.R'))source(file.path(repo,'06_pipeline',f))
  s<-obj$meta$survey;y<-as.integer(obj$meta$year);mappings<-list();proofs<-list();absent<-list()
  proof<-function(path,raw){proofs[[length(proofs)+1L]]<<-list(path=normalizePath(path,winslash='/'),sha256=if(exists('lo_pisa_source_sha',mode='function'))lo_pisa_source_sha(path)else digest::digest(file=path,algo='sha256'),n=nrow(raw),fields=names(raw),labels=lapply(raw,function(x)as.list(attr(x,'labels'))))}
  exclude<-function(which,reason){if(any(which)){z<-q[which,];z$absence_reason<-reason;absent[[length(absent)+1L]]<<-z;q<<-q[!which,]}}
  if(s=='PISA') {
    fields<-if(y==2025)c('BICT_P1','BICT_P2','BICT_S')else if(y>=2015)c('ST019BQ01T','ST019CQ01T','ST019AQ01T')else
      paste0(switch(as.character(y),'2003'='ST15Q0','2006'='ST11Q0','2009'='ST17Q0','2012'='ST20Q0'),c(2,3,1))
    if(y>=2015) {
      raw<-lo_pisa_country_rows(row$raw_path,row$source_country,c('CNTSTUID','W_FSTUWT',fields))
      raw<-lo_background_join(raw,obj$data$SOURCE_STUDENT_ID,'CNTSTUID')
      mapped<-lapply(fields,function(f){
        if(y!=2025)return(lo_background_binary(raw[[f]]))
        labels<-attr(raw[[f]],'labels');yes<-tolower(names(labels))[as.numeric(labels)==1];no<-tolower(names(labels))[as.numeric(labels)==0]
        stopifnot(length(yes)==1L,length(no)==1L,grepl('born in country of test',yes),grepl('not born in country of test',no))
        lo_background_binary(raw[[f]],yes,no)
      })
    }else {
      raw<-lo_pisa_fixed_country_rows(row$raw_path,lo_pisa_sas_columns(row$control_path),row$source_country,c('SCHOOLID','STIDSTD','W_FSTUWT',fields))
      raw$ID<-paste(raw$SCHOOLID,raw$STIDSTD,sep='::');raw<-lo_background_join(raw,obj$data$SOURCE_STUDENT_ID,'ID')
      ctl<-paste(readLines(row$control_path,warn=FALSE),collapse='\n')
      mapped<-lapply(fields,function(f){m<-regmatches(ctl,regexec(paste0('(?m)^\\s*',f,'\\s+([A-Z][A-Z0-9]+)[.]'),ctl,perl=TRUE))[[1]]
        stopifnot(length(m)==2L);labels<-lo_pisa_sas_labels(row$control_path,m[2])
        lo_background_binary(haven::labelled(as.numeric(raw[[f]]),labels),c('yes','country of test','<country of test>'),c('no','other country','other'))})
      proof(row$control_path,data.frame())
    }
    stopifnot(all(abs(as.numeric(raw$W_FSTUWT)-obj$data$W)<1e-10));proof(row$raw_path,raw)
    obj$data$MOTHER_BORN_HERE<-mapped[[1]];obj$data$FATHER_BORN_HERE<-mapped[[2]]
    mappings$parent_fields<-fields;mappings$parent_semantics<-if(y==2025)'Parent/guardian 1 and 2; not identified as mother/father'else'Mother and father country of birth'
    derived<-lo_background_generations(mapped[[1]],mapped[[2]],mapped[[3]])
    mappings$generation_disagreements_with_retained_official_IMMIG<-sum(derived!=obj$data$DEMO_MIGRATION,na.rm=TRUE)
  }else {
    raw<-haven::read_sav(row$raw_path);raw<-lo_background_join(raw,obj$data$SOURCE_STUDENT_ID)
    stopifnot(all(abs(as.numeric(raw$TOTWGT)-obj$data$W)<1e-10));proof(row$raw_path,raw)
    lang<-if(y>=2011)'ASBG03'else if(s=='TIMSS')if(y==2007)'AS4GOLAN'else'ASBGOLAN'else if(y==2006)'ASBGLNGH'else'ASBGLANH'
    if(s=='PIRLS'&&y==2006)exclude(q$module%in%c('language_frequency_binary','home_language_frequency_peer')|(q$module=='peer_baseline'&q$stat=='test_language_share'),'PIRLS2006 always/sometimes/never does not identify the approved always-or-almost versus sometimes-or-never split')else {
      obj$data$DEMO_LANGUAGE<-lo_background_language(raw[[lang]]);mappings$language_field<-lang
    }
    fields<-if(s=='PIRLS'&&y<=2006)c('ASBGBRNM','ASBGBRNF','ASBGBRN1')else if(s=='TIMSS'&&y>=2015)c('ASBG06A','ASBG06B','ASBG07')else
      if(s=='TIMSS'&&y==2007)c('AS4GMBRN','AS4GFBRN','AS4GBORN')else if(s=='TIMSS'&&y==2003)c('ASBGMBRN','ASBGFBRN','ASBGBORN')else character()
    home<-NULL
    if(nzchar(home_path)&&file.exists(home_path)) {
      home<-haven::read_sav(home_path);proof(home_path,home)
      stopifnot(!anyDuplicated(home$IDSTUD),all(as.character(home$IDSTUD)%in%as.character(obj$data$SOURCE_STUDENT_ID)))
      home<-home[match(as.character(obj$data$SOURCE_STUDENT_ID),as.character(home$IDSTUD)),]
    }
    if(length(fields)) {
      stopifnot(all(fields%in%names(raw)));mapped<-lapply(fields,function(f)lo_background_binary(raw[[f]]))
      obj$data$MOTHER_BORN_HERE<-mapped[[1]];obj$data$FATHER_BORN_HERE<-mapped[[2]]
      obj$data$DEMO_MIGRATION<-lo_background_generations(mapped[[1]],mapped[[2]],mapped[[3]])
      mappings$birthplace_fields<-fields
    }else {
      if(s=='PIRLS'&&is.null(home))stop('IEA_HOME_FILE_NEEDED_BEFORE_PARENT_ABSENCE_CONCLUSION')
      labels<-vapply(home,function(x){v<-attr(x,'label');if(is.null(v))''else v},character(1))
      if(any(grepl('(mother|father|parent).*(born|birth)|(born|birth).*(mother|father|parent)',labels,ignore.case=TRUE)))stop('IEA_UNREVIEWED_HOME_PARENT_BIRTHPLACE_FIELDS')
      exclude(q$module%in%c('migration','migration_generation','migration_binary_peer','migration_peer_exposure')|(q$module=='peer_baseline'&q$stat=='reference_share'),'Required parents birthplace absent from reviewed student and available home source; child birthplace is not a substitute')
    }
    first<-if(s=='PIRLS')2021L else 2023L
    if(y<first)exclude(q$module=='extension_home_ses','Chosen official Home SES did not exist in this cycle; older Home Resources is a different construct')else if(any(q$module=='extension_home_ses')) {
      if(is.null(home))stop('IEA_OFFICIAL_HOME_SES_SOURCE_FILE_REQUIRED')
      field<-'ASDHSES'
      if(!field%in%names(home))stop('IEA_OFFICIAL_HOME_SES_FIELD_REVIEW_REQUIRED')
      labels<-attr(home[[field]],'labels')
      stopifnot(identical(tolower(names(labels)[match(1:3,as.numeric(labels))]),c('higher','middle','lower')))
      obj$data$HOME_SES_GROUP<-c('higher','middle','lower')[match(as.numeric(home[[field]]),1:3)]
      obj$meta$home_ses_construct<-'IEA_OFFICIAL_HOME_SES';mappings$home_ses_field<-field
      if(!any(!is.na(obj$data$HOME_SES_GROUP)))exclude(q$module=='extension_home_ses','No valid official Home SES values in the national home questionnaire file')
    }
  }
  obj$meta$background_mapping_status<-'RAW_LABELS_AND_EXACT_IDS_VERIFIED';obj$meta$background_mappings<-mappings
  record<-list(mappings=mappings,sources=proofs,valid_counts=lapply(obj$data[intersect(c('MOTHER_BORN_HERE','FATHER_BORN_HERE','DEMO_LANGUAGE','DEMO_MIGRATION','HOME_SES_GROUP'),names(obj$data))],function(x)as.list(table(x,useNA='always'))))
  path<-file.path(out,paste0('RAW_MAPPING_',digest::digest(record,algo='sha256'),'.json'))
  if(!file.exists(path))jsonlite::write_json(record,path,pretty=TRUE,auto_unbox=TRUE,digits=17)
  list(object=obj,tasks=q,absent=if(length(absent))do.call(rbind,absent)else NULL,proof=path)
}
