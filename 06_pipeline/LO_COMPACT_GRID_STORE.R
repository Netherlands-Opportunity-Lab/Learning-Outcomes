# Compact, single-writer result ledger. No student rows or checkpoint copies.
# One current row per primitive scientific identity. A row is NOT a release.
lo_compact_open <- function(root) {
  for (p in c("DBI", "RSQLite", "digest"))
    if (!requireNamespace(p, quietly=TRUE)) stop("Missing R package: ",p)
  dir.create(root, recursive=TRUE, showWarnings=FALSE)
  database <- file.path(root,"COMPACT_MASTER_GRID.sqlite")
  con <- DBI::dbConnect(RSQLite::SQLite(),database)
  tryCatch({
    DBI::dbExecute(con,"PRAGMA busy_timeout=15000")
    DBI::dbExecute(con,"PRAGMA journal_mode=WAL")
    DBI::dbExecute(con,"PRAGMA synchronous=FULL")
    DBI::dbExecute(con,paste0("CREATE TABLE IF NOT EXISTS grid (",
      "cell_id TEXT PRIMARY KEY, survey TEXT NOT NULL, country TEXT NOT NULL, ",
      "year TEXT NOT NULL, domain TEXT NOT NULL, module TEXT NOT NULL, ",
      "stat TEXT NOT NULL, subgroup TEXT NOT NULL, definition TEXT NOT NULL, unit TEXT NOT NULL, ",
      "peer_environment TEXT NOT NULL, threshold TEXT NOT NULL, ",
      "estimate REAL, standard_error REAL, n_unweighted INTEGER, ",
      "input_fingerprint TEXT NOT NULL, producer_fingerprint TEXT NOT NULL, ",
      "method_id TEXT NOT NULL, status TEXT NOT NULL, hold_reason TEXT NOT NULL)"))
    DBI::dbExecute(con,paste0("CREATE TABLE IF NOT EXISTS batches (",
      "batch_key TEXT PRIMARY KEY, survey TEXT NOT NULL, country TEXT NOT NULL, ",
      "year TEXT NOT NULL, scope TEXT NOT NULL, status TEXT NOT NULL, ",
      "n_rows INTEGER NOT NULL)"))
    if(!"unit"%in%DBI::dbListFields(con,"grid")) DBI::dbExecute(con,"ALTER TABLE grid ADD COLUMN unit TEXT NOT NULL DEFAULT ''")
    # Keep each changed numerical result once, not a full database per run.
    DBI::dbExecute(con,"CREATE TABLE IF NOT EXISTS result_versions AS SELECT '' AS result_version_sha256, * FROM grid WHERE 0")
    DBI::dbExecute(con,"CREATE UNIQUE INDEX IF NOT EXISTS result_version_id ON result_versions(result_version_sha256)")
    DBI::dbExecute(con,"CREATE INDEX IF NOT EXISTS grid_status ON grid(status)")
    DBI::dbExecute(con,"CREATE INDEX IF NOT EXISTS grid_country ON grid(country,survey,year)")
    if(!identical(DBI::dbGetQuery(con,"PRAGMA integrity_check")[[1L]][1L],"ok"))
      stop("COMPACT_GRID_DB_CORRUPT")
    con
  },error=function(e){DBI::dbDisconnect(con);stop(e)})
}
lo_compact_close <- function(con) {
  if(DBI::dbIsValid(con)) {
    # Bound SQLite WAL growth; checkpoint preserves the single canonical store.
    try(DBI::dbGetQuery(con,"PRAGMA wal_checkpoint(TRUNCATE)"),silent=TRUE)
    DBI::dbDisconnect(con)
  }
  invisible(TRUE)
}
lo_compact_require <- function(x) {
  required <- c("cell_id","survey","country","year","domain","module",
                "stat","subgroup","definition","unit","peer_environment","threshold",
                "estimate","standard_error","n_unweighted",
                "input_fingerprint","producer_fingerprint","method_id",
                "status","hold_reason")
  if(!is.data.frame(x)||!length(x$cell_id)||!all(required%in%names(x))||
     anyDuplicated(x$cell_id)||anyNA(x$cell_id)||any(!nzchar(x$cell_id)))
    stop("COMPACT_GRID_INVALID_KEYS_OR_COLUMNS")
  ok <- x$status=="COMPUTED_PENDING_VALIDATION"
  if(anyNA(ok) || any(!x$status%in%c("COMPUTED_PENDING_VALIDATION","HOLD","UNAVAILABLE")))
    stop("COMPACT_GRID_INVALID_STATUS")
  if(any(ok)) {
    y <- x[ok,,drop=FALSE]
    for(k in c("estimate","standard_error","n_unweighted"))
      if(anyNA(y[[k]])||any(!is.finite(as.numeric(y[[k]]))))
        stop("COMPACT_GRID_MISSING_ESTIMATE_SE_OR_N")
    if(any(as.numeric(y$standard_error)<0)||any(as.numeric(y$n_unweighted)<1)||
       any(as.numeric(y$n_unweighted)!=floor(as.numeric(y$n_unweighted))))
      stop("COMPACT_GRID_INVALID_SE_OR_N")
    for(k in c("input_fingerprint","producer_fingerprint"))
      if(any(!grepl("^[a-fA-F0-9]{64}$",y[[k]])))
        stop("COMPACT_GRID_MISSING_FINGERPRINT")
    if(any(!nzchar(y$method_id))||any(nzchar(y$hold_reason)))
      stop("COMPACT_GRID_INVALID_METHOD_OR_HOLD")
  }
  invisible(TRUE)
}
lo_compact_put <- function(con,x) {
  lo_compact_require(x)
  names_sql <- names(DBI::dbGetQuery(con,"SELECT * FROM grid LIMIT 0"))
  x <- x[,names_sql,drop=FALSE]
  ix <- which(x$status=="COMPUTED_PENDING_VALIDATION")
  if(length(ix)) {
    for(i in ix) {
      old <- DBI::dbGetQuery(con,
        "SELECT input_fingerprint,producer_fingerprint,method_id,estimate,standard_error,n_unweighted,status FROM grid WHERE cell_id=?",
        params=list(x$cell_id[[i]]))
      if(nrow(old) && identical(old$status[[1L]],"COMPUTED_PENDING_VALIDATION") &&
         identical(old$input_fingerprint[[1L]],x$input_fingerprint[[i]]) &&
         identical(old$producer_fingerprint[[1L]],x$producer_fingerprint[[i]]) &&
         identical(old$method_id[[1L]],x$method_id[[i]]) &&
         (!identical(old$estimate[[1L]],x$estimate[[i]]) ||
          !identical(old$standard_error[[1L]],x$standard_error[[i]]) ||
          !identical(as.numeric(old$n_unweighted[[1L]]),as.numeric(x$n_unweighted[[i]]))))
        stop("COMPACT_GRID_CONFLICT_IDENTICAL_SCIENCE_ID: ",x$cell_id[[i]])
    }
  }
  inserted <- 0L; reused <- 0L
  DBI::dbWithTransaction(con,{
    remember<-function(row) {
      if(!nrow(row)||row$status[[1]]!="COMPUTED_PENDING_VALIDATION")return(invisible(NULL))
      version<-digest::digest(row,algo="sha256")
      cols<-c("result_version_sha256",names_sql)
      DBI::dbExecute(con,paste0("INSERT OR IGNORE INTO result_versions (",paste(cols,collapse=","),
        ") VALUES (",paste(rep("?",length(cols)),collapse=","),")"),
        params=c(list(version),unname(as.list(row[1,names_sql,drop=FALSE]))))
    }
    sql <- paste0("INSERT INTO grid (",paste(names_sql,collapse=","),
      ") VALUES (",paste(rep("?",length(names_sql)),collapse=","),") ",
      "ON CONFLICT(cell_id) DO UPDATE SET ",
      paste(sprintf("%s=excluded.%s",names_sql[-1L],names_sql[-1L]),collapse=","))
    for(i in seq_len(nrow(x))) {
      remember(DBI::dbGetQuery(con,"SELECT * FROM grid WHERE cell_id=?",params=list(x$cell_id[[i]])))
      old <- DBI::dbGetQuery(con,
        "SELECT input_fingerprint,producer_fingerprint,method_id,status FROM grid WHERE cell_id=?",
        params=list(x$cell_id[[i]]))
      if(nrow(old) && identical(old$status[[1L]],"COMPUTED_PENDING_VALIDATION") &&
         identical(old$input_fingerprint[[1L]],x$input_fingerprint[[i]]) &&
         identical(old$producer_fingerprint[[1L]],x$producer_fingerprint[[i]]) &&
         identical(old$method_id[[1L]],x$method_id[[i]])) {
        reused <- reused+1L
        next
      }
      # A subsequent incomplete attempt can never erase a complete matching result.
      if(nrow(old)&&old$status[[1L]]=="COMPUTED_PENDING_VALIDATION" &&
         x$status[[i]]!="COMPUTED_PENDING_VALIDATION" &&
         identical(old$input_fingerprint[[1L]],x$input_fingerprint[[i]]) &&
         identical(old$producer_fingerprint[[1L]],x$producer_fingerprint[[i]])) next
      DBI::dbExecute(con,sql,params=unname(as.list(x[i,names_sql,drop=FALSE])))
      remember(DBI::dbGetQuery(con,"SELECT * FROM grid WHERE cell_id=?",params=list(x$cell_id[[i]])))
      inserted <- inserted+1L
    }
  })
  list(written=inserted,reused=reused)
}
lo_compact_known <- function(con,ids,input_fingerprint,producer_fingerprint,method_id) {
  if(!length(ids))return(logical())
  if(length(unique(ids))!=length(ids))stop("COMPACT_GRID_DUPLICATE_QUERY")
  out<-rep(FALSE,length(ids))
  for(i in seq_along(ids)) {
    z<-DBI::dbGetQuery(con,
      paste0("SELECT 1 FROM grid WHERE cell_id=? AND input_fingerprint=? ",
        "AND producer_fingerprint=? AND method_id=? ",
        "AND status='COMPUTED_PENDING_VALIDATION' LIMIT 1"),
      params=list(ids[[i]],input_fingerprint,producer_fingerprint,method_id))
    out[[i]]<-nrow(z)==1L
  }
  out
}
lo_compact_hold_rows <- function(tasks,reason,input_fp="",producer_fp="",method="UNAVAILABLE") {
  if(!nrow(tasks))return(data.frame())
  data.frame(cell_id=tasks$metric_key,survey=tasks$survey,country=tasks$country,
     year=tasks$year,domain=tasks$domain,module=tasks$module,
     stat=tasks$stat,subgroup=tasks$group,definition=tasks$definition,unit=tasks$unit,
     peer_environment=tasks$peer_definition,threshold=tasks$threshold,
     estimate=NA_real_,standard_error=NA_real_,n_unweighted=NA_integer_,
     input_fingerprint=input_fp,producer_fingerprint=producer_fp,
     method_id=method,status="HOLD",hold_reason=substr(reason,1L,350L),
     stringsAsFactors=FALSE)
}
lo_compact_export <- function(con,root,selected_ids=NULL) {
  # CSV is a compatibility export; SQLite is authoritative. No history/replicate dumps.
  x<-DBI::dbGetQuery(con,"SELECT * FROM grid ORDER BY country,survey,year,cell_id")
  if(!is.null(selected_ids))x<-x[x$cell_id%in%selected_ids,,drop=FALSE]
  file<-file.path(root,"COMPACT_MASTER_GRID.csv.gz")
  stage<-paste0(file,".new")
  if(file.exists(stage))unlink(stage)
  # 17 significant digits permit IEEE-754 double round-trip in open text.
  # SQLite retains native doubles; display rounding is a separate product.
  exact_text<-x
  for(k in c("estimate","standard_error"))exact_text[[k]]<-
    ifelse(is.na(x[[k]]),NA_character_,sprintf("%.17g",x[[k]]))
  gc<-gzfile(stage,"wt",compression=9)
  tryCatch({write.csv(exact_text,gc,row.names=FALSE,na="");close(gc)},
    error=function(e){try(close(gc),silent=TRUE);unlink(stage);stop(e)})
  if(file.exists(file) && !file.remove(file))stop("COMPACT_GRID_EXPORT_LOCKED")
  if(!file.rename(stage,file))stop("COMPACT_GRID_EXPORT_RENAME_FAILED")
  # Display-only rounding; never round source estimates before comparisons.
  y<-x[x$status=="COMPUTED_PENDING_VALIDATION",,drop=FALSE]
  proportions<-y$unit=="proportion"
  proportions[is.na(proportions)]<-FALSE
  y$estimate[proportions]<-100*y$estimate[proportions]
  y$standard_error[proportions]<-100*y$standard_error[proportions]
  y$unit[proportions]<-"percent"
  display_units<-y$unit%in%c("score_points","percent")
  y$estimate[display_units]<-round(y$estimate[display_units],1L)
  y$standard_error[display_units]<-round(y$standard_error[display_units],2L)
  # Unknown units retain full precision until their display rule is specified.
  presentation<-file.path(root,"COMPACT_DASHBOARD_ROUNDED.csv.gz")
  stage2<-paste0(presentation,".new")
  if(file.exists(stage2))unlink(stage2)
  gc2<-gzfile(stage2,"wt",compression=9)
  tryCatch({write.csv(y,gc2,row.names=FALSE,na="");close(gc2)},
    error=function(e){try(close(gc2),silent=TRUE);unlink(stage2);stop(e)})
  if(file.exists(presentation) && !file.remove(presentation))stop("COMPACT_DISPLAY_EXPORT_LOCKED")
  if(!file.rename(stage2,presentation))stop("COMPACT_DISPLAY_EXPORT_RENAME_FAILED")
  module_status<-DBI::dbGetQuery(con,
    "SELECT survey,module,status,COUNT(*) AS n FROM grid GROUP BY survey,module,status ORDER BY survey,module,status")
  write.csv(module_status,file.path(root,"COMPACT_MODULE_STATUS.csv"),row.names=FALSE)
  DBI::dbGetQuery(con,"PRAGMA wal_checkpoint(TRUNCATE)")
  data.frame(rows=nrow(x),complete=sum(x$status=="COMPUTED_PENDING_VALIDATION"),
     holds=sum(x$status=="HOLD"),database_bytes=file.info(file.path(root,
        "COMPACT_MASTER_GRID.sqlite"))$size,
     full_csv_bytes=file.info(file)$size,
     display_csv_bytes=file.info(presentation)$size)
}

