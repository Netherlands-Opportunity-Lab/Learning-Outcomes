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
  file.path(path.expand("~"),"Downloads","LO05_RESULTATEN",
            ".cloud_sync","drive.local.json")
}

lo_pipeline_find_rclone <- function() {
  existing <- Sys.which("rclone")
  if (nzchar(existing)) return(unname(existing))
  base <- file.path(path.expand("~"),"Downloads")
  if (!dir.exists(base)) stop("Downloads folder not found")
  dirs <- list.dirs(base,recursive=FALSE,full.names=TRUE)
  dirs <- dirs[grepl("^rclone-v",basename(dirs),ignore.case=TRUE)]
  candidates <- unlist(lapply(dirs,function(d) {
    c(file.path(d,"rclone.exe"),
      file.path(list.dirs(d,recursive=FALSE,full.names=TRUE),"rclone.exe"))
  }),use.names=FALSE)
  candidates <- candidates[file.exists(candidates)]
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
  py <- Sys.which("python")
  if (!nzchar(py)) stop("Python 3 not on PATH; required by existing Drive sync module")
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
  Sys.setenv(LO_DRIVE_SYNC_CONFIG=cfg,LO_PYTHON=unname(py))
  cat("Drive sync configured. Local config: ",cfg,
      "\nNo results uploaded or deleted.\n",
      "Next: Rscript 06_pipeline/RUN.R --action=publish\n",sep="")
  invisible(cfg)
}

lo_pipeline_drive_publish <- function(repo,action="publish") {
  config<-lo_pipeline_drive_config_path()
  if(!nzchar(config)) {
    message("Google Drive cloud sync not configured: set LO_DRIVE_SYNC_CONFIG. ",
            "No results uploaded; existing local results remain intact.")
    return(invisible(FALSE))
  }
  if(!file.exists(config)) stop("LO_DRIVE_SYNC_CONFIG points to missing file")
  binary<-Sys.getenv("LO_PYTHON","")
  if (!nzchar(binary)) binary<-unname(Sys.which("python"))
  if (!nzchar(binary)) stop("Python 3 not available on PATH")
  script<-file.path(repo,"06_pipeline","drive_sync.py")
  gitsha<-lo_pipeline_git_info(repo)
  old<-Sys.getenv("LO_PRODUCER_GIT_COMMIT",unset=NA_character_)
  on.exit(if(is.na(old)) Sys.unsetenv("LO_PRODUCER_GIT_COMMIT")
          else Sys.setenv(LO_PRODUCER_GIT_COMMIT=old),add=TRUE)
  Sys.setenv(LO_PRODUCER_GIT_COMMIT=gitsha)
  output<-suppressWarnings(system2(binary,
     shQuote(c(script,action,"--config",config)),stdout=TRUE,stderr=TRUE))
  code<-attr(output,"status")
  cat(paste(output,collapse="\n"),"\n")
  if(!is.null(code) && code!=0L)
    stop("Cloud sync FAILED; scientific run outputs remain local and unchanged")
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

lo_pipeline_vendor_source <- function(repo,bundle) {
  # Prepare historical October producer CODE only, never raw/derived data.
  # The caller reviews and commits these files on the feature branch.
  scripts <- c(
    paste0("code/",c("INTEGRATED.R","LO04_COMMON.R","LO04_CACHE.R",
      "LO04_HISTORY.R","LO04_ADAPTERS.R","LO04_EXECUTION.R",
      "LO04_EXTENDED_EXECUTION.R","LO04_WINDOWS_TESTS.R",
      "LO04_SCIENCE_SMOKE.R","LO04_GC.R","LO05_CONSOLIDATION.R",
      "LO05_LIFECYCLE.R")),
    paste0("engine/",c("V11.R","BACKEND.R","REPAIRS.R","EXTENSIONS.R",
      "production.R","engine.R","store.R","tests.R")))
  destroot<-file.path(repo,"06_pipeline","vendor")
  if (!requireNamespace("digest",quietly=TRUE))
    stop("Package digest is required to produce SHA256 producer manifest")
  out <- list()
  for (relative in scripts) {
    src <- file.path(bundle,relative)
    if (!file.exists(src)) stop("Producer missing: ",src)
    dest <- file.path(destroot,relative)
    dir.create(dirname(dest),recursive=TRUE,showWarnings=FALSE)
    original <- digest::digest(file=src,algo="sha256")
    if (file.exists(dest)) {
      if (digest::digest(file=dest,algo="sha256")!=original)
        stop("Vendored scientific code differs; refuse overwrite: ",dest)
    } else {
      if (!file.copy(src,dest,overwrite=FALSE)) stop("Copy failed: ",dest)
    }
    out[[length(out)+1L]] <- data.frame(
      relative_path=relative,sha256=original,bytes=file.info(src)$size)
  }
  tab<-do.call(rbind,out)
  write.csv(tab,file.path(destroot,"PRODUCER_SOURCE_SHA256.csv"),row.names=FALSE)
  cat("PRODUCER_CODE_READY_FOR_GIT_REVIEW: ",nrow(tab)," files\n",
      "No results/data files copied. Review the commit diff and rights first.\n",sep="")
  invisible(tab)
}

lo_pipeline_main <- function() {
  repo <- lo_pipeline_root()
  action <- tolower(lo_pipeline_arg("action", Sys.getenv("LO_ACTION","plan")))
  scope <- tolower(lo_pipeline_arg("scope",Sys.getenv("LO_SCOPE","nld_plus_19")))
  scopes <- c(nld_only="NLD_ONLY",nld_plus_19="NLD_PLUS_OECD_PPP",
              reference_19="OECD_PPP_ONLY",other="OTHER_INTERNATIONAL",
              all="FULL_INTERNATIONAL")
  if (!scope %in% names(scopes)) stop("Unknown scope: ",scope)
  actions <- c("plan","execute","replicate","vendor","inventory","migrate","maintain","status","publish","watch","setup-drive")
  if (!action %in% actions) stop("Unknown action: ",action)

  stamp <- format(Sys.time(),"%Y%m%d_%H%M%S")
  output <- Sys.getenv("LO_RUN_OUTPUT", file.path(tempdir(),"learning_outcomes_logs"))
  run <- file.path(output,paste0("run_",stamp))
  dir.create(run, recursive=TRUE, showWarnings=FALSE)
  writeLines(c(paste0("git_commit=",lo_pipeline_git_info(repo)),
               paste0("action=",action),paste0("scope=",scope),
               paste0("timestamp=",as.character(Sys.time())),
               capture.output(sessionInfo())),
             file.path(run,"RUN_PROVENANCE.txt"))
  cat("Git-gebonden runner; log: ",run,"\n",sep="")
  config <- Sys.getenv("LO_STORAGE_CONFIG","")
  if (action %in% c("inventory","migrate","status")) {
    lo_pipeline_storage(repo,action,config)
    return(invisible(run))
  }
  if(action=="setup-drive") {
    lo_pipeline_setup_drive()
    return(invisible(run))
  }
  if(action%in%c("publish","watch")) {
    lo_pipeline_drive_publish(repo,action)
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
  if (action=="vendor") {
    bundle<-Sys.getenv("LO05_BUNDLE","")
    if (!nzchar(bundle) || !dir.exists(bundle))
      stop("Set LO05_BUNDLE to your locally verified extracted integration bundle")
    lo_pipeline_vendor_source(repo,bundle)
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
    return(invisible(run))
  }
  bundle <- Sys.getenv("LO05_BUNDLE","")
  if (!nzchar(bundle) || !dir.exists(bundle))
    stop("LO05_BUNDLE must point to the extracted, checksum-verified LO05/LO04 integrated bundle. ",
         "Current 10 October modules are NOT yet a clean AER replication release.",call.=FALSE)
  lo_pipeline_validate_reference(repo,bundle)
  core <- file.path(bundle,"code","INTEGRATED.R")
  if (!file.exists(core)) stop("Historical integration module missing: ",core)
  if (nzchar(config)) lo_pipeline_storage(repo,"status",config)
  options(learning_outcomes.mode=unname(scopes[[scope]]),
          learning_outcomes.action=if (action=="plan")"plan_only" else "production",
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
  invisible(run)
}

if (!isTRUE(getOption("lo.pipeline.functions_only",FALSE)))
  lo_pipeline_main()
