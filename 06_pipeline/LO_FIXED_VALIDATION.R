# Final scientific acceptance: no automatic promotion from old source/metric.
lo_final_quality_gate <- function(bundle, tasks, approval_csv, out) {
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  family <- sub("_age.*$","",tasks$contract_figure_id)
  active <- !(family %in% c("TR_BASIC","GP_SES_HIGH","EN_PERFORMANCE_PEER"))
  required <- tasks[active,,drop=FALSE]
  req_ids <- unique(required$metric_key)
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
    approved <- approved[approved$cell_id %in% req_ids,,drop=FALSE]
    if(nrow(approved)) {
      if(!exists("lo_grid_validate_fill",mode="function"))
        stop("SCIENTIFIC_GATE_HOLD: missing grid validator")
      grid <- data.frame(cell_id=req_ids)
      lo_grid_validate_fill(grid,approved)
    }
  } else message <- "Independent scientific approvals file missing"
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
  # Mandatory new below-basic peer item is not an old high-peer cell.
  peer <- tasks[family=="EN_PERFORMANCE_PEER",,drop=FALSE]
  contexts <- if(nrow(peer))unique(peer[,intersect(
    c("country","survey","year","domain","peer_definition"),names(peer)),
    drop=FALSE]) else data.frame()
  primary <- file.path(dirname(approval_csv),"LOW_PEER_PRIMARY_GATES.csv")
  reviewed_peer <- if(file.exists(primary))read.csv(primary,
    stringsAsFactors=FALSE) else data.frame()
  peer_pass <- !nrow(contexts) || (
    all(c("country","survey","year","domain","peer_definition",
          "scientific_status")%in%names(reviewed_peer)) &&
    all(contexts$country %in%
      reviewed_peer$country[reviewed_peer$scientific_status=="PASS"]))
  # Country matching alone is NOT enough; for >0 contexts require exact keys.
  if(nrow(contexts) && peer_pass) {
    keyfields <- intersect(names(contexts),names(reviewed_peer))
    good <- reviewed_peer[reviewed_peer$scientific_status=="PASS",
                          keyfields,drop=FALSE]
    k <- function(z)do.call(paste,c(z[keyfields],sep="|"))
    peer_pass <- all(k(contexts)%in%k(good))
  }
  all_pass <- length(missing)==0L && all(paper$validated) && isTRUE(peer_pass)
  summary <- data.frame(scope_contracts=nrow(tasks),
    active_primitive_contracts=length(req_ids),
    validated_active_primitives=nrow(approved),
    active_missing=length(missing),
    paper_gates_pass=sum(paper$validated),
    paper_gates_required=8L,
    primary_peer_gate=if(peer_pass)"PASS" else "HOLD",
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
  write.csv(data.frame(cell_id=missing,decision="HOLD_NOT_VALIDATED"),
            file.path(out,"PRIVATE_ACTIVE_CELL_GAPS.csv"),row.names=FALSE)
  invisible(summary)
}
