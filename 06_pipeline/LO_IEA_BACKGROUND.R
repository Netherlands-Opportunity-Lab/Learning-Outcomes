# Reviewed ordinal books construct, separate from official IEA Home SES.
# Missing responses never enter a quartile or the SES variance denominator.
lo_iea_books_variable <- function(survey,year) {
  if(year>=2011L)return('ASBG04')
  if(survey=='TIMSS'&&year==2007L)return('AS4GBOOK')
  'ASBGBOOK'
}
lo_iea_books <- function(x) {
  labs<-attr(x,'labels');labels<-tolower(names(labs)[match(1:5,as.numeric(labs))])
  # Retain ordinal categories, not guessed book counts or interval midpoints.
  patterns<-c('0.*10','11.*25','26.*100','101.*200','200')
  if(anyNA(labels)||!all(vapply(seq_len(5L),function(i)grepl(patterns[i],labels[i]),logical(1))))
    stop('IEA_BOOKS_CATEGORY_LABELS_NOT_VERIFIED')
  a<-as.numeric(x);a[!a%in%1:5]<-NA_real_;a
}
lo_iea_prepare_books <- function(path,survey,year,output_dir,country='NLD',country_code=528L,
                                 allowed_grades=4L,population_note=NULL,population_evidence=NULL) {
  v<-lo_iea_prepare_country(path,survey,year,output_dir,country,country_code,allowed_grades,population_note,population_evidence)
  field<-lo_iea_books_variable(survey,year)
  b<-haven::read_sav(path,col_select=tidyselect::all_of(c('IDSTUD',field)))
  if(!identical(as.numeric(b$IDSTUD),as.numeric(v$raw$IDSTUD)))stop('IEA_BOOKS_SOURCE_ROW_MISMATCH')
  v$raw[[field]]<-b[[field]];v$object$data$SES<-lo_iea_books(b[[field]])
  v$object$meta$ses_construct_id<-'books_ordinal'
  v$object$meta$ses_variable<-field
  v$object$meta$ses_quartile_protocol<-'NATIONAL_WEIGHTED_FRACTIONAL_TIES_RECALCULATED_PER_REPLICATE'
  output<-file.path(output_dir,paste0('canonical_',survey,'_',year,'_',country,'_books_',substr(digest::digest(v$object,algo='sha256'),1,16),'.rds'))
  if(!file.exists(output))saveRDS(v$object,output,compress=FALSE)
  else if(!identical(readRDS(output),v$object))stop('IEA_CHANGED_BOOKS_CANONICAL')
  v$path<-normalizePath(output,winslash='/');v$receipt$canonical_filename<-basename(output)
  v$receipt$canonical_sha256<-digest::digest(file=output,algo='sha256')
  v$receipt$ses_variable<-field;v$receipt$ses_construct<-'Five ordered books-at-home categories, no metric book-count interpretation'
  v$receipt$ses_weighted_coverage<-sum(v$object$data$W[is.finite(v$object$data$SES)])/sum(v$object$data$W)
  v$receipt$not_certified<-c('Official Home SES','language','migration','peers','cross-country comparability','release')
  jsonlite::write_json(v$receipt,file.path(output_dir,'SOURCE_VERIFICATION.json'),auto_unbox=TRUE,pretty=TRUE,digits=17)
  v
}

# Independent category-mass allocation; this does not call the producer's
# fractional-tail helper. Boundary categories receive equal fractional weight.
lo_iea_reference_tails <- function(x,w) {
  valid<-is.finite(x)&is.finite(w)&w>0
  levels<-sort(unique(x[valid]));mass<-vapply(levels,function(k)sum(w[valid&x==k]),numeric(1))
  target<-sum(mass)/4
  allocate<-function(order) {
    result<-numeric(length(x));left<-target
    for(i in order) {
      fraction<-min(1,max(0,left/mass[i]));result[valid&x==levels[i]]<-fraction
      left<-max(0,left-mass[i])
    };result
  }
  list(q1=allocate(seq_along(levels)),q4=allocate(rev(seq_along(levels))))
}
lo_iea_independent_books <- function(raw,q) {
  allowed<-c('ses_national','extension_ses_gender','extension_ses_school','extension_ses_class')
  if(!nrow(q)||length(unique(q$year))!=1L||length(unique(q$survey))!=1L||any(!q$module%in%allowed))
    stop('IEA_BOOKS_UNREVIEWED_TASK')
  year<-as.integer(q$year[1]);survey<-q$survey[1]
  x<-lo_iea_books(raw[[lo_iea_books_variable(survey,year)]])
  zones<-sort(unique(as.numeric(raw$JKZONE)))
  spec<-expand.grid(zone=zones,keep=if(year>=2015)c(0,1)else 1)
  factor<-if(year>=2015).5 else 1
  W<-matrix(as.numeric(raw$TOTWGT),nrow(raw),nrow(spec)+1L)
  for(i in seq_len(nrow(spec))) {
    ix<-raw$JKZONE==spec$zone[i]
    W[ix,i+1]<-W[ix,1]*ifelse(raw$JKREP[ix]==spec$keep[i],2,0)
  }
  tails<-lapply(seq_len(ncol(W)),function(i)lo_iea_reference_tails(x,W[,i]))
  sex<-as.numeric(raw$ITSEX);female<-lo_iea_label_code(raw$ITSEX,c('girl','female'));male<-lo_iea_label_code(raw$ITSEX,c('boy','male'))
  full<-matrix(NA_real_,5,nrow(q),dimnames=list(NULL,q$metric_key))
  reps<-array(NA_real_,c(nrow(spec),5,nrow(q)),dimnames=list(NULL,NULL,q$metric_key));ns<-integer(nrow(q))
  wm<-function(y,w){ok<-is.finite(y)&is.finite(w)&w>0;sum(y[ok]*w[ok])/sum(w[ok])}
  for(k in seq_len(nrow(q))) {
    z<-q[k,];fixed<-z$module%in%c('extension_ses_school','extension_ses_class')
    if(fixed)Y<-matrix(x,nrow(raw),5) else {
      prefix<-switch(z$domain,reading='ASRREA',mathematics='ASMMAT',science='ASSSCI',stop('IEA_BOOKS_DOMAIN'))
      Y<-as.matrix(raw[paste0(prefix,sprintf('%02d',1:5))])
    }
    eligible<-is.finite(x);sx<-rep(1,nrow(raw))
    if(z$module=='extension_ses_gender') {
      desired<-sub('^q[14]_','',z$group);stopifnot(desired%in%c('girl','boy'))
      sx<-as.numeric(sex==if(desired=='girl')female else male);sx[is.na(sx)]<-0
    }
    gap<-z$stat=='score_gap_q4_minus_q1'
    tail<-if(z$module=='extension_ses_gender')sub('_.*$','',z$group)else sub('_.*$','',z$stat)
    if(!fixed)eligible<-eligible & sx>0 & if(gap)(tails[[1]]$q1>0|tails[[1]]$q4>0)else tails[[1]][[tail]]>0
    ns[k]<-sum(eligible)
    M<-matrix(NA_real_,5,ncol(W))
    for(j in 1:5)for(r in seq_len(ncol(W))) {
      y<-Y[,j];w<-W[,r];s<-z$stat
      if(fixed) {
        unit<-if(z$module=='extension_ses_school')as.character(raw$IDSCHOOL)else paste(raw$IDSCHOOL,raw$IDCLASS,sep='::')
        ok<-is.finite(y)&w>0;y<-y[ok];w<-w[ok];unit<-unit[ok]
        mu<-sum(w*y)/sum(w);sw<-tapply(w,unit,sum);sy<-tapply(w*y,unit,sum)
        M[j,r]<-100*sum(sw*(sy/sw-mu)^2)/sum(w*(y-mu)^2)
      }else if(gap)M[j,r]<-wm(y,w*tails[[r]]$q4)-wm(y,w*tails[[r]]$q1)
      else {
        s<-sub('^q[14]_','',s)
        if(s%in%c('basic','high','below')) {
          cut<-as.numeric(z$threshold);stopifnot(cut%in%c(475,625))
          y<-if(s=='below')as.numeric(y<cut)else as.numeric(y>=cut)
        }else if(s!='mean')stop('IEA_BOOKS_STAT_NOT_REVIEWED')
        M[j,r]<-wm(y,w*tails[[r]][[tail]]*sx)
      }
    }
    if(any(!is.finite(M)))stop('IEA_BOOKS_NONFINITE_RESULT: ',z$metric_key)
    full[,k]<-M[,1];reps[,,k]<-t(M[,-1,drop=FALSE])
  }
  variance<-vapply(seq_len(nrow(q)),function(k)mean(rowSums((t(reps[,,k])-full[,k])^2)*factor)+1.2*var(full[,k]),numeric(1))
  list(results=data.frame(cell_id=q$metric_key,estimate=colMeans(full),standard_error=sqrt(variance),n_unweighted=ns),
    joint=list(cell_ids=q$metric_key,full_pv=full,replicate_pv=reps,replicate_spec=spec,factor=factor,pv_count=5L,SES_variance_uses_fixed_observed_books=TRUE))
}
