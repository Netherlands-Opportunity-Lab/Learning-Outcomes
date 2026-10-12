# A real (synthetic) R-native publisher test; no pupil data, Google auth or rclone.
# Run from repository root; requires jsonlite, digest and zip.
stopifnot(requireNamespace("jsonlite",quietly=TRUE),
          requireNamespace("digest",quietly=TRUE),
          requireNamespace("zip",quietly=TRUE))
source("06_pipeline/DRIVE_SYNC.R",encoding="UTF-8")

work <- tempfile("lo_native_drive_test_")
dir.create(work,recursive=TRUE)
root <- file.path(work,"LO05_RESULTATEN")
run_id <- "run_20261012_084825"
run <- file.path(root,"runs",run_id)
dir.create(file.path(run,"PHASE_NLD","LO02_RELEASED_PISA_CORE_GENDER"),
           recursive=TRUE,showWarnings=FALSE)
dir.create(file.path(root,"master_reconciliation"),
           recursive=TRUE,showWarnings=FALSE)
writeLines(c("RUNNER=LEARNING_OUTCOMES_INTEGRATED_V2_20261010",
             "ACTION=production","SCIENTIFIC_FINAL_FREEZE=NOT_ACHIEVED",
             "PHASE_NLD=RELEASED_PISA_ATTEMPTED_CANDIDATES_NOT_RELEASED"),
           file.path(run,"STATUS.txt"))
write.csv(data.frame(phase="NLD",status="REVIEW"),
          file.path(run,"PHASE_STATUS.csv"),row.names=FALSE)
write.csv(data.frame(selected=1867),
          file.path(run,"PLAN_COUNTS.csv"),row.names=FALSE)
write.csv(data.frame(phase="NLD",n_reused=2,n_computed=0),
          file.path(run,"PHASE_NLD","LO02_RELEASED_PISA_CORE_GENDER","AANTALLEN.csv"),
          row.names=FALSE)
write.csv(data.frame(test="synthetic",result="PASS"),
          file.path(run,"PHASE_NLD","WINDOWS_INTEGRATION_TESTS.csv"),
          row.names=FALSE)
members <- c("STATUS.txt","PHASE_STATUS.csv","PLAN_COUNTS.csv",
             "PHASE_NLD/WINDOWS_INTEGRATION_TESTS.csv",
             "PHASE_NLD/LO02_RELEASED_PISA_CORE_GENDER/AANTALLEN.csv")
make_zip <- function(extra=character()) {
  p <- file.path(run,"LEARNING_OUTCOMES_RETURN.zip")
  if(file.exists(p)) unlink(p)
  zip::zipr(p,files=c(members,extra),root=run)
  stopifnot(file.exists(p))
}
make_zip()

remote_folder <- file.path(work,"remote")
dir.create(remote_folder,recursive=TRUE)
prefix <- "lo_private:Learning-Outcomes-Private/"
resolve <- function(x) {
  if(startsWith(x,prefix))
    return(file.path(remote_folder,substring(x,nchar(prefix)+1L)))
  x
}
calls <- character()
# Override only the network executor; exercise real file selection, ZIP
# inspection, SHA-256 readback, manifest and LATEST ordering.
lo_drive_run <- function(exe,args) {
  stopifnot(length(args)==3L,identical(args[[1]],"copyto"))
  calls <<- c(calls,paste(args,collapse=" | "))
  src <- resolve(args[[2]])
  dest <- resolve(args[[3]])
  if(!file.exists(src))stop("Synthetic rclone: source missing: ",src)
  dir.create(dirname(dest),recursive=TRUE,showWarnings=FALSE)
  if(!file.copy(src,dest,overwrite=TRUE))
    stop("Synthetic rclone copy failed")
  invisible("COPIED")
}
fake_exe <- file.path(work,"rclone_fake.exe")
file.create(fake_exe)
cfg <- file.path(work,"private.json")
jsonlite::write_json(list(local_results_root=root,
  remote="lo_private:Learning-Outcomes-Private",
  data_visibility="PRIVATE_ACCOUNT_ONLY",
  rclone_binary=fake_exe,
  min_age_seconds=0,max_file_bytes=64*1024^2),
  cfg,auto_unbox=TRUE,pretty=TRUE)
Sys.setenv(LO_DRIVE_SYNC_RUN_ID=run_id)
ans <- lo_drive_sync(cfg,action="publish",rclone_override=fake_exe,
                     producer_commit="TEST_ONLY")
stopifnot(ans$selected>=5L,ans$uploaded>=5L)
named <- file.path(remote_folder,"reports",run_id)
stopifnot(
  file.exists(file.path(named,"LEARNING_OUTCOMES_RETURN.zip")),
  file.exists(file.path(named,"STATUS.txt")),
  file.exists(file.path(named,"PHASE_STATUS.csv")),
  file.exists(file.path(named,"PLAN_COUNTS.csv")),
  file.exists(file.path(named,"PHASE_NLD","WINDOWS_INTEGRATION_TESTS.csv")),
  file.exists(file.path(named,"PHASE_NLD",
                        "LO02_RELEASED_PISA_CORE_GENDER","AANTALLEN.csv")))
remote_latest <- file.path(remote_folder,"LATEST.json")
stopifnot(file.exists(remote_latest))
pointer <- jsonlite::fromJSON(remote_latest)
manifest <- file.path(remote_folder,"manifests",
                       paste0(pointer$manifest,".json"))
stopifnot(file.exists(manifest))
m <- jsonlite::fromJSON(manifest)
stopifnot(identical(m$scientific_status,"NOT_AUTOMATICALLY_VALIDATED"),
          !any(grepl("^[A-Za-z]:",m$files$path)),
          any(grepl("LEARNING_OUTCOMES_RETURN.zip",m$files$path,fixed=TRUE)),
          all(m$files$scientific_status=="NOT_AUTOMATICALLY_VALIDATED"))

# Re-publishing the same bytes remains correct and non-destructive.
lo_drive_sync(cfg,action="publish",rclone_override=fake_exe,
              producer_commit="TEST_ONLY")
stopifnot(file.exists(file.path(named,"LEARNING_OUTCOMES_RETURN.zip")))
latest_before_bad <- digest::digest(file=remote_latest,algo="sha256")
calls_before_bad <- length(calls)

# Regression: legitimate reviewed CSV reports can exceed the old
# blanket 8 MiB expanded-member limit without loosening the name/content gate.
gc_file <- file.path(run,"GC_CANDIDATES.csv")
writeBin(rep(charToRaw("reviewed,synthetic,report\\n"),500000L),gc_file)
members <- c(members,"GC_CANDIDATES.csv")
make_zip()
legitimate <- lo_drive_sync(cfg,action="publish",rclone_override=fake_exe,
                            producer_commit="TEST_ONLY")
stopifnot(identical(legitimate$run_report_completeness,"FULL_REVIEWED"),
          file.exists(file.path(named,"LEARNING_OUTCOMES_RETURN.zip")))
# An oversized-but-known ZIP is withheld, yet separately inspected named
# text reports still reach private Drive and the manifest marks PARTIAL.
writeBin(rep(charToRaw("reviewed,synthetic,report\\n"),3500000L),gc_file)
make_zip()
oversized <- lo_drive_sync(cfg,action="publish",rclone_override=fake_exe,
                           producer_commit="TEST_ONLY")
stopifnot(identical(oversized$run_report_completeness,
                    "PARTIAL_OVERSIZE_HELD"))
partial_pointer <- jsonlite::fromJSON(remote_latest)
partial_manifest <- jsonlite::fromJSON(file.path(
  remote_folder,"manifests",paste0(partial_pointer$manifest,".json")))
stopifnot(identical(partial_manifest$run_report_completeness,
                    "PARTIAL_OVERSIZE_HELD"),
          !any(grepl("LEARNING_OUTCOMES_RETURN.zip",
                     partial_manifest$files$path,fixed=TRUE)))
members <- setdiff(members,"GC_CANDIDATES.csv")
unlink(gc_file)
make_zip()

# A ZIP containing an unknown raw student source never leaves the laptop.
writeLines("FAKE RAW STUDENT DATA",file.path(run,"students.sav"))
make_zip("students.sav")
unsafe <- try(lo_drive_sync(cfg,action="publish",
                            rclone_override=fake_exe),silent=TRUE)
stopifnot(inherits(unsafe,"try-error"),
          identical(digest::digest(file=remote_latest,algo="sha256"),
                    latest_before_bad), length(calls)==calls_before_bad)
# Restore known ZIP and check unknown credential payload fails before copying.
make_zip()
writeLines(c("RUNNER=LEARNING_OUTCOMES_INTEGRATED_V2_20261010",
             "SCIENTIFIC_FINAL_FREEZE=NOT_ACHIEVED",
             "access_token=SECRETLEAKEXAMPLE12345"),
           file.path(run,"STATUS.txt"))
make_zip()
unsafe <- try(lo_drive_sync(cfg,action="publish",
                            rclone_override=fake_exe),silent=TRUE)
stopifnot(inherits(unsafe,"try-error"))
Sys.setenv(LO_DRIVE_SYNC_RUN_ID="../../secret")
unsafe <- try(lo_drive_sync(cfg,action="publish",
                            rclone_override=fake_exe),silent=TRUE)
stopifnot(inherits(unsafe,"try-error"))
Sys.unsetenv("LO_DRIVE_SYNC_RUN_ID")
unlink(work,recursive=TRUE)
cat("PASS: reviewed LO05 ZIP, named private reports, verified SHA, no student/credential escape, run-ID guard\n")
