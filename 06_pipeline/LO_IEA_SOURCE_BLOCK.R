# Exact Netherlands grade-four source preparation. No legacy canonical cache,
# no country substitution, no implicit exclusion of delayed PIRLS respondents.
lo_iea_label_code <- function(x,labels) {
  a<-attr(x,"labels");i<-tolower(trimws(names(a)))%in%labels
  if(sum(i)!=1L)stop("IEA_SOURCE_LABEL_AMBIGUOUS")
  unname(a[i])
}
lo_iea_prepare_nld <- function(path,survey,year,output_dir) {
  if(!survey%in%c("PIRLS","TIMSS")||!year%in%if(survey=="PIRLS")c(2001,2006,2011,2016,2021)else c(2003,2007,2011,2015,2019,2023))
    stop("IEA_UNREVIEWED_CYCLE")
  codes<-if(survey=="PIRLS")c(READ="ASRREA")else c(MATH="ASMMAT",SCIE="ASSSCI")
  pv<-unlist(lapply(codes,function(k)paste0(k,sprintf('%02d',1:5))))
  fields<-c('IDCNTRY','IDSTUD','IDSCHOOL','IDCLASS','IDPOP','IDGRADE','ITSEX','TOTWGT','JKZONE','JKREP',pv)
  header<-haven::read_sav(path,n_max=0)
  if(!all(fields%in%names(header)))stop("IEA_REQUIRED_RAW_FIELDS_MISSING")
  raw<-haven::read_sav(path,col_select=tidyselect::all_of(fields))
  if(anyNA(raw[c('IDCNTRY','IDSTUD','IDSCHOOL','IDCLASS','IDPOP','IDGRADE')])||
     anyDuplicated(raw[c('IDCNTRY','IDSTUD')])||any(raw$IDCNTRY!=528)||any(raw$IDPOP!=1))stop("IEA_NLD_POPULATION_IDENTITY_FAILED")
  delayed<-survey=="PIRLS"&&year==2021L
  grades<-if(delayed)c(4,5)else 4
  if(any(!raw$IDGRADE%in%grades))stop("IEA_GRADE_OUTSIDE_REVIEWED_POPULATION")
  if(any(!is.finite(raw$TOTWGT)|raw$TOTWGT<=0)||any(!raw$JKREP%in%c(0,1))||
     anyNA(raw$JKZONE)||any(raw$JKZONE<1)||any(!is.finite(as.matrix(raw[pv]))))stop("IEA_INCOMPLETE_PV_OR_DESIGN")
  zones<-split(as.numeric(raw$JKREP),as.numeric(raw$JKZONE))
  if(any(!vapply(zones,function(z)setequal(z,c(0,1)),logical(1))))stop("IEA_INCOMPLETE_JK_ZONE_PAIR")
  female<-lo_iea_label_code(raw$ITSEX,c('girl','female'));male<-lo_iea_label_code(raw$ITSEX,c('boy','male'))
  d<-data.frame(SOURCE_STUDENT_ID=as.character(raw$IDSTUD),STUDENT=as.character(raw$IDSTUD),
    SCHOOL=as.character(raw$IDSCHOOL),CLASS=as.character(raw$IDCLASS),GRADE=as.numeric(raw$IDGRADE),
    W=as.numeric(raw$TOTWGT),JKZONE=as.numeric(raw$JKZONE),JKREP=as.numeric(raw$JKREP),
    DEMO_GENDER=c('girl','boy')[match(as.numeric(raw$ITSEX),c(female,male))],stringsAsFactors=FALSE)
  d$GENDER<-d$DEMO_GENDER
  for(k in names(codes))for(j in 1:5)d[[paste0('PV_',k,'_',j)]]<-as.numeric(raw[[paste0(codes[[k]],sprintf('%02d',j))]])
  note<-if(delayed)'Official fourth-grade cohort, including respondents assessed after the summer in fifth grade; no post-hoc grade exclusion'else 'Official fourth-grade national public-use student sample'
  evidence<-if(delayed)'https://www.expertisecentrumnederlands.nl/pirls-2021-resultaten/download/PIRLS-2021_Rapportage.pdf#page=13'else 'https://www.iea.nl/data-tools/repository'
  meta<-list(survey=survey,year=as.integer(year),v9_country='NLD',source_country_code=528L,
    preparation='DIRECT_FROM_OFFICIAL_PUF_WITHOUT_LEGACY_CACHE',class_identity='ACTUAL_CLASS_NESTED_WITHIN_SCHOOL',
    gender_variable='ITSEX',gender_status='SOURCE_VALUE_LABEL_VERIFIED',population=note,population_evidence=evidence,
    repair_raw_sha256=digest::digest(file=path,algo='sha256'))
  obj<-list(data=d,meta=meta);dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
  output<-file.path(output_dir,paste0('canonical_',survey,'_',year,'_NLD_',substr(digest::digest(obj,algo='sha256'),1,16),'.rds'))
  if(!file.exists(output))saveRDS(obj,output,compress=FALSE)
  else if(!identical(readRDS(output),obj))stop('IEA_CHANGED_CANONICAL_OUTPUT')
  receipt<-list(status='RAW_SAMPLE_AND_FIELDS_VERIFIED',survey=survey,year=year,country='NLD',n=nrow(d),
    raw_sha256=meta$repair_raw_sha256,canonical_filename=basename(output),canonical_sha256=digest::digest(file=output,algo='sha256'),
    all_source_records_retained=TRUE,grade4_n=sum(d$GRADE==4),grade5_n=sum(d$GRADE==5),population=note,population_evidence=evidence,
    gender_weighted_coverage=sum(d$W[!is.na(d$GENDER)])/sum(d$W),jk_zones=length(zones),
    replicate_scheme=if(year>=2015)'TWO_PER_ZONE_FACTOR_HALF'else 'JKREP_ONE_PER_ZONE_FACTOR_ONE',
    pv_count=5L,not_certified=c('SES','language','migration','peer methods','cross-country comparability','publication release'))
  jsonlite::write_json(receipt,file.path(output_dir,'SOURCE_VERIFICATION.json'),pretty=TRUE,auto_unbox=TRUE,digits=17)
  list(raw=raw,object=obj,path=normalizePath(output,winslash='/'),receipt=receipt)
}

# Independent verification works directly on official source columns. Joint
# arrays retain matched PV/replicate coordinates for later approved contrasts.
lo_iea_independent_selected <- function(raw,q) {
  if(!nrow(q)||length(unique(q$year))!=1L||length(unique(q$survey))!=1L||
     any(!q$module%in%c('core','gender','extension_performance_school','extension_performance_class')))
    stop('IEA_INDEPENDENT_UNREVIEWED_TASK')
  year<-as.integer(q$year[1]);zones<-sort(unique(as.numeric(raw$JKZONE)))
  spec<-expand.grid(zone=zones,keep=if(year>=2015)c(0,1)else 1)
  factor<-if(year>=2015).5 else 1
  W<-matrix(as.numeric(raw$TOTWGT),nrow(raw),nrow(spec)+1L)
  for(i in seq_len(nrow(spec))) {
    selected<-raw$JKZONE==spec$zone[i]
    W[selected,i+1]<-W[selected,1]*ifelse(raw$JKREP[selected]==spec$keep[i],2,0)
  }
  sex<-as.numeric(raw$ITSEX)
  female<-lo_iea_label_code(raw$ITSEX,c('girl','female'));male<-lo_iea_label_code(raw$ITSEX,c('boy','male'))
  full<-matrix(NA_real_,5,nrow(q),dimnames=list(NULL,q$metric_key))
  reps<-array(NA_real_,c(nrow(spec),5,nrow(q)),dimnames=list(NULL,NULL,q$metric_key));ns<-integer(nrow(q))
  wm<-function(y,w){ok<-is.finite(y)&is.finite(w)&w>0;sum(y[ok]*w[ok])/sum(w[ok])}
  quant<-function(y,w,p){ok<-is.finite(y)&w>0;o<-order(y[ok]);v<-y[ok][o];z<-w[ok][o];v[which(cumsum(z)>=p*sum(z))[1]]}
  for(k in seq_len(nrow(q))) {
    z<-q[k,];prefix<-switch(z$domain,reading='ASRREA',mathematics='ASMMAT',science='ASSSCI',stop('IEA_UNKNOWN_DOMAIN'))
    y<-as.matrix(raw[paste0(prefix,sprintf('%02d',1:5))]);if(any(!is.finite(y)))stop('IEA_INCOMPLETE_PVS')
    a<-rep(TRUE,nrow(raw));b<-NULL
    if(z$module=='gender') {
      if(z$stat=='gap'){stopifnot(z$group=='girls_minus_boys');a<-sex==female;b<-sex==male}
      else a<-sex==switch(z$group,girl=female,boy=male,stop('IEA_UNKNOWN_GENDER_GROUP'))
    }
    a[is.na(a)]<-FALSE;if(!is.null(b))b[is.na(b)]<-FALSE
    ns[k]<-sum(a|if(is.null(b))FALSE else b)
    m<-matrix(NA_real_,5,ncol(W))
    for(j in 1:5)for(r in seq_len(ncol(W))) {
      v<-y[,j];w<-W[,r];s<-z$stat
      if(s%in%c('total_below','total_high')) {
        threshold<-if(s=='total_below')475 else 625
        if(as.numeric(z$threshold)!=threshold)stop('IEA_UNREVIEWED_THRESHOLD')
        v<-if(s=='total_below')as.numeric(v<threshold)else as.numeric(v>=threshold)
      }
      m[j,r]<-if(grepl('^extension_performance_',z$module)) {
        stopifnot(s=='between_variance_share')
        unit<-if(z$module=='extension_performance_school')as.character(raw$IDSCHOOL)else paste(raw$IDSCHOOL,raw$IDCLASS,sep='::')
        mu<-sum(w*v)/sum(w);sw<-tapply(w,unit,sum);sy<-tapply(w*v,unit,sum);ok<-sw>0
        100*sum(sw[ok]*(sy[ok]/sw[ok]-mu)^2)/sum(w*(v-mu)^2)
      }else if(!is.null(b))wm(v,w*a)-wm(v,w*b)
      else if(s%in%c('mean','total_below','total_high'))wm(v,w*a)
      else if(s%in%c('p10','p50','p90'))quant(v,w,as.numeric(sub('p','',s))/100)
      else if(s=='p90_p10')quant(v,w,.9)-quant(v,w,.1)
      else stop('IEA_UNREVIEWED_STAT')
    }
    if(any(!is.finite(m)))stop('IEA_INCOMPLETE_ESTIMATION: ',z$metric_key)
    full[,k]<-m[,1];reps[,,k]<-t(m[,-1,drop=FALSE])
  }
  variance<-vapply(seq_len(nrow(q)),function(k)mean(rowSums((t(reps[,,k])-full[,k])^2)*factor)+1.2*var(full[,k]),numeric(1))
  list(results=data.frame(cell_id=q$metric_key,estimate=colMeans(full),standard_error=sqrt(variance),n_unweighted=ns),
    joint=list(cell_ids=q$metric_key,full_pv=full,replicate_pv=reps,replicate_spec=spec,factor=factor,pv_count=5L))
}
