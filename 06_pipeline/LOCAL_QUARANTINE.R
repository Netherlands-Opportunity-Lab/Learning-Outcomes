# Controlled local lifecycle, scoped ONLY to PISA_PIRLS_MASTER_PIPELINE.
# Stage requires prior approved manifest and both independent restore receipts.
# Quarantine is outside Downloads. Final deletion requires a separate opt-in.
lo_quarantine_run <- function(action=c("stage","restore","finalize")) {
  action <- match.arg(action)
  if (!requireNamespace("digest",quietly=TRUE)) stop("digest package required")
  home <- Sys.getenv("USERPROFILE",unset=path.expand("~"))
  root <- normalizePath(Sys.getenv("LO_MASTER_PROJECT_ROOT",
      file.path(home,"Downloads","PISA_PIRLS_MASTER_PIPELINE")),
      winslash="/",mustWork=TRUE)
  if (basename(root)!="PISA_PIRLS_MASTER_PIPELINE" &&
      Sys.getenv("LO_MASTER_CUSTOM_ROOT")!="YES")
    stop("Unexpected project root")
  state <- normalizePath(file.path(home,"Downloads","LO05_RESULTATEN",
    "master_reconciliation"),winslash="/",mustWork=TRUE)
  quarantine <- Sys.getenv("LO_QUARANTINE_ROOT",
      file.path(home,"Documents","PISA_LEARNING_OUTCOMES_QUARANTINE"))
  quarantine <- normalizePath(quarantine,winslash="/",mustWork=FALSE)
  downloads <- normalizePath(file.path(home,"Downloads"),winslash="/",
                             mustWork=TRUE)
  if (startsWith(quarantine,paste0(downloads,"/")) ||
      startsWith(quarantine,paste0(root,"/")) ||
      startsWith(root,paste0(quarantine,"/")))
    stop("Quarantine must be outside Downloads and project root")
  ledger <- file.path(state,"LOCAL_QUARANTINE_LEDGER.csv")
  template <- data.frame(relative_path=character(),sha256=character(),
    bytes=double(),staged_at_utc=character(),quarantine_path=character(),
    status=character(),stringsAsFactors=FALSE)
  current <- if(file.exists(ledger)) read.csv(ledger,stringsAsFactors=FALSE) else template
  # Refuse races with another cleanup process; never delete an active lock.
  lock <- file.path(state,"QUARANTINE_OPERATION.lock")
  if(file.exists(lock)) stop("Quarantine operation lock exists; manual review required")
  if(!file.create(lock))stop("Cannot acquire cleanup lock")
  on.exit(unlink(lock),add=TRUE)
  sha <- function(path) tolower(unname(digest::digest(file=path,algo="sha256")))
  safe_rel <- function(rel) {
    if(length(rel)!=1L || is.na(rel) || !nzchar(rel) ||
       grepl("(^/|^[A-Za-z]:|[\\\\]|(^|/)\\.\\.(/|$)|(^|/)\\.(/|$))",rel))
      stop("Unsafe relative path")
    p <- normalizePath(file.path(root,rel),winslash="/",mustWork=TRUE)
    if(!startsWith(p,paste0(root,"/")) ||
       nzchar(Sys.readlink(p)))stop("Outside project or symbolic link")
    p
  }
  persist <- function() {
    tmp <- tempfile(tmpdir=state)
    write.csv(current,tmp,row.names=FALSE)
    if(!file.copy(tmp,ledger,overwrite=TRUE))stop("Ledger save failed")
    unlink(tmp)
  }
  if(action=="stage") {
    approval <- file.path(state,"LOCAL_CLEANUP_APPROVED.csv")
    queue <- file.path(state,"LOCAL_CLEANUP_APPROVAL_QUEUE.csv")
    if(!file.exists(approval)||!file.exists(queue))
      stop("No approved manifest and candidate queue; nothing moved")
    a <- read.csv(approval,stringsAsFactors=FALSE)
    q <- read.csv(queue,stringsAsFactors=FALSE)
    required <- c("relative_path","sha256","approved")
    if(!all(required%in%names(a)))stop("Approval schema invalid")
    if(!all(c("relative_path","sha256")%in%names(q)))
      stop("Queue must contain checked SHA-256; refresh cleanup gate")
    a <- a[toupper(as.character(a$approved))=="YES",,drop=FALSE]
    if(!nrow(a)){cat("Quarantine: zero approved files\n");return(invisible(current))}
    if(anyDuplicated(a$relative_path))stop("Duplicate approvals")
    if(!all(paste(a$relative_path,a$sha256) %in%
            paste(q$relative_path,q$sha256)))stop("Approval not backed by verified queue")
    if(Sys.getenv("LO_ALLOW_QUARANTINE_MOVE")!="YES")
      stop("Set LO_ALLOW_QUARANTINE_MOVE=YES explicitly to stage")
    if(toupper(substr(root,1L,1L))!=toupper(substr(quarantine,1L,1L)))
      stop("Quarantine must be on same Windows volume for atomic rename")
    for(i in seq_len(nrow(a))) {
      rel <- as.character(a$relative_path[i])
      src <- safe_rel(rel)
      expected <- tolower(as.character(a$sha256[i]))
      if(!grepl("^[a-f0-9]{64}$",expected))stop("Bad SHA256 approval")
      if(sha(src)!=expected)stop("Source SHA changed; no move")
      if(rel%in%current$relative_path[current$status=="STAGED"])
        stop("Already staged: ",rel)
      dst <- file.path(quarantine,rel)
      dir.create(dirname(dst),recursive=TRUE,showWarnings=FALSE)
      if(file.exists(dst))stop("Quarantine destination already exists")
      bytes <- as.numeric(file.info(src)$size)
      if(!file.rename(src,dst))stop("Atomic move failed; source left unchanged")
      if(sha(dst)!=expected) {
        if(!file.rename(dst,src))stop("Post-move SHA failed; restore manually")
        stop("Post-move SHA mismatch; source restored")
      }
      current <- rbind(current,data.frame(relative_path=rel,sha256=expected,
        bytes=bytes,staged_at_utc=format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC"),
        quarantine_path=dst,status="STAGED",stringsAsFactors=FALSE))
      persist()
      cat("STAGED AND VERIFIED:",rel,"\n")
    }
  } else if(action=="restore") {
    rel <- Sys.getenv("LO_RESTORE_RELATIVE_PATH","")
    i <- which(current$relative_path==rel & current$status=="STAGED")
    if(length(i)!=1L)stop("Specify one staged LO_RESTORE_RELATIVE_PATH")
    dst <- file.path(root,rel)
    src <- current$quarantine_path[i]
    if(file.exists(dst)||!file.exists(src)||sha(src)!=current$sha256[i])
      stop("Restore blocked: destination exists, source missing or hash mismatch")
    dir.create(dirname(dst),recursive=TRUE,showWarnings=FALSE)
    if(!file.rename(src,dst))stop("Restore rename failed")
    if(sha(dst)!=current$sha256[i])stop("Restored hash mismatch")
    current$status[i] <- "RESTORED";persist()
    cat("RESTORED AND VERIFIED:",rel,"\n")
  } else {
    if(Sys.getenv("LO_ALLOW_FINAL_DELETE")!="YES")
      stop("Final deletion requires LO_ALLOW_FINAL_DELETE=YES")
    days <- as.numeric(Sys.getenv("LO_QUARANTINE_RETENTION_DAYS","30"))
    if(!is.finite(days)||days<30)stop("Minimum retention is 30 days")
    for(i in which(current$status=="STAGED")) {
      age <- as.numeric(difftime(Sys.time(),
        as.POSIXct(current$staged_at_utc[i],format="%Y-%m-%dT%H:%M:%SZ",tz="UTC"),
        units="days"))
      if(!is.finite(age)||age<days)next
      p <- current$quarantine_path[i]
      if(!file.exists(p)||sha(p)!=current$sha256[i])stop("Final SHA check failed")
      # Do not finalize without independent receipt files still present.
      if(!file.exists(file.path(state,"INDEPENDENT_BACKUP_RESTORE_RECEIPTS.csv")) ||
         !file.exists(file.path(state,"VERIFIED_CLOUD_ARTIFACTS.csv")))
        stop("Backup receipt absent; final deletion blocked")
      if(!identical(Sys.getenv("LO_FINAL_DELETE_APPROVED_SHA"),current$sha256[i]))
        next
      unlink(p)
      if(file.exists(p))stop("Final delete failed")
      current$status[i] <- "FINALIZED";persist()
      cat("FINALIZED AFTER RETENTION:",current$relative_path[i],"\n")
    }
  }
  invisible(current)
}
lo_quarantine_run(Sys.getenv("LO_QUARANTINE_ACTION","stage"))
