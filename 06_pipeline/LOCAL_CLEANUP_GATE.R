# Local cleanup gate: never delete directly; move verified redundant copies to
# quarantine outside Downloads after two independent, verified remote receipts.
lo_cleanup_prepare <- function() {
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  base <- file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation")
  root <- Sys.getenv("LO_MASTER_PROJECT_ROOT",file.path(home,"Downloads","PISA_PIRLS_MASTER_PIPELINE"))
  inventory <- file.path(base,"MASTER_FILES_PRIVATE.csv")
  dup <- file.path(base,"EXACT_DUPLICATE_RESULT_GROUPS.csv")
  cloud <- file.path(base,"VERIFIED_CLOUD_ARTIFACTS.csv")
  independent <- file.path(base,"INDEPENDENT_BACKUP_RESTORE_RECEIPTS.csv")
  if(!file.exists(inventory))stop("Inventory missing")
  d <- read.csv(inventory,stringsAsFactors=FALSE)
  candidates <- d[FALSE,,drop=FALSE]
  closure <- file.path(base,"PRODUCT_DEPENDENCY_CLOSURE.csv")
  if(file.exists(dup)&&file.exists(cloud)&&file.exists(independent)&&file.exists(closure)) {
    a<-read.csv(dup,stringsAsFactors=FALSE)
    b<-read.csv(cloud,stringsAsFactors=FALSE)
    c<-read.csv(independent,stringsAsFactors=FALSE)
    e<-read.csv(closure,stringsAsFactors=FALSE)
    required <- c("relative_path","sha256")
    if(all(required%in%names(a)) && all(c(required,"verification")%in%names(b)) &&
       all(c(required,"restore_status","independent_location")%in%names(c)) &&
       all(c(required,"closure_status")%in%names(e))) {
      a<-a[!is.na(a$sha256)&nzchar(a$sha256),,drop=FALSE]
      b<-b[b$verification=="READBACK_SHA256_PASS",,drop=FALSE]
      c<-c[c$restore_status=="RESTORE_SHA256_PASS"&nzchar(c$independent_location),,drop=FALSE]
      e<-e[e$closure_status=="PASS",,drop=FALSE]
      k <- paste(a$relative_path,a$sha256)
      eligible <- k%in%paste(b$relative_path,b$sha256) &
                  k%in%paste(c$relative_path,c$sha256) &
                  k%in%paste(e$relative_path,e$sha256)
      paths <- a$relative_path[eligible]
      candidates <- d[d$relative_path%in%paths &
         d$classification=="DERIVED_CANDIDATE_UNVERIFIED",,drop=FALSE]
    }
  }
  hashes <- if(nrow(candidates))a$sha256[match(candidates$relative_path,a$relative_path)] else character()
  out <- data.frame(relative_path=candidates$relative_path,sha256=hashes,bytes=candidates$bytes,
    classification=candidates$classification,
    decision=rep("QUARANTINE_ELIGIBLE_REQUIRES_FINAL_APPROVAL",nrow(candidates)),
    stringsAsFactors=FALSE)
  write.csv(out,file.path(base,"LOCAL_CLEANUP_APPROVAL_QUEUE.csv"),row.names=FALSE)
  approval <- data.frame(relative_path=out$relative_path,sha256=out$sha256,
                         approved=rep("NO",nrow(out)),stringsAsFactors=FALSE)
  approval_path <- file.path(base,"LOCAL_CLEANUP_APPROVED.csv")
  if(!file.exists(approval_path))write.csv(approval,approval_path,row.names=FALSE)
  cat("Independently restored and cloud-verified duplicate candidates:",nrow(out),"\n")
  cat("No local files moved or deleted. Approval and fresh hash recheck required.\n")
  invisible(out)
}
lo_cleanup_prepare()
