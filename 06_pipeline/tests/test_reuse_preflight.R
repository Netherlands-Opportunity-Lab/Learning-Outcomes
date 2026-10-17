# Synthetic preflight regression, no pupil data and no production.
source("06_pipeline/REUSE_PREFLIGHT.R",encoding="UTF-8")
base <- tempfile("reuse_guard_")
home <- file.path(base,"home")
bundle <- file.path(base,"bundle")
dir.create(file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation"),
  recursive=TRUE,showWarnings=FALSE)
dir.create(file.path(bundle,"engine"),recursive=TRUE,showWarnings=FALSE)
tasks <- data.frame(metric_key=c("a","b"),country=c("NLD","FRA"),
                    module="core",survey="PISA")
write.csv(tasks,file.path(bundle,"engine","TASKS.csv"),row.names=FALSE)
write.csv(data.frame(country=c("NLD","FRA","CZE"),
  strictly_above_czechia=c("TRUE","TRUE","FALSE")),
  file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"),row.names=FALSE)
q <- data.frame(metric_key=c("a","b"),
  scientific_action=c("VALIDATE_EXISTING_RESULT","COMPUTE_OR_FIND_OLDER_RESULT"),
  release_status="NOT_RELEASED")
state <- file.path(home,"Downloads","LO05_RESULTATEN","master_reconciliation")
write.csv(q,file.path(state,"CONTRACT_LEVEL_REUSE_AND_COMPUTE_QUEUE.csv"),
          row.names=FALSE)
old <- Sys.getenv("USERPROFILE",unset=NA_character_)
Sys.setenv(USERPROFILE=home)
res <- lo_reuse_preflight(bundle,"nld_plus_19")
stopifnot(sum(res$contracts)==2L,
          file.exists(file.path(state,"EXECUTION_REUSE_PREFLIGHT.csv")))
err <- try(lo_reuse_preflight(bundle,"nld_plus_19",enforce=TRUE),silent=TRUE)
stopifnot(inherits(err,"try-error"))
if(is.na(old))Sys.unsetenv("USERPROFILE") else Sys.setenv(USERPROFILE=old)
unlink(base,recursive=TRUE)
cat("PASS synthetic zero-approval preflight and execute fail-closed guard\n")
