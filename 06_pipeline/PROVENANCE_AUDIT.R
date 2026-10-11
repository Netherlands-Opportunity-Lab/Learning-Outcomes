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
  output <- file.path(base,"RESULT_PROVENANCE_MATRIX.csv")
  write.csv(out,output,row.names=FALSE)
  cat("Written:",output,"\nScientific release unchanged. No data transferred.\n")
  invisible(out)
}
lo_provenance_audit()
