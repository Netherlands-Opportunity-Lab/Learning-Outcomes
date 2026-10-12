# Existing LO02 NLD results: read-only exact-identity export, NO pupil calculations.
# The exporter intentionally fails closed if the 40 new results cannot be
# linked to the chosen scientific run by an explicit immutable identifier.
lo_existing_result_export <- function(root, run_id) {
  stopifnot(grepl("^run_[0-9]{8}_[0-9]{6}$",run_id))
  if(!requireNamespace("DBI",quietly=TRUE) ||
     !requireNamespace("RSQLite",quietly=TRUE) ||
     !requireNamespace("digest",quietly=TRUE))
    stop("HOLD: DBI, RSQLite and digest required; no data exported")
  rundir <- file.path(root,"runs",run_id)
  if(!dir.exists(rundir)) stop("HOLD: requested source run absent")
  counts <- file.path(rundir,"PHASE_NLD",
      "LO02_RELEASED_PISA_CORE_GENDER","AANTALLEN.csv")
  if(!file.exists(counts))stop("HOLD: LO02 production counts absent")
  counts_data <- read.csv(counts,stringsAsFactors=FALSE)
  expected <- sum(as.integer(counts_data$n[counts_data$action=="COMPUTE"]),
                  na.rm=TRUE)
  if(!is.finite(expected)||expected<1L)stop("HOLD: no exact COMPUTE count")
  # Bounded search of known LO02 directories only; no 95GB project rescan.
  roots <- c(file.path(root,"lo02"),file.path(root,"LO02"),
             file.path(root,"runs",run_id,"PHASE_NLD"),
             file.path(dirname(root),"LO02_RESULTATEN"))
  roots <- roots[dir.exists(roots)]
  # Windows paths are case-insensitive: root/lo02 and root/LO02 can be the
  # same directory, so deduplicate by case-folded normalized path.
  if(length(roots)) {
    roots <- normalizePath(roots,winslash="/",mustWork=TRUE)
    roots <- roots[!duplicated(tolower(roots))]
  }
  dbs <- unlist(lapply(roots,function(p)
     list.files(p,pattern="\\.(sqlite|sqlite3|db)$",
                recursive=TRUE,full.names=TRUE,ignore.case=TRUE)))
  if(length(dbs)) {
    dbs <- normalizePath(dbs,winslash="/",mustWork=TRUE)
    dbs <- dbs[!duplicated(tolower(dbs))]
  }
  outdir <- file.path(rundir,"PRIVATE_RESULT_EXPORT")
  dir.create(outdir,recursive=TRUE,showWarnings=FALSE)
  diag <- list()
  eligible <- list()
  approved_names <- c("metric_key","country","survey","module","year",
     "stat","group","estimate","se","ci_low","ci_high","method_id",
     "input_fingerprint","science_fingerprint","code_fingerprint",
     "source_sha256","producer_sha256","result_hash","result_version_id",
     "run_id","production_run_id","created_run_id","validation_status")
  for(p in dbs) {
    con <- tryCatch(DBI::dbConnect(RSQLite::SQLite(),p,
       flags=RSQLite::SQLITE_RO),error=function(e)NULL)
    if(is.null(con))next
    tryCatch({
      for(tab in DBI::dbListTables(con)) {
        cols <- DBI::dbListFields(con,tab)
        # A full run-identity column and scientific result keys are mandatory.
        marker <- intersect(c("run_id","production_run_id","created_run_id"),cols)
        valid <- all(c("metric_key","estimate","se")%in%cols) &&
           length(marker)>0L &&
           !grepl("student|microdata|respondent|person|pupil",tab,
                  ignore.case=TRUE)
        diag[[length(diag)+1L]] <- data.frame(
          file_class="LO02_SQLITE",db_sha256=unname(digest::digest(file=p,algo="sha256")),
          table=tab,has_exact_run_marker=length(marker)>0L,
          required_fields_present=all(c("metric_key","estimate","se")%in%cols),
          considered=valid,stringsAsFactors=FALSE)
        if(!valid)next
        for(k in marker) {
          q <- function(z)as.character(DBI::dbQuoteIdentifier(con,z))
          wanted <- intersect(approved_names,cols)
          sql <- paste0("SELECT ",paste(vapply(wanted,q,character(1)),collapse=","),
             " FROM ",q(tab)," WHERE ",q(k)," = ?")
          z <- tryCatch(DBI::dbGetQuery(con,sql,params=list(run_id)),
               error=function(e)data.frame())
          if(nrow(z))eligible[[length(eligible)+1L]]<-z
        }
      }
    },finally=DBI::dbDisconnect(con))
  }
  diagnostics <- if(length(diag))do.call(rbind,diag) else
    data.frame(file_class="NONE",db_sha256="",table="",has_exact_run_marker=FALSE,
     required_fields_present=FALSE,considered=FALSE)
  # A missing run_id must not trigger another pupil calculation.
  # Record a safe diagnostic of exact table metadata and aggregate counts,
  # using only the bounded, already-discovered SQLite databases.
  snapshot <- list()
  for(p in dbs) {
    con <- tryCatch(DBI::dbConnect(RSQLite::SQLite(),p,
       flags=RSQLite::SQLITE_RO),error=function(e)NULL)
    if(is.null(con))next
    tryCatch({
      for(tab in DBI::dbListTables(con)) {
        cols <- DBI::dbListFields(con,tab)
        if(!("metric_key"%in%cols) ||
           grepl("student|microdata|respondent|person|pupil",tab,ignore.case=TRUE))
          next
        qt <- as.character(DBI::dbQuoteIdentifier(con,tab))
        n <- tryCatch(DBI::dbGetQuery(con,paste0("SELECT COUNT(*) AS n FROM ",qt))$n[[1L]],
                      error=function(e)NA_integer_)
        distinct <- tryCatch(DBI::dbGetQuery(con,paste0(
          "SELECT COUNT(DISTINCT metric_key) AS n FROM ",qt))$n[[1L]],
          error=function(e)NA_integer_)
        snapshot[[length(snapshot)+1L]] <- data.frame(
          db_sha256=digest::digest(file=p,algo="sha256"),
          object=tab,n_rows=n,n_metric_keys=distinct,
          has_result_value=("estimate"%in%cols),
          has_se=("se"%in%cols),
          exact_run_link=any(c("run_id","production_run_id","created_run_id")%in%cols),
          evidence_status="METADATA_ONLY_NOT_VALIDATED",stringsAsFactors=FALSE)
      }
    },finally=DBI::dbDisconnect(con))
  }
  snap <- if(length(snapshot))do.call(rbind,snapshot) else
    data.frame(db_sha256=character(),object=character(),n_rows=integer(),
      n_metric_keys=integer(),has_result_value=logical(),has_se=logical(),
      exact_run_link=logical(),evidence_status=character())
  write.csv(snap,file.path(outdir,"LO02_SNAPSHOT_COUNTS.csv"),row.names=FALSE)
  # Compare every bounded aggregate result SQLite snapshot by full common
  # scientific columns. This cannot prove the exact 40 run outputs unless
  # old and new versions and unambiguous provenance are both present.
  profiles <- list()
  for(p in dbs) {
    con <- tryCatch(DBI::dbConnect(RSQLite::SQLite(),p,
       flags=RSQLite::SQLITE_RO),error=function(e)NULL)
    if(is.null(con))next
    tryCatch({
      for(tab in DBI::dbListTables(con)) {
        cols <- DBI::dbListFields(con,tab)
        if(!all(c("metric_key","estimate","se")%in%cols) ||
           grepl("student|microdata|respondent|person|pupil",tab,
                 ignore.case=TRUE))next
        q <- function(z)as.character(DBI::dbQuoteIdentifier(con,z))
        extra <- intersect(c("country","survey","module","year",
          "group","stat","input_fingerprint","science_fingerprint",
          "code_fingerprint","result_hash","result_version_id"),cols)
        fields <- c("metric_key","estimate","se",extra)
        if(length(fields)>20L)next
        query <- paste0("SELECT ",paste(vapply(fields,q,character(1)),
                         collapse=",")," FROM ",q(tab))
        z <- tryCatch(DBI::dbGetQuery(con,query),error=function(e)NULL)
        if(is.null(z)||nrow(z)>100000L)next
        # Do not export full rows at this stage. Only compare per-metric
        # evidence against other already-present aggregate snapshots.
        raw_identity <- apply(z[,fields,drop=FALSE],1L,function(row)
          paste(ifelse(is.na(row),"<NA>",as.character(row)),collapse="\\x1f"))
        profiles[[length(profiles)+1L]] <- list(
          db=digest::digest(file=p,algo="sha256"),table=tab,
          key=as.character(z$metric_key),
          rowhash=vapply(raw_identity,function(t)
            digest::digest(t,algo="sha256",serialize=FALSE),character(1L)),
          n=nrow(z))
      }
    },finally=DBI::dbDisconnect(con))
  }
  comparisons <- list()
  if(length(profiles)>=2L)for(i in seq_len(length(profiles)-1L))
    for(j in (i+1L):length(profiles)) {
      a<-profiles[[i]]; b<-profiles[[j]]
      if(identical(a$db,b$db))next
      valid_unique <- !anyDuplicated(a$key) && !anyDuplicated(b$key)
      shared <- if(valid_unique)intersect(a$key,b$key) else character()
      ix <- match(shared,a$key); iy <- match(shared,b$key)
      match_hash <- sum(a$rowhash[ix]==b$rowhash[iy],na.rm=TRUE)
      comparisons[[length(comparisons)+1L]] <- data.frame(
        left_db_sha256=a$db,right_db_sha256=b$db,
        left_table=a$table,right_table=b$table,
        left_n=a$n,right_n=b$n,shared_keys=length(shared),
        identical_full_row_hashes=match_hash,
        differing_shared_keys=length(shared)-match_hash,
        keys_only_left=if(valid_unique)length(setdiff(a$key,b$key)) else NA_integer_,
        keys_only_right=if(valid_unique)length(setdiff(b$key,a$key)) else NA_integer_,
        evidence_status=if(valid_unique)"DIAGNOSTIC_NOT_RUN_LINKED"
            else "HOLD_DUPLICATE_METRIC_KEYS",stringsAsFactors=FALSE)
    }
  diff <- if(length(comparisons))do.call(rbind,comparisons) else
    data.frame(left_db_sha256="",right_db_sha256="",left_table="",
      right_table="",left_n=NA_integer_,right_n=NA_integer_,
      shared_keys=NA_integer_,identical_full_row_hashes=NA_integer_,
      differing_shared_keys=NA_integer_,keys_only_left=NA_integer_,
      keys_only_right=NA_integer_,
      evidence_status="HOLD_NO_PAIR_OF_AGGREGATE_SNAPSHOTS")
  write.csv(diff,file.path(outdir,"LO02_SNAPSHOT_COMPARISONS.csv"),
            row.names=FALSE)
  # Never share absolute paths, database bytes, or arbitrary field names.
  write.csv(diagnostics,file.path(outdir,"LO02_EXPORT_SCHEMA_AUDIT.csv"),
            row.names=FALSE)
  status <- "HOLD_NO_EXACT_RUN_LINK"
  if(length(eligible)) {
    z <- do.call(rbind,eligible)
    scope_ok <- (!"country"%in%names(z) ||
                 all(as.character(z$country)=="NLD")) &&
                (!"survey"%in%names(z) ||
                 all(as.character(z$survey)=="PISA")) &&
                (!"module"%in%names(z) ||
                 all(as.character(z$module)%in%c("core","gender")))
    fields_ok <- all(is.finite(suppressWarnings(as.numeric(z$estimate)))) &&
                 all(is.finite(suppressWarnings(as.numeric(z$se))))
    if(anyDuplicated(z$metric_key)==0L &&
       nrow(z)==expected && scope_ok && fields_ok) {
      status <- "PRIVATE_REVIEW_ONLY_EXACT_RUN_MATCH"
      z <- z[,intersect(approved_names,names(z)),drop=FALSE]
      write.csv(z,file.path(outdir,"LO02_NEW_RESULT_ROWS.csv"),
                row.names=FALSE,na="")
    } else status <- "HOLD_AMBIGUOUS_OR_NONNLD_OR_INVALID_ESTIMATE_SE"
  }
  summary <- data.frame(run_id=run_id,expected_new_results=expected,
    matched_new_results=if(length(eligible))nrow(do.call(rbind,eligible)) else 0L,
    status=status,scientific_release="NOT_GRANTED",stringsAsFactors=FALSE)
  write.csv(summary,file.path(outdir,"LO02_EXPORT_STATUS.csv"),row.names=FALSE)
  cat("LO02 read-only export:",status,"expected=",expected,
      " matched=",summary$matched_new_results,"\n")
  invisible(summary)
}
