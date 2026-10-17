# C:-disk retirement gate. No direct deletion. This checks an independent
# off-C restore beyond the private Google Drive SHA-readback before stage.
lo_fixed_backup_cleanup_gate <- function(state,action="plan") {
  action<-match.arg(action,c("plan","quarantine","finalize"))
  required_files <- c("LOCAL_CLEANUP_APPROVAL_QUEUE.csv",
    "VERIFIED_CLOUD_ARTIFACTS.csv",
    "INDEPENDENT_BACKUP_RESTORE_RECEIPTS.csv",
    "PRODUCT_DEPENDENCY_CLOSURE.csv")
  paths <- file.path(state,required_files)
  out <- file.path(state,"FIXED_SAFE_C_DISK_CLEANUP.csv")
  if(!all(file.exists(paths))) {
    z<-data.frame(eligible=0L,approved=0L,bytes_to_be_freed=0,
      status="HOLD_MISSING_TWO_RESTORE_AND_PRODUCT_CLOSURE",
      stringsAsFactors=FALSE)
    write.csv(z,out,row.names=FALSE)
    if(action!="plan")stop(z$status)
    return(invisible(z))
  }
  read <- function(n)read.csv(file.path(state,n),stringsAsFactors=FALSE,
                             check.names=FALSE)
  q<-read(required_files[[1]]);cloud<-read(required_files[[2]])
  backup<-read(required_files[[3]]);product<-read(required_files[[4]])
  keys<-c("relative_path","sha256")
  if(!all(c(keys,"bytes")%in%names(q)) ||
     !all(c(keys,"verification")%in%names(cloud)) ||
     !all(c(keys,"restore_status","independent_location")%in%names(backup)) ||
     !all(c(keys,"closure_status")%in%names(product)))
    stop("C_CLEANUP_HOLD: invalid private backup/product evidence schema")
  if(anyDuplicated(paste(q$relative_path,q$sha256)))
    stop("C_CLEANUP_HOLD: duplicated cleanup identity")
  qa <- paste(q$relative_path,tolower(q$sha256),sep="|")
  match_good <- function(z,ok) paste(z$relative_path[ok],
                             tolower(z$sha256[ok]),sep="|")
  google<-match_good(cloud,cloud$verification=="READBACK_SHA256_PASS")
  restored <- backup$restore_status=="RESTORE_SHA256_PASS" &
      !is.na(backup$independent_location) &
      nzchar(backup$independent_location) &
      !grepl("(^[Cc]:[/\\\\]|Learning-Outcomes-Private|lo_private:)",
              backup$independent_location,ignore.case=TRUE)
  other<-match_good(backup,restored)
  closed<-match_good(product,product$closure_status=="PASS")
  verified<-qa%in%google & qa%in%other & qa%in%closed
  q$verified_off_c_restore_and_product_closure<-verified
  approvals <- file.path(state,"LOCAL_CLEANUP_APPROVED.csv")
  permitted <- rep(FALSE,nrow(q))
  if(file.exists(approvals)) {
    a<-read.csv(approvals,stringsAsFactors=FALSE)
    if(all(c(keys,"approved")%in%names(a)) && !anyDuplicated(
       paste(a$relative_path,a$sha256))) {
      yay<-paste(a$relative_path[toupper(a$approved)=="YES"],
                 tolower(a$sha256[toupper(a$approved)=="YES"]),sep="|")
      permitted <- qa%in%yay
    }
  }
  q$user_approval<-permitted
  write.csv(q,file.path(state,"PRIVATE_FIXED_CLEANUP_REVIEW.csv"),
            row.names=FALSE)
  z<-data.frame(eligible=sum(verified),approved=sum(verified&permitted),
     bytes_to_be_freed=0,
     prospective_redundant_bytes=sum(as.numeric(q$bytes[verified]),na.rm=TRUE),
     status=if(any(verified&permitted))
       "QUARANTINE_ELIGIBLE_STILL_NO_BYTES_FREED"
       else "HOLD_OR_NO_APPROVED_CANDIDATES",
     stringsAsFactors=FALSE)
  write.csv(z,out,row.names=FALSE)
  if(action!="plan" && !all(verified[permitted]))
    stop("C_CLEANUP_HOLD: approvals without off-C independent restore")
  if(action!="plan" && !any(verified&permitted))
    stop("C_CLEANUP_HOLD: zero eligible approved files")
  # Quarantine on the SAME C: drive does not reclaim disk capacity. Only
  # after >=30 days + fresh hashes + source rights + user-specific approval
  # can the existing LOCAL_QUARANTINE.R finalize remove a verified duplicate.
  invisible(z)
}
