# Learning Outcomes: one versioned entry point for storage and R production.
# Historical scientific lock (28 September 2026) is NOT overwritten.
# For Windows: set LO_REPO_ROOT, LO05_BUNDLE, LO_STORAGE_CONFIG and source this file.
# CLI: Rscript 06_pipeline/RUN.R --action=plan --scope=nld_plus_19
# Actions: plan, execute, replicate, inventory, migrate, maintain, status
# No action by default may delete source data or change the public release.

lo_pipeline_root <- function() {
  e <- Sys.getenv("LO_REPO_ROOT", unset="")
  if (nzchar(e)) return(normalizePath(e, winslash="/", mustWork=TRUE))
  a <- grep("^--file=", commandArgs(FALSE), value=TRUE)
  f <- if (length(a)) sub("^--file=", "", a[[1]]) else ""
  if (!nzchar(f)) {
    fs <- sys.frames()
    for (i in rev(seq_along(fs))) {
      if (!is.null(fs[[i]]$ofile)) { f <- fs[[i]]$ofile; break }
    }
  }
  if (!nzchar(f)) stop("Set LO_REPO_ROOT to the cloned Git repository", call.=FALSE)
  normalizePath(file.path(dirname(f), ".."), winslash="/", mustWork=TRUE)
}

lo_pipeline_arg <- function(name, default="") {
  a <- commandArgs(trailingOnly=TRUE)
  pat <- paste0("^--",name,"=")
  found <- grep(pat,a,value=TRUE)
  if (!length(found)) return(default)
  sub(pat,"",found[[length(found)]])
}

lo_pipeline_storage <- function(repo, action, config) {
  if (!nzchar(config) || !file.exists(config))
    stop("Set LO_STORAGE_CONFIG to a local JSON file (never commit its paths)", call.=FALSE)
  py <- Sys.getenv("LO_PYTHON", unset="python")
  cmd <- file.path(repo,"06_pipeline","storage_manager.py")
  arguments <- c(cmd, action, "--config", config)
  out <- suppressWarnings(system2(py, shQuote(arguments), stdout=TRUE, stderr=TRUE))
  code <- attr(out,"status")
  cat(paste(out,collapse="\n"),"\n")
  if (!is.null(code) && code != 0L)
    stop("Storage operation failed; production/cleanup stopped",call.=FALSE)
  invisible(out)
}

# One-time local setup; never stores OAuth tokens in Git or this config.
lo_pipeline_drive_config_path <- function() {
  override <- Sys.getenv("LO_DRIVE_SYNC_CONFIG","")
  if (nzchar(override)) return(override)
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  candidates <- unique(c(
    file.path(home,"Downloads","LO05_RESULTATEN",
              ".cloud_sync","drive.local.json"),
    file.path(home,"Documents","Downloads","LO05_RESULTATEN",
              ".cloud_sync","drive.local.json"),
    file.path(path.expand("~"),"Downloads","LO05_RESULTATEN",
              ".cloud_sync","drive.local.json")))
  existing <- candidates[vapply(candidates,function(p)
    isTRUE(file.exists(as.character(p)[1L])),logical(1L))]
  if(length(existing))return(existing[[1L]])
  candidates[[1L]]
}

lo_pipeline_find_rclone <- function() {
  explicit <- Sys.getenv("LO_RCLONE_EXE","")
  if (nzchar(explicit)) {
    if (!file.exists(explicit))
      stop("LO_RCLONE_EXE points to missing file: ",explicit)
    return(normalizePath(explicit,winslash="/",mustWork=TRUE))
  }
  cfgpath <- lo_pipeline_drive_config_path()
  if(file.exists(cfgpath) && requireNamespace("jsonlite",quietly=TRUE)) {
    stored <- tryCatch(jsonlite::fromJSON(cfgpath),error=function(e)NULL)
    if(!is.null(stored) && is.character(stored$rclone_binary) &&
       length(stored$rclone_binary)==1L &&
       isTRUE(file.exists(stored$rclone_binary)))
      return(normalizePath(stored$rclone_binary,
                           winslash="/",mustWork=TRUE))
  }
  existing <- Sys.which("rclone")
  if (nzchar(existing)) return(unname(existing))
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  base <- file.path(home,"Downloads")
  if (!dir.exists(base)) stop("Downloads folder not found")
  dirs <- list.dirs(base,recursive=FALSE,full.names=TRUE)
  dirs <- dirs[grepl("^rclone-v",basename(dirs),ignore.case=TRUE)]
  candidates <- unlist(lapply(dirs,function(d) {
    c(file.path(d,"rclone.exe"),
      file.path(list.dirs(d,recursive=FALSE,full.names=TRUE),"rclone.exe"))
  }),use.names=FALSE)
  candidates <- as.character(unlist(candidates,use.names=FALSE))
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  candidates <- candidates[vapply(candidates,function(p)
    isTRUE(file.exists(as.character(p)[1L])),logical(1L))]
  if (!length(candidates))
    stop("rclone.exe not found in Downloads or PATH")
  normalizePath(candidates[[1]],winslash="/",mustWork=TRUE)
}

lo_pipeline_setup_drive <- function() {
  home <- path.expand("~")
  roots <- unique(c(file.path(home,"Downloads"),
                    file.path(Sys.getenv("USERPROFILE",home),"Downloads"),
                    file.path(home,"OneDrive","Downloads"),
                    file.path(home,"OneDrive","Documents"),
                    file.path(home,"Documents")))
  preferred <- Sys.getenv("LO_LOCAL_RESULTS_ROOT","")
  candidates <- if (nzchar(preferred)) preferred else character()
  candidates <- c(candidates,file.path(roots,"LO05_RESULTATEN"))
  # A missing results folder is not an error for a first-time cloud setup.
  # Only create an empty output root; never overwrite historical results.
  # Check paths one at a time: some Windows R installations reject
  # a vector in the underlying file.exists() implementation.
  candidates <- as.character(unlist(candidates,use.names=FALSE))
  candidates <- unique(candidates[!is.na(candidates) & nzchar(candidates)])
  existing <- candidates[vapply(candidates,function(p) {
    isTRUE(dir.exists(as.character(p)[1L]))
  },logical(1L))]
  if (length(existing)) {
    base <- normalizePath(existing[[1]],winslash="/",mustWork=TRUE)
  } else if (nzchar(preferred)) {
    base <- normalizePath(preferred,winslash="/",mustWork=FALSE)
    dir.create(base,recursive=TRUE,showWarnings=FALSE)
  } else {
    base <- file.path(roots[[1]],"LO05_RESULTATEN")
    dir.create(base,recursive=TRUE,showWarnings=FALSE)
  }
  if (!dir.exists(base)) stop("Cannot create or access local results root: ",base)
  rc <- lo_pipeline_find_rclone()
  remotes <- suppressWarnings(system2(rc,"listremotes",stdout=TRUE,stderr=TRUE))
  code <- attr(remotes,"status")
  if ((!is.null(code) && code!=0L) || !("lo_private:" %in% trimws(remotes)))
    stop("rclone remote lo_private: is not configured")
  target <- "lo_private:Learning-Outcomes-Private"
  check <- suppressWarnings(system2(rc,c("lsd",shQuote(target)),
                                    stdout=TRUE,stderr=TRUE))
  code <- attr(check,"status")
  if (!is.null(code) && code!=0L)
    stop("Cannot access existing private Drive folder; nothing changed")
  cfg <- lo_pipeline_drive_config_path()
  dir.create(dirname(cfg),recursive=TRUE,showWarnings=FALSE)
  if (file.exists(cfg))
    stop("Drive config already exists; refusing to overwrite: ",cfg)
  js <- function(x) encodeString(x,quote='"')
  lines <- c("{",
    paste0('  "local_results_root": ',js(normalizePath(base,winslash="/")),","),
    paste0('  "remote": ',js(target),","),
    '  "data_visibility": "PRIVATE_ACCOUNT_ONLY",',
    paste0('  "rclone_binary": ',js(normalizePath(rc,winslash="/")),","),
    '  "min_age_seconds": 120,',
    '  "max_file_bytes": 2147483648,',
    '  "max_transfers": 2,',
    '  "watch_interval_seconds": 180',
    "}")
  writeLines(lines,cfg,useBytes=TRUE)
  Sys.setenv(LO_DRIVE_SYNC_CONFIG=cfg)
  cat("Drive sync configured. Local config: ",cfg,
      "\nNo results uploaded or deleted.\n",
      "Next: Rscript 06_pipeline/RUN.R --action=publish\n",sep="")
  invisible(cfg)
}

lo_pipeline_drive_publish <- function(repo,action="publish") {
  config <- lo_pipeline_drive_config_path()
  if (!file.exists(config)) {
    message("Drive sync not configured; no upload attempted.")
    return(invisible(FALSE))
  }
  source(file.path(repo,"06_pipeline","DRIVE_SYNC.R"),local=environment(),
         encoding="UTF-8")
  rc <- lo_pipeline_find_rclone()
  lo_drive_sync(config,action=action,rclone_override=rc,
                producer_commit=lo_pipeline_git_info(repo))
  invisible(TRUE)
}

lo_pipeline_git_info <- function(repo) {
  git <- Sys.which("git")
  if (!nzchar(git)) return("git_not_available")
  out <- suppressWarnings(system2(git,c("-C",shQuote(repo),"rev-parse","HEAD"),
                                  stdout=TRUE,stderr=FALSE))
  exitcode <- attr(out,"status")
  if (length(out) != 1L || (!is.null(exitcode) && exitcode != 0L))
    return("git_commit_unavailable")
  out
}

lo_pipeline_validate_reference <- function(repo,bundle) {
  ref <- read.csv(file.path(repo,"06_pipeline","reference_oecd19_2024.csv"),
                  stringsAsFactors=FALSE)
  if (nrow(ref)!=19L || anyDuplicated(ref$country) ||
      "NLD"%in%ref$country ||
      !identical(unique(ref$reference_id),"OECD_PPP_GT_CZE_2024_RECONSTRUCTED"))
    stop("Versioned 19-country reference is invalid")
  legacy <- file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv")
  if (!file.exists(legacy)) stop("Local bundle reference registry missing")
  old <- read.csv(legacy,stringsAsFactors=FALSE)
  if (!all(c("country","strictly_above_czechia")%in%names(old)))
    stop("Local reference registry schema mismatch")
  foreign <- old$country[toupper(as.character(old$strictly_above_czechia)) %in%
                      c("TRUE","T","1") & old$country!="NLD"]
  if (!setequal(foreign,ref$country) || length(unique(foreign))!=19L)
    stop("Local legacy engine and versioned Git reference differ; production held")
  invisible(ref)
}

lo_pipeline_vendor_source <- function(repo,bundle,push=FALSE) {
  # Exact historical SHA256 is preserved in the manifest. Public text copies
  # are sanitised only for a user-specific absolute-path fallback; never
  # claim numerical science equivalence without a cold-source comparison.
  source(file.path(repo,"06_pipeline","BUNDLE_DISCOVERY.R"),
         local=environment(),encoding="UTF-8")
  lo_bundle_verify(bundle)
  paths <- c("LEARNING_OUTCOMES_RUN.R","PROJECT_CONFIG.R",
    file.path("code",c("INTEGRATED.R","LO04_COMMON.R","LO04_HISTORY.R",
      "LO04_CACHE.R","LO04_ADAPTERS.R","LO04_EXECUTION.R",
      "LO04_EXTENDED_EXECUTION.R","LO04_WINDOWS_TESTS.R",
      "LO04_SCIENCE_SMOKE.R","LO04_GC.R","LO05_CONSOLIDATION.R",
      "LO05_LIFECYCLE.R")),
    file.path("engine",c("BACKEND.R","V11.R","REPAIRS.R",
      "EXTENSIONS.R","production.R","engine.R","store.R","tests.R",
      "WORKER.R","app.R")))
  destroot <- file.path(repo,"06_pipeline","archive_or_superseded",
                       "LO05_CODE_LOCK_20261010")
  dir.create(destroot,recursive=TRUE,showWarnings=FALSE)
  if(!requireNamespace("digest",quietly=TRUE)) stop("digest package required")
  record <- list()
  for(relative in paths) {
    src<-file.path(bundle,relative)
    if(!file.exists(src))stop("Producer source absent: ",relative)
    original<-unname(digest::digest(file=src,algo="sha256"))
    lines<-readLines(src,warn=FALSE,encoding="UTF-8")
    safe<-gsub(paste0("C:","/Users/","[A-Za-z0-9_.-]+/Downloads"),
               "~/Downloads",lines,perl=TRUE)
    san <- !identical(lines,safe)
    if(any(grepl("[A-Za-z]:[/\\\\]Users[/\\\\]",safe)))
      stop("Unexpected private Windows path remains: ",relative)
    dst<-file.path(destroot,relative)
    dir.create(dirname(dst),recursive=TRUE,showWarnings=FALSE)
    if(!san) {
      # Preserve exact original CRLF/newline bytes when no privacy edit is needed.
      sanitized<-original
      if(file.exists(dst)) {
        if(!identical(unname(digest::digest(file=dst,algo="sha256")),
                     original))
          stop("Unchanged archived source differs: ",relative)
      } else if(!file.copy(src,dst,overwrite=FALSE))
        stop("Could not retain byte-identical code: ",relative)
    } else {
      tmp<-tempfile(tmpdir=dirname(dst))
      writeLines(safe,tmp,useBytes=TRUE)
      sanitized<-unname(digest::digest(file=tmp,algo="sha256"))
      if(file.exists(dst)) {
        if(!identical(unname(digest::digest(file=dst,algo="sha256")),
                      sanitized))
          stop("Refusing to overwrite privacy-sanitized code: ",relative)
        unlink(tmp)
      } else if(!file.rename(tmp,dst))
        stop("Cannot save privacy-sanitized code: ",relative)
    }
    record[[length(record)+1L]]<-data.frame(relative_path=relative,
      original_sha256=original,git_copy_sha256=sanitized,
      path_sanitized=if(san)"YES_REVIEW_EQUIVALENCE" else "NO",
      original_bytes=file.info(src)$size,stringsAsFactors=FALSE)
  }
  data <- do.call(rbind,record)
  manifest <- file.path(destroot,"SOURCE_CODE_ORIGINAL_VS_PUBLIC_SHA256.csv")
  if(file.exists(manifest)) {
    old<-read.csv(manifest,colClasses="character",stringsAsFactors=FALSE)
    if(!identical(as.character(old$original_sha256),data$original_sha256))
      stop("Existing Git producer manifest differs from pinned code")
  } else write.csv(data,manifest,row.names=FALSE,na="")
  message("Archived ",nrow(data)," verified R producer files; no source data or results copied.")
  if(push) {
    git<-Sys.which("git")
    if(!nzchar(git))stop("Git for Windows unavailable")
    run<-function(args) {
      out<-suppressWarnings(system2(git,shQuote(args),
                                      stdout=TRUE,stderr=TRUE))
      status<-attr(out,"status");if(is.null(status))status<-0L
      if(status!=0L)stop("Git code-history operation failed: ",
         paste(tail(out,5),collapse="\n"))
      out
    }
    wanted<-"feat/reproducible-storage-and-cleanup-20261010"
    current<-run(c("-C",repo,"branch","--show-current"))
    if(length(current)!=1L||current[[1]]!=wanted)
      stop("Refusing code push on a different Git branch")
    subdir<-"06_pipeline/archive_or_superseded/LO05_CODE_LOCK_20261010"
    run(c("-C",repo,"add","--",subdir))
    changed<-run(c("-C",repo,"diff","--cached","--name-only","--",subdir))
    if(length(changed)) {
      run(c("-C",repo,"-c","user.name=Learning Outcomes Source Archivist",
            "-c","user.email=learning-outcomes-runner@users.noreply.github.com",
            "commit","-m","Archive reviewed October scientific producer code"))
    }
    run(c("-C",repo,"push","origin",paste0("HEAD:refs/heads/",wanted)))
    message("Historical producer files pushed safely to GitHub feature branch.")
  }
  invisible(data)
}

lo_pipeline_science_bundle <- function(repo) {
  source(file.path(repo,"06_pipeline","BUNDLE_DISCOVERY.R"),
         local=environment(),encoding="UTF-8")
  path <- lo_bundle_discover()
  Sys.setenv(LO05_BUNDLE=path)
  path
}
lo_pipeline_product_contract <- function(repo,bundle) {
  source(file.path(repo,"06_pipeline","PRODUCT_SCOPE_GATE.R"),
         local=environment(),encoding="UTF-8")
  root <- file.path(Sys.getenv("USERPROFILE",unset=path.expand("~")),
                    "Downloads","LO05_RESULTATEN","runs")
  lo_product_gate(bundle,output_root=root,
    product_register=file.path(repo,"06_pipeline","BR_POLICY_DECK_21_SOURCE_REGISTER_20261010.csv"))
}

lo_pipeline_main <- function() {
  repo <- lo_pipeline_root()
  action <- tolower(lo_pipeline_arg("action", Sys.getenv("LO_ACTION","plan")))
  scope <- tolower(lo_pipeline_arg("scope",Sys.getenv("LO_SCOPE","nld_plus_19")))
  scopes <- c(nld_only="NLD_ONLY",nld_plus_19="NLD_PLUS_OECD_PPP",
              reference_19="OECD_PPP_ONLY",other="OTHER_INTERNATIONAL",
              all="FULL_INTERNATIONAL")
  if (!scope %in% names(scopes)) stop("Unknown scope: ",scope)
  actions <- c("plan","execute","replicate","vendor","vendor-push","check-contract","reference-audit","storage-audit","storage-plan","storage-dedupe","storage-migrate","storage-retirement-plan","storage-cleanup-apply","inventory","migrate","maintain","status","publish","watch","setup-drive","status-publish","provenance-audit","audit-batch","reconcile-and-plan","cleanup-stage","cleanup-restore","cleanup-finalize","next-batch","reuse-preflight","test-only")
  if (!action %in% actions) stop("Unknown action: ",action)

  stamp <- format(Sys.time(),"%Y%m%d_%H%M%S")
  output <- Sys.getenv("LO_RUN_OUTPUT", file.path(Sys.getenv("USERPROFILE",unset=path.expand("~")),"Downloads","LO05_RESULTATEN","runner_logs"))
  run <- file.path(output,paste0("run_",stamp))
  dir.create(run, recursive=TRUE, showWarnings=FALSE)
  writeLines(c(paste0("git_commit=",lo_pipeline_git_info(repo)),
               paste0("action=",action),paste0("scope=",scope),
               paste0("timestamp=",as.character(Sys.time())),
               capture.output(sessionInfo())),
             file.path(run,"RUN_PROVENANCE.txt"))
  cat("Git-gebonden runner; log: ",run,"\n",sep="")
  config <- Sys.getenv("LO_STORAGE_CONFIG","")
  if (action=="status-publish") {
    lo_pipeline_publish_status(repo,action,scope,"OBSERVED")
    return(invisible(run))
  }
  run_finished <- FALSE
  if(action %in% c("plan","execute","replicate","test-only")) {
    on.exit({
      tryCatch(lo_pipeline_publish_status(repo,action,scope,
        if(run_finished) "RUNNER_COMPLETED" else "FAILED_OR_INTERRUPTED"),
        error=function(e) warning("GitHub status not updated; safe local pending manifest retained. ",
                                  conditionMessage(e),call.=FALSE))
    },add=TRUE)
  }
  if (action %in% c("inventory","migrate","status")) {
    lo_pipeline_storage(repo,action,config)
    return(invisible(run))
  }
  if(action %in% c("storage-audit","storage-plan","storage-migrate",
                   "storage-retirement-plan","storage-cleanup-apply")) {
    source(file.path(repo,"06_pipeline","MASTER_STORAGE.R"),
           local=environment(),encoding="UTF-8")
    answer <- lo_master_action(action)
    tryCatch(lo_pipeline_publish_status(repo,action,scope,"OBSERVED"),
      error=function(e)warning("Public status held; private audit intact: ",
                               conditionMessage(e),call.=FALSE))
    return(invisible(answer))
  }
  if(action %in% c("cleanup-stage","cleanup-restore","cleanup-finalize")) {
    Sys.setenv(LO_QUARANTINE_ACTION=switch(action,
      "cleanup-stage"="stage","cleanup-restore"="restore",
      "cleanup-finalize"="finalize"))
    source(file.path(repo,"06_pipeline","LOCAL_QUARANTINE.R"),
           local=environment(),encoding="UTF-8")
    return(invisible(run))
  }
  if(action=="next-batch") {
    # Single durable batched pass. Independent steps report a specific failure.
    # No scientific production and no deletion/quarantine mutation here.
    steps <- list()
    step <- function(name,expr) {
      started <- Sys.time()
      error <- ""
      tryCatch(force(expr),error=function(e) {
        error <<- conditionMessage(e)
        message("NEXT_BATCH_STEP_HELD [",name,"]: ",error)
      })
      steps[[length(steps)+1L]] <<- data.frame(
        step=name,status=if(nzchar(error))"HOLD" else "PASS",
        elapsed_seconds=round(as.numeric(difftime(Sys.time(),started,units="secs")),2),
        reason=error,stringsAsFactors=FALSE)
      invisible(!nzchar(error))
    }
    step("scientific_product_contract",{
      bundle <- lo_pipeline_science_bundle(repo)
      lo_pipeline_product_contract(repo,bundle)
    })
    step("existing_provenance_inventory",source(
      file.path(repo,"06_pipeline","PROVENANCE_AUDIT.R"),
      local=environment(),encoding="UTF-8"))
    step("canonical_result_identity",source(
      file.path(repo,"06_pipeline","CANONICAL_RESULT_RECONCILIATION.R"),
      local=environment(),encoding="UTF-8"))
    step("contract_level_reuse_queue",{
      bundle <- lo_pipeline_science_bundle(repo)
      source(file.path(repo,"06_pipeline","CONTRACT_REUSE_QUEUE.R"),
             local=environment(),encoding="UTF-8")
      lo_contract_reuse_queue(bundle)
    })
    source(file.path(repo,"06_pipeline","MASTER_STORAGE.R"),
           local=environment(),encoding="UTF-8")
    cfg <- lo_master_init()
    step("retirement_review",lo_master_gc_plan(cfg))
    step("bounded_duplicate_sha",lo_master_duplicate_audit(cfg))
    step("local_cleanup_approval_queue",source(
      file.path(repo,"06_pipeline","LOCAL_CLEANUP_GATE.R"),
      local=environment(),encoding="UTF-8"))
    step("private_drive_report_archive",lo_master_share_reports(cfg))
    statuses <- do.call(rbind,steps)
    write.csv(statuses,file.path(run,"NEXT_BATCH_STEPS.csv"),row.names=FALSE)
    cat("NEXT_BATCH_DONE: ",sum(statuses$status=="PASS")," PASS; ",
        sum(statuses$status=="HOLD")," HOLD. Detailed status: ",
        file.path(run,"NEXT_BATCH_STEPS.csv"),"\n",sep="")
    cat("No pupil calculations, no local moves or deletions.\n")
    return(invisible(run))
  }
  if(action=="reconcile-and-plan") {
    source(file.path(repo,"06_pipeline","PROVENANCE_AUDIT.R"),
           local=environment(),encoding="UTF-8")
    source(file.path(repo,"06_pipeline","RECONCILE_AND_PLAN.R"),
           local=environment(),encoding="UTF-8")
    source(file.path(repo,"06_pipeline","RESULT_LINEAGE_RECORDS.R"),
           local=environment(),encoding="UTF-8")
    source(file.path(repo,"06_pipeline","CANONICAL_RESULT_RECONCILIATION.R"),
           local=environment(),encoding="UTF-8")
    # One batched conservative retirement proposal; no deletion.
    source(file.path(repo,"06_pipeline","MASTER_STORAGE.R"),
           local=environment(),encoding="UTF-8")
    lo_master_gc_plan(lo_master_init())
    source(file.path(repo,"06_pipeline","LOCAL_CLEANUP_GATE.R"),
           local=environment(),encoding="UTF-8")
    cat("KEEP/ARCHIVE/DELETE review staged: zero deletions authorized.\n")
    return(invisible(run))
  }
  if(action=="audit-batch") {
    # One invocation, reuse existing inventory and report results.
    source(file.path(repo,"06_pipeline","PROVENANCE_AUDIT.R"),
           local=environment(),encoding="UTF-8")
    source(file.path(repo,"06_pipeline","MASTER_STORAGE.R"),
           local=environment(),encoding="UTF-8")
    cfg <- lo_master_init()
    quota <- file.path(cfg$state,"CLOUD_QUOTA_AND_MIGRATION_LIMIT.csv")
    cat("Audit batch complete; quota report available:",file.exists(quota),"\n")
    cat("Scientific release unchanged; no microdata calculations or deletion.\n")
    return(invisible(run))
  }
  if(action=="provenance-audit") {
    source(file.path(repo,"06_pipeline","PROVENANCE_AUDIT.R"),
           local=environment(),encoding="UTF-8")
    return(invisible(run))
  }
  if(action=="setup-drive") {
    lo_pipeline_setup_drive()
    return(invisible(run))
  }
  if(action%in%c("publish","watch")) {
    if(action=="publish") {
      # One user command for BOTH publication routes; Git status still updates
      # if optional Drive is unavailable.
      tryCatch(lo_pipeline_drive_publish(repo,"publish"),
        error=function(e) warning("Private Drive sync held: ",conditionMessage(e),
                                   call.=FALSE))
      tryCatch(lo_pipeline_publish_status(repo,action,scope,"OBSERVED"),
        error=function(e) warning("GitHub status held: ",conditionMessage(e),
                                   call.=FALSE))
    } else lo_pipeline_drive_publish(repo,action)
    return(invisible(run))
  }
  if (action=="maintain") {
    # This is an opt-in housekeeping action, not a side effect of any calculation.
    lo_pipeline_storage(repo,"migrate",config)
    lo_pipeline_storage(repo,"verify-backup",config)
    lo_pipeline_storage(repo,"cleanup-plan",config)
    # Apply is allowed ONLY if the local storage config enables it AND all
    # scientific/product dependency and independent-backup gates have passed.
    if (identical(Sys.getenv("LO_APPLY_VERIFIED_CLEANUP"),"YES"))
      lo_pipeline_storage(repo,"cleanup-apply",config)
    return(invisible(run))
  }
  if (action%in%c("vendor","vendor-push")) {
    bundle <- lo_pipeline_science_bundle(repo)
    lo_pipeline_vendor_source(repo,bundle,push=action=="vendor-push")
    return(invisible(run))
  }
  if (action=="check-contract") {
    bundle <- lo_pipeline_science_bundle(repo)
    lo_pipeline_product_contract(repo,bundle)
    return(invisible(run))
  }
  if (action=="reference-audit") {
    bundle <- lo_pipeline_science_bundle(repo)
    source(file.path(repo,"06_pipeline","REFERENCE_SOURCE_AUDIT.R"),
           local=environment(),encoding="UTF-8")
    root <- file.path(Sys.getenv("USERPROFILE",unset=path.expand("~")),
                      "Downloads","LO05_RESULTATEN")
    lo_wdi_2024_reference_audit(bundle,root)
    return(invisible(run))
  }
  if (action=="replicate") {
    if (!identical(Sys.getenv("LO_ALLOW_FULL_REPLICATION"),"YES"))
      stop("Full source re-estimation requires LO_ALLOW_FULL_REPLICATION=YES")
    canonical <- file.path(repo,"02_analysis","current",
                           "EXECUTED_COMPLETION_SCRIPT_SANITISED.R")
    if (!file.exists(canonical)) stop("Pinned source missing")
    message("Clean reproduction of the 28 September 2026 scientific lock. ",
            "Use provider-obtained source files and separately validate outputs.")
    source(canonical,local=new.env(parent=.GlobalEnv),encoding="UTF-8")
    run_finished <- TRUE
    return(invisible(run))
  }
  if(action=="reuse-preflight") {
    bundle <- lo_pipeline_science_bundle(repo)
    source(file.path(repo,"06_pipeline","REUSE_PREFLIGHT.R"),
           local=environment(),encoding="UTF-8")
    lo_reuse_preflight(bundle,scope)
    return(invisible(run))
  }
  # One verified source only: no mixing modules from different October ZIPs.
  bundle <- lo_pipeline_science_bundle(repo)
  lo_pipeline_validate_reference(repo,bundle)
  lo_pipeline_product_contract(repo,bundle)
  if(action=="execute") {
    source(file.path(repo,"06_pipeline","REUSE_PREFLIGHT.R"),
           local=environment(),encoding="UTF-8")
    lo_reuse_preflight(bundle,scope,enforce=TRUE)
  }
  core <- file.path(bundle,"code","INTEGRATED.R")
  if (!file.exists(core)) stop("Historical integration module missing: ",core)
  if (nzchar(config)) lo_pipeline_storage(repo,"status",config)
  options(learning_outcomes.mode=unname(scopes[[scope]]),
          learning_outcomes.action=if (action=="plan")"plan_only" else if(action=="test-only")"test_only" else "production",
          learning_outcomes.gc_policy="report_only")
  # Increments rely on current local LO05 bundle; scientific gate failures are
  # reported, not promoted. Do not alter the historical scientific release.
  source(core,local=.GlobalEnv,encoding="UTF-8")
  if (!exists("lo_integrated_main",mode="function"))
    stop("Legacy integrated engine cannot be called")
  lo_integrated_main(normalizePath(bundle,winslash="/",mustWork=TRUE))
  if (nzchar(config)) {
    # Record newly created outputs without deleting original caches.
    lo_pipeline_storage(repo,"migrate",config)
    lo_pipeline_storage(repo,"cleanup-plan",config)
  }
  # Cloud publish is a post-production side effect; failure never overwrites
  # scientific results. During long runs a scheduled --action=publish task
  # independently uploads only completed atomic checkpoints.
  if(file.exists(lo_pipeline_drive_config_path())) {
    tryCatch(lo_pipeline_drive_publish(repo,"publish"),
      error=function(e)warning("Cloud sync held after computation: ",conditionMessage(e)))
  }
  run_finished <- TRUE
  invisible(run)
}

if (!isTRUE(getOption("lo.pipeline.functions_only",FALSE)))
  lo_pipeline_main()
