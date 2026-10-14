# Content approval is separate from method certification and scientific release.
# The CSV records direct human decisions; old source decks and generated task
# contracts do not approve an optional analysis. No data or files are written.
lo_validate_scope_decisions <- function(decisions) {
  required <- c("approval_id","title","status","decision_date","user_evidence")
  if(!is.data.frame(decisions) || !all(required%in%names(decisions)) ||
     anyNA(decisions[required]) || anyDuplicated(decisions$approval_id) ||
     !setequal(decisions$approval_id,sprintf("A%02d",1:17)) ||
     any(!decisions$status%in%c("PENDING","APPROVED","REJECTED","DEFERRED")))
    stop("SCOPE_DECISION_INVALID: expected distinct A01-A17 decisions")
  final <- decisions$status!="PENDING"
  if(any(final & (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",decisions$decision_date) |
                  !nzchar(trimws(decisions$user_evidence)))))
    stop("SCOPE_DECISION_INVALID: human decision date/evidence missing")
  invisible(decisions)
}

lo_read_scope_decisions <- function(repo) {
  path <- file.path(repo,"06_pipeline","SCOPE_APPROVALS.csv")
  if(!file.exists(path))stop("SCOPE_DECISION_MISSING: ",path)
  x <- read.csv(path,colClasses="character",stringsAsFactors=FALSE,
                check.names=FALSE,na.strings=character())
  lo_validate_scope_decisions(x)
  x
}

lo_scope_is_approved <- function(decisions,id) {
  if(length(id)!=1L || is.na(id) || !id%in%sprintf("A%02d",1:17))
    stop("SCOPE_DECISION_UNKNOWN_ID")
  # Absence of a recorded decision cannot authorize new content.
  if(is.null(decisions))return(FALSE)
  lo_validate_scope_decisions(decisions)
  identical(decisions$status[match(id,decisions$approval_id)],"APPROVED")
}

lo_scoped_low_peer_tasks <- function(tasks,decisions=NULL) {
  if(!lo_scope_is_approved(decisions,"A01"))
    return(tasks[FALSE,,drop=FALSE])
  if(!exists("lo_grid_new_low_peer_tasks",mode="function"))
    stop("SCOPE_DECISION_MISSING_PEER_CONTRACT_BUILDER")
  # A scope yes permits specifying targets, never automatic compute/release.
  lo_grid_new_low_peer_tasks(tasks)
}

# This is the shared primitive scope gate used by audit, execution and export.
# A09 ranks are approved derived products, never additional pupil-level tasks.
# Their selected certified parents and balanced panel are recorded separately.
lo_scope_active_tasks <- function(tasks,decisions=NULL) {
  family<-sub("_age.*$","",tasks$contract_figure_id)
  keep<-!family%in%c("TR_BASIC","TR_POSITION")
  keep[family=="GP_SES_HIGH"]<-lo_scope_is_approved(decisions,"A02")
  low<-tasks$module=="peer_below_basic"
  keep[family=="EN_PERFORMANCE_PEER" & low]<-lo_scope_is_approved(decisions,"A01")
  keep[family=="EN_PERFORMANCE_PEER" & !low]<-lo_scope_is_approved(decisions,"A03")
  extension_ids<-c(extension_home_ses="A04",extension_ses_gender="A06",
    extension_performance_school="A11",extension_performance_class="A12",
    extension_ses_school="A13",extension_ses_class="A14")
  for(m in names(extension_ids))keep[tasks$module==m]<-lo_scope_is_approved(decisions,extension_ids[[m]])
  keep[tasks$module=="extension_ses_gender" & tasks$stat=="high"]<-
    lo_scope_is_approved(decisions,"A06") && lo_scope_is_approved(decisions,"A02")
  tasks[keep,,drop=FALSE]
}
