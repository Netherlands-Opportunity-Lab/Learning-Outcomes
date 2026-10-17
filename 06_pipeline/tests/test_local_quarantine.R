# Synthetic quarantine regression: exact SHA, independent receipts, restore, isolation.
if(!requireNamespace("digest",quietly=TRUE))stop("digest needed for this test")
base <- tempfile("synthetic_quarantine_")
home <- normalizePath(base,winslash="/",mustWork=FALSE)
root <- file.path(home,"Downloads","PISA_PIRLS_MASTER_PIPELINE")
state <- file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation")
dir.create(root,recursive=TRUE,showWarnings=FALSE)
dir.create(state,recursive=TRUE,showWarnings=FALSE)
rel <- "22_completion_final/cache/redundant.rds"
src <- file.path(root,rel)
dir.create(dirname(src),recursive=TRUE,showWarnings=FALSE)
writeBin(as.raw(1:24),src)
sha <- digest::digest(file=src,algo="sha256")
write.csv(data.frame(relative_path=rel,sha256=sha,
 bytes=24,classification="DERIVED_CANDIDATE_UNVERIFIED",
 decision="QUARANTINE_ELIGIBLE_REQUIRES_FINAL_APPROVAL"),
 file.path(state,"LOCAL_CLEANUP_APPROVAL_QUEUE.csv"),row.names=FALSE)
write.csv(data.frame(relative_path=rel,sha256=sha,approved="YES"),
 file.path(state,"LOCAL_CLEANUP_APPROVED.csv"),row.names=FALSE)
write.csv(data.frame(relative_path=rel,sha256=sha,
 verification="READBACK_SHA256_PASS"),
 file.path(state,"VERIFIED_CLOUD_ARTIFACTS.csv"),row.names=FALSE)
write.csv(data.frame(relative_path=rel,sha256=sha,
 restore_status="RESTORE_SHA256_PASS",independent_location="verified-independent-test-object"),
 file.path(state,"INDEPENDENT_BACKUP_RESTORE_RECEIPTS.csv"),row.names=FALSE)
write.csv(data.frame(relative_path=rel,sha256=sha,closure_status="PASS"),
 file.path(state,"PRODUCT_DEPENDENCY_CLOSURE.csv"),row.names=FALSE)
other <- file.path(home,"Downloads","unrelated_personal_file.txt")
writeLines("must remain",other)
old <- Sys.getenv(c("USERPROFILE","LO_MASTER_PROJECT_ROOT","LO_QUARANTINE_ROOT",
 "LO_QUARANTINE_ACTION","LO_ALLOW_QUARANTINE_MOVE","LO_RESTORE_RELATIVE_PATH"),
 unset=NA_character_)
restore_env <- function() {
 for(k in names(old))if(is.na(old[[k]]))Sys.unsetenv(k) else
   do.call(Sys.setenv,as.list(setNames(old[[k]],k)))
}
Sys.setenv(USERPROFILE=home,LO_MASTER_PROJECT_ROOT=root,
 LO_QUARANTINE_ROOT=file.path(home,"Documents","PISA_QUARANTINE"),
 LO_QUARANTINE_ACTION="stage",LO_ALLOW_QUARANTINE_MOVE="YES")
source("06_pipeline/LOCAL_QUARANTINE.R",encoding="UTF-8")
q <- file.path(home,"Documents","PISA_QUARANTINE",rel)
stopifnot(file.exists(q),!file.exists(src),
 identical(digest::digest(file=q,algo="sha256"),sha),file.exists(other))
Sys.setenv(LO_QUARANTINE_ACTION="restore",LO_RESTORE_RELATIVE_PATH=rel)
source("06_pipeline/LOCAL_QUARANTINE.R",encoding="UTF-8")
stopifnot(file.exists(src),!file.exists(q),
 identical(digest::digest(file=src,algo="sha256"),sha),file.exists(other))
restore_env()
unlink(base,recursive=TRUE)
cat("PASS synthetic quarantine stage/restore, exact SHA and Downloads isolation\n")
