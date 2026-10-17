# Contract-to-observed scientific identity reconciliation, read-only.
# Not a scientific release: a matching metric key alone is not proof of valid method.
lo_contract_reuse_queue <- function(bundle) {
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  base <- file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation")
  decisions <- file.path(base,"CANONICAL_RESULT_REUSE_DECISIONS_PRIVATE.csv")
  taskfile <- file.path(bundle,"engine","TASKS.csv")
  if(!file.exists(decisions)||!file.exists(taskfile))stop("Canonical decisions or October contract absent")
  d <- read.csv(decisions,stringsAsFactors=FALSE,colClasses="character",check.names=FALSE)
  tasks <- read.csv(taskfile,stringsAsFactors=FALSE,colClasses="character",check.names=FALSE)
  if(!all(c("metric_key","decision","distinct_result_hashes")%in%names(d)) ||
     !all(c("metric_key","country","module","survey")%in%names(tasks)))
    stop("Scientific contract/reconciliation schema mismatch")
  if(anyDuplicated(tasks$metric_key))stop("Duplicate contract metric_key")
  # Multiple identities for one metric_key must not be assumed to represent one result.
  g <- split(seq_len(nrow(d)),d$metric_key)
  stat <- lapply(g,function(ix) {
    x <- d[ix,,drop=FALSE]
    conflict <- as.numeric(x$distinct_result_hashes)>1L
    data.frame(metric_key=x$metric_key[1L],candidate_identities=nrow(x),
      hash_conflict_identities=sum(conflict,na.rm=TRUE),
      numeric_conflict_identities=if("distinct_numeric_estimate_se"%in%names(x))
        sum(as.numeric(x$distinct_numeric_estimate_se)>1L,na.rm=TRUE) else NA_integer_,
      stringsAsFactors=FALSE)
  })
  observed <- if(length(stat))do.call(rbind,stat) else data.frame(
    metric_key=character(),candidate_identities=integer(),
    hash_conflict_identities=integer(),numeric_conflict_identities=integer())
  ix <- match(tasks$metric_key,observed$metric_key)
  tasks$candidate_identities <- observed$candidate_identities[ix]
  tasks$hash_conflict_identities <- observed$hash_conflict_identities[ix]
  tasks$numeric_conflict_identities <- observed$numeric_conflict_identities[ix]
  tasks$candidate_identities[is.na(tasks$candidate_identities)] <- 0L
  tasks$hash_conflict_identities[is.na(tasks$hash_conflict_identities)] <- 0L
  # Archive evidence is not in the 55,915-identity SQLite comparison in all cases.
  # Look up these two already checksum-pinned archived registers before calling
  # any key missing. No student data are read or recalculated.
  keys_from_archive <- function(rel) {
    p <- file.path(bundle,rel)
    if(!file.exists(p))return(character())
    con <- if(grepl("[.]gz$",p))gzfile(p,"rt") else file(p,"rt")
    on.exit(close(con),add=TRUE)
    x <- read.csv(con,stringsAsFactors=FALSE,colClasses="character",
                  check.names=FALSE)
    if(!"metric_key"%in%names(x))stop("Archive metric_key missing: ",rel)
    unique(as.character(x$metric_key[!is.na(x$metric_key) & nzchar(x$metric_key)]))
  }
  lo01 <- keys_from_archive("evidence/LO01_HISTORICAL_CANDIDATES.csv.gz")
  lo02 <- keys_from_archive("evidence/LO02_RETURN_20261010_CURRENT_RESULTS.csv.gz")
  tasks$lo01_historical_candidate <- tasks$metric_key %in% lo01
  tasks$lo02_archived_candidate <- tasks$metric_key %in% lo02
  numeric <- tasks$numeric_conflict_identities
  numeric[is.na(numeric)] <- 0L
  # The numeric equality summary is only reliable where both estimate AND SE
  # were present. The canonical decision label documents that distinction.
  labels <- lapply(g,function(ix)unique(as.character(d$decision[ix])))
  names(labels) <- names(g)
  incomplete <- vapply(labels,function(a)
    any(a=="HASH_CONFLICT_NUMERIC_EVIDENCE_INCOMPLETE"),logical(1))
  # Map each task to a *reason*, not to scientific release permission.
  hashes_missing_numeric <- tasks$metric_key %in% names(incomplete)[incomplete]
  tasks$scientific_action <- ifelse(numeric>0L,
     "ADJUDICATE_NUMERIC_CONFLICT",
    ifelse(hashes_missing_numeric,"REVIEW_HASH_NUMERIC_INCOMPLETE",
    ifelse(tasks$hash_conflict_identities>0L,"REVIEW_HASH_METADATA_PARITY",
    ifelse(tasks$candidate_identities>0L,"VALIDATE_EXISTING_RESULT",
    ifelse(tasks$lo02_archived_candidate,"VALIDATE_LO02_ARCHIVE_CANDIDATE",
    ifelse(tasks$lo01_historical_candidate,"REVIEW_LO01_HISTORIC_CANDIDATE",
           "SEARCH_HISTORICAL_BEFORE_COMPUTE"))))))
  tasks$engine_route <- ifelse(tasks$survey=="PISA" &
     tasks$module %in% c("core","gender"),
     "LO02_V5_NATIVE_PER_TASK_INPUT_AND_SCIENCE_FINGERPRINT_REUSE",
     "MODULE_METHOD_CERTIFICATION_REQUIRED")
  # Split work by production phase, never mistake OECD19 for the full
  # international dashboard universe.
  ref <- file.path(dirname(taskfile),"..","PPP_COMPARATOR_MEMBERSHIP_v2.csv")
  comparator <- if(file.exists(ref))read.csv(ref,stringsAsFactors=FALSE) else data.frame()
  foreign <- if(all(c("country","strictly_above_czechia")%in%names(comparator)))
    setdiff(as.character(comparator$country[
      as.character(comparator$strictly_above_czechia)=="TRUE"]), "NLD") else character()
  tasks$production_phase <- ifelse(tasks$country=="NLD","01_NLD",
    ifelse(tasks$country%in%foreign,"02_REFERENCE19","03_OTHER"))
  # A single metric_key may have multiple historical input/specification identities.
  # These counts are candidates, not a green light to reuse.
  tasks$next_gate <- ifelse(tasks$scientific_action=="ADJUDICATE_NUMERIC_CONFLICT",
    "VERIFY_NUMERIC_SOURCE_SAMPLE_DESIGN_AND_CURRENT_VERSION",
    ifelse(tasks$scientific_action=="REVIEW_HASH_NUMERIC_INCOMPLETE",
      "VERIFY_ESTIMATE_AND_SE_PRESENT_BEFORE_NUMERIC_PARITY_CLAIM",
    ifelse(tasks$scientific_action=="REVIEW_HASH_METADATA_PARITY",
      "CHECK_HASH_DEFINITION_METADATA_CI_AND_PROVENANCE_NO_RECOMPUTE_YET",
    ifelse(tasks$scientific_action %in% c("VALIDATE_EXISTING_RESULT",
        "VALIDATE_LO02_ARCHIVE_CANDIDATE","REVIEW_LO01_HISTORIC_CANDIDATE"),
      "CHECK_INPUT_SPECIFICATION_CODE_AND_DESIGN_VARIANCE",
      "SEARCH_V8_V9_V11_AND_LO02_BEFORE_COMPUTE"))))
  tasks$release_status <- "NOT_RELEASED_METHOD_AND_INPUT_CHECK_PENDING"
  wanted <- c("metric_key","country","survey","module","production_phase","scientific_action","next_gate","engine_route",
     "lo01_historical_candidate","lo02_archived_candidate",
     "candidate_identities","hash_conflict_identities",
     "numeric_conflict_identities","release_status")
  write.csv(tasks[,wanted],file.path(base,"CONTRACT_LEVEL_REUSE_AND_COMPUTE_QUEUE.csv"),
            row.names=FALSE)
  coverage <- aggregate(list(n=rep(1L,nrow(tasks))),
       tasks[c("country","survey","module","scientific_action")],sum)
  write.csv(coverage,file.path(base,"CONTRACT_COVERAGE_BY_FAMILY.csv"),row.names=FALSE)
  n <- table(tasks$scientific_action)
  cat("Contract reconciliation: ",nrow(tasks)," contracts; ",
      paste(names(n),as.integer(n),collapse="; "),"\n",sep="")
  cat("Note: exact key coverage does NOT imply scientific reuse eligibility.\n")
  invisible(n)
}
