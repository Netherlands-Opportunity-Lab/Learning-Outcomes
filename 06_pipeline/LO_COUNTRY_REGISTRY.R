# Source coverage selects work; validated result coverage permits publication.
# Neither historical country lists nor AVAILABLE labels establish eligibility.
lo_empty_support <- function() {
  cols<-unique(c(lo_balance_columns(),"country","source_path","source_sha256",
    "certificate_path","certificate_sha256","status"))
  as.data.frame(setNames(rep(list(character()),length(cols)),cols),stringsAsFactors=FALSE)
}
lo_read_source_support <- function(path,repo=NULL) {
  if(!file.exists(path))return(lo_empty_support())
  x<-read.csv(path,colClasses="character",stringsAsFactors=FALSE,
             check.names=FALSE,na.strings=character())
  if(!all(names(lo_empty_support())%in%names(x)))stop("SOURCE_SUPPORT_SCHEMA_INVALID")
  lo_balance_key(x)
  if(anyNA(x$country)||any(!grepl("^[A-Z0-9]{3}$",x$country)))stop("SOURCE_SUPPORT_COUNTRY_INVALID")
  verified<-x[x$status=="SOURCE_SUPPORT_VERIFIED",,drop=FALSE]
  checked<-new.env(parent=emptyenv())
  for(i in seq_len(nrow(verified))) {
    row<-verified[i,,drop=FALSE]
    for(pair in list(c("source_path","source_sha256"),c("certificate_path","certificate_sha256"))) {
      path<-row[[pair[1]]];hash<-row[[pair[2]]]
      key<-paste(path,hash)
      if(!exists(key,checked,inherits=FALSE)) {
        if(!file.exists(path)||!grepl("^[a-f0-9]{64}$",hash)||
           digest::digest(file=path,algo="sha256")!=hash)stop("SOURCE_SUPPORT_CHANGED_BYTES")
        assign(key,TRUE,checked)
      }
    }
    cert<-jsonlite::fromJSON(row$certificate_path,simplifyVector=TRUE)
    if(!identical(cert$status,"SOURCE_SUPPORT_VERIFIED") ||
       !identical(cert$source_sha256,row$source_sha256) ||
       !identical(cert$country,row$country) ||
       !lo_balance_key(row)%in%cert$support_keys ||
       is.null(cert$comparability_evidence) || !nzchar(cert$comparability_evidence))
      stop("SOURCE_SUPPORT_CERTIFICATE_MISMATCH")
    if(!is.data.frame(cert$evidence_files) || !nrow(cert$evidence_files) ||
       !all(c("path","sha256")%in%names(cert$evidence_files)))
      stop("SOURCE_SUPPORT_EVIDENCE_REQUIRED")
    for(j in seq_len(nrow(cert$evidence_files))) {
      p<-cert$evidence_files$path[j];h<-cert$evidence_files$sha256[j]
      key<-paste(p,h)
      if(!exists(key,checked,inherits=FALSE)) {
        if(!file.exists(p)||!grepl("^[a-f0-9]{64}$",h)||
           digest::digest(file=p,algo="sha256")!=h)stop("SOURCE_SUPPORT_EVIDENCE_CHANGED")
        assign(key,TRUE,checked)
      }
    }
  }
  if(anyDuplicated(paste(verified$country,lo_balance_key(verified))))
    stop("SOURCE_SUPPORT_DUPLICATE_EDITION")
  if(!is.null(repo)) {
    source(file.path(repo,'06_pipeline/LO_POPULATION_REVIEW.R'),local=environment())
    verified<-lo_population_filter_support(verified,lo_population_review(repo))
  }
  verified
}
lo_runtime_scope <- function(bundle,tasks,scope,source_support) {
  scope<-match.arg(scope,c("nld_only","nld_plus_19","all_required"))
  pool<-read.csv(file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"),
    colClasses="character",stringsAsFactors=FALSE)
  if(!all(c("country","strictly_above_czechia")%in%names(pool)))stop("CANDIDATE_POOL_SCHEMA")
  rich<-sort(unique(pool$country[toupper(pool$strictly_above_czechia)=="TRUE"]))
  if(!"NLD"%in%rich || any(!grepl("^[A-Z0-9]{3}$",rich)))stop("CANDIDATE_POOL_IDENTITY")
  # All observed contract countries are reviewed, including outside COMMON42.
  candidates<-sort(unique(c(tasks$country,rich,source_support$country)))
  admission<-lo_support_eligibility(source_support,candidates)
  eligible<-admission$countries$country[admission$countries$dashboard_eligible]
  selected<-switch(scope,nld_only="NLD",nld_plus_19=union("NLD",intersect(rich,eligible)),
                   all_required=union("NLD",eligible))
  countries<-admission$countries
  countries$rich_candidate<-countries$country%in%rich
  countries$selected_for_production<-countries$country%in%selected
  countries$country_name_nl<-countries$country;countries$country_name_en<-countries$country
  legacy<-file.path(bundle,"COMMON42_REGISTER.csv")
  if(file.exists(legacy)) {
    labels<-read.csv(legacy,colClasses="character",stringsAsFactors=FALSE)
    idx<-match(countries$country,labels$route_code)
    for(lang in c("nl","en")) {
      col<-paste0("country_name_",lang)
      if(col%in%names(labels))countries[[col]][!is.na(idx)]<-labels[[col]][idx[!is.na(idx)]]
    }
  }
  countries$eligibility_basis<-ifelse(countries$country%in%eligible,
    "SHA_VERIFIED_SOURCE_SUPPORT",ifelse(countries$country%in%source_support$country,
    "VERIFIED_SUPPORT_INCOMPLETE", "SOURCE_SUPPORT_NOT_YET_VERIFIED"))
  list(scope=scope,selected=sort(unique(selected)),dashboard=sort(intersect(selected,eligible)),
    comparator=rich,foreign_reference=setdiff(rich,"NLD"),
    additional_reference=setdiff(rich,eligible),countries=countries,cycle_detail=admission$detail,
    source_support=source_support,reference_candidates=sort(eligible),membership_policy="FULL_FOCUS_SUPPORT_6x3")
}

lo_country_production_approval <- function(repo,countries,eligible=character()) {
  if(!length(setdiff(countries,"NLD")))return(invisible(TRUE))
  p<-file.path(repo,"06_pipeline","COUNTRY_PRODUCTION_APPROVALS.csv")
  if(!file.exists(p))stop("COUNTRY_LIST_HUMAN_DECISION_REQUIRED")
  x<-read.csv(p,colClasses="character",na.strings=character())
  if(!all(c("country","status","decision_date","user_evidence")%in%names(x)) ||
     anyDuplicated(x$country))stop("COUNTRY_DECISION_INVALID")
  yes<-x$country[x$status=="APPROVED" & nzchar(x$user_evidence) &
    grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",x$decision_date)]
  # Direct human decision 2026-10-15: all countries under the existing rules.
  # The policy authorizes only the already source-certified eligible set;
  # it is never a wildcard that makes an unverified country eligible.
  if("ALL_SOURCE_ELIGIBLE"%in%yes)yes<-union(yes,eligible)
  if(!all(countries%in%yes))stop("COUNTRY_LIST_HUMAN_DECISION_REQUIRED")
  invisible(TRUE)
}
lo_runtime_scope_evidence <- function(info,out) {
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  write.csv(info$countries,file.path(out,"COUNTRY_SOURCE_ELIGIBILITY.csv"),row.names=FALSE)
  write.csv(info$cycle_detail,file.path(out,"COUNTRY_CYCLE_COUNTS.csv"),row.names=FALSE)
  invisible(info$countries)
}
# A display slice never changes the baseline gate. Each comparison adds the
# union of its approved subgroup/peer support to the complete focus core.
lo_focus_required_support <- function(core,comparison,focus,nld_anchor=NULL) {
  base<-core[core$country==focus,,drop=FALSE]
  if(!nrow(base))stop("FOCUS_CORE_ANCHOR_EMPTY")
  if(focus=="NLD") {
    if(is.null(nld_anchor))stop("NLD_DECK_ANCHOR_REQUIRED")
    expected<-unlist(lapply(seq_len(nrow(nld_anchor)),function(i)
      paste(nld_anchor$survey[i],nld_anchor$age_group[i],nld_anchor$domain[i],
        strsplit(nld_anchor$years[i],";",fixed=TRUE)[[1]],sep="|")))
    actual<-paste(base$survey,base$age_group,base$domain,base$year,sep="|")
    if(!all(expected%in%actual))stop("NLD_CORE_ANCHOR_INCOMPLETE")
  }
  cols<-lo_balance_columns()
  unique(rbind(base[cols],comparison[cols]))
}
