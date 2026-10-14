# Native R -> rclone -> private Google Drive, without Python.
# Never deletes local or remote files; never uploads raw microdata.
# Each completed artifact is addressed by SHA-256; pointer is published last.
lo_drive_run <- function(exe,args) {
  # RStudio remains local. Transient Windows DNS/Google API failures must
  # not invalidate previously computed results or force a pupil rerun.
  # No deletion, no rclone sync, and no pointer advance on upload failure.
  max_attempts <- 5L
  for(attempt in seq_len(max_attempts)) {
    out <- tryCatch(
      suppressWarnings(system2(exe,shQuote(args),stdout=TRUE,stderr=TRUE)),
      error=function(e)structure(conditionMessage(e),status=1L))
    status <- attr(out,"status")
    if(is.null(status)||identical(as.integer(status),0L))return(out)
    message_text <- paste(tail(out,12L),collapse=" | ")
    transient <- grepl(
      "no such host|temporary failure|serverbusy|service unavailable|connection reset|timeout|timed out|429|500|502|503|504|rate limit|dns",
      message_text,ignore.case=TRUE)
    if(!transient || attempt==max_attempts)
      stop("PRIVATE_DRIVE_SYNC_PENDING: rclone failed after ",attempt,
           " attempt(s); local results retained. ",
           substr(message_text,1L,750L),call.=FALSE)
    pause <- min(30,2^attempt)
    cat("Private Drive temporary network issue; retry ",
        attempt,"/",max_attempts," after ",pause,
        " seconds; local results preserved.\n",sep="")
    Sys.sleep(pause)
  }
}

lo_drive_sync <- function(config,action=c("publish","preview","watch"),rclone_override="",
                          producer_commit="UNKNOWN",results_root_override="",fixed_scope="") {
  action <- match.arg(action)
  if (!requireNamespace("jsonlite",quietly=TRUE) ||
      !requireNamespace("digest",quietly=TRUE))
    stop("R packages jsonlite and digest are required for safe Drive sync")
  if (!file.exists(config)) stop("Drive config missing: ",config)
  cfg <- jsonlite::fromJSON(config,simplifyVector=TRUE)
  if (!identical(cfg$data_visibility,"PRIVATE_ACCOUNT_ONLY"))
    stop("Drive sync requires PRIVATE_ACCOUNT_ONLY")
  if(nzchar(fixed_scope)&&!fixed_scope%in%c('nld_only','nld_plus_19','all_required'))stop('DRIVE_INVALID_FIXED_SCOPE')
  root <- normalizePath(if(nzchar(results_root_override))results_root_override else cfg$local_results_root,winslash="/",mustWork=TRUE)
  remote <- as.character(cfg$remote)
  if (length(remote)!=1L || !grepl("^[A-Za-z0-9_-]+:[A-Za-z0-9_./-]+$",remote) ||
      grepl("\\.\\.",remote)) stop("Unsafe or missing rclone remote")
  exe <- if(nzchar(rclone_override)) rclone_override else as.character(cfg$rclone_binary)
  if (!file.exists(exe) && !nzchar(Sys.which(exe)))
    stop("rclone executable not found: ",exe)
  maxbytes <- if(is.null(cfg$max_file_bytes)) 2e9 else as.numeric(cfg$max_file_bytes)
  minage <- if(is.null(cfg$min_age_seconds)) 120 else as.numeric(cfg$min_age_seconds)
  stage <- file.path(root,".cloud_sync")
  dir.create(stage,recursive=TRUE,showWarnings=FALSE)
  lock <- file.path(stage,"r_sync.lock")
  if (file.exists(lock)) {
    age <- as.numeric(difftime(Sys.time(),file.info(lock)$mtime,units="mins"))
    if (is.na(age) || age<60) stop("Another Drive sync may be running: ",lock)
    stop("Stale Drive sync lock needs manual review: ",lock)
  }
  if (!file.create(lock)) stop("Could not acquire sync lock")
  on.exit(unlink(lock),add=TRUE)
  # PRIVATE publication only. A finished LO05 run has a fixed, reviewed
  # report schema and a ZIP created by the pinned INTEGRATED.R producer.
  # Never recurse over arbitrary files, nor export RDS/Parquet/SQLite/microdata.
  lo_drive_allowed_members <- function() c(
    "STATUS.txt", "PREFLIGHT.txt", "PLAN_COUNTS.csv",
    "CONSOLIDATION_STATUS.csv", "CONSOLIDATED_SOURCE_COUNTS.csv",
    "PRODUCT_REQUIREMENTS_TRACE.csv", "FIGURE_COVERAGE.csv",
    "HISTORICAL_PRODUCT_PINS_STATUS.txt", "GC_CANDIDATES.csv",
    "GC_DELETION_LOG.csv", "GC_FAILURE.txt",
    "CONSOLIDATION_FAILURE.txt", "MIGRATION_HOLD.txt",
    "POSTPRODUCTION_CONSOLIDATION.csv",
    "POSTPRODUCTION_CONSOLIDATION_FAILURE.txt",
    "RELEASE_FINGERPRINTS.csv", "NLD_CACHES_FOUND.csv",
    "PHASE_STATUS.csv", "PHASE_NLD/WINDOWS_INTEGRATION_TESTS.csv",
    "PHASE_NLD/LO02_RELEASED_PISA_CORE_GENDER/AANTALLEN.csv",
    "PHASE_NLD/CANDIDATES_JOURNAL.csv",
    "PHASE_NLD/RELEASED_EXECUTION_FAILURE.txt",
    "PHASE_NLD/WINDOWS_TEST_FAILURE.txt",
    "PHASE_NLD/CANDIDATE_FAILURE.txt",
    "PHASE_OECD19/WINDOWS_INTEGRATION_TESTS.csv",
    "PHASE_OECD19/LO02_RELEASED_PISA_CORE_GENDER/AANTALLEN.csv",
    "PHASE_OECD19/CANDIDATES_JOURNAL.csv",
    "PHASE_OECD19/RELEASED_EXECUTION_FAILURE.txt",
    "PHASE_OECD19/WINDOWS_TEST_FAILURE.txt",
    "PHASE_OECD19/CANDIDATE_FAILURE.txt"
  )
  lo_drive_named_reports <- function() c(
    "STATUS.txt", "PREFLIGHT.txt", "PLAN_COUNTS.csv",
    "CONSOLIDATION_STATUS.csv", "CONSOLIDATED_SOURCE_COUNTS.csv",
    "FIGURE_COVERAGE.csv", "PHASE_STATUS.csv",
    "PHASE_NLD/WINDOWS_INTEGRATION_TESTS.csv",
    "PHASE_NLD/LO02_RELEASED_PISA_CORE_GENDER/AANTALLEN.csv",
    "PHASE_OECD19/WINDOWS_INTEGRATION_TESTS.csv",
    "PHASE_OECD19/LO02_RELEASED_PISA_CORE_GENDER/AANTALLEN.csv",
    "PRIVATE_RESULT_EXPORT/LO02_EXPORT_STATUS.csv",
    "PRIVATE_RESULT_EXPORT/LO02_EXPORT_SCHEMA_AUDIT.csv",
    "PRIVATE_RESULT_EXPORT/LO02_SNAPSHOT_COUNTS.csv",
    "PRIVATE_RESULT_EXPORT/LO02_SNAPSHOT_COMPARISONS.csv",
    "PRIVATE_RESULT_EXPORT/LO02_NEW_RESULT_ROWS.csv"
  )
  lo_drive_run_id_ok <- function(id) {
    length(id)==1L && !is.na(id) &&
      grepl("^run_[0-9]{8}_[0-9]{6}$", id)
  }
  lo_drive_secret_hit <- function(s) {
    grepl("-----BEGIN [A-Z ]*PRIVATE KEY-----",s,perl=TRUE) ||
      grepl("(access_token|refresh_token|client_secret|private_key|password)[[:space:]]*[:=][[:space:]]*['\"]?[A-Za-z0-9_./+=-]{10,}",
            s,perl=TRUE,ignore.case=TRUE)
  }
  lo_drive_text_safe <- function(bytes, label) {
    if(any(as.integer(bytes)==0L))
      stop("PRIVATE_REPORT_HOLD: binary/NUL content in ",label)
    s <- tryCatch(rawToChar(bytes),error=function(e)NA_character_)
    if(is.na(s) || isTRUE(lo_drive_secret_hit(s)))
      stop("PRIVATE_REPORT_HOLD: unsafe text/secret signature in ",label)
    invisible(TRUE)
  }
  lo_drive_zip_safe <- function(zipfile) {
    if(!file.exists(zipfile))stop("PRIVATE_REPORT_HOLD: return ZIP missing")
    if(is.na(file.info(zipfile)$size) ||
       file.info(zipfile)$size > 64*1024^2)
      stop("PRIVATE_REPORT_SIZE_HOLD: compressed return ZIP exceeds 64 MiB; ",
           "ZIP_mib=",round(file.info(zipfile)$size/1024^2,2))
    listing <- tryCatch(utils::unzip(zipfile,list=TRUE),
                        error=function(e)e)
    if(inherits(listing,"error") ||
       !all(c("Name","Length")%in%names(listing)))
      stop("PRIVATE_REPORT_HOLD: cannot inspect return ZIP")
    names <- gsub("\\","/",as.character(listing$Name),fixed=TRUE)
    is_dir <- endsWith(names,"/")
    allowed <- lo_drive_allowed_members()
    valid_dirs <- unique(unlist(lapply(allowed,function(x) {
      bits <- strsplit(x,"/",fixed=TRUE)[[1L]]
      if(length(bits)<2L)return(character())
      paste0(vapply(seq_len(length(bits)-1L),function(k)
        paste(bits[seq_len(k)],collapse="/"),character(1L)),"/")
    }),use.names=FALSE))
    report_names <- names[!is_dir]
    # zip::zipr(mode="cherry-pick") on some Windows installations
    # flattens PHASE_NLD/.../AANTALLEN.csv to AANTALLEN.csv. A
    # flattened basename is accepted only if exactly ONE approved source
    # path with that basename exists in THIS completed run and its SHA
    # is identical. This prevents conflating NLD and OECD19 files.
    source_for_member <- function(name) {
      candidates <- if(name%in%allowed) name else
        allowed[basename(allowed)==name]
      existing <- candidates[file.exists(file.path(dirname(zipfile),candidates))]
      if(length(existing)!=1L)
        stop("PRIVATE_REPORT_HOLD: unknown or ambiguous ZIP member: ",name)
      existing[[1L]]
    }
    mapped <- vapply(report_names,function(name)
      tryCatch(source_for_member(name),error=function(e)NA_character_),
      character(1L),USE.NAMES=FALSE)
    bad <- c(names[is_dir & !names%in%valid_dirs],
             report_names[is.na(mapped)])

    if(!length(report_names) ||
       length(names)>length(allowed)+length(valid_dirs) ||
       anyDuplicated(names) ||
       length(bad) ||
       !all(c("STATUS.txt","PHASE_STATUS.csv","PLAN_COUNTS.csv")%in%report_names))
      stop("PRIVATE_REPORT_HOLD: return ZIP has unknown, duplicate or missing members",
           if(length(bad))paste0(" (",paste(head(bad,3L),collapse=";"),")") else "")
    sizes <- suppressWarnings(as.numeric(listing$Length))
    # Historical LO05 GC/cache reports are text but can exceed the old
    # blanket 8 MiB per-entry / 48 MiB total limits. Retain a strict ZIP
    # whitelist, source-byte SHA equality and text/credential checks.
    # Only these exact named reports have a larger, still bounded allowance.
    limits <- rep(8 * 1024^2, length(names))
    large_reports <- c(
      "GC_CANDIDATES.csv", "PRODUCT_REQUIREMENTS_TRACE.csv",
      "NLD_CACHES_FOUND.csv", "PHASE_NLD/CANDIDATES_JOURNAL.csv",
      "PHASE_OECD19/CANDIDATES_JOURNAL.csv"
    )
    report_indices <- which(!is_dir)
    large_indices <- report_indices[!is.na(mapped) & mapped %in% large_reports]
    limits[large_indices] <- 64 * 1024^2
    total_limit <- 256 * 1024^2
    wrong_directory <- any(is_dir & (!is.finite(sizes) | sizes!=0))
    bad_sizes <- which(!is.finite(sizes) | sizes<0 | sizes>limits)
    total <- sum(sizes)
    if(length(bad_sizes) || !is.finite(total) || total>total_limit ||
       wrong_directory) {
      worst <- if(length(bad_sizes)) bad_sizes[[1L]] else
        if(length(sizes)) which.max(sizes)[[1L]] else NA_integer_
      culprit <- if(is.finite(worst)) names[[worst]] else "unknown"
      value <- if(is.finite(worst)) sizes[[worst]]/1024^2 else NA_real_
      cat("Drive reviewed ZIP size diagnostic: largest/offending member=",
          culprit,"; uncompressed_mib=",round(value,2),
          "; total_uncompressed_mib=",round(total/1024^2,2),
          "; ZIP_mib=",round(file.info(zipfile)$size/1024^2,2),
          "; directory_metadata_invalid=",wrong_directory,"\n",sep="")
      stop("PRIVATE_REPORT_SIZE_HOLD: vetted report archive exceeds bounded ",
           "size policy; offending member=",culprit,
           "; member_mib=",round(value,2),
           "; total_mib=",round(total/1024^2,2))
    }
    for(i in which(!is_dir)) {
      con <- tryCatch(unz(zipfile,names[[i]],open="rb"),
                      error=function(e)e)
      if(inherits(con,"error"))
        stop("PRIVATE_REPORT_HOLD: cannot open ZIP member: ",names[[i]])
      bytes <- tryCatch(readBin(con,what="raw",n=as.integer(sizes[[i]])+1L),
                        finally=close(con))
      if(length(bytes)!=sizes[[i]])
        stop("PRIVATE_REPORT_HOLD: member read size mismatch: ",names[[i]])
      lo_drive_text_safe(bytes,names[[i]])
      source_path <- source_for_member(names[[i]])
      disk_file <- file.path(dirname(zipfile),source_path)
      if(!file.exists(disk_file) ||
         !identical(unname(digest::digest(bytes,algo="sha256",serialize=FALSE)),
                    unname(digest::digest(file=disk_file,algo="sha256"))))
        stop("PRIVATE_REPORT_HOLD: archive/source bytes differ: ",names[[i]])
    }
    invisible(TRUE)
  }
  lo_drive_run_finished <- function(dir) {
    f <- file.path(dir,c("STATUS.txt","PHASE_STATUS.csv",
                         "PLAN_COUNTS.csv","LEARNING_OUTCOMES_RETURN.zip"))
    if(!all(file.exists(f)))return(FALSE)
    status <- tryCatch(readLines(f[[1]],warn=FALSE),
                       error=function(e)character())
    any(grepl("^RUNNER=LEARNING_OUTCOMES_INTEGRATED_",status)) &&
      any(grepl("^SCIENTIFIC_FINAL_FREEZE=",status))
  }
  lo_drive_pick_run <- function() {
    id <- Sys.getenv("LO_DRIVE_SYNC_RUN_ID","")
    if(nzchar(id) && !lo_drive_run_id_ok(id))
      stop("PRIVATE_REPORT_HOLD: invalid LO_DRIVE_SYNC_RUN_ID")
    runs <- file.path(root,"runs")
    if(!dir.exists(runs)) {
      if(nzchar(id))stop("PRIVATE_REPORT_HOLD: runs directory absent")
      return("")
    }
    if(nzchar(id)) {
      d <- file.path(runs,id)
      if(!dir.exists(d)||!lo_drive_run_finished(d))
        stop("PRIVATE_REPORT_HOLD: requested run not completed: ",id)
      return(d)
    }
    ds <- list.dirs(runs,recursive=FALSE,full.names=TRUE)
    ds <- ds[vapply(basename(ds),lo_drive_run_id_ok,logical(1))]
    ds <- ds[vapply(ds,lo_drive_run_finished,logical(1))]
    if(!length(ds))return("")
    sort(ds,decreasing=TRUE)[[1]]
  }
  lo_drive_quota_report <- function() {
    p <- file.path(root,"master_reconciliation",
                   "CLOUD_QUOTA_AND_MIGRATION_LIMIT.csv")
    if(!file.exists(p))return(character())
    info <- file.info(p)
    if(is.na(info$size) || info$size>min(maxbytes,65536))return(character())
    age <- as.numeric(difftime(Sys.time(),info$mtime,units="secs"))
    if(is.na(age)||age<minage)return(character())
    z <- tryCatch(read.csv(p,stringsAsFactors=FALSE,check.names=FALSE),
                  error=function(e)NULL)
    expected <- c("account_visibility","quota_known","free_gib",
                  "estimated_priority_gib","raw_89gb_removable","reason")
    if(is.null(z) || !identical(names(z),expected) || nrow(z)!=1L ||
       !identical(as.character(z$account_visibility[[1]]),
                  "PRIVATE_ACCOUNT_ONLY"))return(character())
    bytes<-readBin(p,what="raw",n=as.integer(info$size)+1L)
    lo_drive_text_safe(bytes,"CLOUD_QUOTA_AND_MIGRATION_LIMIT.csv")
    p
  }
  lo_drive_minimum_reports <- function() {
    base <- file.path(root,"master_reconciliation","MINIMUM_FIGURE_QUEUE")
    # Aggregates only: never transmit the full private metric_key queue.
    allowed <- c("MINIMUM_COMPUTE_BOUNDS.csv",
       "FIGURE_FAMILY_COUNTRY_MODULE_COUNTS.csv",
       "FIGURE_FAMILY_MINIMUM_ACTION_COUNTS.csv",
       "ACTIVE_PRODUCT_RECONCILIATION.csv",
       "ADDITIONAL_BELOW_BASIC_PEER_CONTEXTS.csv",
       "FIGURE_ID_COUNTRY_MINIMUM_ACTION_COUNTS.csv",
       "UNLINKED_DERIVED_FIGURES.csv",
       "GRID_ARCHIVE_FILL_COUNTS.csv",
       "GRID_BATCH_READY_COUNTS.csv")
    chosen <- file.path(base,allowed)
    chosen <- chosen[file.exists(chosen)]
    for(p in chosen) {
      info <- file.info(p)
      if(is.na(info$size)||info$size>1024^2)
        stop("PRIVATE_REPORT_HOLD: minimum figure aggregate too large")
      bytes <- readBin(p,what="raw",n=as.integer(info$size)+1L)
      if(length(bytes)!=info$size)
        stop("PRIVATE_REPORT_HOLD: minimum figure aggregate changed")
      lo_drive_text_safe(bytes,basename(p))
      # Avoid leaking private Windows paths in a copy to the private Drive.
      if(grepl("[A-Za-z]:[/\\\\]Users[/\\\\]",rawToChar(bytes),ignore.case=TRUE))
        stop("PRIVATE_REPORT_HOLD: private path in minimum figure aggregate")
    }
    chosen
  }
  lo_drive_fixed_reports <- function() {
    scope_names <- c("nld_only","nld_plus_19","all_required")
    if(nzchar(fixed_scope))scope_names<-fixed_scope
    safe <- character()
    for(scope in scope_names) {
      base <- file.path(root,"FIXED_PRODUCTION_V1",scope)
      if(!dir.exists(base))next
      for(rel in c("GRID_AUDIT_SUMMARY.csv","PRODUCTION_SCOPE_STATUS.csv",
        "SCIENTIFIC_QUALITY_SUMMARY.csv","FINAL_FIXED_PIPELINE/RECONCILIATION_SUMMARY.csv",
        "SCOPE_SELECTION_SUMMARY.csv")) {
        p <- file.path(base,rel)
        if(!file.exists(p))next
        info <- file.info(p)
        if(is.na(info$size) || info$size>1024^2)
          stop("PRIVATE_REPORT_HOLD: fixed summary too large")
        bytes <- readBin(p,what="raw",n=as.integer(info$size)+1L)
        if(length(bytes)!=info$size)
          stop("PRIVATE_REPORT_HOLD: fixed report changed")
        lo_drive_text_safe(bytes,basename(p))
        # Never pass personal local file paths through summary reports.
        if(grepl("[A-Za-z]:[/\\\\]Users[/\\\\]",rawToChar(bytes),ignore.case=TRUE))
          stop("PRIVATE_REPORT_HOLD: path exposed by fixed status")
        safe <- c(safe,p)
      }
      # Full scientific aggregate result ledgers are private, NOT GitHub
      # release assets. These are exact producer-created file names with
      # reviewed aggregate-only schemas; never recurse into arbitrary caches.
      private_files <- list(
        "PRIVATE_MASTER_GRID.csv"=c("cell_id","survey","country",
                 "year","estimate","standard_error","n_unweighted","status"),
        "PRIVATE_BATCH_PLAN.csv"=c("batch_id","n_cells","status"),
        "PRIVATE_GUIDED_VALIDATED_ROWS.csv"=c("figure_id","country",
                 "estimate","se","scientific_status"),
        "PRIVATE_GUIDED_MAPPING_HOLDS.csv"=c("cell_id","figure_id","reason"),
        "PRIVATE_GRID_MATCH_STATUS.csv"=c("metric_key","status",
                 "approved_to_compute"),
        "PRIVATE_ARCHIVE_EVIDENCE.csv"=c("metric_key","source_kind",
                 "estimate","se","n_unweighted","scientific_status"),
        "PRIVATE_V8_V9_CANDIDATE_MATCH.csv"=c("metric_key",
                 "archive_v8_v9_coarse_candidate"),
        "PRIVATE_FIXED_COMPARATOR_POINTS.csv"=c("focus_country",
                 "point_mean","status"),
        "PRIVATE_ACTIVE_CELL_GAPS.csv"=c("cell_id","decision"))
      cover <- list()
      for(rel in names(private_files)) {
        p <- if(rel%in%c("PRIVATE_GRID_MATCH_STATUS.csv",
                        "PRIVATE_ARCHIVE_EVIDENCE.csv",
                        "PRIVATE_V8_V9_CANDIDATE_MATCH.csv"))
          file.path(base,"FINAL_FIXED_PIPELINE",rel)
        else file.path(base,rel)
        if(!file.exists(p)) {
          cover[[length(cover)+1L]] <- data.frame(file=rel,
              status="MISSING_NOT_BACKED_UP",bytes=0)
          next
        }
        sz <- file.info(p)$size
        if(!is.finite(sz) || sz>min(maxbytes,64*1024^2)) {
          cover[[length(cover)+1L]] <- data.frame(file=rel,
              status="OVERSIZE_NOT_BACKED_UP",bytes=as.numeric(sz))
          next
        }
        headers <- tryCatch(names(read.csv(p,nrows=0,
                   check.names=FALSE)),error=function(e)character())
        if(!all(private_files[[rel]]%in%headers) ||
           any(grepl("(^|_)(student_id|pupil_id|respondent_id|school_id|raw_data)",
                     headers,ignore.case=TRUE)))
          stop("PRIVATE_REPORT_HOLD: unreviewed aggregate schema: ",rel)
        bytes <- readBin(p,what="raw",n=as.integer(sz)+1L)
        if(length(bytes)!=sz)stop("PRIVATE_REPORT_HOLD: aggregate changed")
        lo_drive_text_safe(bytes,rel)
        # Private exact-grid provenance legitimately contains source paths.
        # These reviewed aggregate schemas remain private and secret-screened;
        # the public/status summaries above still forbid personal paths.
        safe <- c(safe,p)
        cover[[length(cover)+1L]] <- data.frame(file=rel,
             status="ELIGIBLE_PRIVATE_SHA_READBACK",bytes=as.numeric(sz))
      }
      if(length(cover)) {
        coverage <- do.call(rbind,cover)
        coverage$scope <- scope
        covpath <- file.path(base,"PRIVATE_AGGREGATE_BACKUP_COVERAGE.csv")
        write.csv(coverage,covpath,row.names=FALSE)
        safe <- c(safe,covpath)
      }
    }
    safe
  }
  select_files <- function() {
    # A fixed-stage run must back up its actual output root and selected scope,
    # never rediscover an unrelated historical LO05 run from the old config.
    if(nzchar(fixed_scope)) {
      chosen<-lo_drive_fixed_reports()
      attr(chosen,'return_zip_status')<-'FIXED_SCOPE_AGGREGATES_ONLY'
      return(chosen)
    }
    chosen <- c(lo_drive_quota_report(),lo_drive_minimum_reports(),
                lo_drive_fixed_reports())
    d <- lo_drive_pick_run()
    if(!nzchar(d)) {
      cat("Drive run publication: no completed LO05 run found.\n")
      return(chosen)
    }
    zipfile <- file.path(d,"LEARNING_OUTCOMES_RETURN.zip")
    zip_hold <- tryCatch({
      lo_drive_zip_safe(zipfile)
      ""
    },error=function(e)conditionMessage(e))
    if(nzchar(zip_hold) &&
       !startsWith(zip_hold,"PRIVATE_REPORT_SIZE_HOLD:"))
      stop(zip_hold) # unknown members, secrets, changed content: fail closed.
    files <- file.path(d,lo_drive_named_reports())
    files <- files[file.exists(files)]
    result_export <- file.path(d,"PRIVATE_RESULT_EXPORT",
                                "LO02_NEW_RESULT_ROWS.csv")
    if(result_export %in% files) {
      gate <- file.path(d,"PRIVATE_RESULT_EXPORT","LO02_EXPORT_STATUS.csv")
      if(!file.exists(gate))stop("PRIVATE_REPORT_HOLD: result export gate absent")
      g <- read.csv(gate,stringsAsFactors=FALSE)
      if(nrow(g)!=1L ||
         !identical(g$status[[1L]],"PRIVATE_REVIEW_ONLY_EXACT_RUN_MATCH") ||
         !identical(g$scientific_release[[1L]],"NOT_GRANTED") ||
         as.integer(g$matched_new_results[[1L]])!=
            as.integer(g$expected_new_results[[1L]]))
        stop("PRIVATE_REPORT_HOLD: result export not exact-run approved")
    }
    if(!length(files) && nzchar(zip_hold))
      stop("PRIVATE_REPORT_HOLD: no small reviewed reports for partial return")
    # A bounded oversize archive stays local and is NOT copied. Publish only
    # separately verified, safe text reports with an explicit PARTIAL receipt;
    # this lets the scientific counts be reviewed without a new pupil run.
    if(!nzchar(zip_hold)) files <- c(zipfile,files)
    if(nzchar(zip_hold))
      cat("Drive partial return: full ZIP HELD by size policy; ",
          "publishing individually screened reports only. ",
          zip_hold,"\n",sep="")
    for(p in files) {
      n <- normalizePath(p,winslash="/",mustWork=TRUE)
      expected_prefix <- paste0(normalizePath(file.path(root,"runs"),
                                                 winslash="/",mustWork=TRUE),"/")
      if(!startsWith(n,expected_prefix))
        stop("PRIVATE_REPORT_HOLD: path outside results/runs")
      link <- Sys.readlink(p)
      if(length(link)==1L && !is.na(link) && nzchar(link))
        stop("PRIVATE_REPORT_HOLD: symlinked report not allowed")
      info <- file.info(p)
      if(is.na(info$size)||info$size>min(maxbytes,64*1024^2))
        stop("PRIVATE_REPORT_HOLD: oversized report: ",basename(p))
      if(tolower(tools::file_ext(p))!="zip") {
        bytes <- readBin(p,what="raw",n=as.integer(info$size)+1L)
        if(length(bytes)!=info$size)
          stop("PRIVATE_REPORT_HOLD: report changed: ",basename(p))
        lo_drive_text_safe(bytes,basename(p))
      }
    }
    cat("Drive selection: completed ",basename(d),"; ",
        length(files)," reviewed report files (ZIP included).\n",sep="")
    selected <- unique(c(chosen,files))
    attr(selected,"return_zip_status") <-
      if(nzchar(zip_hold))"PARTIAL_OVERSIZE_HELD" else "FULL_REVIEWED"
    attr(selected,"zip_size_hold") <- zip_hold
    selected
  }
  publish_once <- function() {
    ff <- select_files()
    return_zip_status <- attr(ff,"return_zip_status")
    if(is.null(return_zip_status))return_zip_status <- "NO_COMPLETED_RUN"
    zip_size_hold <- attr(ff,"zip_size_hold")
    if (!length(ff)) {
      cat("Drive sync: no eligible completed result summaries; nothing uploaded.\n")
      return(invisible(list(selected=0L,uploaded=0L)))
    }
    records <- list()
    for (p in ff) {
      relative <- substring(p,nchar(root)+2L)
      before <- file.info(p)
      hash <- digest::digest(file=p,algo="sha256")
      after <- file.info(p)
      if (!identical(before$size,after$size) || !identical(before$mtime,after$mtime))
        stop("File changed during hashing: ",relative)
      records[[length(records)+1L]] <- list(
        path=gsub("\\\\","/",relative),sha256=hash,
        bytes=unname(as.numeric(after$size)),
        # Copying an older artifact does not make this sync revision its
        # producer. Scientific provenance stays in the artifact/run records.
        sync_git_commit=producer_commit,
        scientific_status="NOT_AUTOMATICALLY_VALIDATED",
        source=p,
        report_path=if(grepl("^runs/run_[0-9]{8}_[0-9]{6}/",relative))
          sub("^runs/","reports/",gsub("\\\\","/",relative))
        else if(startsWith(relative,"master_reconciliation/MINIMUM_FIGURE_QUEUE/"))
          paste0("reports/minimum_figures/",basename(relative))
        else if(grepl("^FIXED_PRODUCTION_V1/(nld_only|nld_plus_19|all_required)/",relative)) {
          parts <- strsplit(relative,"/",fixed=TRUE)[[1L]]
          paste0("reports/fixed_pipeline/",parts[[2L]],"/",basename(relative))
        }
        else "")
    }
    if (action=="preview") {
      cat("Drive preview: ",length(records)," eligible files; no upload.\n",sep="")
      for (rec in records) cat("  ",rec$path," (",rec$bytes," bytes)\n",sep="")
      return(invisible(list(selected=length(records),uploaded=0L)))
    }
    uploaded <- 0L
    for (rec in records) {
      p <- rec$source
      ext <- tolower(tools::file_ext(p))
      object <- paste0(remote,"/objects/",substr(rec$sha256,1,2),"/",rec$sha256,".",ext)
      # Copying to immutable object names preserves every earlier version.
      # Google Drive MD5 metadata may be absent or delayed. Verify actual
      # remote bytes by reading the object back and comparing SHA-256.
      lo_drive_run(exe,c("copyto",p,object))
      verify_file <- tempfile("lo_remote_verify_",fileext=paste0(".",ext))
      tryCatch({
        lo_drive_run(exe,c("copyto",object,verify_file))
        if (!identical(digest::digest(file=verify_file,algo="sha256"),rec$sha256))
          stop("Remote SHA-256 mismatch: ",rec$path)
      },finally=unlink(verify_file))
      if (!identical(digest::digest(file=p,algo="sha256"),rec$sha256))
        stop("Local file changed during transfer: ",rec$path)
      # Human-readable path, private only. The immutable SHA object above
      # remains the authoritative backup. No remote deletion/sync.
      if(nzchar(rec$report_path)) {
        named <- paste0(remote,"/",rec$report_path)
        lo_drive_run(exe,c("copyto",object,named))
        check_named <- tempfile("lo_named_report_verify_",
                                fileext=paste0(".",ext))
        tryCatch({
          lo_drive_run(exe,c("copyto",named,check_named))
          if(!identical(digest::digest(file=check_named,algo="sha256"),
                        rec$sha256))
            stop("Named Drive report SHA-256 mismatch: ",rec$report_path)
        },finally=unlink(check_named))
      }
      uploaded <- uploaded+1L
    }
    clean <- lapply(records,function(rec) rec[names(rec)!="source"])
    manifest <- list(schema_version="lo-rclone-r-v1",
      created_utc=format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC"),
      visibility="PRIVATE_ACCOUNT_ONLY",
      scientific_status="NOT_AUTOMATICALLY_VALIDATED",
      run_report_completeness=return_zip_status,
      zip_size_hold=if(is.null(zip_size_hold))"" else zip_size_hold,
      files=clean)
    manifestfile <- file.path(stage,"manifest_pending.json")
    jsonlite::write_json(manifest,manifestfile,auto_unbox=TRUE,pretty=TRUE)
    mh <- digest::digest(file=manifestfile,algo="sha256")
    id <- paste0(format(Sys.time(),"%Y%m%dT%H%M%SZ",tz="UTC"),"_",substr(mh,1,16))
    destination <- paste0(remote,"/manifests/",id,".json")
    lo_drive_run(exe,c("copyto",manifestfile,destination))
    verify_manifest <- tempfile("lo_remote_manifest_",fileext=".json")
    tryCatch({
      lo_drive_run(exe,c("copyto",destination,verify_manifest))
      if (!identical(digest::digest(file=verify_manifest,algo="sha256"),mh))
        stop("Remote manifest SHA-256 verification failed")
    },finally=unlink(verify_manifest))
    pointer <- file.path(stage,"pointer_pending.json")
    jsonlite::write_json(list(manifest=id,sha256=mh),pointer,auto_unbox=TRUE,pretty=TRUE)
    lo_drive_run(exe,c("copyto",pointer,paste0(remote,"/LATEST.json")))
    cat("Drive sync verified: ",uploaded," files; manifest ",id,
        "; run_report_completeness=",return_zip_status,"\n",sep="")
    if(identical(return_zip_status,"PARTIAL_OVERSIZE_HELD"))
      cat("NEXT: review private named STATUS, PLAN_COUNTS, PHASE_STATUS and ",
          "AANTALLEN. Full return ZIP was NOT uploaded. No calculation ",
          "or deletion occurred.\n")
    invisible(list(selected=length(records),uploaded=uploaded,
                   manifest=id,run_report_completeness=return_zip_status))
  }
  if (action=="watch") {
    interval <- if(is.null(cfg$watch_interval_seconds)) 180 else
      max(60,as.numeric(cfg$watch_interval_seconds))
    repeat {
      tryCatch(publish_once(),error=function(e)
        message("Drive sync held: ",conditionMessage(e)))
      Sys.sleep(interval)
    }
  }
  publish_once()
}
