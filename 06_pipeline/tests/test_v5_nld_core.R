# Synthetic-only unit tests for guarded NLD PISA V5 execution lane.
source("06_pipeline/V5_NLD_CORE_ONLY.R",encoding="UTF-8")
cfg <- list(run_mode="NLD_ONLY",phases="NLD",action="production",
  workers=1L,allow_raw_imports=FALSE,delete_files=FALSE,
  write_existing_project_registry=FALSE,allow_unverified_promotion=FALSE,
  candidate_calculation=TRUE,gc_policy="auto_exact_duplicate_run_exports")
z <- lo_v5_nld_core_guard(cfg)
stopifnot(identical(z$candidate_calculation,FALSE),
  identical(z$gc_policy,"report_only"),
  identical(cfg$candidate_calculation,TRUE))
bad <- cfg;bad$run_mode <- "NLD_PLUS_OECD_PPP"
stopifnot(inherits(try(lo_v5_nld_core_guard(bad),silent=TRUE),"try-error"))
bad <- cfg;bad$allow_raw_imports <- TRUE
stopifnot(inherits(try(lo_v5_nld_core_guard(bad),silent=TRUE),"try-error"))
bad <- cfg;bad$workers <- 2L
stopifnot(inherits(try(lo_v5_nld_core_guard(bad),silent=TRUE),"try-error"))
tmp <- tempfile("nld_core_mock_")
dir.create(tmp,recursive=TRUE)
mock <- file.path(tmp,"mock_source.R")
# A mock of the two expected pinned science entrypoints without pupil calculations.
lines <- c(
  "lo_integrated_cfg <- function(bundle) list(run_mode='NLD_ONLY',phases='NLD',",
  "  action='production',workers=1L,allow_raw_imports=FALSE,delete_files=FALSE,",
  "  write_existing_project_registry=FALSE,allow_unverified_promotion=FALSE,",
  "  candidate_calculation=TRUE,gc_policy='auto_exact_duplicate_run_exports')",
  "lo_integrated_main <- function(bundle) {",
  "  cfg <- lo_integrated_cfg(bundle)",
  "  stopifnot(!cfg$candidate_calculation,cfg$gc_policy=='report_only')",
  "  writeLines('PASS',file.path(bundle,'MOCK_PASS.txt'))",
  "}"
)
writeLines(lines,mock)
lo_v5_nld_core_execute(tmp,mock)
stopifnot(identical(readLines(file.path(tmp,"MOCK_PASS.txt")),"PASS"))
unlink(tmp,recursive=TRUE)
cat("PASS narrow NL native route, no candidate calculations, safe policy and mock call\n")
