# Product-driven minimum-new-computation planning. Read-only sources;
# never promotes historical candidates to VALIDATED and never recalculates pupils.
lo_minimum_figure_queue <- function(bundle, root) {
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
  if(nrow(tasks)!=79448L || nrow(fig)!=138L ||
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
    ifelse(tasks$figure_family %in% c("GP_SES_GAP","GP_GENDER_GAP",
                                     "DS_SPREAD","GP_MIGRATION_GAP",
                                     "GP_LANGUAGE_GAP"),
      "DERIVED_CONTRAST_REQUIRES_JOINT_VARIANCE",
    ifelse(tasks$figure_family=="EN_PERFORMANCE_PEER",
      "PRIMARY_BELOW_BASIC_OR_OPTIONAL_ADVANCED_REDEFINE_METRIC",
      "ACTIVE_BASE_CONTRACT"))))
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
