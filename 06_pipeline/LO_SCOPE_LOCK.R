# Fixed production scope: NLD / NLD+19 / union of COMMON42 and 19.
# No scope expands silently to 91 historical systems.
lo_locked_scope <- function(bundle, scope=c("nld_only","nld_plus_19","all_required")) {
  scope <- match.arg(scope)
  read <- function(f) {
    p <- file.path(bundle,f)
    if(!file.exists(p)) stop("SCOPE_LOCK_HOLD: required file missing: ",f)
    read.csv(p,colClasses="character",stringsAsFactors=FALSE,check.names=FALSE)
  }
  c42 <- read("COMMON42_REGISTER.csv")
  cmp <- read("PPP_COMPARATOR_MEMBERSHIP_v2.csv")
  stopifnot(all(c("route_code","common42_member")%in%names(c42)),
            all(c("country","strictly_above_czechia")%in%names(cmp)))
  dashboard <- unique(as.character(c42$route_code[toupper(c42$common42_member)=="TRUE"]))
  comparator <- unique(as.character(cmp$country[toupper(cmp$strictly_above_czechia)=="TRUE"]))
  if(length(dashboard)!=42L || length(comparator)!=20L ||
     !("NLD"%in%dashboard) || !("NLD"%in%comparator) ||
     length(setdiff(comparator,"NLD"))!=19L ||
     length(union(dashboard,comparator))!=50L ||
     anyNA(c(dashboard,comparator)) ||
     any(!grepl("^[A-Z0-9]{3}$",c(dashboard,comparator))))
    stop("SCOPE_LOCK_HOLD: 42/20/50 membership has changed")
  selected <- switch(scope,nld_only="NLD",nld_plus_19=comparator,
                     all_required=union(dashboard,comparator))
  list(scope=scope,selected=sort(unique(selected)),dashboard=sort(dashboard),
       comparator=sort(comparator),
       foreign_reference=sort(setdiff(comparator,"NLD")),
       additional_reference=sort(setdiff(comparator,dashboard)))
}
lo_scope_filter_tasks <- function(tasks,scope_info) {
  req <- c("metric_key","country","survey","year","module")
  if(!all(req%in%names(tasks))||anyDuplicated(tasks$metric_key))
    stop("SCOPE_CONTRACT_HOLD: duplicate or incomplete task keys")
  tasks[tasks$country%in%scope_info$selected,,drop=FALSE]
}
lo_scope_write_evidence <- function(scope_info,tasks,out) {
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  roles <- data.frame(country=scope_info$selected,
       is_dashboard=scope_info$selected%in%scope_info$dashboard,
       is_reference=scope_info$selected%in%scope_info$comparator,
       stringsAsFactors=FALSE)
  write.csv(roles,file.path(out,"PRIVATE_COUNTRY_MEMBERSHIP.csv"),row.names=FALSE)
  z <- aggregate(list(n=rep(1L,nrow(tasks))),
     tasks[c("survey","country","module")],sum)
  write.csv(z,file.path(out,"PRIVATE_COUNTRY_MODULE_TASK_COUNTS.csv"),row.names=FALSE)
  summary <- data.frame(scope=scope_info$scope,
    countries=length(scope_info$selected),
    dashboard_members=sum(roles$is_dashboard),
    comparator_members=sum(roles$is_reference),
    selected_primitive_contracts=nrow(tasks),
    publication_status="NOT_RELEASED",stringsAsFactors=FALSE)
  write.csv(summary,file.path(out,"SCOPE_SELECTION_SUMMARY.csv"),row.names=FALSE)
  summary
}
