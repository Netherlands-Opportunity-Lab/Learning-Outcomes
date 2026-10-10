# Public-safe GitHub run-status publisher.
# This module deliberately NEVER publishes raw results, microdata, file paths,
# detailed logs, free-text messages or credentials to the public repository.
# Results stay locally and optional detailed artifacts go to private Drive.
lo_status_safe_code <- function(x, default="UNKNOWN") {
  if (length(x)!=1L || is.na(x)) return(default)
  x <- toupper(trimws(as.character(x)))
  if (!grepl("^[A-Z0-9_]{1,80}$", x)) return(default)
  x
}
lo_status_safe_int <- function(x) {
  if (length(x)!=1L || is.na(x)) return(NULL)
  s <- trimws(as.character(x))
  if (!grepl("^[0-9]{1,12}$",s)) return(NULL)
  n <- suppressWarnings(as.numeric(s))
  if (!is.finite(n)) return(NULL)
  n
}
lo_status_git <- function(git,args,check=TRUE) {
  # shQuote protects spaces in Windows paths and no shell command is evaluated.
  out <- suppressWarnings(system2(git,shQuote(args),stdout=TRUE,stderr=TRUE))
  code <- attr(out,"status")
  if (is.null(code)) code <- 0L
  if (check && code!=0L)
    stop("Git operation failed (exit ",code,"). Check Git credential access.",
         call.=FALSE)
  list(code=code,stdout=out)
}
lo_status_root <- function() {
  explicit <- Sys.getenv("LO_LOCAL_RESULTS_ROOT","")
  if (nzchar(explicit) && dir.exists(explicit))
    return(normalizePath(explicit,winslash="/",mustWork=TRUE))
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  cfgs <- unique(c(Sys.getenv("LO_DRIVE_SYNC_CONFIG",""),
    file.path(home,"Downloads","LO05_RESULTATEN",".cloud_sync","drive.local.json"),
    file.path(home,"Documents","Downloads","LO05_RESULTATEN",
              ".cloud_sync","drive.local.json"),
    file.path(path.expand("~"),"Downloads","LO05_RESULTATEN",
              ".cloud_sync","drive.local.json")))
  if (requireNamespace("jsonlite",quietly=TRUE)) {
    for (cf in cfgs) {
      if (!nzchar(cf) || !file.exists(cf)) next
      settings <- tryCatch(jsonlite::fromJSON(cf),error=function(e)NULL)
      root <- if(is.null(settings)) NULL else settings$local_results_root
      if (is.character(root) && length(root)==1L && dir.exists(root))
        return(normalizePath(root,winslash="/",mustWork=TRUE))
    }
  }
  dirs <- unique(c(file.path(home,"Downloads","LO05_RESULTATEN"),
                   file.path(path.expand("~"),"Downloads","LO05_RESULTATEN")))
  found <- dirs[vapply(dirs,function(x) isTRUE(dir.exists(x)),logical(1))]
  if(length(found)) normalizePath(found[[1]],winslash="/",mustWork=TRUE) else NULL
}
lo_status_latest_run <- function(root) {
  if(is.null(root)) return(NULL)
  base <- file.path(root,"runs")
  if(!dir.exists(base)) return(NULL)
  dirs <- list.dirs(base,full.names=TRUE,recursive=FALSE)
  dirs <- dirs[grepl("^run_[0-9]{8}_[0-9]{6}(_[a-zA-Z0-9]+)?$",basename(dirs))]
  if(!length(dirs)) return(NULL)
  info <- file.info(dirs)
  dirs <- dirs[!is.na(info$mtime)]
  if(!length(dirs)) return(NULL)
  dirs[order(file.info(dirs)$mtime,decreasing=TRUE)][[1]]
}
lo_status_from_file <- function(path) {
  out <- list()
  if(!file.exists(path) || is.na(file.info(path)$size) ||
     file.info(path)$size>1024*1024) return(out)
  lines <- readLines(path,warn=FALSE,encoding="UTF-8",n=600L)
  keys <- c("STATUS","STAGE","RUN_MODE","PRODUCTION_PHASE",
            "SCIENTIFIC_RELEASE","CENTRAL_PROJECT_STORAGE_CHANGED",
            "FULL_SCIENTIFIC_SCOPE_RELEASED","LONG_PRODUCTION_STARTED",
            "LIVE_CENTRAL","CENTRAL_HISTORY","LIVE_LO02")
  counts <- c("TOTAL_CONTRACT_TASKS","SELECTED_TASKS","NLD_SELECTED",
              "OECD19_SELECTED","FOREIGN_COMPARATOR_COUNT",
              "PRODUCTION_PHASE_TASKS","CACHE_FILES_DISCOVERED",
              "HISTORICAL_SOURCE_FILES_PRESENT",
              "HISTORICAL_SOURCE_FILES_NOT_FOUND","LEGACY_EVIDENCE_ROWS",
              "CROSS_REGISTRY_OVERLAPS","NLD_TASKS_COMPUTED",
              "METRICS_REUSED","METRICS_COMPUTED","METRICS_HELD")
  for (line in lines) {
    if (!grepl("^[A-Z0-9_]+=",line)) next
    match <- regexec("^([A-Z0-9_]+)=(.*)$",line)
    parsed <- regmatches(line,match)[[1]]
    if(length(parsed)!=3L) next
    k <- parsed[[2]]
    if (k %in% keys) {
      safe <- lo_status_safe_code(parsed[[3]],default="")
      if(nzchar(safe)) out[[k]] <- safe
    } else if (k %in% counts) {
      safe <- lo_status_safe_int(parsed[[3]])
      if(!is.null(safe)) out[[k]] <- safe
    }
  }
  out
}
lo_status_build <- function(repo,action="status-publish",scope="nld_plus_19",
                            outcome="OBSERVED", code_sha="UNKNOWN") {
  root <- lo_status_root()
  newest <- lo_status_latest_run(root)
  extracted <- if(is.null(newest)) list() else
    lo_status_from_file(file.path(newest,"STATUS.txt"))
  run_id <- if(is.null(newest)) NULL else basename(newest)
  # Never use untrusted free-form values, absolute paths, titles or labels.
  if(!is.null(run_id) &&
     !grepl("^run_[0-9]{8}_[0-9]{6}(_[A-Za-z0-9]+)?$",run_id))
    run_id <- NULL
  counts <- list()
  for (k in c("TOTAL_CONTRACT_TASKS","SELECTED_TASKS","NLD_SELECTED",
              "OECD19_SELECTED","FOREIGN_COMPARATOR_COUNT",
              "PRODUCTION_PHASE_TASKS","CACHE_FILES_DISCOVERED",
              "HISTORICAL_SOURCE_FILES_PRESENT",
              "HISTORICAL_SOURCE_FILES_NOT_FOUND","LEGACY_EVIDENCE_ROWS",
              "CROSS_REGISTRY_OVERLAPS","NLD_TASKS_COMPUTED",
              "METRICS_REUSED","METRICS_COMPUTED","METRICS_HELD")) {
    if(!is.null(extracted[[k]])) counts[[tolower(k)]] <- extracted[[k]]
  }
  states <- list()
  for(k in c("STATUS","STAGE","RUN_MODE","PRODUCTION_PHASE",
             "LIVE_CENTRAL","CENTRAL_HISTORY","LIVE_LO02")) {
    if(!is.null(extracted[[k]])) states[[tolower(k)]] <- extracted[[k]]
  }
  # Never grant scientific release based on unreviewed runtime flags.
  code_sha <- tolower(as.character(code_sha))
  if(length(code_sha)!=1L || !grepl("^[0-9a-f]{40}$",code_sha))
    code_sha <- "UNKNOWN"
  list(
    schema_version="lo-public-safe-run-status-v1",
    privacy="METADATA_ONLY_NO_PATHS_NO_VALUES_NO_LOGS",
    producer_git_commit=code_sha,
    requested_action=lo_status_safe_code(action),
    requested_scope=lo_status_safe_code(scope),
    invocation_outcome=lo_status_safe_code(outcome),
    latest_local_run_id=if(is.null(run_id)) "NONE" else run_id,
    availability=if(is.null(newest)) "NO_RUN_FOUND" else
      if(file.exists(file.path(newest,"STATUS.txt"))) "STATUS_FILE_FOUND"
      else "RUN_FOLDER_ONLY",
    scientific_release="NOT_AUTOMATICALLY_GRANTED",
    runtime_states=states,
    counts=counts)
}
lo_status_publish_git <- function(repo,action="status-publish",
                                  scope="nld_plus_19",outcome="OBSERVED",
                                  dry_run=FALSE) {
  if (identical(Sys.getenv("LO_GITHUB_STATUS","ON"),"OFF")) {
    message("GitHub status publishing disabled by LO_GITHUB_STATUS=OFF.")
    return(invisible(FALSE))
  }
  if (!requireNamespace("jsonlite",quietly=TRUE))
    stop("jsonlite package required for public-safe status manifest")
  git <- unname(Sys.which("git"))
  if(!nzchar(git)) stop("Git for Windows not available on PATH")
  sha <- lo_status_git(git,c("-C",repo,"rev-parse","HEAD"))$stdout[[1]]
  manifest <- lo_status_build(repo,action,scope,outcome,sha)
  staging <- file.path(repo,"06_pipeline","state")
  dir.create(staging,recursive=TRUE,showWarnings=FALSE)
  pending <- file.path(staging,"github_status_pending.json")
  jsonlite::write_json(manifest,pending,pretty=TRUE,auto_unbox=TRUE,null="null")
  # Defense in depth: refuse any accidental path, email, token-like or raw text.
  content <- paste(readLines(pending,warn=FALSE),collapse="\n")
  if(grepl("[A-Za-z]:[/\\\\]|/Users/|/home/|@|(?i:password|token|secret|credential)",
           content,perl=TRUE))
    stop("Status privacy gate rejected output; nothing published")
  if(isTRUE(dry_run)) return(invisible(manifest))
  remote <- lo_status_git(git,c("-C",repo,"remote","get-url","origin"))$stdout
  if(length(remote)!=1L ||
     !grepl("^(https://github[.]com/|git@github[.]com:|ssh://git@github[.]com/)",
            remote) ||
     !grepl("Netherlands-Opportunity-Lab/Learning-Outcomes([.]git)?$",remote))
    stop("Git origin is not the approved Learning-Outcomes repository")
  # Separate status branch: never mutate the developer worktree or main.
  branch <- "lo-run-status"
  lo_status_git(git,c("-C",repo,"fetch","origin",
                      paste0("refs/heads/",branch)))
  worktree <- tempfile("lo-status-worktree-")
  lo_status_git(git,c("-C",repo,"worktree","add","--detach",worktree,"FETCH_HEAD"))
  on.exit({
    try(lo_status_git(git,c("-C",repo,"worktree","remove","--force",worktree),
                      check=FALSE),silent=TRUE)
  },add=TRUE)
  target <- file.path(worktree,"run_status","latest.json")
  dir.create(dirname(target),recursive=TRUE,showWarnings=FALSE)
  if(!isTRUE(file.copy(pending,target,overwrite=TRUE)))
    stop("Could not stage status JSON")
  lo_status_git(git,c("-C",worktree,"add","--","run_status/latest.json"))
  diff <- lo_status_git(git,c("-C",worktree,"diff","--cached",
                              "--quiet","--","run_status/latest.json"),check=FALSE)
  if(diff$code==0L) {
    message("GitHub status already current; no new commit needed.")
    return(invisible(manifest))
  }
  if(diff$code!=1L) stop("Could not check staged status changes")
  lo_status_git(git,c("-C",worktree,"-c",
                      "user.name=Learning Outcomes Local Runner",
                      "-c","user.email=learning-outcomes-runner@users.noreply.github.com",
                      "commit","-m","Update sanitized local run status"))
  lo_status_git(git,c("-C",worktree,"push","origin",
                      paste0("HEAD:refs/heads/",branch)))
  message("GitHub run status published to isolated branch lo-run-status.")
  invisible(manifest)
}
