# Narrow scientific production lane: existing LO02 V5 PISA core/gender for NLD.
# Does not modify the pinned October v2 bundle; no other module runs as a candidate.
# The LO02 engine performs per-metric exact scientific+input fingerprint reuse
# against its OWN live registry. Older central results require separate adjudication.
lo_v5_nld_core_guard <- function(cfg) {
  if(!is.list(cfg) || !identical(cfg$run_mode,"NLD_ONLY") ||
     !identical(cfg$phases,"NLD") || !identical(cfg$action,"production"))
    stop("NLD_CORE_ROUTE_SCOPE_ERROR")
  mandatory_false <- c("allow_raw_imports","delete_files",
    "write_existing_project_registry","allow_unverified_promotion")
  if(!all(vapply(mandatory_false,function(n)identical(cfg[[n]],FALSE),logical(1))) ||
     !identical(cfg$workers,1L))
    stop("NLD_CORE_ROUTE_SAFETY_POLICY_CHANGED")
  cfg$candidate_calculation <- FALSE
  cfg$gc_policy <- "report_only"
  cfg
}
lo_v5_nld_core_execute <- function(bundle,source_file) {
  if(!file.exists(source_file))stop("Pinned integrated engine missing")
  e <- new.env(parent=.GlobalEnv)
  source(source_file,local=e,encoding="UTF-8")
  if(!exists("lo_integrated_cfg",envir=e,inherits=FALSE) ||
     !exists("lo_integrated_main",envir=e,inherits=FALSE))
    stop("Pinned integrated science entrypoints missing")
  original <- get("lo_integrated_cfg",envir=e,inherits=FALSE)
  e$lo_integrated_cfg <- function(b)lo_v5_nld_core_guard(original(b))
  cat("NLD core/gender: only LO02 v5 native task-level fingerprint reuse; ",
      "candidate estimators disabled; raw imports, public release and ",
      "automatic cleanup disabled.\n",sep="")
  e$lo_integrated_main(bundle)
}
