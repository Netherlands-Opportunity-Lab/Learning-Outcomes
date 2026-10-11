# Synthetic contract/legacy merge and conflict-classification test (no pupil data).
source("06_pipeline/CONTRACT_REUSE_QUEUE.R",encoding="UTF-8")
base <- tempfile("contract_triage_")
home <- file.path(base,"home")
bundle <- file.path(base,"bundle")
state <- file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation")
dir.create(state,recursive=TRUE,showWarnings=FALSE)
dir.create(file.path(bundle,"engine"),recursive=TRUE,showWarnings=FALSE)
dir.create(file.path(bundle,"evidence"),recursive=TRUE,showWarnings=FALSE)
keys <- c("numeric","metadata","unknown_numeric","existing","old_only","v5_only","absent")
tasks <- data.frame(metric_key=keys,country=rep("NLD",length(keys)),
  survey=rep("PISA",length(keys)),module=rep("core",length(keys)))
write.csv(tasks,file.path(bundle,"engine","TASKS.csv"),row.names=FALSE)
write.csv(data.frame(country=c("NLD","FRA","CZE"),
  strictly_above_czechia=c("TRUE","TRUE","FALSE")),
  file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"),row.names=FALSE)
d <- data.frame(metric_key=keys[1:4],
  distinct_result_hashes=c(2,2,2,1),
  distinct_numeric_estimate_se=c(2,1,1,1),
  decision=c("HISTORICAL_NUMERIC_CONFLICT_NEEDS_ADJUDICATION",
    "HASH_CONFLICT_NUMERIC_EQUAL","HASH_CONFLICT_NUMERIC_EVIDENCE_INCOMPLETE",
    "MATCHING_COPIES_NOT_YET_VALIDATED"))
write.csv(d,file.path(state,"CANONICAL_RESULT_REUSE_DECISIONS_PRIVATE.csv"),row.names=FALSE)
write_archive <- function(path,key) {
  con <- gzfile(path,"wt")
  write.csv(data.frame(metric_key=key),con,row.names=FALSE)
  close(con)
}
write_archive(file.path(bundle,"evidence","LO01_HISTORICAL_CANDIDATES.csv.gz"),"old_only")
write_archive(file.path(bundle,"evidence","LO02_RETURN_20261010_CURRENT_RESULTS.csv.gz"),"v5_only")
before <- Sys.getenv("USERPROFILE",unset=NA_character_)
Sys.setenv(USERPROFILE=home)
lo_contract_reuse_queue(bundle)
res <- read.csv(file.path(state,"CONTRACT_LEVEL_REUSE_AND_COMPUTE_QUEUE.csv"),
  stringsAsFactors=FALSE)
expected <- c("ADJUDICATE_NUMERIC_CONFLICT","REVIEW_HASH_METADATA_PARITY",
 "REVIEW_HASH_NUMERIC_INCOMPLETE","VALIDATE_EXISTING_RESULT",
 "REVIEW_LO01_HISTORIC_CANDIDATE","VALIDATE_LO02_ARCHIVE_CANDIDATE",
 "SEARCH_HISTORICAL_BEFORE_COMPUTE")
stopifnot(identical(res$scientific_action[match(keys,res$metric_key)],expected),
  all(res$engine_route=="LO02_V5_NATIVE_PER_TASK_INPUT_AND_SCIENCE_FINGERPRINT_REUSE"))
if(is.na(before))Sys.unsetenv("USERPROFILE") else Sys.setenv(USERPROFILE=before)
unlink(base,recursive=TRUE)
cat("PASS separated numerical/hash conflicts and preserved old LO01/LO02 candidate keys\n")
