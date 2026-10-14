# Peak scratch must be MEASURED in a bounded pilot of this producer/source size,
# not inferred from a compressed RDS size. No pilot or production at low space.
lo_production_free_bytes <- function(path) {
  path<-normalizePath(path,winslash="/",mustWork=TRUE)
  if(.Platform$OS.type=="windows") {
    drive<-toupper(substr(path,1,1))
    if(!grepl("^[A-Z]$",drive))stop("SPACE_UNSUPPORTED_VOLUME")
    script<-paste0("[Console]::Write(([System.IO.DriveInfo]::new('",drive,":')).AvailableFreeSpace)")
    x<-system2("powershell",c("-NoProfile","-Command",shQuote(script)),stdout=TRUE)
  } else {
    x<-system2("df",c("-Pk",shQuote(path)),stdout=TRUE)
    row<-strsplit(trimws(tail(x,1)),"[[:space:]]+")[[1]]
    return(as.numeric(row[4])*1024)
  }
  suppressWarnings(as.numeric(paste(x,collapse="")))
}
lo_production_space_check <- function(certificate_path,out) {
  cert<-jsonlite::fromJSON(certificate_path,simplifyVector=TRUE)
  b<-cert$resource_budget
  fields<-c("measured_peak_scratch_bytes","max_scratch_bytes","evidence_path","evidence_sha256")
  if(is.null(b)||!all(fields%in%names(b)))stop("SPACE_MEASURED_RESOURCE_BUDGET_REQUIRED")
  lo_exact_assert_sha(b$evidence_path,b$evidence_sha256,"RESOURCE_PILOT")
  peak<-as.numeric(b$measured_peak_scratch_bytes);limit<-as.numeric(b$max_scratch_bytes)
  if(length(peak)!=1L||length(limit)!=1L||!is.finite(peak)||!is.finite(limit)||
    peak<0||limit<peak)stop("SPACE_INVALID_RESOURCE_BUDGET")
  # Operating reserve remains free on BOTH the output and R temporary volume.
  free<-min(lo_production_free_bytes(out),lo_production_free_bytes(tempdir()))
  if(!is.finite(free)||free<limit+2*1024^3)stop("SPACE_INSUFFICIENT_BEFORE_SOURCE_LOAD")
  invisible(list(free_bytes=free,measured_peak_bytes=peak,scratch_limit_bytes=limit))
}
