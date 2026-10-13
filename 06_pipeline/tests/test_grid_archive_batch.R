source("06_pipeline/MASTER_ESTIMATION_GRID.R")
source("06_pipeline/GRID_ARCHIVE_BATCH.R")
tasks <- data.frame(metric_key=c("k1","k2","k3"),
 survey="PISA",country="NLD",year="2022",domain="reading",
 module="core",stat="mean",group=c("total","girls","boys"),
 definition="score",peer_definition="",threshold="",sample="NLD_2022")
g <- lo_grid_from_tasks(tasks)
sha <- function(z)paste(rep(z,64),collapse="")
candidate <- data.frame(cell_id="k1",status="SCIENTIFICALLY_VALIDATED",
 estimate=490,standard_error=3,n_unweighted=1500,
 sample_id="NLD_2022",method_version="m1",
 input_fingerprint=sha("a"),code_fingerprint=sha("b"),
 result_hash=sha("c"))
filled <- lo_grid_archive_fill(g,candidate)
stopifnot(filled$status[[1]]=="SCIENTIFICALLY_VALIDATED",
 is.na(filled$estimate[[2]]),filled$estimate[[1]]==490)
candidate$sample_id <- "UNRELATED_SAMPLE"
stopifnot(inherits(try(lo_grid_archive_fill(g,candidate),silent=TRUE),"try-error"))
candidate$sample_id <- "NLD_2022"
candidate$status <- "COMPUTED_PENDING_VALIDATION"
unchanged <- lo_grid_archive_fill(g,candidate)
stopifnot(all(is.na(unchanged$estimate)))
g$status[2:3] <- "COMPUTE_REQUIRED_AFTER_METHOD_GATE"
g$method_version[2:3] <- "m1"
g$input_fingerprint[2:3] <- sha("a")
g$weight_design[2:3] <- "weights1"
g$pv_rule[2:3] <- "PV10"
g$variance_rule[2:3] <- "FAYBRR"
batch <- lo_grid_batch_plan(g)
stopifnot(nrow(batch)==1L,batch$n_cells==2L)
g$pv_rule[[3]] <- ""
stopifnot(inherits(try(lo_grid_batch_plan(g),silent=TRUE),"try-error"))
cat("PASS strict archive provenance and two-cell shared-wave batch planning\n")


# Historical archives are candidates only; no estimates are invented.
cand <- lo_grid_mark_archive_candidates(lo_grid_from_tasks(tasks),c("k1","k2"),c("k2"))
stopifnot(cand$status[[1]]=="ARCHIVE_CANDIDATE_FOUND_NOT_VALIDATED",
          cand$status[[2]]=="ARCHIVE_CANDIDATE_FOUND_NOT_VALIDATED",
          cand$archive_source[[2]]=="LO02_CANDIDATE",
          all(is.na(cand$estimate)),
          nrow(lo_grid_batch_plan(cand))==0L)
