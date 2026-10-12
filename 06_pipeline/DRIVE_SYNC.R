# Native R -> rclone -> private Google Drive, without Python.
# Never deletes local or remote files; never uploads raw microdata.
# Each completed artifact is addressed by SHA-256; pointer is published last.
lo_drive_run <- function(exe,args) {
  out <- suppressWarnings(system2(exe, shQuote(args),stdout=TRUE,stderr=TRUE))
  status <- attr(out,"status")
  if (!is.null(status) && status!=0L)
    stop("rclone failed (",status,"): ",paste(tail(out,12),collapse="\n"),call.=FALSE)
  out
}

lo_drive_sync <- function(config,action=c("publish","preview","watch"),rclone_override="",
                          producer_commit="UNKNOWN") {
  action <- match.arg(action)
  if (!requireNamespace("jsonlite",quietly=TRUE) ||
      !requireNamespace("digest",quietly=TRUE))
    stop("R packages jsonlite and digest are required for safe Drive sync")
  if (!file.exists(config)) stop("Drive config missing: ",config)
  cfg <- jsonlite::fromJSON(config,simplifyVector=TRUE)
  if (!identical(cfg$data_visibility,"PRIVATE_ACCOUNT_ONLY"))
    stop("Drive sync requires PRIVATE_ACCOUNT_ONLY")
  root <- normalizePath(cfg$local_results_root,winslash="/",mustWork=TRUE)
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
    "PHASE_OECD19/LO02_RELEASED_PISA_CORE_GENDER/AANTALLEN.csv"
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
      stop("PRIVATE_REPORT_HOLD: return ZIP exceeds 64 MiB")
    listing <- tryCatch(utils::unzip(zipfile,list=TRUE),
                        error=function(e)e)
    if(inherits(listing,"error") ||
       !all(c("Name","Length")%in%names(listing)))
      stop("PRIVATE_REPORT_HOLD: cannot inspect return ZIP")
    names <- as.character(listing$Name)
    if(!length(names) || length(names)>length(lo_drive_allowed_members()) ||
       anyDuplicated(names) ||
       any(!names%in%lo_drive_allowed_members()) ||
       !all(c("STATUS.txt","PHASE_STATUS.csv","PLAN_COUNTS.csv")%in%names))
      stop("PRIVATE_REPORT_HOLD: return ZIP has unknown, duplicate or missing members")
    sizes <- suppressWarnings(as.numeric(listing$Length))
    if(any(!is.finite(sizes)) || any(sizes<0) ||
       any(sizes>8*1024^2) || sum(sizes)>48*1024^2)
      stop("PRIVATE_REPORT_HOLD: ZIP member size exceeds reviewed report limits")
    for(i in seq_along(names)) {
      con <- tryCatch(unz(zipfile,names[[i]],open="rb"),
                      error=function(e)e)
      if(inherits(con,"error"))
        stop("PRIVATE_REPORT_HOLD: cannot open ZIP member: ",names[[i]])
      bytes <- tryCatch(readBin(con,what="raw",n=as.integer(sizes[[i]])+1L),
                        finally=close(con))
      if(length(bytes)!=sizes[[i]])
        stop("PRIVATE_REPORT_HOLD: member read size mismatch: ",names[[i]])
      lo_drive_text_safe(bytes,names[[i]])
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
  select_files <- function() {
    chosen <- lo_drive_quota_report()
    d <- lo_drive_pick_run()
    if(!nzchar(d)) {
      cat("Drive run publication: no completed LO05 run found.\n")
      return(chosen)
    }
    zipfile <- file.path(d,"LEARNING_OUTCOMES_RETURN.zip")
    lo_drive_zip_safe(zipfile)
    files <- file.path(d,lo_drive_named_reports())
    files <- files[file.exists(files)]
    files <- c(zipfile,files)
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
    unique(c(chosen,files))
  }
  publish_once <- function() {
    ff <- select_files()
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
        producer_git_commit=producer_commit,
        scientific_status="NOT_AUTOMATICALLY_VALIDATED",
        source=p,
        report_path=if(grepl("^runs/run_[0-9]{8}_[0-9]{6}/",relative))
          sub("^runs/","reports/",gsub("\\\\","/",relative)) else "")
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
    cat("Drive sync verified: ",uploaded," files; manifest ",id,"\n",sep="")
    invisible(list(selected=length(records),uploaded=uploaded,manifest=id))
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
