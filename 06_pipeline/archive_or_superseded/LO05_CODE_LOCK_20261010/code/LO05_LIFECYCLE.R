# Automatische opruiming: uitsluitend aantoonbaar exacte duplicaten van historische
# RUN-EXPORTS, met minstens één byte-identieke behouden kopie. Nooit ruwe input,
# unieke resultversies, canonical caches, actieve stores of gepubliceerde producten.
lo5_is_within <- function(path,root) {
  path<-tolower(lo4_norm(path));root<-tolower(lo4_norm(root))
  identical(path,root)||startsWith(path,paste0(root,"/"))
}
lo5_gc_candidates <- function(cfg,consolidated,run) {
  root<-cfg$project_root
  keep_roots<-c(file.path(root,"00_PROJECT_REGISTRY"),file.path(root,"03_RESULTS"),
     file.path(root,"15_rc1_pisa_normalised"),file.path(root,"05_pirls_results"),
     file.path(root,"29_results_resume_v11/cache"),cfg$lo02_root,cfg$output_root)
  # Geen volledige Downloads-scans of grote bron-archieven hashen.
  scan_roots<-file.path(root,c("26_dashboard_fast_resumable/runs",
     "27_dashboard_multicountry_v9/runs","28_results_resume_v10/runs",
     "29_results_resume_v11/runs","23_slide_only_completion/runs"))
  scan_roots<-scan_roots[dir.exists(scan_roots)]
  files<-unique(unlist(lapply(scan_roots,function(r)
     list.files(r,recursive=TRUE,full.names=TRUE,pattern="\\.csv(\\.gz)?$",ignore.case=TRUE)),use.names=FALSE))
  if(!length(files))return(data.frame())
  files<-files[file.exists(files)]
  info<-file.info(files)
  pool<-data.frame(path=lo4_norm(files),bytes=as.numeric(info$size),stringsAsFactors=FALSE)
  pool<-pool[is.finite(pool$bytes)&pool$bytes>0,,drop=FALSE]
  pool<-pool[!vapply(pool$path,function(f)any(vapply(keep_roots,function(r)lo5_is_within(f,r),logical(1))),logical(1)),,drop=FALSE]
  # Alleen groepjes met identieke grootte komen voor een dure SHA256 in aanmerking.
  groups<-split(seq_len(nrow(pool)),pool$bytes)
  repeated<-unlist(groups[lengths(groups)>1L],use.names=FALSE)
  pool<-pool[repeated,,drop=FALSE]
  if(!nrow(pool))return(data.frame())
  pool$sha256<-vapply(pool$path,lo4_filehash,character(1))
  pool<-pool[duplicated(pool$sha256)|duplicated(pool$sha256,fromLast=TRUE),,drop=FALSE]
  if(!nrow(pool))return(data.frame())
  pool<-pool[order(pool$sha256,pool$path),,drop=FALSE]
  pool$keeper_path<-vapply(pool$sha256,function(s)sort(pool$path[pool$sha256==s])[1],character(1))
  pool$decision<-ifelse(pool$path==pool$keeper_path,"KEEP_VERIFIED_ORIGINAL","DELETE_ONLY_IF_UNREFERENCED")
  pool$reason<-"Same-byte SHA256 within historical run exports; unique caches and source stores excluded"
  pool
}
lo5_gc <- function(cfg,consolidated,run) {
  candidates<-lo5_gc_candidates(cfg,consolidated,run)
  if(!nrow(candidates)) {
    lo4_csv(data.frame(path=character(),sha256=character(),decision=character()),file.path(run,"GC_CANDIDATES.csv"))
    return(invisible(list(deleted=0L,bytes=0)))
  }
  lo4_csv(candidates,file.path(run,"GC_CANDIDATES.csv"))
  if(!identical(cfg$gc_policy,"auto_exact_duplicate_run_exports")||!isTRUE(consolidated$ok))
    return(invisible(list(deleted=0L,bytes=0)))
  # In geval van een onverwachte wijziging van de centrale stores of niet-geïmporteerde
  # bronnen is verwijdering verboden, ook wanneer een kopie elders bestaat.
  if(any(grepl("HOLD|FAIL",consolidated$migration$status)))return(invisible(list(deleted=0L,bytes=0)))
  # Bescherm alle paden waarop bestaande metadata/producten zouden kunnen wijzen.
  # Dit is conservatief: alleen dubbele oude exports, geen unieke berekeningen.
  idxpath<-file.path(cfg$output_root,"consolidated","RESULT_PROVENANCE.sqlite")
  db<-DBI::dbConnect(RSQLite::SQLite(),idxpath,flags=RSQLite::SQLITE_RO)
  on.exit(DBI::dbDisconnect(db),add=TRUE)
  used_paths<-DBI::dbGetQuery(db,"SELECT snapshot_path FROM source_snapshots")$snapshot_path
  # Een exact dubbele oude export is NIET verwijderbaar als een herkomstregister
  # het originele pad nog rechtstreeks gebruikt. Eerst zo'n verwijzing migreren.
  historical<-lo4_read(file.path(cfg$bundle_dir,"evidence/LO01_HISTORICAL_CANDIDATES.csv.gz"),c("source_file"))
  anchored<-unique(tolower(gsub("\\", "/", historical$source_file, fixed=TRUE)))
  log<-list()
  todel<-which(candidates$decision=="DELETE_ONLY_IF_UNREFERENCED")
  for(i in todel) {
    p<-candidates$path[i];k<-candidates$keeper_path[i];h<-candidates$sha256[i]
    status<-"SKIP_PROTECTED"
    if(!(p%in%used_paths) && !tolower(gsub("\\","/",p,fixed=TRUE))%in%anchored &&
       file.exists(p)&&file.exists(k)&&
        identical(lo4_filehash(p),h)&&identical(lo4_filehash(k),h)&&
        !grepl("MANIFEST|RELEASE|CURRENT|RESULT_HISTORY|BACKUP|MASTER",toupper(basename(p)))) {
      # Hard verwijderen alleen exact dubbel, met gecertificeerde bewaarde kopie.
      # Verificatie en log vóór enige volgende kandidaat.
      ok<-tryCatch(unlink(p)==0L,error=function(e)FALSE)
      status<-if(ok&&!file.exists(p))"DELETED_EXACT_DUPLICATE_KEEPER_VERIFIED" else "DELETE_FAILED"
    }
    log[[length(log)+1L]]<-data.frame(path=p,keeper=k,sha256=h,bytes=candidates$bytes[i],status=status,stringsAsFactors=FALSE)
  }
  z<-if(length(log))do.call(rbind,log) else data.frame(path=character(),keeper=character(),sha256=character(),bytes=numeric(),status=character())
  lo4_csv(z,file.path(run,"GC_DELETION_LOG.csv"))
  invisible(list(deleted=sum(z$status=="DELETED_EXACT_DUPLICATE_KEEPER_VERIFIED"),bytes=sum(z$bytes[z$status=="DELETED_EXACT_DUPLICATE_KEEPER_VERIFIED"])))
}
