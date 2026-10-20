# Pure helpers; no data or registry writes outside per-run output folder.
lo4_require <- function(x) {
  missing <- x[!vapply(x, requireNamespace, logical(1), quietly=TRUE)]
  if(length(missing)) stop("Benodigde R-packages ontbreken: ", paste(missing,collapse=", "),call.=FALSE)
}
lo4_norm <- function(x) normalizePath(x,winslash="/",mustWork=FALSE)
lo4_hash <- function(x) digest::digest(x,algo="sha256",serialize=TRUE)
lo4_filehash <- function(p) unname(digest::digest(file=p,algo="sha256"))
lo4_chr <- function(x) {z<-as.character(x);z[is.na(z)]<-"";z}
lo4_read <- function(path,cols=NULL) {
  if(!file.exists(path))stop("Bestand ontbreekt: ",path,call.=FALSE)
  x<-withCallingHandlers(read.csv(path,colClasses="character",check.names=FALSE,
    na.strings=character(),stringsAsFactors=FALSE),warning=function(w)stop("CSV read warning: ",conditionMessage(w),call.=FALSE))
  if(!is.null(cols)&&!all(cols%in%names(x)))stop("Kolommen ontbreken in ",path,": ",paste(setdiff(cols,names(x)),collapse=","))
  x
}
lo4_csv <- function(x,path) {
  dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
  if(file.exists(path))stop("Weiger resultaat te overschrijven: ",path)
  tmp<-tempfile(paste0(basename(path),"_"),tmpdir=dirname(path))
  on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
  write.csv(x,tmp,row.names=FALSE,na="",fileEncoding="UTF-8")
  if(!file.rename(tmp,path))stop("Atomic CSV rename mislukt: ",path)
  invisible(path)
}
lo4_text <- function(x,path) {
  dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
  if(file.exists(path))stop("Weiger bestand te overschrijven: ",path)
  writeLines(x,path,useBytes=TRUE)
  invisible(path)
}
lo4_unique_run <- function(root) {
  dir.create(file.path(root,"runs"),recursive=TRUE,showWarnings=FALSE)
  label<-paste0("run_",format(Sys.time(),"%Y%m%d_%H%M%S"))
  for(i in 0:999L) {
    p<-file.path(root,"runs",if(i==0L)label else sprintf("%s_%03d",label,i))
    if(dir.create(p,recursive=FALSE,showWarnings=FALSE))return(lo4_norm(p))
  }
  stop("Geen vrije runmap gevonden")
}
lo4_disjoint <- function(output,roots) {
  x<-tolower(lo4_norm(output))
  for(r in roots) { y<-tolower(lo4_norm(r));if(identical(x,y)||startsWith(x,paste0(y,"/")))
    stop("Output mag niet binnen bron-/engine-opslag: ",output) }
}
lo4_config <- function(bundle) {
  path<-getOption("lo4.config_path",file.path(bundle,"LO04_CONFIG.R"))
  if(!file.exists(path))stop("Configuratie ontbreekt: ",path)
  cfg<-dget(path)
  # Explicit one-session overrides; source() starts in PLAN if no option is set.
  a<-getOption("lo05.action",NULL)
  if(!is.null(a))cfg$action<-a
  approval<-getOption("lo05.execute_approval",NULL)
  if(!is.null(approval))cfg$execute_approval<-identical(approval,TRUE)
  phase<-getOption("lo05.phase",NULL)
  if(!is.null(phase))cfg$production_phase<-phase
  mode<-getOption("lo05.mode",NULL)
  if(!is.null(mode))cfg$run_mode<-mode
  if(!is.list(cfg))stop("Configuratie moet een list zijn")
  required<-c("action","run_mode","production_phase","focus_country","project_root","lo02_root","output_root","reference_id","expected_reference_country_count","workers","delete_files","write_existing_project_registry","cache_inspection","execute_approval")
  if(!all(required%in%names(cfg)))stop("Configuratie mist: ",paste(setdiff(required,names(cfg)),collapse=","))
  if(!cfg$action%in%c("plan","windows_tests","scientific_smoke","execute_ready"))stop("Ongeldige action")
  if(!cfg$run_mode%in%c("NLD_ONLY","NLD_PLUS_OECD_PPP","OECD_PPP_ONLY","FULL_INTERNATIONAL","AUDIT_ALL"))stop("Ongeldige run_mode")
  if(!cfg$production_phase%in%c("NLD","OECD19","FULL"))stop("Ongeldige phase")
  if(!identical(cfg$focus_country,"NLD")||!identical(cfg$expected_reference_country_count,19L))stop("Focus / referentiegroep gewijzigd")
  if(!identical(cfg$reference_id,"OECD_PPP_GT_CZE_2024_RECONSTRUCTED"))stop("Referentie-id gewijzigd")
  if(!identical(cfg$workers,1L))stop("Eén SQLite writer vereist")
  if(!identical(cfg$delete_files,FALSE)||!identical(cfg$write_existing_project_registry,FALSE))stop("Bescherming centrale opslag/GC verplicht")
  if(!cfg$cache_inspection%in%c("metadata","semantic"))stop("cache_inspection ongeldig")
  if(cfg$action=="execute_ready"&&!identical(cfg$execute_approval,TRUE))
    stop("Execute vereist expliciete options(lo05.execute_approval=TRUE)")
  cfg
}
lo4_manifest_check <- function(bundle) {
  m<-lo4_read(file.path(bundle,"MANIFEST_SHA256.csv"),c("path","sha256"))
  if(anyDuplicated(m$path))stop("Dubbel manifestpad")
  for(i in seq_len(nrow(m))){p<-file.path(bundle,m$path[i]);if(!file.exists(p)||!identical(lo4_filehash(p),m$sha256[i]))
    stop("SOURCE_HASH_FAIL: ",m$path[i])}
  invisible(m)
}
lo4_keys <- c("country","survey","year","domain","module","stat","group","definition","peer_definition","threshold","unit","calculation_policy")
lo4_metric_key <- function(q) do.call(paste,c(q[lo4_keys],sep="|"))
lo4_assert_metric_keys <- function(q) {
  if(!all(c(lo4_keys,"metric_key")%in%names(q)))stop("Contract mist key columns")
  if(anyDuplicated(q$metric_key)||any(!nzchar(q$metric_key)))stop("Taakduplicaten of lege IDs")
  if(!identical(lo4_metric_key(q),as.character(q$metric_key)))stop("Metric key verschilt van semantische definitie")
}
lo4_safe_read_parquet <- function(path) {
  if(!file.exists(path))return(NULL)
  if(!requireNamespace("arrow",quietly=TRUE))return(NULL)
  as.data.frame(arrow::read_parquet(path,mmap=FALSE))
}
lo4_zip <- function(run,files,name="LO04_RETURN.zip") {
  files<-files[file.exists(file.path(run,files))]
  if(requireNamespace("zip",quietly=TRUE)) {
    res<-tryCatch(zip::zipr(file.path(run,name),files=files,root=run),error=function(e)e)
    if(inherits(res,"error"))warning("Return-ZIP mislukt: ",conditionMessage(res),"; losse rapporten zijn bewaard")
  } else warning("R-package 'zip' ontbreekt; losse retourbestanden zijn bewaard: ",run)
  if(!file.exists(file.path(run,name)))warning("Geen return-ZIP aanwezig, gebruik losse bestanden uit: ",run)
}

lo4_runner_code_fingerprint <- function(bundle) {
  p<-c(file.path(bundle,"LO04_GEINTEGREERDE_RUNNER.R"),
       list.files(file.path(bundle,"code"),pattern="\\.R$",full.names=TRUE))
  lo4_hash(vapply(sort(p),lo4_filehash,character(1)))
}
