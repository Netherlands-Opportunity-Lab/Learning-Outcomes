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
  # Only a narrowly defined aggregate quota summary is automatically eligible.
  # Existing run reports remain local until separately reviewed.
  select_files <- function() {
    p <- file.path(root,"master_reconciliation","CLOUD_QUOTA_AND_MIGRATION_LIMIT.csv")
    if (!file.exists(p)) return(character())
    p <- normalizePath(p,winslash="/",mustWork=TRUE)
    info <- file.info(p)
    if (is.na(info$size) || info$size > min(maxbytes, 65536) ||
        as.numeric(difftime(Sys.time(),info$mtime,units="secs")) < minage)
      return(character())
    z <- tryCatch(read.csv(p,stringsAsFactors=FALSE,check.names=FALSE),
                  error=function(e)NULL)
    expected <- c("account_visibility","quota_known","free_gib",
                  "estimated_priority_gib","raw_89gb_removable","reason")
    if (is.null(z) || !identical(names(z),expected) || nrow(z)!=1L ||
        !identical(as.character(z$account_visibility[[1]]),"PRIVATE_ACCOUNT_ONLY"))
      stop("Quota report schema/privacy gate failed")
    values <- unlist(z,use.names=FALSE)
    if (any(grepl("([A-Za-z]:[/\\\\]|/Users/|/home/|@|https?://|token|secret|password)",
                  as.character(values),ignore.case=TRUE)))
      stop("Quota report content safety gate failed")
    p
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
        source=p)
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
