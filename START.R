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
  if (!nzchar(git)) stop("Git for Windows missing from PATH")
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
  active <- command(c("-C",repo,"branch","--show-current"))$lines
  if (length(active)!=1L || !identical(active[[1]],branch))
    stop("Git branch is not the expected reviewed feature branch: ",branch,
         "\nCurrent: ",paste(active,collapse=", "),
         ". No code was modified or run.")
  message("Learning Outcomes: checking for safe fast-forward updates...")
  # Normal Git merge refuses to overwrite tracked local changes. Never force,
  # reset, checkout, stash, delete or merge an unexpected branch.
  pulled <- command(c("-C",repo,"pull","--ff-only","origin",branch))
  if(length(pulled$lines))cat(paste(pulled$lines,collapse="\n"),"\n")
  runner <- file.path(repo,"06_pipeline","RUN.R")
  if(!file.exists(runner))stop("Integrated runner missing after Git update")
  action <- Sys.getenv("LO_ACTION","")
  if(!nzchar(action)) {
    action <- "storage-audit"
    Sys.setenv(LO_ACTION=action)
  }
  message("One-entry R runner: ",action)
  Sys.setenv(LO_REPO_ROOT=repo)
  # Execute the just-updated source, not stale functions from an R session.
  source(runner,local=new.env(parent=.GlobalEnv),encoding="UTF-8")
  invisible(TRUE)
}
lo_bootstrap_main()
