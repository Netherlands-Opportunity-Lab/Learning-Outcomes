# Grid-first canonical statistical target definition.
# Read only locked contracts. Never calculate pupil estimates in this module.
lo_grid_schema <- function() c("cell_id","survey","country","year","age",
 "domain","sample_id","population_id","subgroup_variable","subgroup_level",
 "outcome_id","statistic","ses_construct_id","threshold_id","peer_environment",
 "peer_target_group","peer_own_group","method_version","weight_design",
 "pv_rule","variance_rule","linking_rule","n_unweighted","n_effective",
 "estimate","standard_error","covariance_group_id","input_fingerprint",
 "code_fingerprint","result_hash","archive_source","status","hold_reason")
lo_grid_from_tasks <- function(tasks) {
 required <- c("metric_key","survey","country","year","domain","module",
               "stat","group","definition","peer_definition","threshold")
 if(!all(required%in%names(tasks)) || anyDuplicated(tasks$metric_key))
   stop("GRID_CONTRACT_HOLD: invalid original task identities")
 field <- function(x)if(x%in%names(tasks)) as.character(tasks[[x]]) else
    rep("",nrow(tasks))
 z <- data.frame(cell_id=field("metric_key"),survey=field("survey"),
    country=field("country"),year=field("year"),age=field("age"),
    domain=field("domain"),sample_id=field("sample"),
    population_id=field("population"),subgroup_variable=field("module"),
    subgroup_level=field("group"),outcome_id=field("definition"),
    statistic=field("stat"),ses_construct_id="",
    threshold_id=field("threshold"),peer_environment=field("peer_definition"),
    peer_target_group="",peer_own_group="",method_version="",
    weight_design="",pv_rule="",variance_rule="",linking_rule="",
    n_unweighted=NA_integer_,n_effective=NA_real_,estimate=NA_real_,
    standard_error=NA_real_,covariance_group_id="",
    input_fingerprint="",code_fingerprint="",result_hash="",
    archive_source="",status="TARGET_NOT_YET_ADJUDICATED",
    hold_reason="Exact sample/construct/method identity and results must be checked",
    stringsAsFactors=FALSE)
 if(nrow(z)!=nrow(tasks)||anyDuplicated(z$cell_id))
    stop("GRID_INTEGRITY_HOLD")
 z
}
lo_grid_validate_fill <- function(grid, candidate) {
  mandatory <- c("cell_id","estimate","standard_error","n_unweighted",
    "input_fingerprint","code_fingerprint","result_hash",
    "method_version","sample_id","status")
  if(!all(mandatory%in%names(candidate)) ||
     anyDuplicated(candidate$cell_id))
     stop("GRID_FILL_HOLD: missing evidence fields or duplicate cells")
  if(!all(candidate$cell_id%in%grid$cell_id))
     stop("GRID_FILL_HOLD: candidate includes uncontracted cell")
  if(!all(candidate$status=="SCIENTIFICALLY_VALIDATED") ||
     any(!is.finite(as.numeric(candidate$estimate))) ||
     any(!is.finite(as.numeric(candidate$standard_error))) ||
     any(!is.finite(as.numeric(candidate$n_unweighted))) ||
     any(as.numeric(candidate$n_unweighted)<1) ||
     any(!grepl("^[a-fA-F0-9]{64}$",candidate$input_fingerprint)) ||
     any(!grepl("^[a-fA-F0-9]{64}$",candidate$code_fingerprint)) ||
     any(!grepl("^[a-fA-F0-9]{64}$",candidate$result_hash)) ||
     any(!nzchar(candidate$method_version)) ||
     any(!nzchar(candidate$sample_id)))
     stop("GRID_FILL_HOLD: scientific validation or provenance missing")
  invisible(TRUE)
}
