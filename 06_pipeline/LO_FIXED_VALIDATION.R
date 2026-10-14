# Final scientific acceptance: no automatic promotion from old source/metric.
lo_final_quality_gate <- function(bundle, tasks, approval_csv, out,
                                  scope_decisions=NULL) {
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  family <- sub("_age.*$","",tasks$contract_figure_id)
  active <- !(family %in% c("TR_BASIC","TR_POSITION","GP_SES_HIGH","EN_PERFORMANCE_PEER"))
  required <- tasks[active,,drop=FALSE]
  if(!is.null(scope_decisions)) {
    required<-lo_scope_active_tasks(tasks,scope_decisions)
    required<-required[required$module!="peer_below_basic",,drop=FALSE]
  }
  req_ids <- unique(required$metric_key)
  unavailable_ids<-character()
  if(exists("lo_extension_availability",mode="function")) {
    unavailable<-lo_extension_availability(required)
    unavailable<-unavailable[unavailable$status%in%c("OFFICIAL_SCALE_NOT_IN_EARLIER_CYCLE",
      "UNAVAILABLE_HOME_QUESTIONNAIRE_NOT_ADMINISTERED"),,drop=FALSE]
    idx<-required$module=="extension_home_ses" & paste(required$country,required$survey,required$year)%in%
      paste(unavailable$country,unavailable$survey,unavailable$year)
    unavailable_ids<-required$metric_key[idx]
    write.csv(required[idx,,drop=FALSE],file.path(out,"DOCUMENTED_UNAVAILABLE_EXTENSION_TARGETS.csv"),row.names=FALSE)
    req_ids<-setdiff(req_ids,unavailable_ids)
  }
  approved <- data.frame()
  status <- "HOLD"
  message <- ""
  if(file.exists(approval_csv)) {
    approved <- tryCatch(read.csv(approval_csv,stringsAsFactors=FALSE,
                 check.names=FALSE),error=function(e)stop(
                 "SCIENTIFIC_GATE_HOLD: cannot read approval table"))
    expected <- c("cell_id","estimate","standard_error","n_unweighted",
       "sample_id","method_version","input_fingerprint",
       "code_fingerprint","result_hash","status")
    if(!all(expected%in%names(approved)) ||
       anyDuplicated(approved$cell_id))
      stop("SCIENTIFIC_GATE_HOLD: invalid or duplicate approvals")
    all_approved <- approved
    approved <- approved[approved$cell_id %in% req_ids,,drop=FALSE]
    if(nrow(approved)) {
      if(!exists("lo_grid_validate_fill",mode="function"))
        stop("SCIENTIFIC_GATE_HOLD: missing grid validator")
      # Final acceptance uses the same exact target/source/design gate as
      # archive fill, not the weaker schema-only validator.
      grid <- lo_grid_from_tasks(required)
      lo_grid_archive_fill(grid,approved)
    }
  } else {
    message <- "Independent scientific approvals file missing"
    all_approved <- data.frame()
  }
  missing <- setdiff(req_ids,approved$cell_id)
  # Publication gates are independent from working candidate counts.
  paper <- read.csv(file.path(bundle,"OPEN_PAPER_REQUIREMENTS.csv"),
              stringsAsFactors=FALSE,colClasses="character")
  if(nrow(paper)!=8L||!setequal(paper$requirement_id,sprintf("Q%02d",1:8)))
    stop("SCIENTIFIC_GATE_HOLD: Q01-Q08 source contract changed")
  gates <- file.path(dirname(approval_csv),"SCIENTIFIC_PAPER_GATES.csv")
  received <- if(file.exists(gates))read.csv(gates,stringsAsFactors=FALSE) else
    data.frame(requirement_id=character(),status=character())
  if(!all(c("requirement_id","status")%in%names(received)) ||
     anyDuplicated(received$requirement_id))
    stop("SCIENTIFIC_GATE_HOLD: invalid Q01-Q08 gate file")
  paper$validated <- paper$requirement_id %in%
    received$requirement_id[received$status=="PASS"]
  write.csv(paper[,c("requirement_id","requirement","validated")],
      file.path(out,"PAPER_Q01_Q08_GATES.csv"),row.names=FALSE)
  # A01 scope approval must precede any BELOW-basic peer requirement.
  # Each approved target still needs its own certified
  # weighted PV/replicate result, sample N and proof of self exclusion.
  # Original HIGH-peer cells never satisfy this requirement.
  low_peer_tasks <- tasks[FALSE,,drop=FALSE]
  if(!is.null(scope_decisions)) {
    if(!exists("lo_scoped_low_peer_tasks",mode="function"))
      stop("SCIENTIFIC_GATE_HOLD: scope decision module missing")
    low_peer_tasks <- lo_scoped_low_peer_tasks(tasks,scope_decisions)
  }
  peer_ids <- low_peer_tasks$metric_key
  peer_approved <- if(nrow(all_approved))
     all_approved[all_approved$cell_id%in%peer_ids,,drop=FALSE]
     else data.frame()
  peer_missing <- setdiff(peer_ids,
            if(nrow(peer_approved))peer_approved$cell_id else character())
  cert_columns <- c("peer_denominator_verified","self_exclusion_verified",
     "method_certification_status","joint_pv_replicate_status",
     "target_contract_sha256","source_edition_sha256",
     "weight_design","pv_rule","variance_rule")
  peer_fields_ok <- !nrow(low_peer_tasks) ||
     (nrow(peer_approved)==nrow(low_peer_tasks) &&
       all(cert_columns%in%names(peer_approved)) &&
       all(vapply(c("peer_denominator_verified","self_exclusion_verified",
           "method_certification_status","joint_pv_replicate_status"),
         function(k) all(peer_approved[[k]]=="PASS"),logical(1L))))
  peer_hash_ok <- !nrow(low_peer_tasks)
  if(peer_fields_ok && nrow(low_peer_tasks)) {
    target <- lo_grid_from_tasks(low_peer_tasks)
    tested <- tryCatch(lo_grid_archive_fill(target,peer_approved),
                       error=function(e)e)
    peer_hash_ok <- !inherits(tested,"error") &&
      all(tested$status=="SCIENTIFICALLY_VALIDATED")
  }
  primary <- file.path(dirname(approval_csv),"LOW_PEER_PRIMARY_GATES.csv")
  registered <- if(file.exists(primary))read.csv(primary,
     stringsAsFactors=FALSE,check.names=FALSE) else data.frame()
  ctx <- if(nrow(low_peer_tasks))unique(low_peer_tasks[,c("country",
      "survey","year","domain","peer_definition"),drop=FALSE])
      else data.frame()
  context_ok <- !nrow(ctx)
  if(nrow(ctx) && all(c("country","survey","year","domain",
                       "peer_definition","scientific_status")%in%
                 names(registered))) {
    fields<-c("country","survey","year","domain","peer_definition")
    key <- function(x)do.call(paste,c(x[fields],sep="|"))
    good <- registered[registered$scientific_status=="PASS",
                       fields,drop=FALSE]
    context_ok <- all(key(ctx)%in%key(good))
  }
  peer_pass <- peer_fields_ok && peer_hash_ok && context_ok &&
               length(peer_missing)==0L
  write.csv(data.frame(cell_id=peer_missing,
     decision=rep("HOLD_NEW_BELOW_BASIC_PEER_NOT_SCIENTIFICALLY_VALIDATED",
                  length(peer_missing))),
     file.path(out,"PRIVATE_NEW_PEER_CELL_GAPS.csv"),row.names=FALSE)
  all_pass <- length(missing)==0L && all(paper$validated) && peer_pass
  summary <- data.frame(scope_contracts=nrow(tasks),
    active_primitive_contracts=length(req_ids)+length(peer_ids),
    validated_active_primitives=nrow(approved)+nrow(peer_approved),
    active_missing=length(missing)+length(peer_missing),
    documented_unavailable_extensions=length(unavailable_ids),
    new_below_basic_peer_targets=length(peer_ids),
    new_below_basic_peer_verified=length(peer_ids)-length(peer_missing),
    paper_gates_pass=sum(paper$validated),
    paper_gates_required=8L,
    primary_peer_gate=if(!length(peer_ids))"NOT_REQUIRED_BY_CURRENT_SCOPE"
                     else if(peer_pass)"PASS" else "HOLD",
    scientific_freeze=if(all_pass)"ELIGIBLE_FOR_INDEPENDENT_REVIEW" else "HOLD",
    publication_authorized="NO_RIGHTS_AND_REPLICATION_REVIEW_PENDING",
    reason=if(all_pass)"Independent reviewer and rights gate pending" else
      paste(c(message,if(length(missing))"ACTIVE_GRID_GAPS",
          if(!all(paper$validated))"Q01_Q08_OPEN",
          if(!peer_pass)"BELOW_BASIC_PEER_REQUIREMENTS_OPEN"),
        collapse=";"),
    stringsAsFactors=FALSE)
  write.csv(summary,file.path(out,"SCIENTIFIC_QUALITY_SUMMARY.csv"),row.names=FALSE)
  # Keep cell keys private; never write them to release/git folder.
  write.csv(data.frame(cell_id=missing,
                      decision=rep("HOLD_NOT_VALIDATED",length(missing))),
            file.path(out,"PRIVATE_ACTIVE_CELL_GAPS.csv"),row.names=FALSE)
  invisible(summary)
}

