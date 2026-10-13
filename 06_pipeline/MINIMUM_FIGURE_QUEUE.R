# Product-driven minimum-new-computation planning. Read-only sources;
# never promotes historical candidates to VALIDATED and never recalculates pupils.
lo_minimum_figure_queue <- function(bundle, root, expected_contracts=79448L,
                                    expected_figures=138L) {
  stopifnot(dir.exists(bundle),dir.exists(root))
  source_csv <- function(rel) {
    p <- file.path(bundle,rel)
    if(!file.exists(p))stop("MINIMUM_PLAN_HOLD: missing pinned ",rel)
    con <- if(endsWith(rel,".gz"))gzfile(p,"rt") else file(p,"rt")
    on.exit(close(con))
    read.csv(con,colClasses="character",check.names=FALSE,na.strings=character(),
             stringsAsFactors=FALSE)
  }
  tasks <- source_csv("engine/TASKS.csv")
  fig <- source_csv("FIGURE_SERIES_CONTRACT_20261002.csv")
  lo01 <- source_csv("evidence/LO01_HISTORICAL_CANDIDATES.csv.gz")
  lo02 <- source_csv("evidence/LO02_RETURN_20261010_CURRENT_RESULTS.csv.gz")
  if(nrow(tasks)!=expected_contracts || nrow(fig)!=expected_figures ||
     anyDuplicated(tasks$metric_key))stop("MINIMUM_PLAN_HOLD: contract lock mismatch")
  a <- unique(lo01$metric_key)
  b <- unique(lo02$metric_key)
  # Existing archived candidates are NOT automatically scientifically reusable.
  tasks$archive_lo01_candidate <- tasks$metric_key %in% a
  tasks$archive_lo02_candidate <- tasks$metric_key %in% b
  tasks$archive_evidence <- ifelse(tasks$archive_lo02_candidate,
    "LO02_UNVALIDATED_CANDIDATE",ifelse(tasks$archive_lo01_candidate,
    "LO01_UNVALIDATED_CANDIDATE","NO_LO01_LO02_MATCH_CHECK_OLDER_CACHES"))
  # Post-user-decision product roles; no silent deletion from original lock.
  tasks$figure_family <- sub("_age.*$","",tasks$contract_figure_id)
  tasks$product_decision <- ifelse(tasks$figure_family=="TR_BASIC",
       "DROP_SEPARATE_VISUAL_CAN_DERIVE_COMPLEMENT",
    ifelse(tasks$figure_family=="GP_SES_HIGH","OPTIONAL_APPENDIX",
    ifelse(tasks$figure_family=="EN_PERFORMANCE_PEER",
      "ORIGINAL_HIGH_PEER_OPTIONAL_NEW_BELOW_BASIC_NOT_IN_LOCK",
    ifelse(tasks$figure_family=="GP_SES_BASIC",
      "DERIVE_BELOW_BASIC_BY_SES_FROM_ABOVE_COMPLEMENT",
    ifelse(tasks$figure_family %in% c("GP_SES_GAP","GP_GENDER_GAP",
                                     "DS_SPREAD","GP_MIGRATION_GAP",
                                     "GP_LANGUAGE_GAP"),
      "DERIVED_CONTRAST_REQUIRES_JOINT_VARIANCE",
    ifelse(tasks$figure_family=="EN_PERFORMANCE_PEER",
      "PRIMARY_BELOW_BASIC_OR_OPTIONAL_ADVANCED_REDEFINE_METRIC",
      "ACTIVE_BASE_CONTRACT"))))))
  # A DERIVED label never proves that the inputs or their uncertainty exist.
  tasks$minimum_action <- ifelse(tasks$archive_lo01_candidate |
                                 tasks$archive_lo02_candidate,
       "VALIDATE_CANDIDATE_NO_COMPUTE_YET",
       "SEARCH_CENTRAL_V8_V9_V11_BEFORE_COMPUTE")
  tasks$scientific_validation <- "NOT_RELEASED"
  tasks$approval_to_compute <- "NO"
  # Cache validity is not inferred from metric_key or mtime.
  # Contract-level current decisions, where present, are diagnostic only.
  qfile <- file.path(root,"master_reconciliation",
                    "CONTRACT_LEVEL_REUSE_AND_COMPUTE_QUEUE.csv")
  if(file.exists(qfile)) {
    q <- read.csv(qfile,colClasses="character",check.names=FALSE)
    if(!all(c("metric_key","scientific_action")%in%names(q)) ||
       anyDuplicated(q$metric_key))
      stop("MINIMUM_PLAN_HOLD: untrustworthy local contract queue")
    ix <- match(tasks$metric_key,q$metric_key)
    tasks$central_observation <- q$scientific_action[ix]
    tasks$central_observation[is.na(tasks$central_observation)] <-
       "NO_CURRENT_CENTRAL_MATCH"
  } else tasks$central_observation <- "NOT_YET_RECONCILED"
  # Snapshot comparisons are evidence only, not permission to compute/reuse.
  sub <- c("figure_family","country","survey","module","product_decision")
  count <- aggregate(list(contract_count=rep(1L,nrow(tasks))),tasks[sub],sum)
  detailed <- aggregate(list(n=rep(1L,nrow(tasks))),
          tasks[c("figure_family","product_decision","minimum_action")],sum)
  out <- file.path(root,"master_reconciliation","MINIMUM_FIGURE_QUEUE")
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  # Avoid exporting full private metric_key + path register via the Drive
  # report channel; files stay local until classified separately.
  write.csv(tasks[,c("metric_key","country","survey","year","module",
     "contract_figure_id","archive_evidence","product_decision",
     "minimum_action","central_observation","scientific_validation",
     "approval_to_compute")],
    file.path(out,"PRIVATE_METRIC_REUSE_QUEUE.csv"),row.names=FALSE)
  write.csv(count,file.path(out,"FIGURE_FAMILY_COUNTRY_MODULE_COUNTS.csv"),row.names=FALSE)
  write.csv(detailed,file.path(out,"FIGURE_FAMILY_MINIMUM_ACTION_COUNTS.csv"),row.names=FALSE)
  # 2026-10-12 decision: the mandatory BELOW-basic peer measure is
  # NOT an outcome in the locked high-peer contract. Each old 3-task
  # peer-context tuple is a potential new 3-task low-peer design, NOT
  # an already computed result and NOT automatically authorized.
  oldpeer <- tasks[tasks$figure_family=="EN_PERFORMANCE_PEER",,drop=FALSE]
  peer_context <- c("country","survey","year","domain","peer_definition")
  context <- unique(oldpeer[,peer_context,drop=FALSE])
  # Do not silently assume a valid peer base, composition or threshold
  # is available; each proposed unit needs method/denominator checks.
  context$proposed_primary_measure <- "peer_share_below_basic"
  context$proposed_groups <- "total;self_below_basic;self_at_or_above_basic"
  context$proposed_result_cells <- 3L
  context$scientific_status <- "REQUIRES_METHOD_SOURCE_AND_REUSE_AUDIT"
  context$approval_to_compute <- "NO"
  write.csv(context,file.path(out,"ADDITIONAL_BELOW_BASIC_PEER_CONTEXTS.csv"),
            row.names=FALSE)
  active <- data.frame(
    category=c("ORIGINAL_LOCKED","REMOVED_COMPLEMENT_DISPLAY",
      "OPTIONAL_SES_ADVANCED","OPTIONAL_ORIGINAL_HIGH_PEERS",
      "RETAINED_LOCKED_CONTRACTS",
      "DERIVED_GAP_OR_SPREAD_WITH_JOINT_VARIANCE",
      "NEW_BELOW_BASIC_PEER_DESIGN_CANDIDATES"),
    contract_cells=c(nrow(tasks),
       sum(tasks$figure_family=="TR_BASIC"),
       sum(tasks$figure_family=="GP_SES_HIGH"),
       nrow(oldpeer),
       sum(!tasks$figure_family%in%c("TR_BASIC","GP_SES_HIGH",
                                  "EN_PERFORMANCE_PEER")),
       sum(tasks$figure_family%in%c("GP_SES_GAP","GP_GENDER_GAP",
          "GP_LANGUAGE_GAP","GP_MIGRATION_GAP","DS_SPREAD")),
       3L*nrow(context)),
    note=c("Historical task lock unchanged",
      "Above basic is 100%-below basic; separate display removed",
      "Original SES high/advanced only optional appendix",
      "Original high-peer design is NOT the new primary below-basic design",
      "Before candidate reuse, method/uncertainty gates apply",
      "Point contrast derivable; SE needs covariance/PV/replicate support",
      "Additional concepts outside 79448 original tasks; NOT approved compute"),
    stringsAsFactors=FALSE)
  write.csv(active,file.path(out,"ACTIVE_PRODUCT_RECONCILIATION.csv"),
            row.names=FALSE)
  summary <- data.frame(
    total_contracts=nrow(tasks),
    archived_candidate_any=sum(tasks$archive_lo01_candidate |
                               tasks$archive_lo02_candidate),
    no_match_in_two_archives=sum(!tasks$archive_lo01_candidate &
                                  !tasks$archive_lo02_candidate),
    proven_new_computations=NA_integer_,
    reason="Other caches and scientific provenance still unverified",
    scientific_release="NOT_GRANTED",stringsAsFactors=FALSE)
  write.csv(summary,file.path(out,"MINIMUM_COMPUTE_BOUNDS.csv"),row.names=FALSE)
  cat("MINIMUM FIGURE QUEUE: ",nrow(tasks)," contract tasks; ",
      summary$archived_candidate_any," LO01/LO02 candidates; ",
      summary$no_match_in_two_archives,
      " need other-cache check before considering new computation. ",
      "No tasks automatically approved for recomputation.\n",sep="")
  invisible(summary)
}
