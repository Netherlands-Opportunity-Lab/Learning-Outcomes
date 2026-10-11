# Bounded exact aggregate-result comparison; no student-level records exported.
# Runs read-only. Missing keys or ambiguous schemas are HOLD, never silently accepted.
lo_compare_results <- function() {
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  base <- file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation")
  root <- Sys.getenv("LO_MASTER_PROJECT_ROOT",file.path(home,"Downloads","PISA_PIRLS_MASTER_PIPELINE"))
  evidence <- file.path(base,"RESULT_LINEAGE_EVIDENCE.csv")
  if(!file.exists(evidence))stop("Run provenance reconciliation first")
  z <- read.csv(evidence,stringsAsFactors=FALSE,check.names=FALSE)
  if(!requireNamespace("digest",quietly=TRUE))stop("digest is required")
  maxrows <- 100000L
  maxbytes <- 32*1024^2
  objects <- list()
  is_sensitive <- function(x) grepl("student|respondent|microdata|raw|individual|person",x,ignore.case=TRUE)
  choose_key <- function(cols) {
    candidates <- c("result_id","result_key","estimate_id","contract_id","cell_id","task_id")
    k <- cols[match(candidates,tolower(cols),nomatch=0L)]
    if(length(k))return(k[1L])
    character()
  }
  read_object <- function(path,table,ext) {
    if(is_sensitive(path)||is_sensitive(table))return(NULL)
    if(ext%in%c("sqlite","db","sqlite3")) {
      if(!requireNamespace("DBI",quietly=TRUE)||!requireNamespace("RSQLite",quietly=TRUE))return(NULL)
      con <- tryCatch(DBI::dbConnect(RSQLite::SQLite(),dbname=path,flags=RSQLite::SQLITE_RO),error=function(e)NULL)
      if(is.null(con))return(NULL)
      on.exit(DBI::dbDisconnect(con),add=TRUE)
      if(!table%in%DBI::dbListTables(con))return(NULL)
      cols <- DBI::dbListFields(con,table)
      key <- choose_key(cols)
      if(!length(key))return(NULL)
      sqltable <- as.character(DBI::dbQuoteIdentifier(con,table))
      n <- DBI::dbGetQuery(con,paste0("SELECT COUNT(*) AS n FROM ",sqltable))$n[[1]]
      if(!is.finite(n)||n<1||n>maxrows)return(NULL)
      if(file.info(path)$size>maxbytes*100)return(NULL)
      wanted <- unique(c(key,cols[grepl("^(estimate|value|score|mean|se|standard_error|lower_ci|upper_ci|survey|country|year|wave|domain|method|source_sha256|producer_code_sha256|code_sha256|version)$",cols,ignore.case=TRUE)]))
      if(length(wanted)<2L)return(NULL)
      quoted <- as.character(DBI::dbQuoteIdentifier(con,wanted))
      d <- DBI::dbGetQuery(con,paste0("SELECT ",paste(quoted,collapse=",")," FROM ",sqltable))
    } else if(ext=="parquet") {
      if(!requireNamespace("arrow",quietly=TRUE))return(NULL)
      pf <- arrow::ParquetFileReader$create(path)
      n <- pf$metadata$num_rows
      if(!is.finite(n)||n<1||n>maxrows||file.info(path)$size>maxbytes)return(NULL)
      d <- as.data.frame(arrow::read_parquet(path))
      key <- choose_key(names(d))
      if(!length(key))return(NULL)
    } else return(NULL)
    if(nrow(d)==0||ncol(d)>120)return(NULL)
    # Require explicit numeric result/estimate column and unique nonempty keys.
    numeric_cols <- names(d)[vapply(d,is.numeric,logical(1))]
    values <- numeric_cols[grepl("^(estimate|value|score|mean|se|standard_error|lower_ci|upper_ci)$",numeric_cols,ignore.case=TRUE)]
    if(!length(values))return(NULL)
    ids <- as.character(d[[key]])
    if(anyNA(ids)||any(!nzchar(ids))||anyDuplicated(ids))return(NULL)
    # Compare all common named scalar result columns, not source row order.
    keep <- unique(c(key,values,names(d)[grepl("^(survey|country|year|wave|domain|method|source_sha256|producer_code_sha256|code_sha256|version)$",names(d),ignore.case=TRUE)]))
    d <- d[order(ids),keep,drop=FALSE]
    for(k in names(d))d[[k]] <- as.character(d[[k]])
    list(data=d,key=key,values=values)
  }
  for(i in seq_len(nrow(z))) {
    rel <- as.character(z$relative_path[i]); table <- as.character(z$object[i])
    path <- file.path(root,rel);ext <- tolower(tools::file_ext(path))
    if(!file.exists(path)||is.na(table)||!nzchar(table))next
    obj <- tryCatch(read_object(path,table,ext),error=function(e)NULL)
    if(!is.null(obj))objects[[length(objects)+1L]] <- c(list(path=rel,table=table),obj)
  }
  comparisons <- list()
  if(length(objects)>1L)for(i in seq_len(length(objects)-1L))for(j in (i+1L):length(objects)) {
    a<-objects[[i]];b<-objects[[j]]
    if(!identical(tolower(a$key),tolower(b$key)))next
    if(!setequal(tolower(a$values),tolower(b$values)))next
    if(nrow(a$data)!=nrow(b$data))next
    if(!setequal(names(a$data),names(b$data)))next
    cols <- sort(names(a$data))
    aa <- a$data[,cols,drop=FALSE];bb <- b$data[,cols,drop=FALSE]
    aa <- aa[order(aa[[a$key]]),,drop=FALSE]
    bb <- bb[order(bb[[b$key]]),,drop=FALSE]
    rownames(aa) <- NULL; rownames(bb) <- NULL
    same <- identical(aa,bb)
    mismatch_rows <- if(same) 0L else sum(vapply(seq_len(nrow(aa)),function(k)
      !identical(unname(unlist(aa[k,,drop=FALSE])),unname(unlist(bb[k,,drop=FALSE]))),logical(1)))
    comparisons[[length(comparisons)+1L]] <- data.frame(
      left_object=paste(a$path,a$table,sep="::"),
      right_object=paste(b$path,b$table,sep="::"),
      rows=nrow(aa),mismatched_rows=mismatch_rows,comparison=if(same)"EXACT_AGGREGATE_MATCH" else "CONFLICT",
      scientific_release="HOLD_PENDING_SOURCE_AND_METHOD_VALIDATION",
      stringsAsFactors=FALSE)
  }
  out <- if(length(comparisons))do.call(rbind,comparisons) else data.frame(
    left_object=character(),right_object=character(),rows=integer(),mismatched_rows=integer(),
    comparison=character(),scientific_release=character())
  write.csv(out,file.path(base,"RESULT_EXACT_COMPARISONS.csv"),row.names=FALSE)
  summary <- data.frame(eligible_objects=length(objects),compared_pairs=nrow(out),
    exact_matches=sum(out$comparison=="EXACT_AGGREGATE_MATCH"),
    conflicts=sum(out$comparison=="CONFLICT"),
    not_compared=nrow(z)-length(objects))
  write.csv(summary,file.path(base,"RESULT_COMPARISON_SUMMARY.csv"),row.names=FALSE)
  cat("Exact aggregate comparison:",paste(names(summary),unlist(summary),sep="=",collapse="; "),"\n")
  cat("Scientific release remains held pending source/method validation.\n")
  invisible(summary)
}
lo_compare_results()
