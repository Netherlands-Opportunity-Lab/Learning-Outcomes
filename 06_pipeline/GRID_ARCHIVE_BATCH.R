# Archive-first grid fill and batch scheduling: read only, no pupil calculations.
# Archive evidence must contain scientific validation, exact sample/method and
# SHA identities. Candidate keys alone NEVER authorize reuse.
lo_grid_archive_fill <- function(grid, candidates) {
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
    for(k in intersect(names(valid),names(grid)))
      grid[[k]][ix] <- valid[[k]]
    grid$status[ix] <- "SCIENTIFICALLY_VALIDATED"
    grid$hold_reason[ix] <- ""
  }
  grid
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
