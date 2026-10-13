# Safe scientific production dispatcher (user-selected production stage).
# Permits already pinned LO02 native PISA core/gender only; remaining modules
# stay explicit HOLD pending source-specific PV/replicate science certification.
lo_fixed_produce <- function(bundle,scope_info,tasks,out,
                             native_run=FALSE,grid=NULL) {
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  fam <- aggregate(list(n=rep(1L,nrow(tasks))),
    tasks[c("survey","module")],sum)
  native <- tasks$survey=="PISA" &
     tasks$module%in%c("core","gender") &
     tasks$country%in%scope_info$selected
  fam$route <- ifelse(fam$survey=="PISA" &
      fam$module%in%c("core","gender"),
      "PINNED_LO02_NATIVE_FINGERPRINT_REUSE",
      "HOLD_SCIENTIFIC_PV_SAMPLE_METHOD_GATE")
  fam$scientific_release <- "NOT_AUTOMATICALLY_VALIDATED"
  write.csv(fam,file.path(out,"PRODUCER_CAPABILITY_MATRIX.csv"),
            row.names=FALSE)
  extra <- setdiff(scope_info$selected,
                   c("NLD",scope_info$foreign_reference))
  n_extra <- sum(tasks$country%in%extra)
  run_status <- data.frame(scope=scope_info$scope,
    selected_contracts=nrow(tasks),
    native_pisa_core_gender_contracts=sum(native),
    other_or_unreleased_contracts=sum(!native),
    countries_outside_native_ref_scope=length(extra),
    extra_contracts=n_extra,
    native_execution="NOT_STARTED",
    scientific_release="HOLD_PENDING_INDEPENDENT_VALIDATION",
    stringsAsFactors=FALSE)
  # New default: bounded one-pass candidate production using the pinned V11
  # estimators. Unlike old LO05 consolidation, never clones current/history
  # Parquet snapshots or student caches. Publication remains a separate gate.
  if(native_run &&
     identical(Sys.getenv("LO_FIXED_PRODUCER_ENGINE",unset="compact"),"compact")) {
    repo<-Sys.getenv("LO_REPO_ROOT",unset="")
    if(!nzchar(repo)||!file.exists(file.path(repo,"06_pipeline",
                                           "LO_COMPACT_RECOMPUTE.R")))
      stop("COMPACT_PRODUCER_REPOSITORY_NOT_CONFIGURED")
    source(file.path(repo,"06_pipeline","LO_COMPACT_RECOMPUTE.R"),
           local=environment(),encoding="UTF-8")
    root<-normalizePath(file.path(out,"..",".."),winslash="/",mustWork=TRUE)
    attempt<-tryCatch(lo_compact_run(bundle,repo,scope_info,tasks,root),
                      error=function(e)e)
    if(inherits(attempt,"error")) {
      run_status$native_execution<-"HOLD_COMPACT_PRODUCER_ERROR"
      run_status$engine_error<-substr(conditionMessage(attempt),1L,400L)
    } else {
      run_status$native_execution<-"COMPACT_CANDIDATES_COMPLETE_NOT_VALIDATED"
      run_status$compact_rows<-attempt$total_grid_rows
      run_status$compact_estimate_se_n<-attempt$complete_candidates
      run_status$compact_holds<-attempt$holds_this_attempt
      run_status$compact_grid_mb<-attempt$grid_mb
      run_status$compact_dashboard_mb<-attempt$dashboard_mb
      run_status$private_grid_root<-file.path(root,"FIXED_PRODUCTION_V1",
        scope_info$scope,"compact")
    }
    write.csv(run_status,file.path(out,"PRODUCTION_SCOPE_STATUS.csv"),row.names=FALSE)
    cat("PRODUCTION_STATUS: ",run_status$native_execution,
       "; compact grid and N require independent scientific validation; ",
       "no historical snapshot copies, no cleanup, no public release.\n",sep="")
    return(invisible(run_status))
  }
  if(!native_run) {
    run_status$native_execution <- "PREVIEW_ONLY"
  } else {
    # Integrated engine is source-SHA verified before this function is called.
    engine <- file.path(bundle,"code","INTEGRATED.R")
    if(!file.exists(engine))stop("PRODUCTION_HOLD: pinned engine missing")
    e <- new.env(parent=.GlobalEnv)
    source(engine,local=e,encoding="UTF-8")
    cfg_original <- get("lo_integrated_cfg",envir=e,inherits=FALSE)
    e$lo_integrated_cfg <- function(b) {
      cfg <- cfg_original(b)
      mode <- if(scope_info$scope=="nld_only")"NLD_ONLY" else
                "NLD_PLUS_OECD_PPP"
      cfg$run_mode <- mode
      cfg$phases <- if(mode=="NLD_ONLY")"NLD" else c("NLD","OECD19")
      cfg$candidate_calculation <- FALSE
      cfg$gc_policy <- "report_only"
      cfg$delete_files <- FALSE
      cfg$allow_raw_imports <- FALSE
      cfg$allow_unverified_promotion <- FALSE
      cfg$write_existing_project_registry <- FALSE
      cfg$workers <- 1L
      cfg
    }
    old_opts <- options(learning_outcomes.mode=if(scope_info$scope=="nld_only")
      "NLD_ONLY" else "NLD_PLUS_OECD_PPP",
      learning_outcomes.action="production",learning_outcomes.gc_policy="report_only")
    on.exit(options(old_opts),add=TRUE)
    # Pinned scientific engine only; its own per-task input+science
    # fingerprints control exact reuse. No unverified module calculation.
    result <- tryCatch(e$lo_integrated_main(bundle),error=function(e)e)
    if(inherits(result,"error")) {
      run_status$native_execution <- "HOLD_NATIVE_ENGINE_FAILURE"
      run_status$engine_error <- substr(conditionMessage(result),1L,400L)
    } else {
      run_status$native_execution <-
        if(scope_info$scope=="all_required")
          "PINNED_NATIVE_NLD19_ATTEMPTED_OTHER30_NEED_SCOPED_ADAPTER"
        else "PINNED_NATIVE_ATTEMPTED_RESULTS_REQUIRE_QA"
      if(is.list(result) && "run"%in%names(result))
        run_status$private_run_id <- basename(result$run)
    }
  }
  write.csv(run_status,file.path(out,"PRODUCTION_SCOPE_STATUS.csv"),row.names=FALSE)
  cat("PRODUCTION_STATUS: ",run_status$native_execution,
      "; non-native modules remain gated; no cleanup or public release.\n",sep="")
  invisible(run_status)
}
