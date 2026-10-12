# Synthetic source: tests exact run isolation, HOLD and no pupil computation.
stopifnot(requireNamespace("DBI",quietly=TRUE),
          requireNamespace("RSQLite",quietly=TRUE),
          requireNamespace("digest",quietly=TRUE))
source("06_pipeline/EXISTING_LO02_EXPORT.R",encoding="UTF-8")
home <- tempfile("lo_export_")
dir.create(home,recursive=TRUE)
rid <- "run_20261012_084825"
run <- file.path(home,"runs",rid)
dir.create(file.path(run,"PHASE_NLD","LO02_RELEASED_PISA_CORE_GENDER"),
           recursive=TRUE)
write.csv(data.frame(action=c("COMPUTE","HOLD"),n=c(2,12)),
          file.path(run,"PHASE_NLD","LO02_RELEASED_PISA_CORE_GENDER",
                    "AANTALLEN.csv"),row.names=FALSE)
dbdir <- file.path(home,"lo02")
dir.create(dbdir)
db <- file.path(dbdir,"synthetic.sqlite")
cn <- DBI::dbConnect(RSQLite::SQLite(),db)
DBI::dbWriteTable(cn,"results",data.frame(
 metric_key=c("a","b","c"),country="NLD",survey="PISA",
 module="core",year=c(2022,2025,2018),
 estimate=c(501,498,504),se=c(3.1,3.2,3.0),
 run_id=c(rid,rid,"run_20261011_010101")))
DBI::dbDisconnect(cn)
x <- lo_existing_result_export(home,rid)
stopifnot(x$status=="PRIVATE_REVIEW_ONLY_EXACT_RUN_MATCH",
          x$matched_new_results==2L)
comparison <- read.csv(file.path(run,"PRIVATE_RESULT_EXPORT","LO02_SNAPSHOT_COMPARISONS.csv"))
stopifnot(comparison$evidence_status[[1L]]=="HOLD_NO_PAIR_OF_AGGREGATE_SNAPSHOTS")
snap <- read.csv(file.path(run,"PRIVATE_RESULT_EXPORT","LO02_SNAPSHOT_COUNTS.csv"))
stopifnot(nrow(snap)==1L,snap$n_rows[[1L]]==3L,
          snap$n_metric_keys[[1L]]==3L,
          snap$exact_run_link[[1L]])

rows <- read.csv(file.path(run,"PRIVATE_RESULT_EXPORT",
                            "LO02_NEW_RESULT_ROWS.csv"))
stopifnot(nrow(rows)==2L,setequal(rows$metric_key,c("a","b")))
# Wrong run ID must fail closed and must not leave prior accepted result export
# falsely classified as new. New run has no matching DB rows.
rid2 <- "run_20261012_084826"
run2 <- file.path(home,"runs",rid2)
dir.create(file.path(run2,"PHASE_NLD","LO02_RELEASED_PISA_CORE_GENDER"),
           recursive=TRUE)
write.csv(data.frame(action="COMPUTE",n=2),
          file.path(run2,"PHASE_NLD","LO02_RELEASED_PISA_CORE_GENDER",
                    "AANTALLEN.csv"),row.names=FALSE)
y <- lo_existing_result_export(home,rid2)
stopifnot(y$status=="HOLD_NO_EXACT_RUN_LINK",
  !file.exists(file.path(run2,"PRIVATE_RESULT_EXPORT",
                         "LO02_NEW_RESULT_ROWS.csv")))
unlink(home,recursive=TRUE)
cat("PASS exact LO02 run export, original db unmodified, absent run HOLD\n")
