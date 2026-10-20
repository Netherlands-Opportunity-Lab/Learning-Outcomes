# Audit-stage library. Reads only explicitly configured, hash-pinned public-use
# sources. No analysis estimates, downloads, countries or source substitutions
# are inferred from filenames. Manifest paths and extracts remain private.
lo_source_pv_coverage <- function(obj,domains) {
  d<-obj$data;w<-as.numeric(d$W)
  rw<-grep('^RW[0-9]+$',names(d),value=TRUE)
  m<-if(obj$meta$survey=='PISA'&&as.integer(obj$meta$year)>=2015L)10L else 5L
  do.call(rbind,lapply(domains,function(domain) {
    code<-switch(domain,reading='READ',mathematics='MATH',science='SCIE')
    fields<-paste0('PV_',code,'_',seq_len(m))
    if(!all(fields%in%names(d)))stop('SOURCE_REQUIRED_PV_FIELDS_MISSING')
    n<-rowSums(is.finite(as.matrix(d[fields])))
    if(any(!n%in%c(0L,m)))stop('SOURCE_PARTIAL_PV_SET')
    observed<-n==m
    if(any(observed)&&any(colSums(as.matrix(d[observed,c('W',rw),drop=FALSE]))<=0))
      stop('SOURCE_OBSERVED_SAMPLE_REPLICATE_DENOMINATOR')
    data.frame(domain=domain,pv_count=m,n_source=nrow(d),n_observed=sum(observed),
      n_wholly_missing=sum(!observed),weighted_coverage=sum(w[observed])/sum(w),
      status=if(any(observed))'OBSERVED_COMPLETE_PV_SETS'else'NO_OBSERVED_DOMAIN_SCORES')
  }))
}

lo_international_cached_support <- function(existing,expected,receipt_path,contract_path) {
  if(!nrow(existing))return(FALSE)
  cols<-unique(c(lo_balance_columns(),'country','source_path','source_sha256','status'))
  at<-match(lo_balance_key(expected),lo_balance_key(existing))
  if(nrow(existing)!=nrow(expected)||anyNA(at)||anyDuplicated(lo_balance_key(existing))||
     !identical(as.list(existing[at,cols]),as.list(expected[cols])))
    stop('INTERNATIONAL_CACHED_SUPPORT_CONTRACT_CHANGED')
  paths<-unique(existing$certificate_path);hashes<-unique(existing$certificate_sha256)
  sha<-function(p)digest::digest(file=p,algo='sha256')
  if(length(paths)!=1L||length(hashes)!=1L||!file.exists(paths)||sha(paths)!=hashes)
    stop('INTERNATIONAL_CACHED_SUPPORT_CERTIFICATE_CHANGED')
  cert<-jsonlite::fromJSON(paths)
  if(!identical(cert$status,'SOURCE_SUPPORT_VERIFIED')||
     !identical(cert$country,expected$country[1])||
     !identical(cert$source_sha256,expected$source_sha256[1])||
     !setequal(cert$support_keys,lo_balance_key(expected))||
     is.null(cert$comparability_evidence)||!nzchar(cert$comparability_evidence)||
     !is.data.frame(cert$evidence_files)||!nrow(cert$evidence_files)||
     !all(c('path','sha256')%in%names(cert$evidence_files)))
    stop('INTERNATIONAL_CACHED_SUPPORT_CERTIFICATE_INVALID')
  if(!all(normalizePath(c(receipt_path,contract_path),winslash='/')%in%cert$evidence_files$path))
    stop('INTERNATIONAL_CACHED_SUPPORT_SOURCE_EVIDENCE_MISSING')
  for(i in seq_len(nrow(cert$evidence_files))) {
    p<-cert$evidence_files$path[i];h<-cert$evidence_files$sha256[i]
    if(!file.exists(p)||!grepl('^[a-f0-9]{64}$',h)||sha(p)!=h)
      stop('INTERNATIONAL_CACHED_SUPPORT_EVIDENCE_CHANGED')
  }
  TRUE
}

lo_international_sources <- function(repo,root,manifest_path,scope=Sys.getenv('LO_SCOPE','all_required')) {
  for(f in c('LO_ATOMIC_CHECKPOINT.R','LO_IEA_SOURCE_BLOCK.R','LO_IEA_BACKGROUND.R',
             'LO_PISA_SOURCE_BLOCK.R','LO_PISA_LEGACY_SOURCE.R','LO_BALANCED_MEMBERSHIP.R','LO_COUNTRY_REGISTRY.R'))source(file.path(repo,'06_pipeline',f))
  manifest<-read.csv(manifest_path,colClasses='character',na.strings=character())
  required<-c('country','survey','year','raw_path','raw_sha256','source_country','control_path','index_path','allowed_grades','population_note','population_evidence')
  stopifnot(all(required%in%names(manifest)),!anyDuplicated(manifest[c('country','survey','year')]))
  master<-file.path(root,'master_reconciliation');out<-file.path(root,'international')
  support_path<-file.path(master,'SOURCE_SUPPORT_CONTRACTS.csv')
  dir.create(master,recursive=TRUE,showWarnings=FALSE)
  support<-if(file.exists(support_path))read.csv(support_path,colClasses='character',na.strings=character())else lo_empty_support()
  source(file.path(repo,'06_pipeline/LO_RUN_CONFIG.R'))
  cfg<-lo_run_config(scope)
  selected<-cfg$selection$countries
  if(cfg$scope=='nld_only')selected<-'NLD'
  if(length(selected))manifest<-manifest[manifest$country%in%selected,,drop=FALSE]
  row_indices<-byte_indices<-list()
  for(index_path in unique(manifest$index_path[nzchar(manifest$index_path)])) {
    x<-if(grepl('[.]rds$',index_path))readRDS(index_path)else jsonlite::fromJSON(index_path)
    if(grepl('[.]rds$',index_path))row_indices[[normalizePath(x$raw_path,winslash='/')]]<-x else byte_indices[[normalizePath(x$raw_path,winslash='/')]]<-x
  }
  source(file.path(repo,'06_pipeline/LO_PISA_PARTITION.R'))
  partitions<-lo_pisa_partition_sources(repo,manifest_path,file.path(out,'raw_partitions'))
  previous<-options(lo.pisa.row_indices=row_indices,lo.pisa.byte_indices=byte_indices,lo.pisa.partitions=partitions)
  on.exit(options(previous),add=TRUE)
  errors<-list();checked_hashes<-new.env(parent=emptyenv())
  # The partition stage has just rehashed these exact raw files and every
  # retained partition. Reuse that in-memory proof within this invocation only.
  for(p in names(partitions))assign(p,partitions[[p]]$raw_sha256,checked_hashes)
  for(i in seq_len(nrow(manifest))) {
    r<-manifest[i,];s<-r$survey;y<-as.integer(r$year);country<-r$country
    if(country=='NLD'&&Sys.getenv('LO_FRESH_REPLICATION','')!='1')next
    id<-paste(country,s,y,sep='_');block<-file.path(out,'sources',id)
    dir.create(block,recursive=TRUE,showWarnings=FALSE)
    tryCatch({
      if(!exists(r$raw_path,checked_hashes,inherits=FALSE))assign(r$raw_path,digest::digest(file=r$raw_path,algo='sha256'),checked_hashes)
      if(get(r$raw_path,checked_hashes)!=r$raw_sha256)stop('INTERNATIONAL_RAW_BYTES_CHANGED')
      receipt_path<-file.path(block,'SOURCE_VERIFICATION.json')
      contract_path<-file.path(block,'SOURCE_INPUT_CONTRACT.json')
      if(file.exists(contract_path)) {
        previous_contract<-jsonlite::fromJSON(contract_path)
        if(!identical(previous_contract,as.list(r[required])))stop('INTERNATIONAL_SOURCE_CONTRACT_CHANGED')
      }else jsonlite::write_json(as.list(r[required]),contract_path,auto_unbox=TRUE,pretty=TRUE)
      if(file.exists(receipt_path)) {
        src<-jsonlite::fromJSON(receipt_path)
        canonical<-file.path(block,src$canonical_filename)
        if(src$country!=country||src$survey!=s||as.integer(src$year)!=y||src$raw_sha256!=r$raw_sha256||digest::digest(file=canonical,algo='sha256')!=src$canonical_sha256)
          stop('INTERNATIONAL_SOURCE_CHECKPOINT_CHANGED')
      }else {
        cat('VERIFY_COUNTRY_SOURCE',id,'\n');flush.console()
        if(s=='PISA') {
          v<-if(y>=2015)lo_pisa_verify_source(r$raw_path,NULL,y,r$source_country,block)else
            lo_pisa_prepare_legacy(r$raw_path,r$control_path,y,r$source_country,block)
          # OECD TAP and IEA TWN are Chinese Taipei, an explicit code alias.
          # No other geographical relabelling is permitted here.
          if(country!=r$source_country) {
            if(country!='TWN'||r$source_country!='TAP')stop('UNREVIEWED_PISA_GEOGRAPHIC_ALIAS')
            v$object$meta$v9_country<-country;v$object$meta$source_country_code<-r$source_country
            canonical<-file.path(block,paste0('canonical_',id,'_verified.rds'))
            saveRDS(v$object,canonical,compress=FALSE)
            v$receipt$country<-country;v$receipt$source_country_code<-r$source_country
            v$receipt$canonical_filename<-basename(canonical);v$receipt$canonical_sha256<-digest::digest(file=canonical,algo='sha256')
          }
        }else v<-lo_iea_prepare_books(r$raw_path,s,y,block,country,as.integer(r$source_country),
                 as.integer(strsplit(r$allowed_grades,';',fixed=TRUE)[[1]]),r$population_note,r$population_evidence)
        v$receipt$population_review<-as.list(r[c('population_note','population_evidence')])
        jsonlite::write_json(v$receipt,receipt_path,pretty=TRUE,auto_unbox=TRUE,digits=17)
        src<-v$receipt;canonical<-file.path(block,src$canonical_filename)
        rm(v);gc(FALSE)
      }
      domains<-if(s=='PIRLS')'reading'else if(s=='TIMSS')c('mathematics','science')else if(y==2003)c('reading','mathematics')else c('reading','mathematics','science')
      if(s=='PISA'&&!is.null(src$verified_domains))domains<-src$verified_domains
      prior<-support[support$country==country&support$survey==s&support$year==y,,drop=FALSE]
      coverage_path<-file.path(block,'PV_DOMAIN_COVERAGE.csv')
      if(!nrow(prior)) {
        coverage<-lo_source_pv_coverage(readRDS(canonical),domains)
        write.csv(coverage,coverage_path,row.names=FALSE)
        domains<-coverage$domain[coverage$n_observed>0]
        if(!length(domains)) {
          cat('SOURCE_NO_OBSERVED_DOMAIN_SCORES',id,src$n,'\n');flush.console();next
        }
      }
      x<-support[rep(1L,length(domains)),];x$country<-country;x$survey<-s;x$year<-as.character(y)
      x$age_group<-if(s=='PISA')'age15'else'age10';x$domain<-domains
      x$definition_id<-paste0(s,'_DOMAIN_MEAN');x$population_comparison_id<-if(s=='PISA')'PISA_AGE_TARGET_PUBLIC_USE'else paste0(s,'_GRADE4_COHORT_MAIN_WAVE')
      x$method_comparison_id<-paste0(s,'_LINKED_DOMAIN_SCALE');x$source_path<-normalizePath(canonical,winslash='/')
      x$source_sha256<-src$canonical_sha256;x$status<-'SOURCE_SUPPORT_VERIFIED'
      prior<-support[support$country==country&support$survey==s&support$year==y,,drop=FALSE]
      # Raw bytes, the complete input contract and canonical bytes were checked
      # above. Reuse the original immutable PV/population proof only after all
      # its evidence hashes have been checked; do not rewrite 525 certificates
      # and the full support CSV on every interrupted-run restart.
      if(lo_international_cached_support(prior,x,receipt_path,contract_path)) {
        cat('REUSE_SOURCE_CHECKPOINT',id,src$n,'\n');flush.console();next
      }
      coverage<-lo_source_pv_coverage(readRDS(canonical),domains)
      if(any(coverage$n_observed==0))stop('SOURCE_SUPPORT_WITHOUT_OBSERVED_PVS')
      write.csv(coverage,coverage_path,row.names=FALSE)
      code_files<-file.path(repo,'06_pipeline',c('LO_INTERNATIONAL_SOURCES.R','LO_IEA_SOURCE_BLOCK.R','LO_IEA_BACKGROUND.R','LO_PISA_SOURCE_BLOCK.R','LO_PISA_LEGACY_SOURCE.R'))
      frozen<-vapply(code_files,function(f){p<-file.path(block,paste0('VERIFIER_',substr(digest::digest(file=f,algo='sha256'),1,16),'.R'));if(!file.exists(p))stopifnot(file.copy(f,p));p},character(1))
      ef<-normalizePath(c(receipt_path,contract_path,coverage_path,frozen),winslash='/');cert_path<-file.path(block,'SOURCE_SUPPORT_CERTIFICATE.json')
      cert<-list(status='SOURCE_SUPPORT_VERIFIED',country=country,source_sha256=src$canonical_sha256,
        support_keys=lo_balance_key(x),comparability_evidence=paste(r$population_note,r$population_evidence),
        evidence_files=data.frame(path=ef,sha256=vapply(ef,function(f)digest::digest(file=f,algo='sha256'),character(1))))
      jsonlite::write_json(cert,cert_path,pretty=TRUE,auto_unbox=TRUE,digits=17)
      x$certificate_path<-normalizePath(cert_path,winslash='/');x$certificate_sha256<-digest::digest(file=cert_path,algo='sha256')
      keep<-!(support$country==country&support$survey==s&support$year==y)
      support<-rbind(support[keep,,drop=FALSE],x)
      lo_atomic_csv(support,support_path)
      cat('SOURCE_CHECKPOINT',id,src$n,'\n');flush.console()
    },error=function(e){
      errors[[length(errors)+1L]]<<-data.frame(country=country,survey=s,year=y,reason=conditionMessage(e))
      lo_atomic_csv(do.call(rbind,errors),file.path(out,'SOURCE_REPAIRS_REQUIRED.csv'))
      cat('SOURCE_REPAIR_REQUIRED',id,conditionMessage(e),'\n');flush.console()
    })
  }
  repairs<-if(length(errors))do.call(rbind,errors)else
    data.frame(country=character(),survey=character(),year=integer(),reason=character())
  lo_atomic_csv(repairs,file.path(out,'SOURCE_REPAIRS_REQUIRED.csv'))
  invisible(list(support=support,errors=errors))
}
