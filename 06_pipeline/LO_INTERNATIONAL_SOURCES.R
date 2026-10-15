# Audit-stage library. Reads only explicitly configured, hash-pinned public-use
# sources. No analysis estimates, downloads, countries or source substitutions
# are inferred from filenames. Manifest paths and extracts remain private.
lo_international_sources <- function(repo,root,manifest_path) {
  for(f in c('LO_ATOMIC_CHECKPOINT.R','LO_IEA_SOURCE_BLOCK.R','LO_IEA_BACKGROUND.R',
             'LO_PISA_SOURCE_BLOCK.R','LO_PISA_LEGACY_SOURCE.R','LO_BALANCED_MEMBERSHIP.R'))source(file.path(repo,'06_pipeline',f))
  manifest<-read.csv(manifest_path,colClasses='character',na.strings=character())
  required<-c('country','survey','year','raw_path','raw_sha256','source_country','control_path','index_path','allowed_grades','population_note','population_evidence')
  stopifnot(all(required%in%names(manifest)),!anyDuplicated(manifest[c('country','survey','year')]))
  master<-file.path(root,'master_reconciliation');out<-file.path(root,'international')
  support_path<-file.path(master,'SOURCE_SUPPORT_CONTRACTS.csv')
  support<-read.csv(support_path,colClasses='character',na.strings=character())
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
  for(i in seq_len(nrow(manifest))) {
    r<-manifest[i,];s<-r$survey;y<-as.integer(r$year);country<-r$country
    if(country=='NLD')next
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
        if(src$country!=country||src$raw_sha256!=r$raw_sha256||digest::digest(file=canonical,algo='sha256')!=src$canonical_sha256)
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
        # No partial PV pool is certified as core coverage.
        pv<-grep('^PV_',names(v$object$data),value=TRUE)
        if(!length(pv)||any(!is.finite(as.matrix(v$object$data[pv]))))stop('INTERNATIONAL_INCOMPLETE_PVS')
        rm(v);gc(FALSE)
      }
      check_obj<-readRDS(canonical);pv<-grep('^PV_',names(check_obj$data),value=TRUE)
      if(!length(pv)||any(!is.finite(as.matrix(check_obj$data[pv]))))stop('INTERNATIONAL_INCOMPLETE_PVS')
      rm(check_obj)
      domains<-if(s=='PIRLS')'reading'else if(s=='TIMSS')c('mathematics','science')else if(y==2003)c('reading','mathematics')else c('reading','mathematics','science')
      if(s=='PISA'&&!is.null(src$verified_domains))domains<-src$verified_domains
      x<-support[rep(1L,length(domains)),];x$country<-country;x$survey<-s;x$year<-as.character(y)
      x$age_group<-if(s=='PISA')'age15'else'age10';x$domain<-domains
      x$definition_id<-paste0(s,'_DOMAIN_MEAN');x$population_comparison_id<-if(s=='PISA')'PISA_AGE_TARGET_PUBLIC_USE'else paste0(s,'_GRADE4_COHORT_MAIN_WAVE')
      x$method_comparison_id<-paste0(s,'_LINKED_DOMAIN_SCALE');x$source_path<-normalizePath(canonical,winslash='/')
      x$source_sha256<-src$canonical_sha256;x$status<-'SOURCE_SUPPORT_VERIFIED'
      code_files<-file.path(repo,'06_pipeline',c('LO_INTERNATIONAL_SOURCES.R','LO_IEA_SOURCE_BLOCK.R','LO_IEA_BACKGROUND.R','LO_PISA_SOURCE_BLOCK.R','LO_PISA_LEGACY_SOURCE.R'))
      frozen<-vapply(code_files,function(f){p<-file.path(block,paste0('VERIFIER_',substr(digest::digest(file=f,algo='sha256'),1,16),'.R'));if(!file.exists(p))stopifnot(file.copy(f,p));p},character(1))
      ef<-normalizePath(c(receipt_path,contract_path,frozen),winslash='/');cert_path<-file.path(block,'SOURCE_SUPPORT_CERTIFICATE.json')
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
  invisible(list(support=support,errors=errors))
}
