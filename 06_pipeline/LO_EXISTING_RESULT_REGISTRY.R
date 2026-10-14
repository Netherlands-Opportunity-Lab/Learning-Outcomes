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
    scientific_status=character(),code_fingerprint=character(),
    result_hash=character(),is_current=character(),stringsAsFactors=FALSE)
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
      scientific_status=if("scientific_status"%in%names(x))
        col("scientific_status") else col("status"),
      code_fingerprint=col("code_fingerprint"),result_hash=col("result_hash"),
      is_current=col("is_current"),
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
  results_root <- normalizePath(file.path(state,"..",".."),
                                  winslash="/",mustWork=TRUE)
  master_root <- Sys.getenv("LO_MASTER_PROJECT_ROOT",file.path(
     Sys.getenv("USERPROFILE",unset=path.expand("~")),
     "Downloads","PISA_PIRLS_MASTER_PIPELINE"))
  dirs <- c(file.path(results_root,"consolidated"),
            file.path(results_root,"verified_snapshots"),
            file.path(results_root,"lo02"),
            file.path(master_root,"00_PROJECT_REGISTRY"),
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
                    c("results","result_history","current_results",
                      "result_versions","results_v4"))) {
          cols <- DBI::dbListFields(con,tab)
          required <- c("metric_key","estimate","se")
          if(!all(required%in%cols))next
          allow <- intersect(c("metric_key","estimate","se","n","n_unweighted",
            "record_version_id","result_hash","science_fingerprint",
            "input_fingerprint","scientific_status","source_sha256",
            "source_id","code_id","publication_status","code_fingerprint",
            "is_current","status"),cols)
          quote <- function(x)as.character(DBI::dbQuoteIdentifier(con,x))
          # Bound before fetching; legacy input signatures can be kilobytes
          # per row. Preserve real SHA values but do not duplicate size/mtime
          # lists from every database backup in the in-memory evidence table.
          n_source <- DBI::dbGetQuery(con,paste0("SELECT COUNT(*) AS n FROM ",
             quote(tab)))$n[[1L]]
          if(n_source>1000000L)stop("EVIDENCE_HOLD: oversized aggregate table")
          select <- vapply(allow,function(k) {
            if(k=="input_fingerprint") paste0("CASE WHEN length(",quote(k),
              ")=64 THEN ",quote(k)," ELSE 'NON_SHA256_SIGNATURE' END AS ",quote(k))
            else quote(k)
          },character(1L))
          sql <- paste0("SELECT ",paste(select,
            collapse=",")," FROM ",quote(tab))
          x <- DBI::dbGetQuery(con,sql)
          if(nrow(x)>1000000L)stop("EVIDENCE_HOLD: oversized aggregate table")
          category <- if(tab=="result_versions")"LIVE_CONSOLIDATED_" else
            if(tab=="results_v4")"LIVE_REGISTRY_" else "LIVE_LO02_"
          z[[length(z)+1L]] <- normal(x,paste0(category,tab))
          dbaudit[[length(dbaudit)+1L]] <- data.frame(
             database_sha256=digest::digest(file=p,algo="sha256"),
             table_name=tab,rows=nrow(x),review_status="NOT_RELEASED",
             stringsAsFactors=FALSE)
        }
      },finally=DBI::dbDisconnect(con))
    }
  # Also inspect already-checked-in canonical current/history Parquet stores,
  # never any pupil tables. Do not create a new 89 GiB source file scan.
  parquet_paths <- c(
    file.path(master_root,"03_RESULTS/current/CURRENT_RESULTS.parquet"),
    file.path(master_root,"03_RESULTS/history/RESULT_HISTORY.parquet"),
    file.path(lo02_root,"registry_v5/CURRENT_RESULTS.parquet"),
    file.path(lo02_root,"registry_v5/RESULT_HISTORY.parquet"))
  parquet_paths <- parquet_paths[file.exists(parquet_paths)]
  parquet_audit <- list()
  for(path in parquet_paths) {
    sz <- file.info(path)$size
    if(!is.finite(sz)||sz>2e9) {
      parquet_audit[[length(parquet_audit)+1L]] <- data.frame(
         source=basename(path),status="HOLD_LARGE_SOURCE_NOT_SCANNED",
         n_candidate=0L,stringsAsFactors=FALSE)
      next
    }
    if(!requireNamespace("arrow",quietly=TRUE)) {
      parquet_audit[[length(parquet_audit)+1L]] <- data.frame(
         source=basename(path),status="HOLD_ARROW_NOT_INSTALLED",
         n_candidate=0L,stringsAsFactors=FALSE)
      next
    }
    obj <- tryCatch({
      reader <- arrow::ParquetFileReader$create(path)
      cols <- reader$GetSchema()$names
      must <- c("metric_key","estimate","se")
      if(!all(must%in%cols))stop("HOLD_PARQUET_METRIC_SCHEMA")
      allowed <- intersect(c(must,"record_version_id","result_hash",
         "input_fingerprint","science_fingerprint","scientific_status",
         "source_sha256","n","n_unweighted"),cols)
      as.data.frame(arrow::read_parquet(path,col_select=allowed))
    },error=function(e)e)
    if(inherits(obj,"error")) {
      parquet_audit[[length(parquet_audit)+1L]] <- data.frame(
        source=basename(path),
        status=substr(paste0("HOLD_READ_ERROR_",conditionMessage(obj)),1,140),
        n_candidate=0L,stringsAsFactors=FALSE)
      next
    }
    if(nrow(obj)>1e6)stop("EVIDENCE_HOLD: parquet has >1m aggregate rows")
    normalized <- normal(obj,paste0("LIVE_PARQUET_",basename(path)))
    z[[length(z)+1L]] <- normalized
    parquet_audit[[length(parquet_audit)+1L]] <- data.frame(
      source=basename(path),status="READ_ONLY_CANDIDATES_NOT_VALIDATED",
      n_candidate=nrow(normalized),stringsAsFactors=FALSE)
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
  # Nonempty size/mtime signatures are not cryptographic input identities.
  evidence$has_input_sha256 <- !is.na(evidence$input_fingerprint) &
    grepl("^[a-fA-F0-9]{64}$",evidence$input_fingerprint)
  evidence$reuse_gate <- "HOLD_REQUIRE_INDEPENDENT_SAMPLE_METHOD_INPUT_PV_N_REVIEW"
  out <- file.path(state,"FINAL_FIXED_PIPELINE")
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  write.csv(evidence,file.path(out,"PRIVATE_ARCHIVE_EVIDENCE.csv"),
     row.names=FALSE,na="")
  audit <- if(length(dbaudit))do.call(rbind,dbaudit) else
    data.frame(database_sha256=character(),table_name=character(),
               rows=integer(),review_status=character())
  write.csv(audit,file.path(out,"PRIVATE_SQLITE_SNAPSHOT_AUDIT.csv"),row.names=FALSE)
  parquet_summary <- if(length(parquet_audit))do.call(rbind,parquet_audit)
     else data.frame(source=character(),status=character(),
                     n_candidate=integer())
  write.csv(parquet_summary,file.path(out,"PRIVATE_PARQUET_SNAPSHOT_AUDIT.csv"),
     row.names=FALSE)
  # Legacy V8/V9 are useful evidence but contain no exact locked
  # metric_key / sampling N. Their country-wave-domain-stat matches are
  # always COARSE_CANDIDATES, not scientifically approved results.
  legacy_files <- c(
    "V8_NLD_DASHBOARD_GRID_FULL.csv.gz",
    "V9_COUNTRIES_NEW_MASTER_ROWS.csv.gz")
  coarse <- character()
  coarse_versions <- list()
  for(legacy in legacy_files) {
    p <- file.path(bundle,"evidence",legacy)
    if(!file.exists(p))stop("EVIDENCE_HOLD: pinned V8/V9 archive missing")
    con <- gzfile(p,"rt")
    a <- tryCatch(read.csv(con,colClasses="character",check.names=FALSE,
               na.strings=character(),stringsAsFactors=FALSE),
               finally=close(con))
    fields <- c("country","survey","year","domain","stat",
                "estimate","se","status")
    if(!all(fields%in%names(a)))stop("EVIDENCE_HOLD: V8/V9 schema changed")
    a$country <- sub("^iso3:","",a$country)
    keycols <- c("country","survey","year","domain","stat")
    item <- function(x)do.call(paste,c(x[keycols],sep="|"))
    a_key <- unique(item(a))
    coarse <- union(coarse,a_key)
    coarse_versions[[length(coarse_versions)+1L]] <- data.frame(
       source_version=legacy,
       archive_rows=nrow(a),
       numeric_estimate_se=sum(is.finite(suppressWarnings(as.numeric(a$estimate))) &
              is.finite(suppressWarnings(as.numeric(a$se)))),
       sample_N_available=FALSE,
       status="COARSE_CANDIDATE_NOT_SCIENTIFIC_REUSE",
       stringsAsFactors=FALSE)
  }
  scoped_key <- do.call(paste,c(tasks[c(
    "country","survey","year","domain","stat")],sep="|"))
  coarse_hit <- scoped_key %in% coarse
  write.csv(data.frame(metric_key=keys,archive_v8_v9_coarse_candidate=coarse_hit,
    verified_N_and_method=FALSE,
    decision="COARSE_MATCH_NOT_APPROVED_NO_SAMPLE_N"),
    file.path(out,"PRIVATE_V8_V9_CANDIDATE_MATCH.csv"),row.names=FALSE)
  write.csv(do.call(rbind,coarse_versions),
    file.path(out,"PRIVATE_V8_V9_SOURCE_SUMMARY.csv"),row.names=FALSE)
  # One row per requested grid key; safe count summaries may leave the laptop.
  present <- keys %in% unique(evidence$metric_key)
  method <- tasks$module
  need <- data.frame(metric_key=keys,country=tasks$country,
    survey=tasks$survey,year=tasks$year,module=method,
    archive_candidates=as.integer(tabulate(match(evidence$metric_key,keys),
                                    nbins=length(keys))),
    status=ifelse(present,"ARCHIVE_CANDIDATE_NOT_APPROVED",
       ifelse(coarse_hit,"V8_V9_COARSE_CANDIDATE_NOT_APPROVED",
         "SEARCH_CENTRAL_V11_AND_CURRENT_HISTORY_BEFORE_COMPUTE")),
    approved_to_compute="NO",stringsAsFactors=FALSE)
  write.csv(need,file.path(out,"PRIVATE_GRID_MATCH_STATUS.csv"),
            row.names=FALSE)
  count <- aggregate(list(n=rep(1L,nrow(need))),
       need[c("country","survey","module","status")],sum)
  write.csv(count,file.path(out,"PRIVATE_MATCH_COUNTS.csv"),row.names=FALSE)
  summary <- data.frame(scope_contracts=nrow(tasks),
       keys_with_archive_candidates=sum(present),
       without_archive_candidate=sum(!present),
       additional_v8_v9_coarse_candidate_keys=sum(coarse_hit & !present),
       archive_record_versions=nrow(evidence),
       sqlite_and_parquet_records=sum(grepl("^LIVE_",evidence$source_kind)),
       parquet_objects_seen=nrow(parquet_summary),
       candidate_rows_with_numeric_se=sum(evidence$has_estimate_and_se),
       candidate_rows_with_sample_n=sum(evidence$has_sample_n),
       candidate_rows_with_input_sha256=sum(evidence$has_input_sha256),
       approved_to_reuse=0L,approved_to_compute=0L,
       status="AWAIT_SCIENTIFIC_IDENTITY_VALIDATION",
       stringsAsFactors=FALSE)
  write.csv(summary,file.path(out,"RECONCILIATION_SUMMARY.csv"),row.names=FALSE)
  invisible(list(summary=summary,evidence=evidence,match=need))
}

