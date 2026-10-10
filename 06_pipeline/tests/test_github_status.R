# Synthetic regression test: Git status metadata only, no network or secrets.
options(lo.pipeline.functions_only=TRUE)
source("06_pipeline/RUN.R",encoding="UTF-8")
source("06_pipeline/GITHUB_STATUS.R",encoding="UTF-8")
stopifnot(requireNamespace("jsonlite",quietly=TRUE))
root <- tempfile("lo_safe_status_fixture_")
dir.create(file.path(root,"runs","run_20261010_154502"),recursive=TRUE)
statusfile <- file.path(root,"runs","run_20261010_154502","STATUS.txt")
writeLines(c(
  "STATUS=PLAN_COMPLETED_RECONCILIATION_READ_ONLY",
  "RUN_MODE=NLD_PLUS_OECD_PPP",
  "SCIENTIFIC_RELEASE=NOT_GRANTED",
  "NLD_SELECTED=1867",
  "OECD19_SELECTED=27979",
  "TOTAL_CONTRACT_TASKS=79448",
  "DETAIL=C:\\Users\\private\\secret_file.csv",
  "NEXT=send student details to outside@example.org",
  "CREDENTIAL=DO_NOT_EXPORT_ME"),statusfile)
oldroot <- Sys.getenv("LO_LOCAL_RESULTS_ROOT",unset=NA_character_)
on.exit_cleanup <- function() {
  if(is.na(oldroot)) Sys.unsetenv("LO_LOCAL_RESULTS_ROOT")
  else Sys.setenv(LO_LOCAL_RESULTS_ROOT=oldroot)
  unlink(root,recursive=TRUE)
}
Sys.setenv(LO_LOCAL_RESULTS_ROOT=root)
repo <- normalizePath(".",winslash="/",mustWork=TRUE)
manifest <- lo_status_publish_git(repo,
   action="status-publish",scope="nld_plus_19",
   outcome="OBSERVED",dry_run=TRUE)
out <- paste(readLines(file.path(repo,"06_pipeline","state",
                                 "github_status_pending.json"),warn=FALSE),
             collapse="\n")
stopifnot(
  identical(manifest$availability,"STATUS_FILE_FOUND"),
  identical(manifest$latest_local_run_id,"run_20261010_154502"),
  manifest$counts$nld_selected==1867,
  manifest$counts$oecd19_selected==27979,
  identical(manifest$scientific_release,"NOT_AUTOMATICALLY_GRANTED"),
  !grepl("secret_file|DO_NOT_EXPORT_ME|outside@example|C:\\\\Users|/Users/",
         out,perl=TRUE),
  !grepl("DETAIL|NEXT|CREDENTIAL",out,fixed=FALSE),
  !grepl("PRIVATE_ACCOUNT_ONLY",out,fixed=TRUE))
stopifnot(identical(lo_status_safe_code("a@b"),"UNKNOWN"),
          is.null(lo_status_safe_int("-1")),
          is.null(lo_status_safe_int("1.5")))
on.exit_cleanup()
cat("PASS GitHub privacy-safe status manifest and numeric whitelist\n")
