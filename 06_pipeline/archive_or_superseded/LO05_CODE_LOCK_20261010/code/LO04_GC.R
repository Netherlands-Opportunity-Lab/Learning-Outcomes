# Safe lifecycle planner. This version NEVER unlinks a historical file.
lo4_gc_preflight <- function(project,bundle,run) {
  categories<-c("OFFICIAL_OECD_IEA_INPUT","CANONICAL_CACHE_CURRENT","LO02_SQLITE_AND_PARQUET",
    "OLDER_CENTRAL_CURRENT_HISTORY","V11_TASK_CACHE","OLD_RUN_EXPORT","DECK_DASHBOARD_RELEASE","EXACT_DUPLICATE_CANDIDATE")
  decision<-c(rep("PROTECTED",4),"HOLD_UNTIL_MIGRATION_ACCEPTANCE",
    "HOLD_UNTIL_PRODUCT_LINKS_CHECKED","PINNED_OR_REVIEW","HOLD_UNTIL_SHA_DEPENDENCY_CHECKED")
  x<-data.frame(category=categories,decision=decision,
    safe_automatic_deletion_now="NO",stringsAsFactors=FALSE)
  lo4_csv(x,file.path(run,"GC_SAFETY_STATUS.csv"))
  invisible(x)
}
