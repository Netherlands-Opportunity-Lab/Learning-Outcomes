# Snapshot-first scientific evidence registry. All record-level evidence stays
# local/private. Never treat a numeric match or metric_key as scientific approval.
lo_existing_result_evidence <- function(bundle, tasks, state,
                                        lo02_root="") {
  if(!all(c("metric_key","survey","country")%in%names(tasks)) ||
     anyDuplicated(tasks$metric_key))
    stop("EVIDENCE_HOLD: invalid scope contract")
  dir.create(state,recursive=TRUE,showWarnings=FALSE)
  keys <- tasks$metric_key
  empty <- data.frame(metric_key=character(),source_kind=character(),
    source_record=character(),estimate=character(),se=character(),
    n_unweighted=character(),input_fingerprint=character(),
    science_fingerprint=character(),source_sha256=character(),
    scientific_status=character(),stringsAsFactors=FALSE)
  normal <- function(x,source) {
    if(!nrow(x))return(empty)
    col <- function(k)if(k%in%names(x))as.character(x[[k]]) else
      rep("",nrow(x))
    y <- data.frame(metric_key=col("metric_key"),source_kind=source,
      source_record=if("record_version_id"%in%names(x))
        col("record_version_id") else col("result_hash"),
      estimate=col("estimate"),se=col("se"),
      n_unweighted=if("n_unweighted"%in%names(x))
        col("n_unweighted") else if("n"%in%names(x)) col("n") else
          rep("",nrow(x)),
      input_fingerprint=col("input_fingerprint"),
      science_fingerprint=col("science_fingerprint"),
      source_sha256=if("evidence_source_sha256"%in%names(x))
        col("evidence_source_sha256") else col("source_sha256"),
      scientific_status=col("scientific_status"),
      stringsAsFactors=FALSE)
    y <- y[!is.na(y$metric_key)&y$metric_key%in%keys,,drop=FALSE]
    y
  }
  z <- list()
  for(source in c("LO01_HISTORICAL_CANDIDATES","LO02_RETURN_20261010_CURRENT_RESULTS")) {
    path <- file.path(bundle,"evidence",paste0(source,".csv.gz"))
    if(!file.exists(path))stop("EVIDENCE_HOLD: pinned historical archive missing: ",source)
    con <- gzfile(path,"rt")
    x <- tryCatch(read.csv(con,colClasses="character",check.names=FALSE,
                  stringsAsFactors=FALSE,na.strings=character()),
       finally=close(con))
    z[[length(z)+1L]] <- normal(x,source)
  }
  # Bounded live LO02 SQLite, if available. Never read student tables.
  dirs <- c(file.path(state,"..","lo02"),
            file.path(state,"..","verified_snapshots"),
            lo02_root)
  dirs <- unique(dirs[nzchar(dirs)&dir.exists(dirs)])
  dbs <- unique(unlist(lapply(dirs,function(d)
    list.files(d,pattern="[.](sqlite|sqlite3|db)$",
               recursive=TRUE,full.names=TRUE,ignore.case=TRUE)),
      use.names=FALSE))
  if(length(dbs)>100L)stop("EVIDENCE_HOLD: >100 SQLite objects; use registry inventory")
  if(length(dbs)) {
    # file.info(character(0)) errors on both current Windows and Linux R.
    sizes <- file.info(dbs)$size
    dbs <- dbs[is.finite(sizes) & sizes<2e9]
  }
  dbaudit <- list()
  if(length(dbs) && requireNamespace("DBI",quietly=TRUE) &&
      requireNamespace("RSQLite",quietly=TRUE) &&
      requireNamespace("digest",quietly=TRUE))
    for(p in dbs) {
      con <- tryCatch(DBI::dbConnect(RSQLite::SQLite(),p,
          flags=RSQLite::SQLITE_RO),error=function(e)NULL)
      if(is.null(con))next
      tryCatch({
        for(tab in intersect(DBI::dbListTables(con),
                    c("results","result_history","current_results"))) {
          cols <- DBI::dbListFields(con,tab)
          required <- c("metric_key","estimate","se")
          if(!all(required%in%cols))next
          allow <- intersect(c("metric_key","estimate","se","n","n_unweighted",
            "record_version_id","result_hash","science_fingerprint",
            "input_fingerprint","scientific_status","source_sha256"),cols)
          quote <- function(x)as.character(DBI::dbQuoteIdentifier(con,x))
          sql <- paste0("SELECT ",paste(vapply(allow,quote,character(1)),
            collapse=",")," FROM ",quote(tab))
          x <- DBI::dbGetQuery(con,sql)
          if(nrow(x)>1000000L)stop("EVIDENCE_HOLD: oversized aggregate table")
          z[[length(z)+1L]] <- normal(x,paste0("LIVE_LO02_",tab))
          dbaudit[[length(dbaudit)+1L]] <- data.frame(
             database_sha256=digest::digest(file=p,algo="sha256"),
             table_name=tab,rows=nrow(x),review_status="NOT_RELEASED",
             stringsAsFactors=FALSE)
        }
      },finally=DBI::dbDisconnect(con))
    }
  evidence <- if(length(z))do.call(rbind,z) else empty
  if(any(!nzchar(evidence$metric_key)))
    stop("EVIDENCE_HOLD: empty key passed scope filter")
  # Distinct archives can contain equivalent/superseded numeric rows.
  # Distinct values are a mandatory HOLD, never pick newest.
  idx <- match(evidence$metric_key,keys)
  scope <- tasks$country[idx]
  evidence$country <- scope
  evidence$has_estimate_and_se <- is.finite(suppressWarnings(as.numeric(evidence$estimate))) &
    is.finite(suppressWarnings(as.numeric(evidence$se))) &
    suppressWarnings(as.numeric(evidence$se))>=0
  evidence$has_sample_n <- is.finite(suppressWarnings(as.numeric(evidence$n_unweighted))) &
    suppressWarnings(as.numeric(evidence$n_unweighted))>0
  evidence$reuse_gate <- "HOLD_REQUIRE_INDEPENDENT_SAMPLE_METHOD_INPUT_PV_N_REVIEW"
  out <- file.path(state,"FINAL_FIXED_PIPELINE")
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  write.csv(evidence,file.path(out,"PRIVATE_ARCHIVE_EVIDENCE.csv"),
     row.names=FALSE,na="")
  audit <- if(length(dbaudit))do.call(rbind,dbaudit) else
    data.frame(database_sha256=character(),table_name=character(),
               rows=integer(),review_status=character())
  write.csv(audit,file.path(out,"PRIVATE_SQLITE_SNAPSHOT_AUDIT.csv"),row.names=FALSE)
  # One row per requested grid key; safe count summaries may leave the laptop.
  present <- keys %in% unique(evidence$metric_key)
  method <- tasks$module
  need <- data.frame(metric_key=keys,country=tasks$country,
    survey=tasks$survey,year=tasks$year,module=method,
    archive_candidates=as.integer(tabulate(match(evidence$metric_key,keys),
                                    nbins=length(keys))),
    status=ifelse(present,"ARCHIVE_CANDIDATE_NOT_APPROVED",
             "SEARCH_CENTRAL_V8_V9_V11_BEFORE_COMPUTE"),
    approved_to_compute="NO",stringsAsFactors=FALSE)
  write.csv(need,file.path(out,"PRIVATE_GRID_MATCH_STATUS.csv"),
            row.names=FALSE)
  count <- aggregate(list(n=rep(1L,nrow(need))),
       need[c("country","survey","module","status")],sum)
  write.csv(count,file.path(out,"PRIVATE_MATCH_COUNTS.csv"),row.names=FALSE)
  summary <- data.frame(scope_contracts=nrow(tasks),
       keys_with_archive_candidates=sum(present),
       without_archive_candidate=sum(!present),
       archive_record_versions=nrow(evidence),
       candidate_rows_with_numeric_se=sum(evidence$has_estimate_and_se),
       candidate_rows_with_sample_n=sum(evidence$has_sample_n),
       approved_to_reuse=0L,approved_to_compute=0L,
       status="AWAIT_SCIENTIFIC_IDENTITY_VALIDATION",
       stringsAsFactors=FALSE)
  write.csv(summary,file.path(out,"RECONCILIATION_SUMMARY.csv"),row.names=FALSE)
  invisible(list(summary=summary,evidence=evidence,match=need))
}
