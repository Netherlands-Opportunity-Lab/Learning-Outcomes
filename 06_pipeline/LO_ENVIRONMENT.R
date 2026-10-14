# Explicit immutable replication uses the recorded R/package versions. Normal
# development keeps recording the actual environment without installing into it.
lo_environment_check <- function(repo,strict=FALSE) {
  path<-file.path(repo,"renv.lock")
  if(!file.exists(path))stop("REPLICATION_ENVIRONMENT_LOCK_MISSING")
  lock<-jsonlite::fromJSON(path,simplifyVector=FALSE)
  required<-names(lock$Packages)
  if(!length(required))stop("REPLICATION_ENVIRONMENT_LOCK_EMPTY")
  actual<-vapply(required,function(p)tryCatch(as.character(utils::packageVersion(p)),error=function(e)"MISSING"),character(1))
  expected<-vapply(lock$Packages,function(p)p$Version,character(1))
  table<-data.frame(package=c("R",required),expected=c(lock$R$Version,expected),actual=c(as.character(getRversion()),actual))
  table$matches<-table$expected==table$actual
  if(strict && any(!table$matches))stop("REPLICATION_ENVIRONMENT_MISMATCH: ",paste(table$package[!table$matches],collapse=", "))
  list(lock_sha256=digest::digest(file=path,algo="sha256"),strict=strict,versions=table,all_match=all(table$matches))
}
