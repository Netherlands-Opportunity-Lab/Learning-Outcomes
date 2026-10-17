# Archive-first grid fill and batch scheduling: read only, no pupil calculations.
# Archive evidence must contain scientific validation, exact sample/method and
# SHA identities. Candidate keys alone NEVER authorize reuse.
lo_grid_archive_fill <- function(grid, candidates,verify_files=FALSE) {
  if(!exists("lo_grid_validate_fill",mode="function"))
    stop("GRID_MODULE_HOLD: source MASTER_ESTIMATION_GRID.R")
  required <- c("cell_id","status","estimate","standard_error","n_unweighted",
     "sample_id","method_version","input_fingerprint","code_fingerprint",
     "result_hash")
  if(!all(required%in%names(candidates)))
    stop("GRID_ARCHIVE_HOLD: required archive evidence missing")
  if(anyDuplicated(candidates$cell_id))
    stop("GRID_ARCHIVE_HOLD: conflicting candidate identities need adjudication")
  valid <- candidates[candidates$status=="SCIENTIFICALLY_VALIDATED",,drop=FALSE]
  if(nrow(valid)) {
    lo_grid_validate_fill(grid,valid)
    if(verify_files)lo_grid_verify_result_artifacts(valid)
    ix <- match(valid$cell_id,grid$cell_id)
    # Existing locked contracts without sample/construct specifics CANNOT
    # be filled solely by matching metric_key; exact target sample is required.
    sample_locked <- !is.na(grid$sample_id[ix]) &
       nzchar(grid$sample_id[ix])
    if(any(sample_locked &
       grid$sample_id[ix]!=valid$sample_id))
      stop("GRID_ARCHIVE_HOLD: certified sample differs from locked sample")
    # Historical task contracts do not contain the exact realised sample.
    # An independent validated record can *lock* that sample once, but only
    # with the original full target-contract SHA, source-edition SHA,
    # weights, PV and design rules (not a metric_key-only match).
    if(any(!sample_locked)) {
      need <- c("target_contract_sha256","source_edition_sha256",
                "weight_design","pv_rule","variance_rule")
      if(!all(need%in%names(valid)) ||
         !"target_contract_sha256"%in%names(grid))
        stop("GRID_ARCHIVE_HOLD: independent sample/target certification absent")
      j <- which(!sample_locked)
      same_contract <- valid$target_contract_sha256[j] ==
                        grid$target_contract_sha256[ix[j]]
      source_ok <- grepl("^[a-fA-F0-9]{64}$",
                         valid$source_edition_sha256[j])
      rules_ok <- Reduce(`&`,lapply(c("weight_design",
                       "pv_rule","variance_rule"),function(k)
        !is.na(valid[[k]][j]) & nzchar(valid[[k]][j])))
      if(anyNA(same_contract)||!all(same_contract & source_ok & rules_ok))
        stop("GRID_ARCHIVE_HOLD: exact contract/edition/design certification mismatch")
    }
    lo_grid_check_population_metadata(grid,valid,ix)
    for(k in setdiff(intersect(names(valid),names(grid)),c("age","population_id")))
      grid[[k]][ix] <- valid[[k]]
    grid$status[ix] <- "SCIENTIFICALLY_VALIDATED"
    grid$hold_reason[ix] <- ""
  }
  grid
}

# Older numerical certificates omitted these descriptive contract fields.
# Keep the explicit target population; a nonblank contradiction is an error.
# The immutable numerical certificate and result hashes are never rewritten.
lo_grid_check_population_metadata <- function(grid,rows,ix) {
  for(k in intersect(c("age","population_id"),names(rows))) {
    value<-as.character(rows[[k]])
    present<-!is.na(value)&nzchar(value)
    if(k=="age")value[present]<-sub("^([0-9]+)$","age\\1",value[present])
    if(any(present & (is.na(grid[[k]][ix]) | value!=grid[[k]][ix])))
      stop("GRID_POPULATION_CERTIFICATE_CONFLICT: ",k)
  }
  invisible(TRUE)
}

# Production reuse needs real pinned artifacts, not 64-character placeholders.
# The private approval certificate binds exact result values to the source,
# method and target. Source-free unit fixtures use the schema-only gate.
lo_grid_verify_result_artifacts <- function(rows) {
  fields<-c("source_path","source_edition_sha256","certification_path","certification_sha256")
  if(!all(fields%in%names(rows)))stop("GRID_RESULT_ARTIFACTS_REQUIRED")
  checked<-new.env(parent=emptyenv())
  certificates<-new.env(parent=emptyenv())
  for(i in seq_len(nrow(rows))) {
    for(pair in list(c("source_path","source_edition_sha256"),c("certification_path","certification_sha256"))) {
      p<-rows[[pair[1]]][i];h<-rows[[pair[2]]][i];key<-paste(p,h)
      if(!exists(key,checked,inherits=FALSE)) {
        if(is.na(p)||!nzchar(p)||!file.exists(p)||!grepl("^[a-f0-9]{64}$",h)||
           digest::digest(file=p,algo="sha256")!=h)stop("GRID_RESULT_CHANGED_ARTIFACT")
        assign(key,TRUE,checked)
      }
    }
    cert_key<-paste(rows$certification_path[i],rows$certification_sha256[i])
    if(exists(cert_key,certificates,inherits=FALSE))cert<-get(cert_key,certificates,inherits=FALSE)
    else {
      cert<-jsonlite::fromJSON(rows$certification_path[i],simplifyVector=TRUE)
      assign(cert_key,cert,certificates)
    }
    evidence<-cert$evidence_files
    if(!is.data.frame(evidence)||!nrow(evidence)||!all(c("path","sha256")%in%names(evidence)))
      stop("GRID_RESULT_CERTIFICATE_WITHOUT_EVIDENCE")
    for(e in seq_len(nrow(evidence))) {
      p<-evidence$path[e];h<-evidence$sha256[e];key<-paste(p,h)
      if(!exists(key,checked,inherits=FALSE)) {
        if(is.na(p)||!nzchar(p)||!file.exists(p)||!grepl("^[a-f0-9]{64}$",h)||
           digest::digest(file=p,algo="sha256")!=h)stop("GRID_RESULT_CHANGED_EVIDENCE")
        assign(key,TRUE,checked)
      }
    }
    cols<-c("cell_id","estimate","standard_error","n_unweighted","sample_id","method_version",
      "target_contract_sha256","source_edition_sha256","input_fingerprint","code_fingerprint","result_hash",
      "weight_design","pv_rule","variance_rule")
    if(!identical(cert$status,"SCIENTIFICALLY_VALIDATED")||!all(cols%in%names(cert$cells)) ||
       anyDuplicated(cert$cells$cell_id))stop("GRID_RESULT_CERTIFICATE_INVALID")
    j<-match(rows$cell_id[i],cert$cells$cell_id)
    if(is.na(j))stop("GRID_RESULT_CERTIFICATE_UNKNOWN_CELL")
    for(k in cols)if(!identical(as.character(rows[[k]][i]),as.character(cert$cells[[k]][j])))
      stop("GRID_RESULT_CERTIFICATE_CHANGED_VALUE_",k)
  }
  invisible(TRUE)
}

# One ordered batch per stable survey/country/year/sample/source/method
# identifier. No execution unless ALL cells are scientifically certified
# as needing computation, and all required grouping identities are complete.
lo_grid_batch_plan <- function(grid) {
  mandatory <- c("cell_id","survey","country","year","sample_id",
    "method_version","input_fingerprint","status","weight_design",
    "pv_rule","variance_rule")
  if(!all(mandatory%in%names(grid)))
    stop("GRID_BATCH_HOLD: incomplete grid schema")
  pending <- grid[grid$status=="COMPUTE_REQUIRED_AFTER_METHOD_GATE",,drop=FALSE]
  if(!nrow(pending))
    return(data.frame(batch_id=character(),n_cells=integer(),
      status=character(),stringsAsFactors=FALSE))
  grouping <- c("survey","country","year","sample_id","method_version",
                "input_fingerprint","weight_design","pv_rule","variance_rule")
  complete <- vapply(pending[grouping],function(x)
    all(!is.na(x)&nzchar(as.character(x))),logical(1L))
  if(!all(complete) || anyDuplicated(pending$cell_id))
    stop("GRID_BATCH_HOLD: missing source/method/design or duplicate cell")
  key <- do.call(paste,c(pending[grouping],sep="|"))
  batch <- split(seq_len(nrow(pending)),key)
  data.frame(batch_id=vapply(batch,function(ix)
    paste0("batch_",substr(digest::digest(key[[ix[[1L]]]],
       algo="sha256",serialize=FALSE),1L,16L)),character(1L)),
    n_cells=vapply(batch,length,integer(1L)),
    status="READY_TO_PLAN_NOT_EXECUTED",stringsAsFactors=FALSE)
}

lo_grid_mark_archive_candidates <- function(grid,lo01_keys,lo02_keys) {
  if(anyDuplicated(grid$cell_id))stop("GRID_ARCHIVE_HOLD: duplicated grid IDs")
  a <- grid$cell_id %in% unique(as.character(lo01_keys))
  b <- grid$cell_id %in% unique(as.character(lo02_keys))
  grid$status[a|b] <- "ARCHIVE_CANDIDATE_FOUND_NOT_VALIDATED"
  grid$archive_source[b] <- "LO02_CANDIDATE"
  grid$archive_source[a & !b] <- "LO01_CANDIDATE"
  grid$hold_reason[a|b] <- "Verify input, exact sample, method, PV/variance and result hash"
  # Never populate estimates, SE, or N from an unverified candidate.
  grid
}


# Independent execution certifications cannot silently convert missing files
# into work orders. This targets ONLY source-locked empty cells with complete
# method, PV/replicate and input/producer fingerprints.
lo_grid_apply_compute_approvals <- function(grid,approved) {
  mandatory <- c("cell_id","decision","certification_status",
    "target_contract_sha256","source_edition_sha256",
    "source_path","certification_path","certification_sha256",
    "input_fingerprint","code_fingerprint","sample_id",
    "method_version","weight_design","pv_rule","variance_rule")
  if(!all(mandatory%in%names(approved)) ||
     anyDuplicated(approved$cell_id) ||
     any(!approved$cell_id%in%grid$cell_id))
    stop("GRID_COMPUTE_HOLD: invalid or uncontracted execution approvals")
  if(!nrow(approved))return(grid)
  ix <- match(approved$cell_id,grid$cell_id)
  if(any(grepl("^UNAVAILABLE_",grid$status[ix])))
    stop("GRID_COMPUTE_HOLD: documented unavailable source cannot become a compute order")
  if(any(approved$decision!="COMPUTE_REQUIRED" |
     approved$certification_status!="METHOD_SAMPLE_INPUT_CERTIFIED"))
    stop("GRID_COMPUTE_HOLD: certification must explicitly authorize computation")
  if(any(grid$status[ix]=="SCIENTIFICALLY_VALIDATED" |
         is.finite(suppressWarnings(as.numeric(grid$estimate[ix])))))
    stop("GRID_COMPUTE_HOLD: refusal to overwrite available verified estimates")
  if(any(approved$target_contract_sha256!=grid$target_contract_sha256[ix]))
    stop("GRID_COMPUTE_HOLD: exact immutable science target hash differs")
  for(k in c("input_fingerprint","code_fingerprint","source_edition_sha256",
             "target_contract_sha256","certification_sha256"))
    if(anyNA(approved[[k]])||
       any(!grepl("^[0-9a-fA-F]{64}$",approved[[k]])))
      stop("GRID_COMPUTE_HOLD: invalid SHA field ",k)
  for(k in c("sample_id","method_version","weight_design",
             "pv_rule","variance_rule","source_path","certification_path"))
    if(anyNA(approved[[k]])||any(!nzchar(approved[[k]])))
      stop("GRID_COMPUTE_HOLD: method or sample not certified: ",k)
  lo_grid_check_population_metadata(grid,approved,ix)
  for(k in setdiff(intersect(names(approved),names(grid)),c("age","population_id")))
    if(!k%in%c("cell_id","target_contract_sha256","estimate",
               "standard_error","n_unweighted","status","hold_reason"))
      grid[[k]][ix] <- approved[[k]]
  grid$status[ix] <- "COMPUTE_REQUIRED_AFTER_METHOD_GATE"
  grid$hold_reason[ix] <- "Exact input/producer fingerprints will be rechecked at production"
  grid
}

