# Engine integration repairs; not a standalone production launcher.
# This file never sources raw data, publishes centrally, or starts production.

lo36_read_csv <- function(path, expected_rows=NULL) {
  # An incomplete compressed CSV must not silently become a smaller inventory.
  x <- withCallingHandlers(read.csv(path, colClasses='character',
    na.strings=character(), check.names=FALSE, stringsAsFactors=FALSE),
    warning=function(w) stop('Bronbestand niet volledig leesbaar: ',path,': ',conditionMessage(w)))
  if(!is.null(expected_rows) && nrow(x)!=expected_rows)
    stop('Onverwacht aantal bronregels: ',path)
  x
}

lo36_canonical <- function(x) {
  # Stable UTF-8, explicit lengths/types; no R serialization or paths/timestamps.
  atom <- function(s) {s<-enc2utf8(s);paste0(nchar(s,type='bytes'),':',s)}
  if(is.null(x))return('Z')
  if(is.data.frame(x)) {
    z<-as.list(x);names(z)<-names(x)
    return(paste0('D',nrow(x),':',lo36_canonical(z)))
  }
  if(is.list(x)) {
    nm<-names(x)
    if(!is.null(nm)) {
      if(anyNA(nm)||any(!nzchar(nm))||anyDuplicated(nm))stop('Named lists require unique nonempty names.')
      ix<-order(enc2utf8(nm),method='radix'); x<-x[ix];nm<-nm[ix]
      return(paste0('M',length(x),':',paste0(vapply(seq_along(x),function(i)
        paste0(atom(nm[i]),lo36_canonical(x[[i]])),character(1)),collapse='')))
    }
    return(paste0('L',length(x),':',paste0(vapply(x,lo36_canonical,character(1)),collapse='')))
  }
  if(!is.null(attributes(x)) && !is.null(class(x)) && !is.atomic(x))stop('Unsupported fingerprint value.')
  kind<-if(is.character(x))'S' else if(is.logical(x))'B' else if(is.numeric(x))'N' else stop('Unsupported fingerprint type.')
  val<-vapply(seq_along(x),function(i){
    y<-x[i];if(is.na(y))return('A')
    if(is.character(y))return(paste0('V',atom(y)))
    if(is.logical(y))return(if(y)'T' else 'F')
    if(!is.finite(y))stop('Nonfinite numeric fingerprint input.')
    if(y==0)y<-0
    paste0('V',atom(formatC(y,digits=17,format='g',decimal.mark='.')))
  },character(1))
  nm<-names(x)
  paste0(kind,length(x),':',paste0(val,collapse=''),
    if(is.null(nm))'U' else paste0('K',paste0(vapply(nm,atom,character(1)),collapse='')))
}

lo36_hash_text <- function(text) {
  if(requireNamespace('digest',quietly=TRUE))
    return(digest::digest(charToRaw(enc2utf8(text)),algo='sha256',serialize=FALSE))
  cmd<-Sys.which('sha256sum')
  if(!nzchar(cmd))stop('Dependency digest ontbreekt; geen zwakkere hashfallback.')
  f<-tempfile();on.exit(unlink(f));writeBin(charToRaw(enc2utf8(text)),f)
  sub(' .*','',system2(cmd,shQuote(f),stdout=TRUE)[1])
}
lo36_fp <- function(x)lo36_hash_text(lo36_canonical(x))

lo36_science_fp <- function(definition,input_sha256,estimator_sha256,calibration=NULL) {
  if(!length(input_sha256)||any(!grepl('^[a-f0-9]{64}$',input_sha256))||
     length(estimator_sha256)!=1L||!grepl('^[a-f0-9]{64}$',estimator_sha256))
    stop('Exacte input- en estimatorhashes vereist.')
  # Callers provide ONLY scientific definitions. Reference and style have separate identities.
  if(any(c('reference','references','style','products','workers')%in%names(definition)))
    stop('Product/referentieconfiguratie hoort niet in de wetenschappelijke definitie.')
  lo36_fp(list(version='science-1',definition=definition,
    inputs=sort(unique(input_sha256),method='radix'),estimator=estimator_sha256,calibration=calibration))
}

lo36_install_compute <- function(engine,extensions) {
  need<-c('v10_compute','v10_pool','pv_names','rc2_num','weighted_mean','v10_gender','v10_language')
  if(!all(vapply(need,exists,logical(1),envir=engine,inherits=TRUE)))stop('Backend niet volledig geladen.')
  if(exists('.lo36_original_compute',engine,inherits=FALSE))return(invisible(engine))
  original<-get('v10_compute',engine)
  backend<-list(original=original,pool=get('v10_pool',engine),pv_names=get('pv_names',engine),
    num=get('rc2_num',engine),weighted_mean=get('weighted_mean',engine),
    gender=get('v10_gender',engine),language=get('v10_language',engine))
  compute<-function(obj,q){
    if(!nrow(q))return(q)
    if(!all(c('metric_key','module','domain','definition','stat')%in%names(q))||anyDuplicated(q$metric_key))
      stop('Ongeldige of dubbele rekentaak.')
    # Mixed core/basic and mean/gap batches must still reach their own estimator.
    ext<-(q$module=='core'&q$stat%in%c('total_basic','total_below'))|
      (q$module%in%c('gender','language_frequency_binary')&q$stat=='gap')
    batch<-interaction(q$module,q$domain,q$definition,ext,drop=TRUE,lex.order=TRUE)
    ans<-lapply(split(seq_len(nrow(q)),batch),function(ix)extensions(obj,q[ix,,drop=FALSE],backend))
    cols<-unique(unlist(lapply(ans,names)))
    ans<-lapply(ans,function(z){for(n in setdiff(cols,names(z)))z[[n]]<-NA;z[cols]})
    z<-do.call(rbind,ans)
    if(nrow(z)!=nrow(q)||anyDuplicated(z$metric_key)||!setequal(z$metric_key,q$metric_key))
      stop('Estimator veranderde de resultaatidentiteit.')
    z<-z[match(q$metric_key,z$metric_key),,drop=FALSE];rownames(z)<-NULL
    if(any(!is.finite(z$estimate))||any(!is.finite(z$se))||any(z$se<0))stop('Ongeldige schatting of onzekerheid.')
    z
  }
  assign('.lo36_original_compute',original,engine)
  assign('v10_compute',compute,engine)
  invisible(engine)
}

lo36_validate_groups <- function(req,cfg) {
  # Configuration must select actual tasks, not merely document unused options.
  keep<-rep(TRUE,nrow(req))
  map<-c(gender='gender',language_exact='language',language_frequency_binary='language',
    migration='migration',migration_generation='migration_generation')
  for(m in names(map)){
    ix<-req$module==m; allowed<-cfg$groups[[map[[m]]]]
    if(is.null(allowed))stop('Groepconfiguratie ontbreekt: ',map[[m]])
    keep[ix]<-req$group[ix]%in%allowed
  }
  keep
}
