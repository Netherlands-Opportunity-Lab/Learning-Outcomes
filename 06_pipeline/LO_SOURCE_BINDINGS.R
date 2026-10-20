# Portable binding of reviewed source identities to local paths. The caller
# supplies a two-column sha256,path CSV; no directory search or guessed version.
lo_bind_international_sources <- function(repo,root,bindings_path,python=Sys.getenv('LO_PYTHON','python'),countries=NULL,include_calibration_contexts=FALSE) {
  source(file.path(repo,'06_pipeline/LO_ATOMIC_CHECKPOINT.R'))
  catalogue<-file.path(repo,'06_pipeline/review_20261013/international')
  m<-read.csv(file.path(catalogue,'SOURCE_CATALOG.csv'),colClasses='character',na.strings=character())
  homes<-read.csv(file.path(catalogue,'HOME_SOURCE_CATALOG.csv'),colClasses='character',na.strings=character())
  if(!is.null(countries)&&length(countries)) {
    if(any(!countries%in%m$country))stop('SOURCE_BINDING_UNKNOWN_COUNTRY')
    # Frozen-SES calibration and deterministic imputation may require input
    # rows outside the output-country selection. These are input dependencies,
    # never additional output targets or reference countries.
    keep<-m$country%in%countries
    if(include_calibration_contexts)keep<-keep|(m$survey=='PISA'&as.integer(m$year)>=2015L)
    m<-m[keep,,drop=FALSE]
    homes<-homes[homes$country%in%countries,,drop=FALSE]
  }
  bindings<-read.csv(bindings_path,colClasses='character',na.strings=character())
  if(!all(c('sha256','path')%in%names(bindings))||anyDuplicated(bindings$sha256)||
     any(!grepl('^[a-f0-9]{64}$',bindings$sha256)))stop('SOURCE_BINDINGS_IDENTITY_INVALID')
  checked<-new.env(parent=emptyenv())
  resolve<-function(hash) {
    if(!nzchar(hash))return('')
    i<-match(hash,bindings$sha256)
    if(is.na(i))stop('SOURCE_BINDING_MISSING_SHA256: ',hash)
    path<-normalizePath(bindings$path[i],winslash='/',mustWork=TRUE)
    if(!exists(hash,checked,inherits=FALSE)) {
      if(digest::digest(file=path,algo='sha256')!=hash)stop('SOURCE_BINDING_BYTES_CHANGED: ',basename(path))
      assign(hash,TRUE,checked)
    }
    path
  }
  if(!'control_sha256'%in%names(m))stop('SOURCE_CATALOG_CONTROL_HASH_REQUIRED')
  m$raw_path<-vapply(m$raw_sha256,resolve,character(1))
  m$control_path<-vapply(m$control_sha256,resolve,character(1))
  homes$path<-vapply(homes$sha256,resolve,character(1))
  out<-file.path(root,'international');dir.create(out,recursive=TRUE,showWarnings=FALSE)
  m$index_path<-''
  for(year in unique(m$year[m$survey=='PISA'])) {
    i<-which(m$survey=='PISA'&m$year==year)
    path<-unique(m$raw_path[i]);hash<-unique(m$raw_sha256[i])
    stopifnot(length(path)==1L,length(hash)==1L)
    if(as.integer(year)>=2015L) {
      dest<-file.path(out,paste0('PISA_',year,'_ROW_INDEX.rds'))
      if(file.exists(dest)) {
        index<-readRDS(dest)
        stopifnot(identical(index$raw_sha256,hash),identical(index$raw_path,path))
      }else {
        selector<-as.character(haven::read_sav(path,col_select=tidyselect::all_of('CNT'))$CNT)
        stopifnot(length(selector)>0L,!anyNA(selector),all(grepl('^[A-Z]{3}$',selector)))
        index<-list(year=as.integer(year),raw_path=path,raw_sha256=hash,selector=selector,n=length(selector))
        temporary<-tempfile('index_',tmpdir=out);saveRDS(index,temporary)
        if(!file.rename(temporary,dest))stop('SOURCE_INDEX_ATOMIC_RENAME')
      }
    }else {
      dest<-file.path(out,paste0('PISA_',year,'_BYTE_INDEX.json'))
      controls<-unique(m$control_path[i]);control_hash<-unique(m$control_sha256[i])
      stopifnot(length(controls)==1L,length(control_hash)==1L,nzchar(control_hash))
      args<-c(file.path(repo,'06_pipeline/LO_BUILD_BYTE_INDEX.py'),'--raw',path,'--control',controls,
        '--year',year,'--expected-sha',hash,'--expected-control-sha',control_hash,'--output',dest)
      status<-system2(python,shQuote(args))
      if(status!=0L)stop('SOURCE_BYTE_INDEX_BUILD_FAILED')
    }
    m$index_path[i]<-normalizePath(dest,winslash='/',mustWork=TRUE)
  }
  columns<-c('country','survey','year','raw_path','raw_sha256','source_country','control_path','index_path','allowed_grades','population_note','population_evidence')
  manifest<-file.path(out,'SOURCE_RUN_MANIFEST.csv')
  # Existing runs have their own pinned path contract. Relocation gets a fresh
  # output root and rebuilds sources from the same publicly pinned identities.
  if(file.exists(manifest)) {
    old<-read.csv(manifest,colClasses='character',na.strings=character())
    if(!identical(old[columns],m[columns]))stop('SOURCE_BINDING_EXISTING_MANIFEST_DIFFERS')
  }else lo_atomic_csv(m[columns],manifest)
  homes$archive<-rep('',nrow(homes));homes$member<-rep('',nrow(homes))
  lo_atomic_csv(homes[c('country','survey','year','path','sha256','archive','member')],file.path(out,'HOME_SOURCE_MANIFEST.csv'))
  invisible(manifest)
}
