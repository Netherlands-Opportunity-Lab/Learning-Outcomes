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
  tasks$scientific_action <- ifelse(tasks$candidate_identities==0L,
    "COMPUTE_OR_FIND_OLDER_RESULT",
    ifelse(tasks$hash_conflict_identities>0L,
       "ADJUDICATE_CONFLICT","VALIDATE_EXISTING_RESULT"))
  tasks$release_status <- "NOT_RELEASED_METHOD_AND_INPUT_CHECK_PENDING"
  wanted <- c("metric_key","country","survey","module","scientific_action",
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
