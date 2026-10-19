# Apply the already verified four-wave/13-item calibration. Do not refit it on
# a different country pool when production membership changes. Other countries
# use the same item parameters and standardization; their country-wave
# imputation remains separate. Full base order and RNG draws are preserved.
lo_ses_extra_prefix <- function(order,available,countries,calibration) {
  key<-function(x)paste(x$source_country,x$year,sep='|')
  if(anyDuplicated(key(order))||!identical(as.integer(order$position),seq_len(nrow(order))))
    stop('SES_IMPUTATION_ORDER_INVALID')
  requested<-available[available$source_country%in%setdiff(ifelse(countries=='TWN','TAP',countries),calibration),,drop=FALSE]
  at<-match(key(requested),key(order))
  if(anyNA(at))stop('SES_IMPUTATION_ORDER_APPEND_REQUIRED')
  if(!length(at))return(order[FALSE,,drop=FALSE])
  prefix<-order[seq_len(max(at)),,drop=FALSE]
  if(any(!key(prefix)%in%key(available)))stop('SES_IMPUTATION_PREFIX_SOURCE_MISSING')
  prefix
}

lo_prepare_international_ses <- function(repo,author,root,partitions,countries) {
  suppressPackageStartupMessages(library(data.table))
  threads<-getDTthreads();on.exit(setDTthreads(threads),add=TRUE);setDTthreads(1L)
  caldir<-file.path(root,'cobreros_four');out<-file.path(root,'international','ses')
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  sha<-function(p)digest::digest(file=p,algo='sha256')
  cal<-jsonlite::fromJSON(file.path(caldir,'PREPARATION_MANIFEST.json'))
  closure<-jsonlite::fromJSON(file.path(caldir,'RAW_INPUT_CLOSURE.json'))
  stopifnot(closure$status=='FOUR_WAVE_RAW_INPUT_PARITY_PASS',cal$author_commit=='1da4b26097e84e732973af672355a1c3103d5d33',
    cal$model_parameter_max_absolute_difference$discrimination<1e-8,cal$model_parameter_max_absolute_difference$steps<1e-8)
  code<-file.path(author,'code/r/R',c('core.R','irt.R','kernels.cpp'))
  input<-file.path(author,'data/extract',paste0('stu_',c(2015,2018,2022,2025),'.parquet'))
  for(p in c(code,input))stopifnot(sha(p)==cal$input_and_code_hashes$sha256[match(p,cal$input_and_code_hashes$path)])
  modelpath<-file.path(caldir,'irt13_model.rds');model<-readRDS(modelpath);stopifnot(isTRUE(model$converged))
  orderpath<-file.path(repo,'06_pipeline/review_20261013/SES_EXTRA_CONTEXT_ORDER.csv')
  order<-read.csv(orderpath,stringsAsFactors=FALSE)
  register<-do.call(rbind,lapply(partitions,function(x)transform(x$files,year=x$year)))
  available<-data.frame(source_country=register$country,year=register$year)
  prefix<-lo_ses_extra_prefix(order,available,countries,cal$calibration_countries)
  contextkey<-function(c,y)paste(c,y,sep='|')
  extra_keys<-contextkey(prefix$source_country,prefix$year)
  register<-register[register$country%in%cal$calibration_countries|
    contextkey(register$country,register$year)%in%extra_keys,,drop=FALSE]
  key<-digest::digest(list(calibration=sha(file.path(caldir,'CALIBRATION_CERTIFICATE.json')),model=sha(modelpath),
    partitions=register,countries=sort(countries),imputation_order=sha(orderpath),
    adapter=sha(file.path(repo,'06_pipeline/LO_INTERNATIONAL_SES.R'))),algo='sha256')
  marker<-file.path(out,paste0('SES_',key,'.json'))
  if(file.exists(marker)) {
    old<-jsonlite::fromJSON(marker)
    stopifnot(all(vapply(old$files$path,sha,character(1))==old$files$sha256));old$certificate_path<-marker;return(invisible(old))
  }
  env<-new.env(parent=globalenv())
  for(p in code[1:2])for(expr in parse(p))if(is.call(expr)&&identical(expr[[1]],as.name('<-'))&&is.call(expr[[3]])&&identical(expr[[3]][[1]],as.name('function')))eval(expr,env)
  env$ROOT<-author;env$INTERIM<-out;env$CACHE<-file.path(out,'cache');dir.create(env$CACHE,recursive=TRUE,showWarnings=FALSE)
  Rcpp::sourceCpp(code[3],cacheDir=file.path(env$CACHE,'Rcpp'),env=env)
  fields<-function(y)if(y<=2018)c(sprintf('st011q%02dta',c(2,4,5,6,9)),sprintf('st012q%02dta',1:3),sprintf('st012q%02dna',6:9),'books6')else
    c(sprintf('st250q%02dja',c(1,2,3,5)),sprintf('st251q%02dja',c(1,3,6,7)),sprintf('st254q%02dja',1:5),'st255q01ja')
  keep<-c('wave','cnt','cntstuid','w_fstuwt','hisei','paredint','hisced')
  parts<-lapply(c(2015L,2018L,2022L,2025L),function(y){g<-env$read_extract(y,c(keep,fields(y)));cbind(g[,c(keep,'raw_row'),with=FALSE],env$recode_four(g))})
  common<-setdiff(Reduce(intersect,lapply(parts,function(g)unique(g$cnt))),'CRI')
  stopifnot(setequal(common,cal$calibration_countries),length(common)==34L)
  d<-rbindlist(parts,fill=TRUE)[cnt%in%common];rm(parts);base_n<-nrow(d)
  extra<-list();rawproof<-list()
  for(reg in partitions)for(ct in reg$files$country[contextkey(reg$files$country,reg$year)%in%extra_keys]) {
    record<-reg$files[reg$files$country==ct,];stopifnot(sha(record$path)==record$sha256)
    raw<-readRDS(record$path);y<-as.integer(reg$year)
    vars<-c('cnt','cntstuid','w_fstuwt','hisei','hisced',if(y!=2015)'paredint',fields(y))
    orig<-toupper(vars);orig[vars=='books6']<-'ST013Q01TA';stopifnot(all(orig%in%names(raw)))
    g<-as.data.table(lapply(raw[orig],function(x){x<-unclass(x);if(is.character(x))as.character(x)else as.numeric(x)}));setnames(g,vars)
    g[,`:=`(wave=y,raw_row=seq_len(.N))];if(y==2015)g[,paredint:=NA_real_]
    stopifnot(!anyDuplicated(g$cntstuid),all(g$cnt==ct),all(g$w_fstuwt>0))
    extra[[contextkey(ct,y)]]<-cbind(g[,c(keep,'raw_row'),with=FALSE],env$recode_four(g))
    rawproof[[contextkey(ct,y)]]<-data.frame(country=ct,year=y,source_sha256=reg$raw_sha256,partition_sha256=record$sha256,n=nrow(g))
  }
  if(length(extra)) {
    if(!setequal(names(extra),extra_keys))stop('SES_IMPUTATION_PREFIX_INCOMPLETE')
    extra<-extra[extra_keys];rawproof<-rawproof[extra_keys]
    d<-rbindlist(c(list(d),extra),fill=TRUE)
  }
  rm(extra);gc(FALSE)
  mapping<-d[seq_len(base_n)][wave==2018L&is.finite(hisced)&is.finite(paredint),.(years=as.numeric(names(sort(table(paredint),decreasing=TRUE))[1])),by=hisced]
  d[wave==2015L,paredint:=mapping$years[match(hisced,mapping$hisced)]]
  d[,pared_c:=fifelse(paredint==3,6,fifelse(paredint==14.5,14,paredint))]
  items<-c('room','computer','software','internet','art','instruments','cars','bathrooms','televisions','tablets','ereaders','computers','books')
  X<-as.matrix(d[,..items]);storage.mode(X)<-'integer';X[is.na(X)]<- -1L
  # Revalidate the model's original calibration-input fingerprint before use.
  wbase<-env$senate(d[seq_len(base_n)]);wfit<-wbase/sum(wbase)*base_n
  stopifnot(identical(digest::digest(list(X[seq_len(base_n),],wfit,body(env$fit_irt)),algo='xxhash64'),model$fingerprint))
  cat('SCORING_FROZEN_CHOSEN_SES',nrow(d),'rows; calibration',base_n,'unchanged\n');flush.console()
  ir<-env$resolve_wle(env$wle_cpp(X,model$a,model$b,min_items=3),X,model$a,model$b)
  valid<-rowSums(X>=0)>=3;stopifnot(!any(valid&(!ir$converged|ir$boundary)))
  theta<-ir$theta;theta[rowSums(X>=0)<8]<-NA_real_
  w<-c(wbase,rep(0,nrow(d)-base_n))
  score<-env$escs(cbind(d$hisei,d$pared_c,theta),env$cell_id(d),w)
  d[,`:=`(SES=score$score,homepos_irt=theta)]
  previous<-as.data.frame(readRDS(file.path(caldir,cal$output_filename)));nld<-as.data.frame(d[cnt=='NLD'])
  i<-match(paste(previous$wave,previous$cntstuid),paste(nld$wave,nld$cntstuid))
  stopifnot(!anyNA(i),identical(is.finite(previous$SES),is.finite(nld$SES[i])),max(abs(previous$SES-nld$SES[i]),na.rm=TRUE)<1e-12)
  # Confirm every retained score, not only NLD. Adding countries must preserve
  # the already certified stochastic imputations byte-for-value. Reuse their
  # immutable files rather than writing duplicate copies under the new key.
  priorfiles<-list();priorproof<-list()
  for(cp in list.files(out,pattern='^SES_[a-f0-9]+[.]json$',full.names=TRUE)) {
    cert0<-jsonlite::fromJSON(cp)
    if(cert0$author_commit!=cal$author_commit||cert0$model_sha256!=sha(modelpath))next
    for(j in seq_len(nrow(cert0$files))) {
      f<-cert0$files[j,];ct<-if(f$country=='TWN')'TAP'else f$country
      x<-d[cnt==ct&wave==as.integer(f$year),.(wave,cnt,cntstuid,raw_row,w_fstuwt,SES,homepos_irt,hisei,pared_c)]
      if(!nrow(x))next
      if(!file.exists(f$path)||sha(f$path)!=f$sha256)stop('SES_PREVIOUS_SCORE_HASH_CHANGED')
      saved<-readRDS(f$path)
      if(!isTRUE(all.equal(as.data.frame(x),as.data.frame(saved),check.attributes=FALSE,tolerance=0)))
        stop('SES_EXPANSION_CHANGED_CERTIFIED_SCORES: ',f$country,' ',f$year)
      k<-contextkey(ct,f$year);priorfiles[[k]]<-f
      priorproof[[length(priorproof)+1L]]<-data.frame(country=f$country,year=f$year,
        previous_certificate_sha256=sha(cp),score_sha256=f$sha256,exact_score_parity=TRUE)
    }
  }
  records<-list()
  for(ct in intersect(unique(d$cnt),ifelse(countries=='TWN','TAP',countries)))for(y in unique(d$wave[d$cnt==ct])) {
    x<-d[cnt==ct&wave==y,.(wave,cnt,cntstuid,raw_row,w_fstuwt,SES,homepos_irt,hisei,pared_c)]
    country<-if(ct=='TAP')'TWN'else ct;p<-file.path(out,paste0(country,'_',y,'_',key,'.rds'))
    oldfile<-priorfiles[[contextkey(ct,y)]]
    if(!is.null(oldfile))p<-oldfile$path else {
      if(file.exists(p))stopifnot(identical(readRDS(p),x))else saveRDS(x,p,compress='gzip')
    }
    records[[length(records)+1L]]<-data.frame(country=country,year=y,path=p,sha256=sha(p),n=nrow(x),valid=sum(is.finite(x$SES)),calibration_member=ct%in%common)
  }
  frozen<-file.path(out,'code',key);dir.create(frozen,recursive=TRUE,showWarnings=FALSE)
  frozenpaths<-vapply(c(orderpath,file.path(repo,'06_pipeline/LO_INTERNATIONAL_SES.R')),function(p) {
    target<-file.path(frozen,basename(p))
    if(!file.exists(target))stopifnot(file.copy(p,target,overwrite=FALSE))
    if(sha(target)!=sha(p))stop('SES_FROZEN_CODE_CONFLICT')
    target
  },character(1))
  cert<-list(status='FROZEN_CHOSEN_SES_APPLIED_WITH_NLD_NUMERIC_PARITY',key=key,author_commit=cal$author_commit,
    calibration_countries=sort(common),calibration_n=base_n,model_sha256=sha(modelpath),
    application='Original fixed item parameters and original 34-country standardization. Append-only country-wave imputation order; all preceding RNG draws preserved even for a subset run. Every reused score is checked exactly; no recalibration.',
    uncertainty='Survey/PV uncertainty conditional on fitted SES; measurement invariance is not established by numerical parity',
    nld_max_absolute_difference=max(abs(previous$SES-nld$SES[i]),na.rm=TRUE),files=do.call(rbind,records),
    extra_raw_mapping=if(length(rawproof))do.call(rbind,rawproof)else NULL,
    imputation_order_sha256=sha(orderpath),prior_application_parity=if(length(priorproof))do.call(rbind,priorproof)else NULL,
    evidence_files=data.frame(path=c(file.path(caldir,'CALIBRATION_CERTIFICATE.json'),modelpath,code,input,frozenpaths),
      sha256=vapply(c(file.path(caldir,'CALIBRATION_CERTIFICATE.json'),modelpath,code,input,frozenpaths),sha,character(1))))
  tmp<-tempfile('ses_receipt_',tmpdir=out)
  jsonlite::write_json(cert,tmp,pretty=TRUE,auto_unbox=TRUE,digits=17)
  if(!file.rename(tmp,marker))stop('SES_RECEIPT_ATOMIC_COMMIT_FAILED')
  cert$certificate_path<-marker;invisible(cert)
}
