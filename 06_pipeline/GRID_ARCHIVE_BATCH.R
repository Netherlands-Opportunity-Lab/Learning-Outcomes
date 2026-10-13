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
    same_sample <- nzchar(grid$sample_id[ix]) &
       grid$sample_id[ix]==valid$sample_id
    if(!all(same_sample))
      stop("GRID_ARCHIVE_HOLD: target sample identity not independently locked")
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
