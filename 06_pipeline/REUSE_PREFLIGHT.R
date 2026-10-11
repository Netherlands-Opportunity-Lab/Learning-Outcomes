# Pre-execution reuse guard. Fail closed until metric-level decisions are independently verified.
lo_reuse_preflight <- function(bundle,scope="nld_plus_19",enforce=FALSE) {
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  base <- file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation")
  taskfile <- file.path(bundle,"engine","TASKS.csv")
  queuefile <- file.path(base,"CONTRACT_LEVEL_REUSE_AND_COMPUTE_QUEUE.csv")
  if(!file.exists(queuefile))stop("REUSE_PREFLIGHT_HOLD: contract queue missing; run next-batch")
  tasks <- read.csv(taskfile,stringsAsFactors=FALSE,colClasses="character")
  q <- read.csv(queuefile,stringsAsFactors=FALSE,colClasses="character")
  if(anyDuplicated(tasks$metric_key)||anyDuplicated(q$metric_key)||
     !setequal(tasks$metric_key,q$metric_key))
    stop("REUSE_PREFLIGHT_HOLD: task/queue identity mismatch")
  if(!all(c("metric_key","scientific_action","release_status")%in%names(q)))
    stop("REUSE_PREFLIGHT_HOLD: missing queue fields")
  members <- read.csv(file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"),
                      stringsAsFactors=FALSE,colClasses="character")
  foreign <- setdiff(members$country[members$strictly_above_czechia=="TRUE"],"NLD")
  selected <- switch(scope,nld_only=tasks$country=="NLD",
    reference_19=tasks$country%in%foreign,
    nld_plus_19=tasks$country=="NLD"|tasks$country%in%foreign,
    other=!(tasks$country=="NLD"|tasks$country%in%foreign),
    all=rep(TRUE,nrow(tasks)),stop("Unknown scope"))
  selected_keys <- tasks$metric_key[selected]
  z <- q[match(selected_keys,q$metric_key),,drop=FALSE]
  # Only explicit audited release decisions can permit execution.
  # A matching metric_key, candidate cache, or VERIFIED_SNAPSHOTS is insufficient.
  approvals <- file.path(base,"SCIENTIFIC_REUSE_EXECUTION_APPROVALS.csv")
  approved <- if(file.exists(approvals))
    read.csv(approvals,stringsAsFactors=FALSE,colClasses="character") else data.frame()
  required <- c("metric_key","decision","input_fingerprint",
    "specification_fingerprint","code_fingerprint","result_hash",
    "validation_status")
  if(!all(required%in%names(approved)))approved <- data.frame()
  if(nrow(approved)&&anyDuplicated(approved$metric_key))
    stop("REUSE_PREFLIGHT_HOLD: duplicate approval metric keys")
  valid <- if(nrow(approved)) {
    ix <- match(z$metric_key,approved$metric_key)
    v <- approved[ix,,drop=FALSE]
    fingerprint_ok <- Reduce(`&`,lapply(
      c("input_fingerprint","specification_fingerprint",
        "code_fingerprint","result_hash"),function(k)
        !is.na(v[[k]])&grepl("^[a-fA-F0-9]{64}$",v[[k]])))
    !is.na(v$decision)&v$decision%in%c("REUSE_VERIFIED","DERIVE_VERIFIED","COMPUTE_REQUIRED")&
      v$validation_status=="PASS"&fingerprint_ok
  } else rep(FALSE,nrow(z))
  z$execution_decision <- rep("HOLD",nrow(z))
  if(any(valid)) z$execution_decision[valid] <-
    approved$decision[match(z$metric_key[valid],approved$metric_key)]
  z$preflight_reason <- ifelse(valid,"APPROVED_FINGERPRINTED_DECISION",
    ifelse(z$scientific_action=="ADJUDICATE_CONFLICT",
      "HISTORICAL_CONFLICT_NOT_ADJUDICATED",
      ifelse(z$scientific_action=="VALIDATE_EXISTING_RESULT",
        "CANDIDATE_NOT_SCIENTIFICALLY_VALIDATED",
        "HISTORICAL_CACHE_SEARCH_NOT_PROVEN_COMPLETE")))
  dir.create(base,recursive=TRUE,showWarnings=FALSE)
  report <- file.path(base,"EXECUTION_REUSE_PREFLIGHT.csv")
  write.csv(z[,c("metric_key","scientific_action","execution_decision","preflight_reason")],
            report,row.names=FALSE)
  summary <- as.data.frame(table(z$execution_decision),stringsAsFactors=FALSE)
  names(summary) <- c("decision","contracts")
  write.csv(summary,file.path(base,"EXECUTION_REUSE_PREFLIGHT_COUNTS.csv"),row.names=FALSE)
  cat("REUSE_PREFLIGHT: ",nrow(z)," selected contracts; ",
      sum(valid)," independently approved; ",sum(!valid)," HOLD.\n",sep="")
  if(!all(valid) && isTRUE(enforce))stop("EXECUTION_BLOCKED_TO_PREVENT_DUPLICATE_CALCULATION: ",
    sum(!valid)," selected contracts lack verified reuse/derive/compute decisions. ",
    "See ",report)
  # A verified decision list is not yet a proven selective execution adapter.
  if(isTRUE(enforce))
    stop("EXECUTION_BLOCKED: verified per-metric skip/compute adapter has not passed parity testing")
  cat("READ_ONLY_PREFLIGHT_COMPLETE: no calculations started.\n")
  invisible(summary)
}
