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
