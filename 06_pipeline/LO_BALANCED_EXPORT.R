# Export reference options from exact certified cells, not display availability.
# The matrix specifies comparability, including SES and peer definitions; never
# invent a population/method comparison ID from a short variable label.
lo_balance_result_adapter <- function(grid,contracts) {
  required<-c("cell_id",lo_balance_columns(),"verification_path","verification_sha256")
  if(!all(required%in%names(contracts)) || anyDuplicated(contracts$cell_id))
    stop("BALANCE_ADAPTER_INVALID_CONTRACTS")
  lo_balance_key(contracts)
  ix<-match(contracts$cell_id,grid$cell_id)
  if(anyNA(ix))stop("BALANCE_ADAPTER_UNAPPROVED_CELL")
  g<-grid[ix,,drop=FALSE]
  if(any(g$status!="SCIENTIFICALLY_VALIDATED"))stop("BALANCE_ADAPTER_UNVALIDATED_RESULT")
  for(k in c("survey","domain","year"))if(any(as.character(g[[k]])!=contracts[[k]]))
    stop("BALANCE_ADAPTER_IDENTITY_MISMATCH")
  checked<-new.env(parent=emptyenv())
  for(i in seq_len(nrow(contracts))) {
    path<-contracts$verification_path[i];hash<-contracts$verification_sha256[i]
    if(!exists(hash,checked,inherits=FALSE)) {
      lo_exact_assert_sha(path,hash,"BALANCE_CERTIFICATE")
      assign(hash,jsonlite::fromJSON(path,simplifyVector=TRUE),checked)
    }
    cert<-get(hash,checked,inherits=FALSE)
    if(!identical(cert$status,"COMPARABILITY_CERTIFIED") ||
       !all(c("cell_id","balance_key","result_hash")%in%names(cert$cells)))
      stop("BALANCE_ADAPTER_EVIDENCE_REQUIRED")
    j<-match(g$cell_id[i],cert$cells$cell_id)
    if(is.na(j)||cert$cells$balance_key[j]!=lo_balance_key(contracts[i,,drop=FALSE]) ||
       cert$cells$result_hash[j]!=g$result_hash[i])stop("BALANCE_ADAPTER_CHANGED_MAPPING")
  }
  cbind(contracts[lo_balance_columns()],g[c("country","estimate","standard_error","n_unweighted","status")],
    source_record_id=g$result_hash,verification_id=contracts$verification_sha256,
    cell_id=g$cell_id,stringsAsFactors=FALSE)
}

lo_balanced_export <- function(repo,grid,contracts,scope_info,out) {
  # Proven absent constructs are disclosed, not fabricated or mapped to other
  # variables. Every actually required focus cell must still be mapped.
  absent<-grepl("^UNAVAILABLE_",grid$status)
  expected<-grid$cell_id[grid$country%in%scope_info$dashboard & !absent]
  if(any(!expected%in%contracts$cell_id))
    stop("BALANCE_FOCUS_CONTRACT_MAPPING_INCOMPLETE: do not shrink focus to available rows")
  x<-lo_balance_result_adapter(grid,contracts)
  anchor<-read.csv(file.path(repo,"06_pipeline","review_20261013",
    "NLD_POLICY_CORE_YEAR_ANCHOR.csv"),colClasses="character")
  core<-x[x$outcome=="mean_score" & x$split_dimension=="none" &
    x$split_group=="total" & x$peer_definition=="none",,drop=FALSE]
  products<-list()
  for(focus in scope_info$dashboard) {
    # Full focus support, all jointly selected groups and peer contexts. A UI
    # view change does not silently cut these requirements to its current tab.
    compare<-x[x$country==focus,,drop=FALSE]
    required<-lo_focus_required_support(core,compare,focus,anchor)
    candidates<-scope_info$reference_candidates
    if(is.null(candidates))candidates<-scope_info$dashboard
    options<-lo_dashboard_reference_options(x,required,candidates,focus)
    selected<-intersect(scope_info$comparator,options$country[options$eligible])
    points<-if(length(selected))lo_dashboard_reference_points(x,required,selected,focus)$points else data.frame()
    products[[focus]]<-list(focus=focus,required_keys=sort(lo_balance_key(required)),
      options=options,default_members=selected,default_points=points,
      default_status=if(length(selected))"BALANCED_REFERENCE_AVAILABLE" else "NO_ELIGIBLE_REFERENCE",
      focus_excluded=TRUE,country_weights="EQUAL_PER_COUNTRY",benchmark_uncertainty=FALSE)
  }
  jsonlite::write_json(list(schema_version=1L,policy="FULL_FOCUS_SUPPORT_6x3",
    grid_sha256=digest::digest(grid,algo="sha256"),focuses=products,
    unavailable_cells=grid[absent,intersect(c("cell_id","country","survey","year","hold_reason"),names(grid)),drop=FALSE]),
    file.path(out,"BALANCED_REFERENCE_EXPORT.json"),auto_unbox=TRUE,pretty=TRUE,na="null")
  invisible(products)
}

# NL-only may read pre-existing certified foreign aggregates. It never creates
# foreign compute tasks. The full exact contract and artifact checks still apply.
lo_reference_only_grid <- function(tasks,approved,scope_info,decisions) {
  countries<-setdiff(scope_info$reference_candidates,scope_info$selected)
  reference_scope<-scope_info;reference_scope$selected<-countries
  source<-lo_country_base_tasks(tasks,reference_scope)
  additions<-lo_scoped_low_peer_tasks(source,decisions)
  source<-lo_scope_active_tasks(source,decisions)
  source<-rbind(source,additions,lo_extension_tasks(source,decisions))
  source<-source[source$metric_key%in%approved$cell_id,,drop=FALSE]
  grid<-lo_grid_from_tasks(source)
  if(!nrow(grid))return(grid)
  a<-approved[approved$cell_id%in%grid$cell_id,,drop=FALSE]
  lo_grid_archive_fill(grid,a,verify_files=TRUE)
}
