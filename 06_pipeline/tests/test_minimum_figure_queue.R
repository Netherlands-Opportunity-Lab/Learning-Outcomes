# Synthetic minimum calculation planner: no pupil estimators, no network.
source("06_pipeline/MINIMUM_FIGURE_QUEUE.R",encoding="UTF-8")
base <- tempfile("lo_minfig_")
bundle <- file.path(base,"bundle")
root <- file.path(base,"LO05_RESULTATEN")
dir.create(file.path(bundle,"engine"),recursive=TRUE)
dir.create(file.path(bundle,"evidence"),recursive=TRUE)
dir.create(root)
tasks <- data.frame(metric_key=c("a","b","c","d"),
  country=c("NLD","NLD","FRA","FRA"),
  survey=c("PISA","PISA","PIRLS","TIMSS"),
  year=c("2022","2025","2021","2023"),
  module=c("core","gender","core","peer"),
  contract_figure_id=c("TR_MEAN_age15_reading",
  "GP_GENDER_GAP_age15_reading","TR_BASIC_age10_reading",
  "EN_PERFORMANCE_PEER_age10_science"))
write.csv(tasks,file.path(bundle,"engine","TASKS.csv"),row.names=FALSE)
write.csv(data.frame(figure_id=c("a","b")),
 file.path(bundle,"FIGURE_SERIES_CONTRACT_20261002.csv"),row.names=FALSE)
write_gz <- function(x,path) {
  con <- gzfile(path,"wt");write.csv(x,con,row.names=FALSE);close(con)
}
write_gz(data.frame(metric_key=c("a","b"),scientific_status="UNVALIDATED"),
 file.path(bundle,"evidence","LO01_HISTORICAL_CANDIDATES.csv.gz"))
write_gz(data.frame(metric_key=c("b","c"),scientific_status="COMPUTED_PENDING_VALIDATION"),
 file.path(bundle,"evidence","LO02_RETURN_20261010_CURRENT_RESULTS.csv.gz"))
x <- lo_minimum_figure_queue(bundle,root,4L,2L)
stopifnot(x$total_contracts==4L,x$archived_candidate_any==3L,
          x$no_match_in_two_archives==1L,
          is.na(x$proven_new_computations))
out <- file.path(root,"master_reconciliation","MINIMUM_FIGURE_QUEUE")
q <- read.csv(file.path(out,"PRIVATE_METRIC_REUSE_QUEUE.csv"))
stopifnot(all(q$approval_to_compute=="NO"),
          q$product_decision[q$metric_key=="c"]==
              "DROP_SEPARATE_VISUAL_CAN_DERIVE_COMPLEMENT",
          q$product_decision[q$metric_key=="b"]==
              "DERIVED_CONTRAST_REQUIRES_JOINT_VARIANCE")
unlink(base,recursive=TRUE)
cat("PASS product-driven minimum queue: historical candidates are not new calculations\n")
