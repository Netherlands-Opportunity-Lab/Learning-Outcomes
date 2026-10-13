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
    # Explicitly no file removal in this stage. Existing lifecycle checks
    # require independent cloud AND additional restore, closure and approval.
    source(file.path(repo,"06_pipeline","LOCAL_CLEANUP_GATE.R"),
           local=environment(),encoding="UTF-8")
    put("cleanup-plan","REVIEW_ONLY_NO_DELETE")
    return(invisible(TRUE))
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
    # Other SQLite objects exist as unvalidated candidates. They never
    # overwrite estimate, standard error or N in the scientific grid.
    live_keys<-unique(audit$evidence$metric_key[
      grepl("^LIVE_LO02_",audit$evidence$source_kind)])
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
    write.csv(grid,file.path(state,"PRIVATE_MASTER_GRID.csv"),
              row.names=FALSE,na="")
    batch<-lo_grid_batch_plan(grid)
    write.csv(batch,file.path(state,"PRIVATE_BATCH_PLAN.csv"),
              row.names=FALSE)
    row<-data.frame(scope=scope,
      selected_countries=length(scope_info$selected),
      original_contracts=nrow(grid),
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
    result<-lo_fixed_produce(bundle,scope_info,selected,state,native_run=TRUE)
    put("produce",as.character(result$native_execution[[1]]),
        "Only exact-fingerprint native PISA core/gender attempted; non-core holds")
    return(invisible(result))
  }
  # Final review is strictly downstream of the grid and approvals; does not
  # invent sample N/SE or publish a default September runtime as new data.
  approval<-file.path(root,"master_reconciliation",
                      "SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv")
  q<-lo_final_quality_gate(bundle,selected,approval,state)
  if(!identical(q$scientific_freeze[[1]],
                "ELIGIBLE_FOR_INDEPENDENT_REVIEW")) {
    put("finalize","HOLD_SCIENTIFIC_GATES",
        paste0(q$active_missing," primitive gaps; Q gates ",
               q$paper_gates_pass,"/8; peers ",q$primary_peer_gate))
    return(invisible(q))
  }
  # Even full scientific validity does not authorize publication without
  # external data rights, reproducibility, slide parity and site QA.
  put("finalize","HOLD_RIGHTS_PRODUCT_AND_DASHBOARD_RELEASE_QA",
      "Next build from validated 42-system data; never silently overwrite site")
  invisible(q)
}
