# Grid-first canonical statistical target definition.
# Read only locked contracts. Never calculate pupil estimates in this module.
lo_grid_schema <- function() c("cell_id","survey","country","year","age",
 "domain","sample_id","population_id","subgroup_variable","subgroup_level",
 "outcome_id","statistic","ses_construct_id","threshold_id","peer_environment",
 "peer_target_group","peer_own_group","method_version","weight_design",
 "pv_rule","variance_rule","linking_rule","n_unweighted","n_effective",
 "estimate","standard_error","covariance_group_id","target_contract_sha256","source_edition_sha256","input_fingerprint",
 "code_fingerprint","result_hash","archive_source","status","hold_reason",
 "source_path","certification_path","certification_sha256")
lo_grid_from_tasks <- function(tasks) {
 required <- c("metric_key","survey","country","year","domain","module",
               "stat","group","definition","peer_definition","threshold")
 if(!all(required%in%names(tasks)) || anyDuplicated(tasks$metric_key))
   stop("GRID_CONTRACT_HOLD: invalid original task identities")
 if(!nrow(tasks))return(as.data.frame(setNames(rep(list(character()),
   length(lo_grid_schema())),lo_grid_schema()),stringsAsFactors=FALSE))
 field <- function(x)if(x%in%names(tasks)) as.character(tasks[[x]]) else
    rep("",nrow(tasks))
 if(!requireNamespace("digest",quietly=TRUE))
    stop("GRID_CONTRACT_HOLD: digest missing")
 signature_columns <- c("metric_key","country","survey","year","domain",
     "module","stat","group","definition","peer_definition","threshold",
     "unit","calculation_policy")
 if(!all(signature_columns%in%names(tasks)))
    stop("GRID_CONTRACT_HOLD: missing exact science contract columns")
 signature_text <- apply(tasks[,signature_columns,drop=FALSE],1L,
    function(row)paste(ifelse(is.na(row),"<NA>",as.character(row)),
                       collapse="|"))
 signatures <- vapply(signature_text,function(value)
    digest::digest(value,algo="sha256",serialize=FALSE),
    character(1L),USE.NAMES=FALSE)
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
    target_contract_sha256=signatures,source_edition_sha256="",
    input_fingerprint="",code_fingerprint="",result_hash="",
    archive_source="",status="TARGET_NOT_YET_ADJUDICATED",
    hold_reason="Exact sample/construct/method identity and results must be checked",
    source_path="",certification_path="",certification_sha256="",
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
     any(as.numeric(candidate$standard_error)<0) ||
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

# Derived output contract: do not treat differences as independent pupil runs.
lo_grid_derived_contract <- function() {
  data.frame(derived_family=c(
    "GP_SES_GAP","GP_GENDER_GAP","GP_LANGUAGE_GAP",
    "GP_MIGRATION_GAP","DS_SPREAD","TR_BASIC",
    "TR_POSITION","BENCHMARK_MEAN"),
    source_requirement=c(
      "SES_Q4_MEAN + SES_Q1_MEAN","GIRLS_MEAN + BOYS_MEAN",
      "LANGUAGE_REFERENCE + LANGUAGE_COMPARISON",
      "MIGRATION_GROUP + NATIVE_GROUP",
      "P90 + P10","BELOW_BASIC","VALIDATED_COUNTRY_MEANS",
      "VALIDATED_SELECTED_COUNTRY_MEANS"),
    transform=c("Q4 - Q1","GIRLS - BOYS","GROUP - REFERENCE",
      "MIGRATION - NATIVE","P90 - P10","100 - BELOW",
      "ORDER_BY_MEAN","EQUAL_COUNTRY_WEIGHT_EXCLUDE_FOCUS"),
    uncertainty_gate=c(rep("JOINT_REPLICATE_PV_OR_COVARIANCE",5),
      "TRANSFORM_COMPLEMENT_VARIANCE",
      "RANK_PRESENTATION_NO_SE",
      "BENCHMARK_PRESENTATION_NO_SE"),
    automatic_pupil_recomputation="NO",
    status="DERIVE_ONLY_WHEN_VALIDATED_SOURCES_PRESENT",
    stringsAsFactors=FALSE)
}


# Proposed below-basic peer outcome is absent from the original
# 79,448 high-peer contracts. Create 3 new, separately identifiable primitive
# targets per exact peer environment/country/survey/wave/subject; never reuse
# the old high-peer estimates as if they were under-basic peers. This is a
# contract-definition helper, not approval. Runtime uses LO_SCOPE_DECISIONS.R.
lo_grid_new_low_peer_tasks <- function(tasks) {
  req <- c("metric_key","country","survey","year","domain",
           "contract_figure_id","peer_definition")
  if(!all(req%in%names(tasks)))stop("GRID_NEW_PEER_HOLD: source schema changed")
  family <- sub("_age.*$","",tasks$contract_figure_id)
  original <- tasks[family=="EN_PERFORMANCE_PEER",,drop=FALSE]
  if(!nrow(original))return(tasks[FALSE,,drop=FALSE])
  ids <- c("country","survey","year","domain","peer_definition",
           "contract_figure_id")
  contexts <- unique(original[,ids,drop=FALSE])
  groups <- c("total","self_below_basic","self_at_or_above_basic")
  new <- contexts[rep(seq_len(nrow(contexts)),each=length(groups)),,drop=FALSE]
  new$group <- rep(groups,times=nrow(contexts))
  new$module <- "peer_below_basic"
  new$stat <- "peer_share_below_basic"
  new$definition <- "below_basic_exclude_self_direct_or_school"
  new$threshold <- ifelse(new$survey=="PISA",
     "PISA_BELOW_LEVEL2","IEA_BELOW_INTERMEDIATE_475")
  new$unit <- "percent"
  new$calculation_policy <- "JOINT_PV_REPLICATE_SELF_EXCLUDED_METHOD_GATE"
  new$outcome <- "peer_share_below_basic"
  new$metric_key <- paste("NEW_PEER_BELOW_BASIC",new$country,new$survey,
    new$year,new$domain,new$peer_definition,new$group,new$threshold,
    sep="|")
  if(anyDuplicated(new$metric_key) ||
     any(new$metric_key%in%tasks$metric_key))
    stop("GRID_NEW_PEER_HOLD: duplicate science target")
  # Preserve the historical task column order without creating a new source
  # metric identity for the optional high-peer measure.
  for(col in setdiff(names(tasks),names(new))) new[[col]] <- ""
  new[,names(tasks),drop=FALSE]
}

