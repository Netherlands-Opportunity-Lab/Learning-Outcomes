# SINGLE-RUNNER INTERNAL MODULE: stage-gated inventory/migration/retirement.
# Never invoked separately; 06_pipeline/RUN.R remains the only user-facing R entry.
# Source/project bytes are NOT sent to public Git. No deletion by default.

lo_master_init <- function() {
  home <- Sys.getenv("USERPROFILE", unset=path.expand("~"))
  root <- Sys.getenv("LO_MASTER_PROJECT_ROOT",
                     file.path(home,"Downloads","PISA_PIRLS_MASTER_PIPELINE"))
  if(!dir.exists(root))
    stop("Master storage root not available: ",root,
         ". Set LO_MASTER_PROJECT_ROOT to the actual 89-GB directory.")
  root <- normalizePath(root,winslash="/",mustWork=TRUE)
  if(!identical(basename(root),"PISA_PIRLS_MASTER_PIPELINE") &&
     !identical(Sys.getenv("LO_MASTER_CUSTOM_ROOT"),"YES"))
    stop("Refusing unrelated root; use LO_MASTER_CUSTOM_ROOT=YES only after review")
  resultdir<-file.path(home,"Downloads","LO05_RESULTATEN")
  if(!dir.exists(resultdir))
    dir.create(resultdir,recursive=TRUE,showWarnings=FALSE)
  state<-file.path(resultdir,"master_reconciliation")
  if(!dir.exists(state))
    dir.create(state,recursive=TRUE,showWarnings=FALSE)
  state<-normalizePath(state,winslash="/",mustWork=TRUE)
  if(startsWith(state,paste0(root,"/")))
    stop("Metadata/output must live OUTSIDE the source master directory")
  list(root=root,state=state,home=home,
       remote="lo_private:Learning-Outcomes-Private/Canonical-Results-v1")
}

lo_master_safe_rel <- function(path,root) {
  x <- normalizePath(path,winslash="/",mustWork=TRUE)
  if(!startsWith(x,paste0(root,"/")))
    stop("Source path escapes audited root: ",x)
  substring(x,nchar(root)+2L)
}

lo_master_class <- function(relative) {
  p <- tolower(gsub("\\\\","/",relative))
  name <- tolower(basename(p))
  ext <- paste0(".",tolower(tools::file_ext(name)))
  if(grepl("(^|/)([.]git|node_modules|[.]rproj[.]user)(/|$)",p))
    return("TOOL_OR_GIT_PROTECTED")
  if(ext%in%c(".sav",".zsav",".dta",".sas7bdat",".sas",".por",".xpt",
              ".dat",".sps",".spss",".rdata",".rda"))
    return("SOURCE_OR_MICRODATA_HOLD")
  if(grepl("(^|/)(raw|raw_data|data_raw|source_data|microdata|input_microdata)(/|$)",p))
    return("SOURCE_OR_MICRODATA_HOLD")
  if(ext%in%c(".r",".rmd",".py",".sql",".do",".stan"))
    return("CODE_OR_METHOD_PROTECTED")
  if(ext%in%c(".pptx",".ppt",".pdf",".docx",".doc",".html",".svg",".png",".jpg"))
    return("PRODUCT_OR_EVIDENCE_PROTECTED")
  if(grepl("(^|/)(00_project_registry|03_results/history|03_results/current|release_registers)(/|$)",p)||
     name%in%c("current_results.parquet","result_history.parquet",
               "project_results_registry.sqlite","result_provenance.sqlite",
               "product_result_links.parquet"))
    return("CANONICAL_REGISTRY_PROTECTED")
  if(ext%in%c(".sqlite",".sqlite3",".db",".duckdb"))
    return("DATABASE_HOLD_LIVE_SNAPSHOT_REQUIRED")
  if(ext%in%c(".zip",".7z",".tar",".tgz",".rar",".gz") &&
     !grepl("([.]csv[.]gz$|[.]parquet[.]gz$)",name))
    return("ARCHIVE_OR_SOURCE_RIGHTS_REVIEW")
  if(grepl("([.]tmp$|[.]partial$|[.]lock$|[.]bak$|[.]old$|[.]sqlite-wal$|[.]sqlite-shm$)",p))
    return("SCRATCH_OR_BACKUP_REVIEW")
  if(grepl("(current_results|result_history|master_analysis|final_product_basis|resultaten_master)",
           name))
    return("CANONICAL_RESULT_PROTECTED")
  if(ext%in%c(".parquet",".rds",".fst",".feather",".csv",".tsv",".json",".rds.gz",
              ".qs",".rdata.gz") &&
     grepl("(cache|result|output|master|metric|figure|consolid|standardis|analyse|analysis|dashboard|final)",
           p))
    return("DERIVED_CANDIDATE_UNVERIFIED")
  if(ext%in%c(".csv",".tsv",".json",".rds",".parquet",".fst",".feather",".qs"))
    return("UNKNOWN_DATA_HOLD")
  if(ext%in%c(".txt",".log",".md",".yml",".yaml"))
    return("LOG_OR_DOCUMENT_PROTECTED")
  "UNKNOWN_FILE_HOLD"
}

lo_master_write_csv <- function(x,p) {
  dir.create(dirname(p),recursive=TRUE,showWarnings=FALSE)
  tmp <- tempfile("csv_atomic_",tmpdir=dirname(p))
  on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
  utils::write.csv(x,tmp,row.names=FALSE,na="",fileEncoding="UTF-8")
  if(!file.rename(tmp,p))stop("Atomic CSV save failed: ",p)
  invisible(p)
}
lo_master_write_text <- function(lines,p) {
  dir.create(dirname(p),recursive=TRUE,showWarnings=FALSE)
  tmp <- tempfile("txt_atomic_",tmpdir=dirname(p))
  on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
  writeLines(lines,tmp,useBytes=TRUE)
  if(!file.rename(tmp,p))stop("Atomic text save failed: ",p)
  invisible(p)
}

lo_master_files <- function(cfg) {
  # Metadata-only traversal; never open or rewrite student data in this pass.
  paths<-list.files(cfg$root,full.names=TRUE,recursive=TRUE,all.files=TRUE,
                    include.dirs=FALSE,no..=TRUE)
  if(!length(paths))
    stop("Master directory has no files; check for access restrictions")
  paths<-paths[vapply(paths,function(p)isTRUE(file.exists(p))&&
                                 !isTRUE(dir.exists(p)),logical(1))]
  if(!length(paths))stop("No readable file paths under master root")
  info<-vector("list",ceiling(length(paths)/1000))
  for(j in seq_along(info)) {
    idx<-seq.int((j-1L)*1000L+1L,min(j*1000L,length(paths)))
    info[[j]]<-file.info(paths[idx])
  }
  meta<-do.call(rbind,info)
  out<-data.frame(
    relative_path=vapply(paths,lo_master_safe_rel,character(1),root=cfg$root),
    bytes=as.numeric(meta$size),
    modified_utc=format(meta$mtime,"%Y-%m-%dT%H:%M:%SZ",tz="UTC"),
    classification=vapply(vapply(paths,lo_master_safe_rel,character(1),
                                  root=cfg$root),lo_master_class,character(1)),
    stringsAsFactors=FALSE)
  out<-out[order(out$relative_path),,drop=FALSE]
  rownames(out)<-NULL
  if(anyDuplicated(out$relative_path))
    stop("Relative path collision in inventory")
  if(anyNA(out$bytes)||any(out$bytes<0))
    warning("Unreadable file metadata in inventory; those files are held")
  out
}
lo_master_registry_schema_audit <- function(cfg,files) {
  targets <- files[grepl("[.](sqlite|db|sqlite3)$",files$relative_path,
                         ignore.case=TRUE),,drop=FALSE]
  findings<-list()
  if(!nrow(targets))return(invisible(NULL))
  for(i in seq_len(nrow(targets))) {
    relative<-targets$relative_path[i]
    if(!requireNamespace("RSQLite",quietly=TRUE) ||
       !requireNamespace("DBI",quietly=TRUE)) {
      findings[[length(findings)+1L]]<-data.frame(
        relative_path=relative,table="NOT_INSPECTED",
        column_names="RSQLITE_NOT_INSTALLED",
        row_version_and_source_lineage="UNVERIFIED")
      next
    }
    p<-file.path(cfg$root,relative)
    con<-tryCatch(DBI::dbConnect(RSQLite::SQLite(),dbname=p,
                                flags=1L),error=function(e)NULL)
    if(is.null(con)) {
      findings[[length(findings)+1L]]<-data.frame(
        relative_path=relative,table="OPEN_READONLY_FAILED",
        column_names="DATABASE_LOCK_OR_SCHEMA_ERROR",
        row_version_and_source_lineage="UNVERIFIED")
      next
    }
    tryCatch({
      tabs<-tryCatch(DBI::dbListTables(con),error=function(e)character())
      for(tab in tabs) {
        fields<-tryCatch(DBI::dbListFields(con,tab),
                         error=function(e)character())
        k<-tolower(fields)
        complete<-any(grepl("result_version|record_version",k)) &&
           any(grepl("source.*sha|input.*hash|source.*fingerprint",k)) &&
           any(grepl("code.*sha|producer.*sha|code.*fingerprint",k))
        findings[[length(findings)+1L]]<-data.frame(
          relative_path=relative,table=tab,
          column_names=paste(fields,collapse=";"),
          row_version_and_source_lineage=if(complete)
            "CANDIDATE_REQUIRES_ROW_LEVEL_VALIDATION" else
            "MISSING_EXPLICIT_PRODUCER_OR_INPUT_VERSION_COLUMN")
      }
    },finally=DBI::dbDisconnect(con))
  }
  if(length(findings))
    lo_master_write_csv(do.call(rbind,findings),
                        file.path(cfg$state,"SQLITE_SCHEMA_LINEAGE_AUDIT.csv"))
  invisible(findings)
}

lo_master_inventory <- function(cfg) {
  files<-lo_master_files(cfg)
  file<-file.path(cfg$state,"MASTER_FILES_PRIVATE.csv")
  lo_master_write_csv(files,file)
  types<-aggregate(files$bytes,list(classification=files$classification),
                   function(x)sum(x,na.rm=TRUE))
  names(types)[2]<-"bytes"
  types$files<-as.integer(table(files$classification)[types$classification])
  types<-types[order(-types$bytes),,drop=FALSE]
  lo_master_write_csv(types,file.path(cfg$state,"MASTER_CLASS_SIZE_COUNTS.csv"))
  top<-data.frame(relative_path=files$relative_path,bytes=files$bytes,
                  classification=files$classification)
  top<-head(top[order(-top$bytes),,drop=FALSE],50L)
  lo_master_write_csv(top,file.path(cfg$state,"LARGEST_50_FILES_PRIVATE.csv"))
  first<-vapply(strsplit(files$relative_path,"/",fixed=TRUE),
                function(x)if(length(x))x[[1L]]else"",character(1))
  byfolder<-aggregate(files$bytes,list(top_level_folder=first),
                      function(x)sum(x,na.rm=TRUE))
  names(byfolder)[2]<-"bytes"
  byfolder<-byfolder[order(-byfolder$bytes),,drop=FALSE]
  lo_master_write_csv(byfolder,file.path(cfg$state,"TOP_LEVEL_FOLDER_BYTES.csv"))
  tryCatch(lo_master_registry_schema_audit(cfg,files),
    error=function(e)warning("Read-only SQLite schema audit held: ",conditionMessage(e)))
  stat<-c("STATUS=MASTER_INVENTORY_COMPLETE",
          "SCIENTIFIC_RELEASE=NOT_GRANTED",
          paste0("STORAGE_FILES_SCANNED=",nrow(files)),
          paste0("STORAGE_BYTES_SCANNED=",format(sum(files$bytes,na.rm=TRUE),
                                     scientific=FALSE,trim=TRUE)),
          paste0("STORAGE_MIB_SCANNED=",round(sum(files$bytes,na.rm=TRUE)/2^20)),
          paste0("STORAGE_UNCLASSIFIED_FILES=",sum(grepl("UNKNOWN",files$classification))),
          "CENTRAL_PROJECT_STORAGE_CHANGED=FALSE",
          "AUTOMATIC_GC_PERFORMED=FALSE",
          "NEXT=REVIEW_CATALOGUE_BEFORE_MIGRATION")
  lo_master_write_text(stat,file.path(cfg$state,"MASTER_INVENTORY_STATUS.txt"))
  cat("Master audit: ",nrow(files)," files, ",
      format(round(sum(files$bytes,na.rm=TRUE)/2^30,2),nsmall=2),
      " GiB. No file content read, uploaded or deleted.\n",sep="")
  invisible(files)
}

lo_master_load_files <- function(cfg) {
  p<-file.path(cfg$state,"MASTER_FILES_PRIVATE.csv")
  if(!file.exists(p))
    stop("Run LO_ACTION=storage-audit first. No implicit 89-GB rescan.")
  read.csv(p,stringsAsFactors=FALSE,check.names=FALSE,
           colClasses=c(relative_path="character",
                        classification="character"),na.strings="")
}

lo_master_plan <- function(cfg) {
  rows<-lo_master_load_files(cfg)
  # Conservative: derived files need source/method parity review before
  # scientific promotion, but are eligible for *private archival copies*.
  canonical<-rows$classification%in%
    c("CANONICAL_REGISTRY_PROTECTED","CANONICAL_RESULT_PROTECTED")
  derived<-rows$classification=="DERIVED_CANDIDATE_UNVERIFIED"
  exts<-tolower(tools::file_ext(rows$relative_path))
  binary_safe<-exts%in%c("parquet","rds","csv","tsv","json","feather",
                        "fst","qs")
  raw_risk<-grepl("(^|/)(student|students|raw|microdata|source|input)(/|$)",
                  tolower(rows$relative_path))
  live_db<-exts%in%c("sqlite","sqlite3","db","duckdb")
  classify<-rep("HOLD_REQUIRE_ORIGINAL_AND_RIGHTS_REVIEW",nrow(rows))
  classify[canonical&!live_db&!raw_risk]<-"PRIORITY_PRIVATE_BACKUP"
  classify[derived&binary_safe&!raw_risk]<-"CANDIDATE_PRIVATE_BACKUP_AFTER_REVIEW"
  classify[live_db]<-"HOLD_DB_SNAPSHOT_REQUIRED"
  classify[grepl("SOURCE|MICRODATA",rows$classification)]<-
    "HOLD_SOURCE_NOT_FOR_AUTOMATIC_CLOUD_TRANSFER"
  classify[rows$classification=="CODE_OR_METHOD_PROTECTED"]<-
    "GIT_HISTORY_NOT_AUTO_REMOVABLE"
  classify[rows$classification=="PRODUCT_OR_EVIDENCE_PROTECTED"]<-
    "PIN_PRODUCT_SHA_FIRST"
  classify[rows$classification=="SCRATCH_OR_BACKUP_REVIEW"]<-
    "CLEANUP_REVIEW_ONLY"
  classify[rows$classification=="ARCHIVE_OR_SOURCE_RIGHTS_REVIEW"]<-
    "HOLD_ARCHIVE_UNKNOWN_CONTENT"
  classify[rows$classification=="UNKNOWN_DATA_HOLD"]<-
    "HOLD_UNCLASSIFIED_DATA"
  rows$storage_action<-classify
  rows$producer_code_sha256<-"UNKNOWN"
  rows$source_data_sha256<-"UNKNOWN"
  rows$scientific_use_status<-"NEEDS_SCIENTIFIC_VALIDATION"
  rows$cloud_status<-"NOT_UPLOADED"
  rows$can_delete_local<-"NO"
  lo_master_write_csv(rows,file.path(cfg$state,"MASTER_STORAGE_ACTION_PLAN.csv"))
  cat("Storage plan: ",sum(classify=="PRIORITY_PRIVATE_BACKUP"),
      " priority aggregate files; ",
      sum(classify=="CANDIDATE_PRIVATE_BACKUP_AFTER_REVIEW"),
      " derived candidates; deletion always blocked at this stage.\n",sep="")
  invisible(rows)
}

lo_master_rclone <- function(cfg, args, fail=TRUE) {
  if(!exists("lo_pipeline_find_rclone",mode="function"))
    stop("Only invoke through the single 06_pipeline/RUN.R runner")
  exe<-lo_pipeline_find_rclone()
  if(length(args)<1L)stop("Empty rclone operation")
  out<-suppressWarnings(system2(exe,shQuote(args),stdout=TRUE,stderr=TRUE))
  code<-attr(out,"status");if(is.null(code))code<-0L
  if(fail && code!=0L)
    stop("rclone operation failed (",code,"): ",
         paste(tail(out,8),collapse=" / "),call.=FALSE)
  list(code=as.integer(code),text=out)
}

lo_master_quota <- function(cfg) {
  result<-lo_master_rclone(cfg,c("about","lo_private:","--json"),fail=FALSE)
  if(result$code!=0L||!requireNamespace("jsonlite",quietly=TRUE))
    return(list(known=FALSE,free=NA_real_,reason="PROVIDER_QUOTA_UNAVAILABLE"))
  x<-tryCatch(jsonlite::fromJSON(paste(result$text,collapse="")),
              error=function(e)NULL)
  if(is.null(x)||is.null(x$free)||!is.finite(as.numeric(x$free)))
    return(list(known=FALSE,free=NA_real_,
                reason="PROVIDER_QUOTA_UNAVAILABLE"))
  list(known=TRUE,free=as.numeric(x$free),reason="OK")
}

lo_master_readback_sha <- function(cfg,remote,expected_sha) {
  if(!requireNamespace("digest",quietly=TRUE))
    stop("Package digest required for SHA-256 object verification")
  tmp<-tempfile("lo_verify_",tmpdir=cfg$state)
  on.exit(unlink(tmp),add=TRUE)
  lo_master_rclone(cfg,c("copyto",remote,tmp))
  actual<-unname(digest::digest(file=tmp,algo="sha256"))
  if(!identical(actual,expected_sha))
    stop("REMOTE_CONTENT_SHA256_MISMATCH: ",remote)
  invisible(TRUE)
}

lo_master_migrate <- function(cfg) {
  if(!requireNamespace("digest",quietly=TRUE))
    stop("Package digest required for SHA-256 migration")
  planfile<-file.path(cfg$state,"MASTER_STORAGE_ACTION_PLAN.csv")
  if(!file.exists(planfile))stop("Run storage-plan after storage-audit first")
  plan<-read.csv(planfile,stringsAsFactors=FALSE)
  allowed<-plan[plan$storage_action=="PRIORITY_PRIVATE_BACKUP",,drop=FALSE]
  if(!nrow(allowed)) {
    cat("No automatically eligible priority aggregate backups.\n")
    return(invisible(NULL))
  }
  limitgb<-suppressWarnings(as.numeric(Sys.getenv("LO_CLOUD_BATCH_GIB","1")))
  if(!is.finite(limitgb)||limitgb<=0||limitgb>10)
    stop("LO_CLOUD_BATCH_GIB must be between 0 and 10 for a controlled batch")
  remaining<-limitgb*2^30
  quota<-lo_master_quota(cfg)
  if(!quota$known)
    stop("Drive free-space quota unavailable; refusing to upload without it")
  if(quota$free < min(remaining,sum(allowed$bytes,na.rm=TRUE))+128*2^20)
    stop("Drive has insufficient free quota for this migration batch")
  receipt_path<-file.path(cfg$state,"VERIFIED_CLOUD_ARTIFACTS.csv")
  received<-if(file.exists(receipt_path))
    read.csv(receipt_path,stringsAsFactors=FALSE) else
    data.frame(relative_path=character(),bytes=double(),sha256=character(),
               remote_object=character(),verification=character(),
               producer_code_sha256=character(),
               source_data_sha256=character(),scientific_status=character(),
               stringsAsFactors=FALSE)
  done<-received$relative_path[received$verification=="READBACK_SHA256_PASS"]
  todo<-allowed[!allowed$relative_path%in%done &
       !is.na(allowed$bytes)&allowed$bytes>0,]
  todo<-todo[order(todo$bytes),,drop=FALSE]
  uploaded<-0L; bytes<-0
  for(i in seq_len(nrow(todo))) {
    rel<-todo$relative_path[i];size<-todo$bytes[i]
    if(size>remaining)next
    src<-file.path(cfg$root,rel)
    if(!file.exists(src)||dir.exists(src)||
       file.info(src)$size!=size)
      stop("File changed after inventory; rerun storage-audit: ",rel)
    before<-file.info(src)
    sha<-unname(digest::digest(file=src,algo="sha256"))
    ext<-tolower(tools::file_ext(src))
    key<-paste0(cfg$remote,"/objects/",substr(sha,1,2),"/",sha,".",ext)
    lo_master_rclone(cfg,c("copyto",src,key))
    lo_master_readback_sha(cfg,key,sha)
    after<-file.info(src)
    if(before$size!=after$size || before$mtime!=after$mtime ||
       !identical(sha,unname(digest::digest(file=src,algo="sha256"))))
      stop("Source changed during upload; refuse receipt: ",rel)
    row<-data.frame(relative_path=rel,bytes=size,sha256=sha,
      remote_object=paste0(substr(sha,1,2),"/",sha,".",ext),
      verification="READBACK_SHA256_PASS",
      producer_code_sha256="UNKNOWN_SOURCE_PRODUCER",
      source_data_sha256="UNKNOWN_INPUT_FINGERPRINT",
      scientific_status="ARCHIVED_NOT_VALIDATED",
      stringsAsFactors=FALSE)
    received<-rbind(received,row)
    lo_master_write_csv(received,receipt_path)
    uploaded<-uploaded+1L;bytes<-bytes+size;remaining<-remaining-size
    cat("Verified ",uploaded,": ",format(size/2^20,digits=4)," MiB; ",
        "SHA ",substr(sha,1,16),"...\n",sep="")
  }
  if(!uploaded)cat("No fitting priority files in selected batch; nothing uploaded.\n")
  # Private catalog only, never public GitHub; it contains relative file paths.
  if(nrow(received)>0L) {
    lo_master_rclone(cfg,c("copyto",receipt_path,
      paste0(cfg$remote,"/catalogue/VERIFIED_CLOUD_ARTIFACTS.csv")))
  }
  cat("Master migration: ",uploaded," SHA-256 readback-verified objects, ",
      format(round(bytes/2^20,1),nsmall=1)," MiB; ",
      "no local deletions.\n",sep="")
  invisible(received)
}

lo_master_gc_plan <- function(cfg) {
  data<-lo_master_load_files(cfg)
  receipts<-file.path(cfg$state,"VERIFIED_CLOUD_ARTIFACTS.csv")
  cloud<-if(file.exists(receipts))
    read.csv(receipts,stringsAsFactors=FALSE) else
    data.frame(relative_path=character(),sha256=character(),
               verification=character())
  eligible<-data$relative_path%in%
    cloud$relative_path[cloud$verification=="READBACK_SHA256_PASS"]
  # Product pins, source archives, active registries, DBs and unknown families
  # are NEVER auto-retired merely because one Drive copy exists.
  candidates<-eligible & data$classification=="DERIVED_CANDIDATE_UNVERIFIED"
  reasons<-ifelse(candidates,"HOLD_SECOND_BACKUP_AND_PRODUCT_LINEAGE",
    "HOLD_ORIGINAL_OR_UNVERIFIED")
  plan<-data.frame(relative_path=data$relative_path,bytes=data$bytes,
                   classification=data$classification,
                   cloud_verified=eligible,retirement_status=reasons,
                   can_delete_now=FALSE,stringsAsFactors=FALSE)
  lo_master_write_csv(plan,file.path(cfg$state,"MASTER_RETIREMENT_PLAN.csv"))
  cat("Retirement plan: ",sum(candidates)," possible future candidates, ",
      "zero authorized deletions. Independent backup, tested restore and ",
      "complete product/result-version closure still required.\n",sep="")
  invisible(plan)
}

lo_master_share_reports <- function(cfg) {
  # Only to the existing owner-controlled, non-public Google Drive.
  # Full relative metadata list may contain sensitive file names; never Git.
  paths <- file.path(cfg$state,c(
    "MASTER_INVENTORY_STATUS.txt",
    "MASTER_CLASS_SIZE_COUNTS.csv",
    "TOP_LEVEL_FOLDER_BYTES.csv",
    "LARGEST_50_FILES_PRIVATE.csv",
    "MASTER_STORAGE_ACTION_PLAN.csv",
    "MASTER_FILES_PRIVATE.csv",
    "MASTER_RETIREMENT_PLAN.csv",
    "SQLITE_SCHEMA_LINEAGE_AUDIT.csv"))
  for(path in paths) {
    if(!file.exists(path)||is.na(file.info(path)$size)||
       file.info(path)$size>35*2^20)next
    target<-paste0(cfg$remote,"/migration-reports/",basename(path))
    tryCatch({
      lo_master_rclone(cfg,c("copyto",path,target))
      if(requireNamespace("digest",quietly=TRUE)) {
        digest<-unname(digest::digest(file=path,algo="sha256"))
        lo_master_readback_sha(cfg,target,digest)
      } else {
        warning("digest not available; report SHA could not be verified")
      }
    },error=function(e)
      warning("Private report not uploaded: ",basename(path),": ",
              conditionMessage(e),call.=FALSE))
  }
  invisible(TRUE)
}

lo_master_record_run_status <- function(cfg,action,result=NULL) {
  root<-file.path(cfg$state,"..","runs")
  dir.create(root,recursive=TRUE,showWarnings=FALSE)
  p<-file.path(root,paste0("run_",format(Sys.time(),"%Y%m%d_%H%M%S")))
  if(!dir.create(p,recursive=TRUE,showWarnings=FALSE))
    stop("Could not create local run status directory")
  n <- file.path(cfg$state,"MASTER_FILES_PRIVATE.csv")
  count<-if(file.exists(n))nrow(utils::read.csv(n,stringsAsFactors=FALSE))else 0L
  size <- if(file.exists(n))sum(utils::read.csv(n,colClasses=c("NULL","numeric","NULL","NULL"))$bytes,
                                 na.rm=TRUE)else 0
  status<-c(paste0("STATUS=",switch(action,
      "storage-audit"="STORAGE_INVENTORY_COMPLETE",
      "storage-plan"="STORAGE_PLAN_READY",
      "storage-migrate"="STORAGE_MIGRATION_ATTEMPTED",
      "storage-retirement-plan"="STORAGE_RETIREMENT_HELD",
      "STORAGE_ACTION_EXECUTED")),
    "SCIENTIFIC_RELEASE=NOT_GRANTED",
    paste0("STORAGE_FILES_SCANNED=",count),
    paste0("STORAGE_MIB_SCANNED=",round(size/2^20)),
    "CENTRAL_PROJECT_STORAGE_CHANGED=FALSE",
    "AUTOMATIC_GC_PERFORMED=FALSE")
  lo_master_write_text(status,file.path(p,"STATUS.txt"))
  invisible(p)
}

lo_master_action <- function(action) {
  cfg<-lo_master_init()
  if(identical(action,"storage-cleanup-apply"))
    stop("DELETION_SAFETY_HOLD: no independently verified restore and ",
         "complete product-result provenance receipt; no deletion permitted.")
  result<-switch(action,
    "storage-audit"=lo_master_inventory(cfg),
    "storage-plan"=lo_master_plan(cfg),
    "storage-migrate"=lo_master_migrate(cfg),
    "storage-retirement-plan"=lo_master_gc_plan(cfg),
    stop("Unsupported storage action: ",action))
  lo_master_record_run_status(cfg,action,result)
  # Reports are metadata only; publication remains inside private Drive.
  tryCatch(lo_master_share_reports(cfg),
    error=function(e)warning("Private report sharing held: ",
                             conditionMessage(e),call.=FALSE))
  invisible(result)
}
