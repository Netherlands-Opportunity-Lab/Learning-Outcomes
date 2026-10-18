# Learning Outcomes: one-click-ish RStudio bootstrap (no separate PowerShell step).
# Versioned at repo root; invokes ONLY 06_pipeline/RUN.R as the science runner.
# Default: storage-audit (metadata only; does not read scientific microdata
# values, calculate estimates, or delete local files).
lo_bootstrap_main <- function() {
  home <- Sys.getenv("USERPROFILE", unset=path.expand("~"))
  repo <- Sys.getenv("LO_REPO_ROOT", unset=file.path(home,"Downloads","Learning-Outcomes"))
  if (!dir.exists(file.path(repo,".git")) && !file.exists(file.path(repo,".git")))
    stop("Learning-Outcomes Git clone not found: ",repo,
         "\nThe first clone needs to exist. Do not download this into another project.")
  repo <- normalizePath(repo,winslash="/",mustWork=TRUE)
  git <- unname(Sys.which("git"))
  if (!nzchar(git)) {
    program_files <- Sys.getenv("ProgramFiles",unset="C:/Program Files")
    userlocal <- Sys.getenv("LOCALAPPDATA",unset=file.path(home,"AppData","Local"))
    candidates <- c(file.path(program_files,"Git","cmd","git.exe"),
                    file.path(userlocal,"Programs","Git","cmd","git.exe"))
    found <- candidates[vapply(candidates,function(p)
       isTRUE(file.exists(p)),logical(1))]
    if(length(found)) git <- found[[1L]]
  }
  if (!nzchar(git)) stop("Git for Windows not found in PATH or standard install folders")
  command <- function(parts,allow_failure=FALSE) {
    result <- suppressWarnings(system2(git,args=shQuote(parts),
                                      stdout=TRUE,stderr=TRUE))
    rc <- attr(result,"status")
    if (is.null(rc)) rc <- 0L
    if (rc!=0L && !allow_failure)
      stop("Git command failed; no R production started (exit ",rc,").\n",
           paste(tail(result,10L),collapse="\n"))
    list(rc=rc,lines=as.character(result))
  }
  remote <- command(c("-C",repo,"remote","get-url","origin"))$lines
  valid <- length(remote)==1L &&
    grepl("^(https://github[.]com/|git@github[.]com:|ssh://git@github[.]com/)",
          remote) &&
    grepl("Netherlands-Opportunity-Lab/Learning-Outcomes([.]git)?$",remote)
  if (!valid) stop("Git origin is not the expected Learning-Outcomes repository")
  branch <- "feat/reproducible-storage-and-cleanup-20261010"
  action <- Sys.getenv("LO_START_ACTION",unset="storage-audit")
  if(!nzchar(action))action<-"storage-audit"
  if(action!='fixed-status') {
    source(file.path(repo,'06_pipeline/LO_PROCESS_LOCK.R'),local=environment())
    common<-command(c('-C',repo,'rev-parse','--git-common-dir'))$lines
    if(length(common)!=1L)stop('BOOTSTRAP_GIT_DIRECTORY_UNKNOWN')
    if(!grepl('^(/|[A-Za-z]:[/\\\\])',common))common<-file.path(repo,common)
    root<-Sys.getenv('LO_FIXED_ROOT',file.path(home,'Downloads','LO05_RESULTATEN'))
    bootstrap_lock<-lo_startup_lock(common,root)
    on.exit(lo_process_unlock(bootstrap_lock),add=TRUE)
  }
  reproduce<-Sys.getenv("LO_REPRODUCE_COMMIT","")
  active <- command(c("-C",repo,"branch","--show-current"))$lines
  if (!nzchar(reproduce) && (length(active)!=1L || !identical(active[[1]],branch)))
    stop("Git branch is not the expected reviewed feature branch: ",branch,
         "\nCurrent: ",paste(active,collapse=", "),
         ". No code was modified or run.")
  if(nzchar(reproduce)) {
    if(!grepl("^[0-9a-f]{40}$",reproduce))stop("LO_REPRODUCE_COMMIT requires the full recorded commit SHA")
    head<-command(c("-C",repo,"rev-parse","HEAD"))$lines
    if(!identical(head,reproduce))stop("Replication checkout is not at the recorded commit")
    dirty<-command(c("-C",repo,"status","--porcelain","--untracked-files=no"))$lines
    if(length(dirty))stop("Replication requires unchanged tracked code")
    source(file.path(repo,"06_pipeline","LO_ENVIRONMENT.R"),local=environment())
    lo_environment_check(repo,strict=TRUE)
    message("Learning Outcomes: immutable replication; commit and environment verified.")
  } else if(action!='fixed-status') {
  message("Learning Outcomes: checking for safe fast-forward updates...")
  # Normal Git merge refuses to overwrite tracked local changes. Never force,
  # reset, checkout, stash, delete or merge an unexpected branch.
  pulled <- command(c("-C",repo,"pull","--ff-only","origin",branch))
  if(length(pulled$lines))cat(paste(pulled$lines,collapse="\n"),"\n")
  }
  runner <- file.path(repo,"06_pipeline","RUN.R")
  if(!file.exists(runner))stop("Integrated runner missing after Git update")
  # Avoid resuming a stale LO_ACTION=execute or publish from a prior R session.
  # Set LO_START_ACTION explicitly only when the user chooses another stage.
  action <- Sys.getenv("LO_START_ACTION",unset="storage-audit")
  if(!nzchar(action)) action <- "storage-audit"
  if(action=='produce-approved') {
    # Update once above, then freeze all stages to one reviewed checkout. The
    # aggregate deposit happens after the stages so its commit cannot move the
    # producer checkout halfway through an immutable run.
    head<-command(c('-C',repo,'rev-parse','HEAD'))$lines
    prior<-Sys.getenv('LO_REPRODUCE_COMMIT','')
    prior_action<-Sys.getenv('LO_ACTION','')
    prior_drive<-Sys.getenv('LO_DEFER_PRIVATE_DRIVE','')
    on.exit({if(nzchar(prior))Sys.setenv(LO_REPRODUCE_COMMIT=prior)else Sys.unsetenv('LO_REPRODUCE_COMMIT');Sys.setenv(LO_ACTION=prior_action,LO_DEFER_PRIVATE_DRIVE=prior_drive)},add=TRUE)
    Sys.setenv(LO_REPRODUCE_COMMIT=head,LO_REPO_ROOT=repo,LO_DEFER_PRIVATE_DRIVE='1')
    source(file.path(repo,'06_pipeline/LO_RUN_CONFIG.R'),local=environment())
    config_path<-Sys.getenv('LO_RUN_CONFIG','')
    scope<-if(nzchar(config_path))jsonlite::fromJSON(config_path)$scope else Sys.getenv('LO_SCOPE','nld_only')
    root<-Sys.getenv('LO_FIXED_ROOT',file.path(home,'Downloads','LO05_RESULTATEN'))
    for(stage in c('fixed-audit','fixed-produce','fixed-finalize','fixed-status')) {
      Sys.setenv(LO_ACTION=stage)
      source(runner,local=new.env(parent=.GlobalEnv),encoding='UTF-8')
    }
    # Sealed blocks were transferred during production. Commit the final run
    # records as well, including settings, code and exact result-version links.
    source(file.path(repo,'06_pipeline/LO_REMOTE_CHECKPOINT.R'),local=environment())
    lo_remote_checkpoint(repo,root)
    if(Sys.getenv('LO_GITHUB_RESULTS',if(nzchar(reproduce))'off'else'review')=='review') {
      source(file.path(repo,'06_pipeline/LO_GITHUB_RESULTS.R'),local=environment())
      tryCatch(lo_github_results_deposit(repo,root,scope),error=function(e) {
        message('GITHUB_RESULTS_PENDING: ',conditionMessage(e))
        stop('Numerical work is retained locally; GitHub result deposit is not yet verified. Repeat after resolving the reported Git issue.',call.=FALSE)
      })
    }
    # One final human-readable report sync; scientific block checkpoints have
    # already been transferred and restored during the calculation sequence.
    private_sync<-new.env(parent=.GlobalEnv)
    prior_functions<-getOption('lo.pipeline.functions_only')
    options(lo.pipeline.functions_only=TRUE)
    tryCatch(source(runner,local=private_sync,encoding='UTF-8'),finally=options(lo.pipeline.functions_only=prior_functions))
    if(file.exists(private_sync$lo_pipeline_drive_config_path())) {
      message('Private Drive: verifying the completed run once; GitHub result deposit has already been attempted.')
      tryCatch(private_sync$lo_pipeline_drive_publish(repo,'publish',results_root=root,fixed_scope=scope),
        error=function(e)message('FIXED_PRIVATE_SYNC_PENDING: ',conditionMessage(e)))
    }
    cat('Approved results are durable. Repeating this command resumes only missing approved calculations and repeats the final checks.\n')
    cat('Read the fixed-finalize report for remaining scientific/product gates; completing this command is not publication approval.\n')
    return(invisible(TRUE))
  }
  Sys.setenv(LO_ACTION=action)
  message("One-entry R runner: ",action)
  Sys.setenv(LO_REPO_ROOT=repo)
  # Execute the just-updated source, not stale functions from an R session.
  source(runner,local=new.env(parent=.GlobalEnv),encoding="UTF-8")
  invisible(TRUE)
}
lo_bootstrap_main()

