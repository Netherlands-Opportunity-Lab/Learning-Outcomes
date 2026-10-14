# SINGLE FIXED CONTROLLER: audit -> produce -> finalize (+ separate cleanup).
# This file deliberately never changes the pinned scientific engine or the
# September released website. All scientific values remain local/private.
lo_fixed_controller <- function(repo,bundle,
  stage=c("audit","produce","finalize","cleanup-plan","status"),
  scope=c("nld_only","nld_plus_19","all_required"),
  root=file.path(Sys.getenv("USERPROFILE",unset=path.expand("~")),
                 "Downloads","LO05_RESULTATEN")) {
  stage<-match.arg(stage);scope<-match.arg(scope)
  for(name in c("LO_SCOPE_LOCK.R","MASTER_ESTIMATION_GRID.R",
    "GRID_ARCHIVE_BATCH.R","LO_EXISTING_RESULT_REGISTRY.R",
    "LO_FIXED_VALIDATION.R","LO_FIXED_PRODUCERS.R")) {
    source(file.path(repo,"06_pipeline",name),
           local=environment(),encoding="UTF-8")
  }
  scope_info<-lo_locked_scope(bundle,scope)
  tasks<-read.csv(file.path(bundle,"engine","TASKS.csv"),
     colClasses="character",stringsAsFactors=FALSE,check.names=FALSE)
  if(nrow(tasks)!=79448L||anyDuplicated(tasks$metric_key))
    stop("FIXED_PIPELINE_HOLD: original 79448-key lock changed")
  selected<-lo_scope_filter_tasks(tasks,scope_info)
  new_peer_tasks<-lo_grid_new_low_peer_tasks(selected)
  state<-file.path(root,"FIXED_PRODUCTION_V1",scope)
  dir.create(state,recursive=TRUE,showWarnings=FALSE)
  evidence_dir<-file.path(state,"FINAL_FIXED_PIPELINE")
  dir.create(evidence_dir,recursive=TRUE,showWarnings=FALSE)
  if(stage=="status") {
    status_file<-file.path(state,"FIXED_STAGE_STATUS.csv")
    if(!file.exists(status_file)) {
      cat("FIXED_PIPELINE_STATUS=NOT_STARTED; scope=",scope,"\n",sep="")
      return(invisible(data.frame()))
    }
    x<-read.csv(status_file,stringsAsFactors=FALSE)
    print(x,row.names=FALSE)
    return(invisible(x))
  }
  lock<-file.path(state,"FIXED_PRODUCTION_OPERATION.lock")
  if(file.exists(lock))
    stop("FIXED_PIPELINE_BUSY: prior lock exists; check local RStudio session")
  if(!file.create(lock))stop("Cannot create fixed production lock")
  on.exit(unlink(lock),add=TRUE)
  statusfile<-file.path(state,"FIXED_STAGE_STATUS.csv")
  old<-if(file.exists(statusfile))read.csv(statusfile,stringsAsFactors=FALSE) else
    data.frame(stage=character(),scope=character(),status=character(),
      timestamp_utc=character(),detail=character(),stringsAsFactors=FALSE)
  put<-function(name,status,detail="") {
    item<-data.frame(stage=name,scope=scope,status=status,
      timestamp_utc=format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC"),
      detail=substr(detail,1L,450L),stringsAsFactors=FALSE)
    latest<-rbind(old,item)
    write.csv(latest,statusfile,row.names=FALSE)
    old <<- latest
    cat("FIXED_STAGE=",name," STATUS=",status,
        if(nzchar(detail))paste0(" DETAIL=",detail)else"","\n",sep="")
    invisible(item)
  }
  if(stage=="cleanup-plan") {
    # No file removal. Use existing candidate review, then the stronger
    # OFF-C independent restore proof gate; a missing input is a HOLD report.
    master <- file.path(root,"master_reconciliation")
    review <- tryCatch(source(file.path(repo,"06_pipeline",
       "LOCAL_CLEANUP_GATE.R"),local=environment(),encoding="UTF-8"),
       error=function(e)e)
    source(file.path(repo,"06_pipeline","LO_FIXED_CLEANUP_GATES.R"),
           local=environment(),encoding="UTF-8")
    report <- lo_fixed_backup_cleanup_gate(master,action="plan")
    put("cleanup-plan",
       if(inherits(review,"error"))"HOLD_MISSING_CANDIDATE_INVENTORY"
       else "REVIEW_ONLY_NO_DELETE",
       if(inherits(review,"error"))conditionMessage(review)
       else "No C-disk space freed; off-C restores required")
    return(invisible(report))
  }
  membership <- lo_scope_write_evidence(scope_info,selected,state)
  if(stage=="audit"||!file.exists(file.path(state,"PRIVATE_MASTER_GRID.csv"))) {
    audit<-lo_existing_result_evidence(bundle,selected,state,
       lo02_root=Sys.getenv("LO02_ROOT",
          file.path(Sys.getenv("USERPROFILE",unset=path.expand("~")),
                    "Downloads","LO02_PRODUCTIE")))
    grid<-lo_grid_from_tasks(selected)
    grid<-lo_grid_mark_archive_candidates(grid,
       audit$evidence$metric_key[
         audit$evidence$source_kind=="LO01_HISTORICAL_CANDIDATES"],
       audit$evidence$metric_key[
         audit$evidence$source_kind=="LO02_RETURN_20261010_CURRENT_RESULTS"])
    # Active below-basic peer estimates are NEW science targets and remain
    # separate from the 3 old HIGH-peer cells per context.
    if(nrow(new_peer_tasks)) {
      peer_grid <- lo_grid_from_tasks(new_peer_tasks)
      peer_grid$status <- "NEW_LOW_PEER_METHOD_GATE_REQUIRED"
      peer_grid$hold_reason <-
         "Requires weighted PV/replicate, peer self-exclusion and source sample certification"
      grid <- rbind(grid,peer_grid)
    }
    # Other SQLite objects exist as unvalidated candidates. They never
    # overwrite estimate, standard error or N in the scientific grid.
    live_keys<-unique(audit$evidence$metric_key[
      grepl("^LIVE_(LO02|CONSOLIDATED|PARQUET)_",audit$evidence$source_kind)])
    is_live<-grid$cell_id%in%live_keys &
      grid$status=="TARGET_NOT_YET_ADJUDICATED"
    grid$status[is_live]<-"LIVE_SQLITE_CANDIDATE_NOT_VALIDATED"
    approved_file<-file.path(root,"master_reconciliation",
                             "SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv")
    if(file.exists(approved_file)) {
      a<-read.csv(approved_file,stringsAsFactors=FALSE,check.names=FALSE)
      # A shared metric_key is insufficient; sample identity must already
      # have been locked in the true target grid.
      filled<-tryCatch(lo_grid_archive_fill(grid,a),error=function(e)e)
      if(inherits(filled,"error"))
        put("archive-fill","HOLD",conditionMessage(filled))
      else grid<-filled
    }
    # Only independent method/source/sample/PV certificates may produce
    # compute instructions; never infer new work merely from an empty cell.
    compute_file <- file.path(root,"master_reconciliation",
                             "SCIENTIFIC_COMPUTE_APPROVALS.csv")
    if(file.exists(compute_file)) {
      approved_compute <- read.csv(compute_file,
           stringsAsFactors=FALSE,check.names=FALSE)
      chosen <- approved_compute[approved_compute$cell_id%in%grid$cell_id,
                                  ,drop=FALSE]
      grid <- lo_grid_apply_compute_approvals(grid,chosen)
    }
    write.csv(grid,file.path(state,"PRIVATE_MASTER_GRID.csv"),
              row.names=FALSE,na="")
    batch<-lo_grid_batch_plan(grid)
    write.csv(batch,file.path(state,"PRIVATE_BATCH_PLAN.csv"),
              row.names=FALSE)
    row<-data.frame(scope=scope,
      selected_countries=length(scope_info$selected),
      original_contracts=nrow(selected),
      new_below_basic_peer_targets=nrow(new_peer_tasks),
      total_primitive_targets=nrow(grid),
      archive_candidates=sum(grepl("CANDIDATE",grid$status)),
      validated=sum(grid$status=="SCIENTIFICALLY_VALIDATED"),
      approved_compute_batches=nrow(batch),
      scientific_status="NOT_RELEASED",stringsAsFactors=FALSE)
    write.csv(row,file.path(state,"GRID_AUDIT_SUMMARY.csv"),row.names=FALSE)
    put("audit","COMPLETED_WITH_SCIENCE_GATES",paste0(nrow(grid),
        " target rows; ",row$archive_candidates," candidates, ",
        row$validated," validated; ",nrow(batch)," approved batches"))
    if(stage=="audit")return(invisible(row))
  }
  if(stage=="produce") {
    # Stage 2 is a deliberate production action; not run during audit/final.
    # The saved grid is the authoritative minimal worklist for stage 2.
    # A missing/invalid grid is a HOLD, not permission to run all PISA tasks.
    saved <- file.path(state,"PRIVATE_MASTER_GRID.csv")
    if(!file.exists(saved))
      stop("FIXED_PRODUCE_HOLD: stage-1 grid missing")
    grid <- read.csv(saved,stringsAsFactors=FALSE,check.names=FALSE,
                     na.strings=character())
    if(anyDuplicated(grid$cell_id))
      stop("FIXED_PRODUCE_HOLD: duplicate grid cell ID")
    result<-lo_fixed_produce(bundle,scope_info,selected,state,
                            native_run=TRUE,grid=grid)
    put("produce",as.character(result$native_execution[[1]]),
        "Exact-cell dispatch is held until a certified scoped adapter is implemented")
    return(invisible(result))
  }
  # Finalize ALWAYS constructs a private copy of the ACTIVE 42-system
  # guided dashboard (with truthful missing-data placeholders), even if the
  # independent scientific freeze has not passed yet.
  approval <- file.path(root,"master_reconciliation",
                        "SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv")
  source(file.path(repo,"06_pipeline","LO_FINAL_GUIDED_EXPORT.R"),
         local=environment(),encoding="UTF-8")
  a <- if(file.exists(approval))read.csv(approval,
                 stringsAsFactors=FALSE,check.names=FALSE) else data.frame()
  dashboard_tasks <- selected[selected$country%in%scope_info$dashboard,
                              ,drop=FALSE]
  dashboard_tasks <- rbind(dashboard_tasks,
    new_peer_tasks[new_peer_tasks$country%in%scope_info$dashboard,,drop=FALSE])
  guided_approved <- if(nrow(a) && "cell_id"%in%names(a))
    a[a$cell_id%in%dashboard_tasks$metric_key,,drop=FALSE] else data.frame()
  map <- tryCatch(lo_guided_grid_export(bundle,dashboard_tasks,
                             guided_approved,state),error=function(e)e)
  if(inherits(map,"error")) {
    put("guided-mapping","HOLD",conditionMessage(map))
  } else {
    validated_export <- file.path(state,"PRIVATE_GUIDED_VALIDATED_ROWS.csv")
    if(!requireNamespace("digest",quietly=TRUE))
      stop("FIXED_PIPELINE_HOLD: digest missing for immutable preview")
    build_hash <- substr(digest::digest(file=validated_export,algo="sha256"),
                         1L,18L)
    candidate <- file.path(state,paste0("DASHBOARD_GUIDED_REVIEW_",build_hash))
    preview_state <- if(dir.exists(candidate)) {
      if(file.exists(file.path(candidate,"BUILD_SHA256_MANIFEST.json")))
        "REUSED_IMMUTABLE_PRIVATE_CANDIDATE"
      else "HOLD_PARTIAL_IMMUTABLE_CANDIDATE"
    } else {
      py <- Sys.getenv("LO_PYTHON","python")
      builder <- file.path(repo,"06_pipeline",
                           "LO_FINAL_GUIDED_DASHBOARD_BUILD.py")
      args <- c(builder,"--repo",repo,"--bundle",bundle,
        "--validated-grid",validated_export,"--output",candidate)
      x <- tryCatch(suppressWarnings(system2(py,shQuote(args),
              stdout=TRUE,stderr=TRUE)),error=function(e)e)
      if(inherits(x,"error"))paste0("HOLD_PYTHON:",conditionMessage(x))
      else {
        status <- attr(x,"status")
        if(!is.null(status) && status!=0L)
          paste0("HOLD_BUILDER:",paste(tail(x,3L),collapse=" | "))
        else "PRIVATE_GUIDED_CANDIDATE_BUILT"
      }
    }
    write.csv(data.frame(scope=scope,rendered_source_rows=map$guided_focus_rows,
       unmapped_validated_source_rows=map$mapping_holds,
       preview_id=if(startsWith(preview_state,"HOLD"))"" else build_hash,
       preview_status=preview_state,
       public_release="NOT_AUTHORIZED"),
       file.path(state,"GUIDED_PREVIEW_SUMMARY.csv"),row.names=FALSE)
    put("guided-preview",preview_state,
        paste0(map$guided_focus_rows," mapped, ",map$mapping_holds,
               " held; public September site unchanged"))
  }
  # No count-based scientific release. Independent paper, covariance,
  # data-edition and peer denominator gates remain authoritative.
  q <- tryCatch(lo_final_quality_gate(bundle,selected,approval,state),
                error=function(e)e)
  if(inherits(q,"error")) {
    put("finalize","HOLD_SCIENTIFIC_GATE_ERROR",conditionMessage(q))
    return(invisible(q))
  }
  if(!identical(q$scientific_freeze[[1]],
                "ELIGIBLE_FOR_INDEPENDENT_REVIEW")) {
    put("finalize","HOLD_SCIENTIFIC_GATES",
        paste0(q$active_missing," active grid gaps; Q01-Q08 ",
               q$paper_gates_pass,"/8; primary peers ",
               q$primary_peer_gate))
    return(invisible(q))
  }
  if(scope!="all_required") {
    put("finalize","SCOPE_SCIENCE_REVIEW_ELIGIBLE",
        "A public 42-system dashboard needs all_required research coverage")
    return(invisible(q))
  }
  # Immutable candidate must be independently reviewed with an explicit
  # SHA-pinned scientific/rights/replication/21-slide certificate.
  certificate <- file.path(state,"PUBLIC_RELEASE_CERTIFICATION.json")
  if(!file.exists(certificate) || inherits(map,"error") ||
     !exists("candidate") || !dir.exists(candidate)) {
    put("finalize","HOLD_RELEASE_CERTIFICATE_OR_GUIDED_CANDIDATE",
        "Missing independent SHA-pinned release evidence")
    return(invisible(q))
  }
  script <- file.path(repo,"06_pipeline","LO_FINAL_GUIDED_PUBLIC_RELEASE.py")
  args <- c(script,"--repo",repo,"--candidate",candidate,
            "--certificate",certificate)
  py <- Sys.getenv("LO_PYTHON","python")
  x <- tryCatch(suppressWarnings(system2(py,shQuote(args),
              stdout=TRUE,stderr=TRUE)),error=function(e)e)
  if(inherits(x,"error")) {
    put("finalize","HOLD_GUIDED_RELEASE_SCRIPT",conditionMessage(x))
  } else {
    status <- attr(x,"status")
    if(!is.null(status) && status!=0L)
      put("finalize","HOLD_GUIDED_RIGHTS_OR_QA",
           paste(tail(x,4L),collapse=" | "))
    else put("finalize","GUIDED_RELEASE_STAGED_NOT_DEPLOYED",
         "Immutable SHA-pinned candidate staged for human review")
  }
  invisible(q)
}

