# Existing source requirements are retained, but only direct user scope selects
# primitive tasks. Every active requirement is linked or explicitly unresolved.
lo_product_trace <- function(repo,tasks,grid,decisions,out) {
  defs<-jsonlite::fromJSON(file.path(repo,"06_pipeline","review_20261013",
                                   "PRODUCT_REQUIREMENTS.json"),simplifyVector=FALSE)
  selected<-lo_scope_active_tasks(tasks,decisions)
  fam<-sub("_age.*$","",selected$contract_figure_id)
  links<-list();spec<-list()
  for(r in defs$requirements) {
    ids<-unlist(r$approval_items)
    explicitly_chosen<-length(ids)>0L && all(vapply(ids,function(id)lo_scope_is_approved(decisions,id),logical(1)))
    source_only<-(r$product%in%c("SCIENTIFIC_SEMINAR","SCIENTIFIC_NOTE") && !explicitly_chosen) ||
      identical(r$current_scope,"HISTORICAL_SOURCE_ONLY")
    rank_derivation<-identical(r$derivation,"BALANCED_RANK_FROM_APPROVED_RESULTS")
    i<-if(rank_derivation && explicitly_chosen)seq_len(nrow(selected)) else
      which(fam%in%unlist(if(explicitly_chosen&&!is.null(r$current_figure_families))r$current_figure_families else r$figure_families))
    placement<-if(!is.null(r$current_placement))r$current_placement else r$role
    if(rank_derivation && identical(r$product,"DASHBOARD_DERIVATION"))
      i<-i[!startsWith(selected$module[i],"extension_") & fam[i]!="GP_SES_HIGH"]
    if(identical(r$scope,"NLD"))i<-i[selected$country[i]=="NLD"]
    for(k in names(r$task_filters))i<-i[selected[[k]][i]%in%unlist(r$task_filters[[k]])]
    if(source_only)i<-integer()
    if(length(i))links[[length(links)+1L]]<-data.frame(
      requirement_id=r$requirement_id,product=r$product,source_locator=r$source_locator,
      approved_placement=placement,
      figure_id=selected$contract_figure_id[i],cell_id=selected$metric_key[i],
      stringsAsFactors=FALSE)
    spec[[length(spec)+1L]]<-data.frame(requirement_id=r$requirement_id,
      product=r$product,source_locator=r$source_locator,
      approved_placement=placement,
      role=if(source_only)"HISTORICAL_SOURCE_ONLY" else if(explicitly_chosen)"APPROVED_EXTENSION_WITH_METHOD_GATES" else r$role,
      active_cell_links=length(i),
      supplemental_dependencies=paste(unlist(r$additional_dependencies),collapse=";"),
      pending_choices=paste(Filter(function(a)!lo_scope_is_approved(decisions,a),
                                   unlist(r$approval_items)),collapse=";"),
      status=if(source_only)"SOURCE_NOT_COMPUTE_ORDER" else if(rank_derivation && !explicitly_chosen)
        "DERIVATION_NOT_APPROVED" else if(rank_derivation)
        "APPROVED_DERIVATION_PARENT_CANDIDATES_FINAL_SELECTION_REQUIRED" else if(length(i))
        "EXACT_CELL_LINKS_WITH_SEPARATE_SCIENCE_STATUS" else "EDITORIAL_OR_SUPPLEMENTAL_SPECIFICATION",
      stringsAsFactors=FALSE)
  }
  # Later direct decisions are first-class product requirements even when the
  # old slides lack a family identifier for the new exact cells.
  for(id in c("A04","A06","A11","A12","A13","A14")) {
    modules<-c(A04="extension_home_ses",A06="extension_ses_gender",
      A11="extension_performance_school",A12="extension_performance_class",
      A13="extension_ses_school",A14="extension_ses_class")
    i<-which(selected$module==modules[[id]])
    if(!length(i))next
    placement<-decisions$placement_or_condition[match(id,decisions$approval_id)]
    links[[length(links)+1L]]<-data.frame(requirement_id=paste0("USER_20261014_",id),
      product=placement,source_locator=paste0("SCOPE_APPROVALS.csv#",id),
      approved_placement=placement,
      figure_id=selected$contract_figure_id[i],cell_id=selected$metric_key[i])
    spec[[length(spec)+1L]]<-data.frame(requirement_id=paste0("USER_20261014_",id),
      product=placement,source_locator=paste0("SCOPE_APPROVALS.csv#",id),
      approved_placement=placement,
      role="EXPLICITLY_APPROVED_EXTENSION",active_cell_links=length(i),
      supplemental_dependencies="source;sample;method;uncertainty;comparability",pending_choices="",
      status="EXACT_CELL_LINKS_WITH_SEPARATE_SCIENCE_STATUS")
  }
  # Paper claims are a small registered set of exact aggregate parents, not a
  # request for a new country-by-year testing cross-product.
  claim_path<-file.path(repo,'06_pipeline/review_20261013/PAPER_CLAIMS.json')
  if(file.exists(claim_path)&&'NLD'%in%selected$country) {
    claims<-jsonlite::fromJSON(claim_path,simplifyVector=FALSE)$claims
    for(claim in claims) {
      ids<-unique(Filter(nzchar,unlist(claim[c('parent_a','parent_b','gap_cell')])))
      i<-match(ids,selected$metric_key)
      outside<-ids[is.na(i)];ids<-ids[!is.na(i)];i<-i[!is.na(i)]
      if(length(i))links[[length(links)+1L]]<-data.frame(requirement_id=claim$claim_id,
        product='PAPER_REGISTERED_CLAIM',source_locator=paste0('PAPER_CLAIMS.json#',claim$claim_id),
        approved_placement='PAPER',figure_id=selected$contract_figure_id[i],cell_id=ids)
      spec[[length(spec)+1L]]<-data.frame(requirement_id=claim$claim_id,
        product='PAPER_REGISTERED_CLAIM',source_locator=paste0('PAPER_CLAIMS.json#',claim$claim_id),
        approved_placement='PAPER',role='A17_LIMITED_RETROSPECTIVE_CLAIM',active_cell_links=length(ids),
        supplemental_dependencies=paste(c('Q02','Q08','exact_parent_covariance','linking_uncertainty',outside),collapse=';'),pending_choices='',
        status=if(length(outside))'REGISTERED_CLAIM_PARENTS_OUTSIDE_SELECTED_RUN'else'EXACT_CLAIM_PARENTS_AND_SEPARATE_Q08_REVIEW')
    }
  }
  l<-if(length(links))do.call(rbind,links) else data.frame(cell_id=character())
  if(nrow(l)) {
    ix<-match(l$cell_id,grid$cell_id)
    if(anyNA(ix))stop("PRODUCT_TRACE_UNCONTRACTED_CELL")
    cols<-setdiff(names(grid),"cell_id")
    l<-cbind(l,grid[ix,cols,drop=FALSE])
    l$derivation<-ifelse(grepl("^GP_SES_BASIC",l$figure_id),
      "BELOW_BASIC_FROM_EXACT_UNIT_COMPLEMENT_IF_NEEDED",
      ifelse(grepl("^GP_(SES|GENDER)_GAP",l$figure_id),
        "JOINT_REPLICATE_OR_COVARIANCE_OF_LEVELS","EXACT_PRIMITIVE_OR_CERTIFIED_DERIVATION"))
    rank_ids<-vapply(Filter(function(r)identical(r$derivation,
      "BALANCED_RANK_FROM_APPROVED_RESULTS"),defs$requirements),
      function(r)r$requirement_id,character(1))
    l$derivation[l$requirement_id%in%rank_ids]<-
      "RANK_OF_CERTIFIED_OUTCOME_OR_JOINT_GAP_WITH_FIXED_PANEL_NO_NEW_PUPIL_TASK"
    l$derivation[l$product=='PAPER_REGISTERED_CLAIM']<-'REGISTERED_CLAIM_EXACT_PARENT_DIFFERENCE_AND_Q08_COVARIANCE'
  }
  write.csv(l,file.path(out,"PRIVATE_ACTIVE_PRODUCT_CELL_TRACE.csv"),row.names=FALSE,na="")
  s<-do.call(rbind,spec)
  write.csv(s,file.path(out,"ACTIVE_REQUIREMENT_REGISTER.csv"),row.names=FALSE,na="")
  invisible(s)
}

# A saved worklist cannot outlive changed scientific contracts or human choices.
lo_fixed_input_manifest <- function(repo,bundle,root,scope) {
  source(file.path(repo,"06_pipeline","LO_RUN_CONFIG.R"),local=environment())
  files<-c(tasks=file.path(bundle,"engine","TASKS.csv"),
    pool=file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"),
    environment=file.path(repo,"renv.lock"),
    decisions=file.path(repo,"06_pipeline","SCOPE_APPROVALS.csv"),
    products=file.path(repo,"06_pipeline","review_20261013","PRODUCT_REQUIREMENTS.json"),
    rank_product=file.path(repo,"06_pipeline","review_20261013","RANK_PRODUCT_CONTRACT.json"),
    extensions=file.path(repo,"06_pipeline","LO_APPROVED_EXTENSIONS.R"),
    gender_policy=file.path(repo,"06_pipeline","LO_GENDER_POOL_POLICY.R"),
    scope_code=file.path(repo,"06_pipeline","LO_SCOPE_DECISIONS.R"),
    country_decisions=file.path(repo,"06_pipeline","COUNTRY_PRODUCTION_APPROVALS.csv"),
    country_code=file.path(repo,"06_pipeline","LO_COUNTRY_REGISTRY.R"),
    population_review=file.path(repo,"06_pipeline","review_20261013","POPULATION_CORRECTIONS.json"),
    population_code=file.path(repo,"06_pipeline","LO_POPULATION_REVIEW.R"),
    paper_policy=file.path(repo,"06_pipeline","review_20261013","PAPER_QA_CURRENT.json"),
    paper_claims=file.path(repo,"06_pipeline","review_20261013","PAPER_CLAIMS.json"),
    balance_policy=file.path(repo,"06_pipeline","review_20261013","BALANCED_REFERENCE_POLICY.json"),
    anchor=file.path(repo,"06_pipeline","review_20261013","NLD_POLICY_CORE_YEAR_ANCHOR.csv"),
    support=file.path(root,"master_reconciliation","SOURCE_SUPPORT_CONTRACTS.csv"),
    compute=file.path(root,"master_reconciliation","SCIENTIFIC_COMPUTE_APPROVALS.csv"),
    validated=file.path(root,"master_reconciliation","SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv"),
    unavailable=file.path(root,"master_reconciliation","SOURCE_UNAVAILABLE_CELLS.csv"))
  hashes<-vapply(files,function(p)if(file.exists(p))
    digest::digest(file=p,algo="sha256") else "ABSENT",character(1))
  cfg<-lo_run_config(scope)
  hashes<-c(hashes,fresh_source_replication=if(Sys.getenv('LO_FRESH_REPLICATION','')=='1')'ENABLED'else'DISABLED',
    run_configuration=lo_run_config_hash(cfg),
    run_config_code=digest::digest(file=file.path(repo,"06_pipeline","LO_RUN_CONFIG.R"),algo="sha256"))
  list(scope=scope,configuration=cfg,sha256=as.list(hashes))
}
