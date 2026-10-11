# Metadata-only reconciliation. No deletion, no promotion, no data upload.
lo_provenance_audit <- function() {
  base <- file.path(Sys.getenv("USERPROFILE"),"Downloads","LO05_RESULTATEN","master_reconciliation")
  inv <- file.path(base,"MASTER_FILES_PRIVATE.csv")
  if (!file.exists(inv)) stop("Existing inventory not found; refusing implicit rescan")
  z <- read.csv(inv,stringsAsFactors=FALSE,check.names=FALSE)
  if (!all(c("relative_path","classification") %in% names(z))) stop("Unexpected inventory schema")
  f <- ifelse(grepl("PISA",z$relative_path,ignore.case=TRUE),"PISA",
       ifelse(grepl("PIRLS",z$relative_path,ignore.case=TRUE),"PIRLS",
       ifelse(grepl("TIMSS",z$relative_path,ignore.case=TRUE),"TIMSS","CROSS_STUDY")))
  categories <- c("PISA","PIRLS","TIMSS","CROSS_STUDY")
  out <- do.call(rbind,lapply(categories,function(k) {
    a <- z[f==k,,drop=FALSE]
    data.frame(family=k,inventory_count=nrow(a),
      canonical_count=sum(grepl("CANONICAL",a$classification)),
      registry_candidates=sum(grepl("REGISTRY|PROVENANCE|RESULT_HISTORY|CURRENT_RESULTS",a$relative_path,ignore.case=TRUE)),
      producer_candidates=sum(grepl("[.](R|py|sql)$",a$relative_path,ignore.case=TRUE)),
      result_source_join="NOT_VERIFIED",
      status="HOLD",
      next_gate="Verify producer SHA, input SHA, methodology and result identity against read-only registers",
      stringsAsFactors=FALSE)
  }))
  # Inspect only metadata of likely canonical SQLite/Parquet registries.
  # Never scan student records or silently promote results.
  root <- Sys.getenv("LO_MASTER_PROJECT_ROOT",
                     file.path(Sys.getenv("USERPROFILE"),"Downloads",
                               "PISA_PIRLS_MASTER_PIPELINE"))
  targets <- z[grepl("(^|/)(CURRENT_RESULTS|RESULT_HISTORY|PRODUCT_RESULT_LINKS|RESULT_PROVENANCE|PROJECT_RESULTS_REGISTRY)[.]|[.]sqlite$",z$relative_path,ignore.case=TRUE),,drop=FALSE]
  evidence <- list()
  if(nrow(targets)) for(i in seq_len(nrow(targets))) {
    rel <- as.character(targets$relative_path[[i]])
    path <- file.path(root,rel)
    ext <- tolower(tools::file_ext(rel))
    state <- "HOLD_NOT_INSPECTED"
    objects <- ""
    if (!file.exists(path)) state <- "HOLD_MISSING_FILE"
    else if(ext %in% c("sqlite","sqlite3","db")) {
      if(!requireNamespace("DBI",quietly=TRUE) || !requireNamespace("RSQLite",quietly=TRUE))
        state <- "HOLD_DB_PACKAGES_UNAVAILABLE"
      else {
        con <- tryCatch(DBI::dbConnect(RSQLite::SQLite(),dbname=path,
                   flags=RSQLite::SQLITE_RO),error=function(e)NULL)
        if(is.null(con)) state <- "HOLD_DB_OPEN_FAILED"
        else {
          objects <- paste(tryCatch(DBI::dbListTables(con),error=function(e)character()),collapse=";")
          DBI::dbDisconnect(con)
          state <- "SCHEMA_INSPECTED_NOT_PROVENANCE_VERIFIED"
        }
      }
    } else if(ext=="parquet") {
      if(!requireNamespace("arrow",quietly=TRUE)) state <- "HOLD_ARROW_UNAVAILABLE"
      else {
        sch <- tryCatch(arrow::ParquetFileReader$create(path)$GetSchema(),error=function(e)NULL)
        if(is.null(sch)) state <- "HOLD_PARQUET_SCHEMA_FAILED"
        else {objects <- paste(sch$names,collapse=";");state <- "SCHEMA_INSPECTED_NOT_PROVENANCE_VERIFIED"}
      }
    } else state <- "HOLD_UNSUPPORTED_FORMAT"
    evidence[[length(evidence)+1L]] <- data.frame(relative_path=rel,
      inspection_status=state,schema_objects=objects,scientific_status="HOLD",
      stringsAsFactors=FALSE)
  }
  registry <- if(length(evidence))do.call(rbind,evidence) else
    data.frame(relative_path=character(),inspection_status=character(),
               schema_objects=character(),scientific_status=character())
  write.csv(registry,file.path(base,"RESULT_REGISTRY_SCHEMA_AUDIT.csv"),row.names=FALSE)
  cat("Registry candidates inspected:",nrow(registry),
      "; no scientific provenance promoted.\\n")
  output <- file.path(base,"RESULT_PROVENANCE_MATRIX.csv")
  write.csv(out,output,row.names=FALSE)
  cat("Written:",output,"\nScientific release unchanged. No data transferred.\n")
  invisible(out)
}
lo_provenance_audit()
