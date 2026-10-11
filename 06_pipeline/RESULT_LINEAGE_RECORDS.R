# Read-only result lineage evidence and conservative reuse planning.
# No source microdata are read, no files are deleted, no result is auto-released.
lo_reconcile_records <- function() {
  home <- Sys.getenv("USERPROFILE", unset=path.expand("~"))
  base <- file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation")
  root <- Sys.getenv("LO_MASTER_PROJECT_ROOT",
                      file.path(home,"Downloads","PISA_PIRLS_MASTER_PIPELINE"))
  a <- file.path(base,"RESULT_REGISTRY_SCHEMA_AUDIT.csv")
  if (!file.exists(a)) stop("Missing existing registry audit; no rescan requested")
  inv <- read.csv(a,stringsAsFactors=FALSE,check.names=FALSE)
  if (!all(c("relative_path","inspection_status") %in% names(inv)))
    stop("Unexpected registry audit columns")
  sha_file <- file.path(base,"MASTER_PRODUCER_CODE_SHA256.csv")
  known <- if(file.exists(sha_file)) read.csv(sha_file,stringsAsFactors=FALSE) else data.frame()
  known_sha <- if("sha256" %in% names(known)) unique(tolower(as.character(known$sha256))) else character()
  hash_re <- "^(sha256|source_sha256|producer_sha256|code_sha256|producer_code_sha256|input_sha256|source_data_sha256)$"
  id_re <- "^(result_id|result_key|estimate_id|contract_id|task_id|cell_id)$"
  evidence <- list()
  append_evidence <- function(path,object,n,ids,hashcols,methodcols,code_match,status,reason) {
    evidence[[length(evidence)+1L]] <<- data.frame(
      relative_path=path,object=object,record_count=as.numeric(n),
      identity_columns=paste(ids,collapse=";"),
      hash_columns=paste(hashcols,collapse=";"),
      method_columns=paste(methodcols,collapse=";"),
      producer_hash_matches=as.integer(code_match),
      decision=status,reason=reason,stringsAsFactors=FALSE)
  }
  for(i in seq_len(nrow(inv))) {
    rel <- as.character(inv$relative_path[i])
    p <- file.path(root,rel)
    if (!file.exists(p)) {
      append_evidence(rel,"",NA,character(),character(),character(),0L,
                      "HOLD","File missing");next
    }
    ext <- tolower(tools::file_ext(p))
    if (ext %in% c("sqlite","sqlite3","db") &&
        requireNamespace("DBI",quietly=TRUE) &&
        requireNamespace("RSQLite",quietly=TRUE)) {
      con <- tryCatch(DBI::dbConnect(RSQLite::SQLite(),dbname=p,
                        flags=RSQLite::SQLITE_RO),error=function(e)NULL)
      if(is.null(con)) {
        append_evidence(rel,"",NA,character(),character(),character(),0L,
                        "HOLD","Read-only DB open failed");next
      }
      tryCatch({
        for(t in DBI::dbListTables(con)) {
          cols <- DBI::dbListFields(con,t)
          ids <- cols[grepl(id_re,cols,ignore.case=TRUE)]
          hashes <- cols[grepl(hash_re,cols,ignore.case=TRUE)]
          methods <- cols[grepl("method|survey|wave|country|domain|version|release",cols,ignore.case=TRUE)]
          qtable <- as.character(DBI::dbQuoteIdentifier(con,t))
          n <- tryCatch(DBI::dbGetQuery(con,paste0("SELECT COUNT(*) AS n FROM ",qtable))$n[[1]],error=function(e)NA_real_)
          codecols <- hashes[grepl("producer|code",hashes,ignore.case=TRUE)]
          matched <- 0L
          # Bound potentially expensive DISTINCT scans and exclude raw/student tables.
          safe_aggregate <- is.finite(n) && n <= 1000000 &&
            !grepl("student|microdata|raw|respondent",t,ignore.case=TRUE)
          if(length(codecols) && length(known_sha) && safe_aggregate) {
            for(c in codecols) {
              qcol <- as.character(DBI::dbQuoteIdentifier(con,c))
              # Aggregation happens inside SQLite: no student-level records exported.
              query <- paste0("SELECT LOWER(CAST(",qcol," AS TEXT)) AS h, COUNT(*) AS n FROM ",
                              qtable," WHERE ",qcol," IS NOT NULL GROUP BY 1")
              vals <- tryCatch(DBI::dbGetQuery(con,query),error=function(e)data.frame())
              if("h" %in% names(vals)) matched <- matched +
                sum(vals$h %in% known_sha,na.rm=TRUE)
            }
          }
          decision <- if(length(ids) && length(hashes) && matched>0L)
            "CONDITIONAL_LINEAGE_EVIDENCE" else "HOLD"
          reason <- if(decision!="HOLD")
            "Code hash found; input, method, exact result identity and numerical parity still require verification"
            else "Insufficient linked producer/input/identity evidence"
          append_evidence(rel,t,n,ids,hashes,methods,matched,decision,reason)
        }
      },error=function(e) append_evidence(rel,"",NA,character(),character(),character(),0L,
                                         "HOLD",paste("DB inspection error:",conditionMessage(e))),
        finally=DBI::dbDisconnect(con))
    } else if(ext=="parquet" && requireNamespace("arrow",quietly=TRUE)) {
      pf <- tryCatch(arrow::ParquetFileReader$create(p),error=function(e)NULL)
      if(is.null(pf)) {
        append_evidence(rel,"",NA,character(),character(),character(),0L,"HOLD","Parquet open failed")
      } else {
        cols <- pf$GetSchema()$names
        n <- tryCatch(pf$metadata$num_rows,error=function(e)NA_real_)
        append_evidence(rel,"parquet",n,cols[grepl(id_re,cols,ignore.case=TRUE)],
          cols[grepl(hash_re,cols,ignore.case=TRUE)],
          cols[grepl("method|survey|wave|country|domain|version|release",cols,ignore.case=TRUE)],
          0L,"HOLD","Parquet schema and row count only; no row-level join")
      }
    } else append_evidence(rel,"",NA,character(),character(),character(),0L,
                           "HOLD","Unsupported format or required package missing")
  }
  out <- if(length(evidence))do.call(rbind,evidence) else data.frame()
  write.csv(out,file.path(base,"RESULT_LINEAGE_EVIDENCE.csv"),row.names=FALSE)
  counts <- if(nrow(out))as.data.frame(table(out$decision),stringsAsFactors=FALSE) else
    data.frame(Var1=character(),Freq=integer())
  names(counts) <- c("decision","count")
  write.csv(counts,file.path(base,"RESULT_LINEAGE_DECISION_COUNTS.csv"),row.names=FALSE)
  cat("Lineage evidence inspected:",nrow(out),"objects\n")
  print(counts,row.names=FALSE)
  cat("All results remain non-released; only conditional evidence or HOLD.\n")
  invisible(out)
}
lo_reconcile_records()
