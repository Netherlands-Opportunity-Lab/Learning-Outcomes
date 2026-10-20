# Cache adjudication by actual scientific columns, never by newest file/size.
# Catalog documented historical cache roots. Never discover source identity from mtime alone.
lo4_roots <- function(project) {
  rel<-c("27_dashboard_multicountry_v9/cache", "26_dashboard_fast_resumable/cache",
    "23_slide_only_completion/cache", "22_completion_final_v8/cache",
    "20_rc2_domains/cache", "21_completion_repair_v7/cache",
    "29_results_resume_v11/cache", "28_results_resume_v10/cache",
    "15_rc1_pisa_normalised/standardised_extracts", "05_pirls_results/all_available_cell_cache_v1")
  p<-file.path(project,rel)
  unique(p[dir.exists(p)])
}
lo4_cache_candidates <- function(project,survey,year,country) {
  # A canonical cache is not the same as a result-level RDS or a standardised extract.
  nm<-sprintf("canonical_%s_%s_%s.rds",survey,year,country)
  roots<-lo4_roots(project)
  # V11 bevat aantoonbaar NL 2003 en 2009; LO06 Windows-retour 2026-10-10.
  # Maak geen onderscheid op mapouderdom: toets iedere canonical inhoudelijk.
  roots<-roots[!grepl("all_available_cell_cache_v1|standardised_extracts",roots)]
  if(!length(roots))return(character())
  found<-unique(unlist(lapply(roots,function(r)
    list.files(r,pattern=paste0("^",nm,"$"),recursive=TRUE,full.names=TRUE,ignore.case=TRUE)),use.names=FALSE))
  sort(found[file.exists(found)])
}
lo4_known_cache_inventory <- function(project,scope_countries) {
  roots<-lo4_roots(project)
  if(!length(roots))return(data.frame(root=character(),path=character(),type=character(),bytes=numeric(),mtime=character()))
  out<-list()
  for(r in roots) {
    # Filename/metadata inventory only.  No large RDS content is read here.
    f<-list.files(r,recursive=TRUE,full.names=TRUE,pattern="\\.(rds|csv|parquet)$",ignore.case=TRUE)
    if(!length(f))next
    b<-basename(f)
    canonical<-grepl("^canonical_(PISA|PIRLS|TIMSS)_",b,ignore.case=TRUE)
    resultcache<-grepl("all_available_cell_cache|results_resume",r,ignore.case=TRUE)
    standard<-grepl("STANDARDISED",b,ignore.case=TRUE)
    label<-ifelse(canonical,"CANONICAL",ifelse(standard,"STANDARDISED",ifelse(resultcache,"TASK_OR_RESULT_CACHE","OTHER_CACHE")))
    # Focus on documented source roots; retain all filenames for provenance, not just NL.
    info<-file.info(f)
    out[[length(out)+1L]]<-data.frame(root=lo4_norm(r),path=lo4_norm(f),type=label,
      bytes=as.numeric(info$size),mtime=as.character(info$mtime),stringsAsFactors=FALSE)
  }
  if(!length(out))return(data.frame(root=character(),path=character(),type=character(),bytes=numeric(),mtime=character()))
  do.call(rbind,out)
}
lo4_pv_fields <- function(d,domain) {
  prefix<-switch(domain,reading="PV_READ_",mathematics="PV_MATH_",science="PV_SCIE_",all="",stop("Unknown domain"))
  if(!nzchar(prefix))return(character())
  grep(paste0("^",prefix),names(d),value=TRUE)
}
lo4_required_science_fields <- function(obj,task) {
  d<-obj$data
  m<-unique(task$module);if(length(m)!=1L)stop("Module projection not unique")
  domains<-unique(task$domain)
  if(!is.data.frame(d)||!nrow(d)||!"W"%in%names(d))stop("INVALID_CANONICAL_DATA_OR_WEIGHTS")
  need<-"W"
  rw<-grep("^RW[0-9]+$",names(d),value=TRUE)
  # Also include JRR keys if the engine builds replicate weights from design identifiers.
  design<-intersect(c("JKZONE","JKREP","JKSTRAT","JKPAIR","STRATUM","PSU"),names(d))
  need<-c(need,rw,design)
  for(domain in setdiff(domains,"all")){
    pv<-lo4_pv_fields(d,domain)
    if(!length(pv))stop("PVs ontbreken voor ",domain)
    need<-c(need,pv)
  }
  if(m%in%c("gender"))need<-c(need,"DEMO_GENDER")
  if(m%in%c("ses_national","ses_peer_exposure"))need<-c(need,"SES")
  if(m%in%c("ses_harmonized"))need<-c(need,"SES","SOURCE_STUDENT_ID")
  if(m%in%c("language_exact","language_frequency","language_frequency_binary",
              "home_language_peer_exposure","home_language_frequency_peer"))need<-c(need,"DEMO_LANGUAGE","TEST_LANGUAGE")
  if(m%in%c("migration","migration_generation","migration_binary_peer","migration_peer_exposure"))
    need<-c(need,"DEMO_MIGRATION","MOTHER_BORN_HERE","FATHER_BORN_HERE")
  if(m%in%c("ses_peer_exposure","home_language_peer_exposure","home_language_frequency_peer",
              "migration_binary_peer","migration_peer_exposure","high_proficiency_peer_exposure","peer_baseline")){
    need<-c(need,"SCHOOL")
    if(any(task$peer_definition=="direct_learning_environment")){
      need<-c(need,if(obj$meta$survey=="PISA")"PROGRAM" else "CLASS")
    }
    if(m%in%c("peer_baseline","ses_peer_exposure"))need<-c(need,"SES","DEMO_LANGUAGE","DEMO_MIGRATION")
  }
  # Birthplace is required for *nl_one_parent_abroad*, not necessarily binary OECD migration.
  if(any(task$definition=="nl_one_parent_abroad"))need<-c(need,"MOTHER_BORN_HERE","FATHER_BORN_HERE")
  need<-unique(need)
  missing<-setdiff(need,names(d))
  # Do not force optional demographic columns for OECD binary if canonical migration is explicit.
  if(m%in%c("migration","migration_binary_peer","migration_generation","migration_peer_exposure") &&
     !any(task$definition=="nl_one_parent_abroad") && "DEMO_MIGRATION"%in%names(d))
    missing<-setdiff(missing,c("MOTHER_BORN_HERE","FATHER_BORN_HERE"))
  if(length(missing))stop("CANONICAL_MISSING_USED_FIELDS: ",paste(missing,collapse=","))
  intersect(need,names(d))
}
lo4_projection <- function(obj,task) {
  if(!is.list(obj)||!is.data.frame(obj$data)||!is.list(obj$meta))stop("INVALID_CANONICAL")
  if(!identical(as.character(obj$meta$survey),task$survey[1]) ||
     !identical(as.character(obj$meta$year),task$year[1]))stop("CANONICAL_SURVEY_YEAR_MISMATCH")
  if(!is.null(obj$meta$v9_country) && nzchar(as.character(obj$meta$v9_country)) &&
     !identical(as.character(obj$meta$v9_country),task$country[1]))stop("CANONICAL_COUNTRY_MISMATCH")
  fields<-lo4_required_science_fields(obj,task)
  # Digest serialization is faster and less memory-hungry than pasting every row.
  hashes<-vapply(fields,function(f)lo4_hash(obj$data[[f]]),character(1))
  lo4_hash(list(schema="LO04_science_columns_v1",country=task$country[1],survey=task$survey[1],
                year=task$year[1],module=task$module[1],domains=sort(unique(task$domain)),
                definitions=sort(unique(task$definition)),peer=sort(unique(task$peer_definition)),
                fields=hashes,n=nrow(obj$data)))
}
lo4_cache_audit <- function(project,plan,deep=FALSE) {
  q<-plan[plan$country=="NLD" & plan$survey=="PISA",,drop=FALSE]
  years<-sort(unique(as.integer(q$year)))
  out<-list()
  for(y in years){
    p<-lo4_cache_candidates(project,"PISA",y,"NLD")
    if(!length(p)){
      out[[length(out)+1L]]<-data.frame(year=y,survey="PISA",path="",bytes=NA_real_,sha256="",
        comparison="ABSENT_IN_KNOWN_CANONICAL_ROOTS",module="",input_projection_hash="",reason="Look for standardised extracts; not interchangeable without rebuilding and validating canonical")
      next
    }
    info<-file.info(p);hash<-vapply(p,lo4_filehash,character(1))
    rows<-lapply(seq_along(p),function(i)data.frame(year=y,survey="PISA",path=lo4_norm(p[i]),bytes=as.numeric(info$size[i]),
      sha256=hash[i],comparison=if(length(unique(hash))==1L)"EXACT_FILE_DUPLICATE" else "DIFFERENT_BYTES_CHECK_SCIENCE_FIELDS",
      module="",input_projection_hash="",reason="Byte-level evidence only",stringsAsFactors=FALSE))
    if(deep){
      units<-split(seq_len(nrow(q[q$year==as.character(y),,drop=FALSE])),q$module[q$year==as.character(y)])
      subset<-q[q$year==as.character(y),,drop=FALSE]
      hashes_for_modules<-list()
      for(i in seq_along(p)){
        obj<-tryCatch(readRDS(p[i]),error=function(e)e)
        for(mod in names(units)){
          index<-units[[mod]];t<-subset[index,,drop=FALSE]
          # A single country/year/module can involve multiple domains; projection includes all requested domains.
          h<-if(inherits(obj,"error"))paste0("READ_ERROR: ",conditionMessage(obj)) else
            tryCatch(lo4_projection(obj,t),error=function(e)paste0("PROJECTION_HOLD: ",conditionMessage(e)))
          hashes_for_modules[[paste(i,mod,sep="::")]]<-h
          rows[[length(rows)+1L]]<-data.frame(year=y,survey="PISA",path=lo4_norm(p[i]),bytes=as.numeric(info$size[i]),
           sha256=hash[i],comparison="PENDING_CROSS_CANDIDATE_COMPARISON",module=mod,input_projection_hash=h,reason="" )
        }
      }
      if(length(p)>1L){
        for(mod in names(units)){
          h<-vapply(seq_along(p),function(i)hashes_for_modules[[paste(i,mod,sep="::")]],character(1))
          status<-if(any(grepl("^READ_ERROR:|^PROJECTION_HOLD:",h)))"REQUIRES_SOURCE_REPAIR" else
            if(length(unique(h))==1L)"SCIENTIFIC_INPUT_PROJECTION_EQUIVALENT" else "SCIENTIFIC_INPUT_CONFLICT_HOLD"
          for(i in seq_along(rows))if(rows[[i]]$year==y&&identical(rows[[i]]$module,mod))rows[[i]]$comparison<-status
        }
      } else {
        for(i in seq_along(rows))if(rows[[i]]$year==y&&nzchar(rows[[i]]$module))
          rows[[i]]$comparison<-if(grepl("^PROJECTION_HOLD:|^READ_ERROR:",rows[[i]]$input_projection_hash))"REQUIRES_SOURCE_REPAIR" else "SINGLE_CANDIDATE_PROJECTION_TESTED"
      }
    }
    out<-c(out,rows)
  }
  if(!length(out))return(data.frame())
  do.call(rbind,out)
}
lo4_legacy_standardised_paths <- function(project) {
  p<-file.path(project,"15_rc1_pisa_normalised","standardised_extracts")
  if(!dir.exists(p))return(data.frame())
  z<-list.files(p,pattern="^PISA_[0-9]{4}_RC1_STANDARDISED\\.rds$",full.names=TRUE)
  if(!length(z))return(data.frame())
  data.frame(path=lo4_norm(z),bytes=as.numeric(file.info(z)$size),
    status="HISTORIC_STANDARDISED_EXTRACT_REQUIRES_CANONICAL_TRANSFORMATION_NOT_DIRECT_CACHE")
}
