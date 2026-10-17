# Read-only result reconciliation. Metadata and bounded aggregate registers only.
lo_reconcile_plan <- function() {
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  base <- file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation")
  root <- Sys.getenv("LO_MASTER_PROJECT_ROOT",file.path(home,"Downloads","PISA_PIRLS_MASTER_PIPELINE"))
  audit <- file.path(base,"RESULT_REGISTRY_SCHEMA_AUDIT.csv")
  if(!file.exists(audit)) stop("Run audit-batch first; no implicit full rescan")
  d <- read.csv(audit,stringsAsFactors=FALSE,check.names=FALSE)
  if(!all(c("relative_path","inspection_status")%in%names(d)))stop("Registry audit schema mismatch")
  rows <- list()
  for(i in seq_len(nrow(d))) {
    rel <- as.character(d$relative_path[i]); p <- file.path(root,rel)
    status <- as.character(d$inspection_status[i])
    count <- NA_real_; keys <- ""; verdict <- "HOLD"; reason <- "Lineage not established"
    ext <- tolower(tools::file_ext(p))
    if(file.exists(p) && ext%in%c("sqlite","sqlite3","db") &&
       requireNamespace("DBI",quietly=TRUE) && requireNamespace("RSQLite",quietly=TRUE)) {
      con <- tryCatch(DBI::dbConnect(RSQLite::SQLite(),dbname=p,flags=RSQLite::SQLITE_RO),
                      error=function(e)NULL)
      if(!is.null(con)) {
        tables <- tryCatch(DBI::dbListTables(con),error=function(e)character())
        count <- length(tables)
        keylist <- character()
        for(t in tables) {
          fields <- tryCatch(DBI::dbListFields(con,t),error=function(e)character())
          keylist <- c(keylist,fields[grepl("result.?id|source.?sha|producer.?sha|method|code.?sha|release|version",fields,ignore.case=TRUE)])
        }
        keys <- paste(unique(keylist),collapse=";")
        DBI::dbDisconnect(con)
        status <- "READ_ONLY_DB_SCHEMA_RECONCILED"
        reason <- if(nzchar(keys))"Lineage fields exist; value-level join pending" else "No recognized lineage columns"
      }
    } else if(file.exists(p) && ext=="parquet" && requireNamespace("arrow",quietly=TRUE)) {
      fields <- tryCatch(arrow::ParquetFileReader$create(p)$GetSchema()$names,error=function(e)character())
      count <- length(fields)
      keys <- paste(fields[grepl("result.?id|source.?sha|producer.?sha|method|code.?sha|release|version",fields,ignore.case=TRUE)],collapse=";")
      status <- if(length(fields))"READ_ONLY_PARQUET_SCHEMA_RECONCILED" else "HOLD_PARQUET_SCHEMA"
      reason <- "Parquet schema only; row-level lineage pending"
    }
    rows[[i]] <- data.frame(relative_path=rel,inspection_status=status,object_or_field_count=count,
      lineage_fields=keys,reuse_decision=verdict,reason=reason,stringsAsFactors=FALSE)
  }
  out <- if(length(rows))do.call(rbind,rows) else data.frame()
  write.csv(out,file.path(base,"RESULT_RECONCILIATION_REGISTER.csv"),row.names=FALSE)
  plan <- data.frame(family=c("PISA","PIRLS","TIMSS","INTERNATIONAL_COMPARATORS"),
    action="VERIFY_LINEAGE_THEN_REUSE_OR_RECOMPUTE",status="HOLD",
    priority=c(1L,2L,3L,4L),stringsAsFactors=FALSE)
  write.csv(plan,file.path(base,"REUSE_AND_COMPUTE_QUEUE.csv"),row.names=FALSE)
  cat("Reconciled register schemas:",nrow(out),"\n")
  cat("Read-only output:",file.path(base,"RESULT_RECONCILIATION_REGISTER.csv"),"\n")
  cat("No scientific release or new microdata computation.\n")
  invisible(out)
}
lo_reconcile_plan()
