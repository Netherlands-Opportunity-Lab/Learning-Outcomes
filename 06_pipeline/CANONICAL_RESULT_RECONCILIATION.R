# Canonical-result reconciliation across historical SQLite registers.
# Read-only, reuse candidate evidence only. NO release, mutation, deletion or student reads.
lo_canonical_result_reconciliation <- function() {
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  base <- file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation")
  root <- Sys.getenv("LO_MASTER_PROJECT_ROOT",
                     file.path(home,"Downloads","PISA_PIRLS_MASTER_PIPELINE"))
  inv <- file.path(base,"MASTER_FILES_PRIVATE.csv")
  if(!file.exists(inv))stop("Inventory absent; no implicit project rescan")
  if(!requireNamespace("DBI",quietly=TRUE) ||
     !requireNamespace("RSQLite",quietly=TRUE))
    stop("Install DBI and RSQLite; canonical reconciliation cannot run")
  files <- read.csv(inv,stringsAsFactors=FALSE,check.names=FALSE)
  paths <- files$relative_path[grepl("[.]sqlite$",files$relative_path,ignore.case=TRUE)]
  paths <- unique(paths)
  records <- list(); failures <- list()
  required <- c("metric_key","input_fingerprint","code_fingerprint",
                "result_hash")
  for(rel in paths) {
    path <- file.path(root,rel)
    if(!file.exists(path))next
    con <- tryCatch(DBI::dbConnect(RSQLite::SQLite(),dbname=path,
                      flags=RSQLite::SQLITE_RO),error=function(e)e)
    if(inherits(con,"error")) {
      failures[[length(failures)+1L]] <- data.frame(source=basename(rel),
        reason="OPEN_FAILED",stringsAsFactors=FALSE);next
    }
    tryCatch({
      for(tab in intersect(c("result_records","results_v4","lifecycle_result_versions"),
                           DBI::dbListTables(con))) {
        cols <- DBI::dbListFields(con,tab)
        if(!all(required%in%cols))next
        wanted <- intersect(c("record_version_id","metric_key",
          "input_fingerprint","specification_fingerprint","code_fingerprint",
          "result_hash","status","is_current","estimate","se","ci_low","ci_high",
          "source_file","source_fingerprint","producer_run_id","producer_code_id",
          "created_at","last_verified_at"),cols)
        quoted <- as.character(DBI::dbQuoteIdentifier(con,wanted))
        tbl <- as.character(DBI::dbQuoteIdentifier(con,tab))
        # Aggregate scientific results only, not raw/student tables.
        d <- DBI::dbGetQuery(con,paste0("SELECT ",paste(quoted,collapse=","),
                                       " FROM ",tbl))
        if(nrow(d)>250000L)stop("RESULT_TABLE_OVER_LIMIT")
        if(!nrow(d))next
        for(nm in setdiff(c("record_version_id","specification_fingerprint",
          "estimate","se","status","is_current"),names(d)))d[[nm]] <- NA
        d$database <- basename(rel)
        d$table <- tab
        records[[length(records)+1L]] <- d[,c("database","table",
          "record_version_id","metric_key","input_fingerprint",
          "specification_fingerprint","code_fingerprint","result_hash",
          "status","is_current","estimate","se")]
      }
    },error=function(e)failures[[length(failures)+1L]] <<-
      data.frame(source=basename(rel),reason=conditionMessage(e),
                 stringsAsFactors=FALSE),
      finally=DBI::dbDisconnect(con))
  }
  if(!length(records)) {
    cat("Canonical comparison BLOCKED: no readable result tables with fingerprint fields.\n")
    return(invisible(FALSE))
  }
  d <- do.call(rbind,records)
  for(nm in c("metric_key","input_fingerprint","specification_fingerprint",
              "code_fingerprint","result_hash"))
    d[[nm]] <- as.character(d[[nm]])
  # Scientific identity: metric+input+specification+producer code.
  # Never treat absent provenance as a match.
  complete <- !is.na(d$metric_key)&nzchar(d$metric_key)&
    !is.na(d$input_fingerprint)&nzchar(d$input_fingerprint)&
    !is.na(d$specification_fingerprint)&nzchar(d$specification_fingerprint)&
    !is.na(d$code_fingerprint)&nzchar(d$code_fingerprint)&
    !is.na(d$result_hash)&nzchar(d$result_hash)
  d$identity <- NA_character_
  d$identity[complete] <- paste(d$metric_key[complete],
    d$input_fingerprint[complete],d$specification_fingerprint[complete],
    d$code_fingerprint[complete],sep="|")
  usable <- d[complete,,drop=FALSE]
  families <- split(usable,usable$identity)
  tally <- lapply(families,function(g) {
    hashes <- unique(g$result_hash)
    # Historical SQLite backups repeat records. Determine whether differing
    # hashes also imply differing estimates/SEs, and whether both are current.
    vals <- suppressWarnings(as.numeric(g$estimate))
    ses <- suppressWarnings(as.numeric(g$se))
    num_signature <- paste(ifelse(is.finite(vals),format(vals,digits=17,scientific=TRUE),"NA"),
                           ifelse(is.finite(ses),format(ses,digits=17,scientific=TRUE),"NA"),sep="|")
    distinct_numeric <- length(unique(num_signature))
    # A matching NA/NA placeholder must NEVER be interpreted as numerical parity.
    numeric_comparable <- all(is.finite(vals) & is.finite(ses))
    current <- toupper(as.character(g$is_current)) %in% c("TRUE","T","1")
    current_hashes <- unique(g$result_hash[current])
    is_conflict <- length(hashes)>1L
    class <- if(!is_conflict) {
      if(nrow(g)>1L)"MATCHING_COPIES_NOT_YET_VALIDATED"
      else "SINGLE_VERSION_NOT_YET_VALIDATED"
    } else if(!numeric_comparable) "HASH_CONFLICT_NUMERIC_EVIDENCE_INCOMPLETE"
      else if(distinct_numeric==1L) "HASH_CONFLICT_NUMERIC_EQUAL"
      else if(length(current_hashes)>1L) "MULTIPLE_CURRENT_NUMERIC_CONFLICT"
      else "HISTORICAL_NUMERIC_CONFLICT_NEEDS_ADJUDICATION"
    data.frame(metric_key=g$metric_key[[1]],
      evidence_copies=nrow(g),distinct_result_hashes=length(hashes),
      distinct_numeric_estimate_se=distinct_numeric,
      numeric_comparable=numeric_comparable,
      current_rows=sum(current),distinct_current_hashes=length(current_hashes),
      distinct_databases=length(unique(g$database)),
      decision=class,stringsAsFactors=FALSE)
  })
  out <- if(length(tally))do.call(rbind,tally) else data.frame(
    metric_key=character(),evidence_copies=integer(),
    distinct_result_hashes=integer(),distinct_numeric_estimate_se=integer(),numeric_comparable=logical(),
    current_rows=integer(),distinct_current_hashes=integer(),distinct_databases=integer(),
    decision=character())
  rownames(out) <- NULL
  write.csv(out,file.path(base,"CANONICAL_RESULT_REUSE_DECISIONS_PRIVATE.csv"),
            row.names=FALSE)
  status <- data.frame(
    register_rows=nrow(d),identities_with_complete_fingerprints=length(families),
    incomplete_lineage_rows=sum(!complete),
    matching_copy_identities=sum(out$decision=="MATCHING_COPIES_NOT_YET_VALIDATED"),
    conflicting_identities=sum(out$distinct_result_hashes>1L),
    numeric_conflict_identities=sum(out$numeric_comparable &
      out$distinct_numeric_estimate_se>1L),
    hash_conflicts_without_complete_numerics=sum(out$distinct_result_hashes>1L &
      !out$numeric_comparable),
    hash_conflicts_with_numerical_parity=sum(out$decision=="HASH_CONFLICT_NUMERIC_EQUAL"),
    multiple_current_numeric_conflicts=sum(out$decision=="MULTIPLE_CURRENT_NUMERIC_CONFLICT"),
    singleton_identities=sum(out$decision=="SINGLE_VERSION_NOT_YET_VALIDATED"),
    register_errors=length(failures),scientific_release="NOT_GRANTED")
  write.csv(status,file.path(base,"CANONICAL_RECONCILIATION_SUMMARY.csv"),row.names=FALSE)
  if(length(failures))write.csv(do.call(rbind,failures),
    file.path(base,"CANONICAL_RECONCILIATION_ERRORS_PRIVATE.csv"),row.names=FALSE)
  cat("Canonical records:",nrow(d),"; comparable scientific identities:",
      nrow(out),"; same-identity conflicts:",status$conflicting_identities,
      "; input/SE-incomplete hash conflicts:",status$hash_conflicts_without_complete_numerics,
      "; hash conflicts with complete numeric parity:",status$hash_conflicts_with_numerical_parity,
      "; incomplete lineage rows:",status$incomplete_lineage_rows,"\n")
  cat("Summary:",file.path(base,"CANONICAL_RECONCILIATION_SUMMARY.csv"),"\n")
  cat("Scientific release remains held pending source and methodology checks.\n")
  invisible(status)
}
lo_canonical_result_reconciliation()
