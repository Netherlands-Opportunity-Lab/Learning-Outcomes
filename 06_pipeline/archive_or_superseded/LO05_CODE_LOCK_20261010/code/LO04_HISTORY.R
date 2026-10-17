# Historical provenance bridge. ALL old repositories are opened read-only.
# No historical/current SQLite or Parquet path is created, written or migrated here.
lo4_references <- function(bundle) {
  old<-lo4_read(file.path(bundle,"REFERENTIE_ASSEMBLAGE.csv.gz"))
  q<-old[old$reference=="OECD_GDP_PPP_GE_CZE_2024",,drop=FALSE]
  if(nrow(q)!=300L)stop("Oorspronkelijke 300 referentieseries ontbreken")
  m<-unique(q$eligible_members)
  if(length(m)!=1L)stop("Inconsistente referentiemembership")
  ge<-strsplit(m,";",fixed=TRUE)[[1]]
  if(length(ge)!=21L||!all(c("NLD","CZE")%in%ge)||anyDuplicated(ge))stop("Originele 21-member membership mismatch")
  strict<-setdiff(ge,"CZE");foreign<-setdiff(strict,"NLD")
  if(length(strict)!=20L||length(foreign)!=19L)stop("Referentiegroep != 19 buitenlandse landen")
  official<-lo4_read(file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"))
  got<-official$country[official$strictly_above_czechia=="TRUE"]
  if(!setequal(got,strict))stop("GDP statuslijst niet gelijk aan historische referentiecontract")
  list(contracts=q,all=strict,foreign=foreign,archive_status="MEMBERSHIP_ONLY_2024_WDI_RAW_SNAPSHOT_NOT_INCLUDED",
       countries=official)
}
lo4_reference_deps <- function(tasks,ref) {
  years<-strsplit(ref$contracts$years,";",fixed=TRUE)
  sig<-rep(ref$contracts$series_id,lengths(years))
  valid<-paste(sig,unlist(years,use.names=FALSE),sep="~YEAR~")
  cols<-c("survey","domain","module","stat","group","definition","peer_definition","threshold","unit","calculation_policy")
  key<-paste(do.call(paste,c(tasks[cols],sep="|")),tasks$year,sep="~YEAR~")
  key%in%valid
}
lo4_scope <- function(tasks,ref,cfg) {
  ok<-tasks$survey%in%cfg$surveys & tasks$domain%in%cfg$domains &
      tasks$year%in%as.character(cfg$waves)
  if(!identical(cfg$modules,"ALL_CONTRACT_MODULES"))ok<-ok & tasks$module%in%cfg$modules
  nl<-ok & tasks$country==cfg$focus_country
  foreign<-ok & tasks$country%in%ref$foreign & lo4_reference_deps(tasks,ref)
  phase<-rep("OUTSIDE_SCOPE",nrow(tasks))
  if(cfg$run_mode=="NLD_ONLY")phase[nl]<-"NLD"
  if(cfg$run_mode=="OECD_PPP_ONLY")phase[foreign]<-"OECD19"
  if(cfg$run_mode=="NLD_PLUS_OECD_PPP"){phase[nl]<-"NLD";phase[foreign]<-"OECD19"}
  if(cfg$run_mode%in%c("AUDIT_ALL","FULL_INTERNATIONAL")){phase[ok]<-"FULL";phase[nl]<-"NLD";phase[foreign]<-"OECD19"}
  if(cfg$run_mode=="OTHER_INTERNATIONAL")phase[ok & !nl & !foreign]<-"FULL"
  if(cfg$action=="execute_ready"){
    allowed<-switch(cfg$production_phase,NLD="NLD",OECD19="OECD19",FULL=c("NLD","OECD19","FULL"))
    if(cfg$production_phase=="FULL"&&cfg$run_mode!="FULL_INTERNATIONAL")stop("FULL productie vereist FULL_INTERNATIONAL run_mode")
    phase[!phase%in%allowed]<-"OUTSIDE_EXECUTION_PHASE"
  }
  tasks$phase<-phase
  tasks
}
lo4_char_frame <- function(x) { if(is.null(x))return(data.frame());as.data.frame(lapply(x,lo4_chr),stringsAsFactors=FALSE,check.names=FALSE) }
lo4_sqlite_snapshot <- function(path,tables) {
  if(!file.exists(path)||!requireNamespace("RSQLite",quietly=TRUE)||!requireNamespace("DBI",quietly=TRUE))
    return(list(status="NOT_READABLE",data=list(),integrity="NOT_CHECKED"))
  con<-tryCatch(DBI::dbConnect(RSQLite::SQLite(),path,flags=RSQLite::SQLITE_RO),error=function(e)e)
  if(inherits(con,"error"))return(list(status=paste0("READ_ONLY_OPEN_FAIL: ",conditionMessage(con)),data=list(),integrity="NOT_CHECKED"))
  on.exit(DBI::dbDisconnect(con),add=TRUE)
  integrity<-tryCatch(DBI::dbGetQuery(con,"PRAGMA integrity_check")[[1]],error=function(e)conditionMessage(e))
  tab<-DBI::dbListTables(con)
  ans<-list()
  for(n in intersect(tables,tab))ans[[n]]<-lo4_char_frame(DBI::dbReadTable(con,n))
  list(status="READ_ONLY",data=ans,integrity=integrity,tables=tab)
}
lo4_old_central <- function(root) {
  p<-file.path(root,"03_RESULTS/current/CURRENT_RESULTS.parquet")
  db<-file.path(root,"00_PROJECT_REGISTRY/PROJECT_RESULTS_REGISTRY.sqlite")
  cur<-tryCatch(lo4_safe_read_parquet(p),error=function(e)e)
  if(inherits(cur,"error"))return(list(status="CURRENT_PARQUET_READ_ERROR",detail=conditionMessage(cur),current=data.frame(),sqlite=list()))
  if(is.null(cur)){
    csvgz<-file.path(root,"03_RESULTS/current/CURRENT_RESULTS.csv.gz")
    cur<-if(file.exists(csvgz))lo4_read(csvgz) else data.frame()
  }
  cur<-lo4_char_frame(cur)
  hp<-file.path(root,"03_RESULTS/history/RESULT_HISTORY.parquet")
  history<-lo4_char_frame(tryCatch(lo4_safe_read_parquet(hp),error=function(e)NULL))
  s<-lo4_sqlite_snapshot(db,c("lifecycle_current_result_index","lifecycle_result_versions","lifecycle_product_result_links"))
  status<-"CENTRAL_PRESENT_UNVERIFIED"
  if(nrow(cur)&&all(c("metric_key","record_version_id")%in%names(cur))&&
     !anyDuplicated(cur$metric_key) && identical(s$integrity,"ok")&&
     "lifecycle_current_result_index"%in%names(s$data)) {
    ix<-s$data$lifecycle_current_result_index
    if(all(c("metric_key","record_version_id")%in%names(ix)) &&
       nrow(ix)==nrow(cur) && !anyDuplicated(ix$metric_key)&&
       identical(unname(ix$record_version_id[match(cur$metric_key,ix$metric_key)]),unname(cur$record_version_id)))
      status<-"CENTRAL_CURRENT_MATCHES_SQLITE"
    else status<-"CENTRAL_SQLITE_CURRENT_MISMATCH"
  } else if(!nrow(cur)) status<-"CENTRAL_MISSING_OR_EMPTY"
  else if(!identical(s$integrity,"ok"))status<-"CENTRAL_SQLITE_NOT_VERIFIED"
  hstatus<-"HISTORY_FILE_NOT_READ"
  if(nrow(history)&&"record_version_id"%in%names(history)&&!anyDuplicated(history$record_version_id)&&
     "lifecycle_result_versions"%in%names(s$data)&&"record_version_id"%in%names(s$data$lifecycle_result_versions)){
     v<-s$data$lifecycle_result_versions
     hstatus<-if(nrow(v)==nrow(history)&&setequal(v$record_version_id,history$record_version_id))
       "CENTRAL_HISTORY_IDS_MATCH_SQLITE" else "CENTRAL_HISTORY_IDS_MISMATCH_SQLITE"
  }
  list(status=status,history_status=hstatus,detail="",current=cur,history=history,sqlite=s,path=p)
}
lo4_lo02_live <- function(lo02,bundle) {
  db<-file.path(lo02,"registry_v5","PROJECT_RESULTS_REGISTRY.sqlite")
  p<-file.path(lo02,"registry_v5","CURRENT_RESULTS.parquet")
  s<-lo4_sqlite_snapshot(db,c("results","analysis_inputs"))
  cur<-lo4_char_frame(tryCatch(lo4_safe_read_parquet(p),error=function(e)NULL))
  hist<-lo4_char_frame(tryCatch(lo4_safe_read_parquet(file.path(lo02,"registry_v5","RESULT_HISTORY.parquet")),error=function(e)NULL))
  stat<-"LO02_LIVE_UNAVAILABLE_ARCHIVE_ONLY"
  if(identical(s$integrity,"ok")&&"results"%in%names(s$data)){
    v<-s$data$results;now<-v[v$is_current=="1",,drop=FALSE]
    if(nrow(cur)&&nrow(now)==nrow(cur)&&
       all(c("record_version_id","metric_key")%in%names(cur))&&
       identical(sort(cur$record_version_id),sort(now$record_version_id)))stat<-"LO02_LIVE_SQLITE_PARQUET_MATCH"
    else stat<-"LO02_SQLITE_PARQUET_MISMATCH_NO_PROMOTION"
  }
  if(!nrow(cur)){
    cur<-lo4_read(file.path(bundle,"evidence/LO02_RETURN_20261010_CURRENT_RESULTS.csv.gz"))
    stat<-"LO02_ARCHIVED_RETURN_ONLY_READONLY"
  }
  list(status=stat,current=cur,history=hist,sqlite=s,live=(stat=="LO02_LIVE_SQLITE_PARQUET_MATCH"))
}
lo4_historical <- function(bundle) {
  x<-lo4_read(file.path(bundle,"evidence/LO01_HISTORICAL_CANDIDATES.csv.gz"))
  if(any(!nzchar(x$metric_key)))stop("Historisch overzicht bevat lege sleutel")
  x
}
lo4_join_status <- function(q,central,lo02,historic) {
  c<-central$current;l<-lo02$current
  if(!"metric_key"%in%names(c))c<-data.frame(metric_key=character())
  if(!"metric_key"%in%names(l))l<-data.frame(metric_key=character())
  # Historical records may contain several producers for one key. Retain all in evidence.
  hidx<-match(q$metric_key,historic$metric_key)
  cidx<-match(q$metric_key,c$metric_key)
  lidx<-match(q$metric_key,l$metric_key)
  nc<-!is.na(cidx);nl<-!is.na(lidx);nh<-!is.na(hidx)
  q$legacy_central_record_version<-if("record_version_id"%in%names(c))ifelse(nc,c$record_version_id[pmax(1,cidx)],"") else ""
  q$lo02_record_version<-if("record_version_id"%in%names(l))ifelse(nl,l$record_version_id[pmax(1,lidx)],"") else ""
  q$legacy_candidate_file<-ifelse(nh,historic$source_file[pmax(1,hidx)],"")
  q$legacy_producer_code_id<-ifelse(nh,historic$producer_code_id[pmax(1,hidx)],"")
  q$legacy_evidence_sha256<-ifelse(nh,historic$evidence_source_sha256[pmax(1,hidx)],"")
  q$history_status<-ifelse(nc,central$status,ifelse(nl,lo02$status,ifelse(nh,"LO01_CANDIDATE","NOT_FOUND")))
  q$planning_action<-"OUT_OF_SCOPE";q$planning_reason<-"NOT_SELECTED"
  sel<-q$phase%in%c("NLD","OECD19","FULL")
  q$planning_action[sel]<-"HOLD";q$planning_reason[sel]<-"NEEDS_SCIENTIFIC_ADAPTER_AND_INPUT_CHECK"
  q$planning_action[sel & nh]<-"REVIEW";q$planning_reason[sel & nh]<-"HISTORICAL_CANDIDATE_NEEDS_PROVENANCE_AND_DEFINITION_CHECK"
  q$planning_action[sel & nl]<-"REVIEW";q$planning_reason[sel & nl]<-"LO02_RESULT_PENDING_SCIENTIFIC_VALIDATION"
  q$planning_action[sel & nc]<-"REVIEW";q$planning_reason[sel & nc]<-"CENTRAL_RESULT_READ_ONLY_NEEDS_SCIENCE_IDENTITY_MATCH"
  if(central$status=="CENTRAL_SQLITE_CURRENT_MISMATCH"){
    q$planning_action[sel & nc]<-"HOLD";q$planning_reason[sel & nc]<-"CENTRAL_SQLITE_PARQUET_MISMATCH"
  }
  if(lo02$status=="LO02_SQLITE_PARQUET_MISMATCH_NO_PROMOTION"){
    q$planning_action[sel & nl & !nc]<-"HOLD";q$planning_reason[sel & nl & !nc]<-"LO02_SQLITE_PARQUET_MISMATCH"
  }
  # No cross-vintage automatic equivalence: equal metric_key/estimate is insufficient.
  q$provenance_decision<-ifelse(nc,"CENTRAL_EXISTING",ifelse(nl,"LO02_EXISTING",ifelse(nh,"LO01_HISTORIC_REVIEW","NONE")))
  q
}
lo4_write_sidecar <- function(q,central,lo02,historic,run) {
  if(!requireNamespace("DBI",quietly=TRUE)||!requireNamespace("RSQLite",quietly=TRUE))return("SIDECAR_NOT_WRITTEN_PACKAGES_MISSING")
  path<-file.path(run,"LO04_PROVENANCE_BRIDGE.sqlite")
  con<-DBI::dbConnect(RSQLite::SQLite(),path)
  on.exit(DBI::dbDisconnect(con),add=TRUE)
  DBI::dbExecute(con,"PRAGMA journal_mode=DELETE")
  DBI::dbWithTransaction(con,{
    DBI::dbWriteTable(con,"plan",q,overwrite=TRUE)
    DBI::dbWriteTable(con,"historical_candidates",historic,overwrite=TRUE)
    if(nrow(central$current))DBI::dbWriteTable(con,"central_current_readonly_copy",central$current,overwrite=TRUE)
    if(nrow(central$history))DBI::dbWriteTable(con,"central_history_readonly_copy",central$history,overwrite=TRUE)
    if(nrow(lo02$current))DBI::dbWriteTable(con,"lo02_current_readonly_copy",lo02$current,overwrite=TRUE)
    if(nrow(lo02$history))DBI::dbWriteTable(con,"lo02_history_readonly_copy",lo02$history,overwrite=TRUE)
    if("lifecycle_product_result_links"%in%names(central$sqlite$data))
      DBI::dbWriteTable(con,"historical_product_links_readonly_copy",central$sqlite$data$lifecycle_product_result_links,overwrite=TRUE)
    DBI::dbWriteTable(con,"source_health",data.frame(store=c("CENTRAL","LO02"),status=c(central$status,lo02$status)),overwrite=TRUE)
  })
  DBI::dbExecute(con,"CREATE INDEX IF NOT EXISTS plan_metric_key_index ON plan(metric_key)")
  DBI::dbExecute(con,"CREATE INDEX IF NOT EXISTS history_metric_key_index ON historical_candidates(metric_key)")
  if(!identical(DBI::dbGetQuery(con,"PRAGMA integrity_check")[[1]],"ok"))stop("Sidecar SQLite integriteitscheck mislukt")
  "SIDECAR_READONLY_SNAPSHOTS_STAGED"
}

lo4_cross_registry_comparison <- function(central,lo02) {
  a<-central$current;b<-lo02$current
  if(!all(c("metric_key","estimate","se")%in%names(a))||!all(c("metric_key","estimate","se")%in%names(b)))return(data.frame())
  common<-intersect(a$metric_key,b$metric_key)
  if(!length(common))return(data.frame())
  ia<-match(common,a$metric_key);ib<-match(common,b$metric_key)
  est_a<-suppressWarnings(as.numeric(a$estimate[ia]));est_b<-suppressWarnings(as.numeric(b$estimate[ib]))
  se_a<-suppressWarnings(as.numeric(a$se[ia]));se_b<-suppressWarnings(as.numeric(b$se[ib]))
  diff<-abs(est_a-est_b);same<-is.finite(diff)&diff<=1e-8
  out<-data.frame(metric_key=common,central_estimate=est_a,lo02_estimate=est_b,
    delta=est_b-est_a,central_se=se_a,lo02_se=se_b,
    numeric_comparison=ifelse(same,"NUMERIC_MATCH_NOT_PROOF_OF_SCIENCE_IDENTITY","DIFFERENCE_NEEDS_DEFINITION_REVIEW"),
    stringsAsFactors=FALSE)
  out
}
lo4_product_version_trace <- function(product_links,joined) {
  z<-product_links[product_links$metric_key%in%joined$metric_key,,drop=FALSE]
  if(!nrow(z))return(z)
  j<-match(z$metric_key,joined$metric_key)
  z$central_record_version_id<-joined$legacy_central_record_version[j]
  z$lo02_record_version_id<-joined$lo02_record_version[j]
  z$record_link_status<-ifelse(nzchar(z$central_record_version_id),"CENTRAL_VERSION_EXISTS_VERIFY_FIGURE_PIN",
    ifelse(nzchar(z$lo02_record_version_id),"LO02_VERSION_EXISTS_NOT_PUBLIC_RELEASE","NO_VERIFIED_VERSION_YET"))
  z
}

# Historical artifacts provide evidence of calculations, never scientific approval by themselves.
lo4_offline_evidence <- function(bundle) {
  artifacts<-c("V8_NLD_DASHBOARD_GRID_FULL.csv.gz", "V9_COUNTRIES_NEW_MASTER_ROWS.csv.gz",
    "V9_COUNTRIES_NEW_OR_REUSED_TASK_RESULTS.csv.gz")
  rows<-lapply(artifacts,function(n){p<-file.path(bundle,"evidence",n)
    if(!file.exists(p))return(NULL)
    hdr<-tryCatch(names(lo4_read(p)),error=function(e)character())
    data.frame(artifact=n,size_bytes=as.numeric(file.info(p)$size),sha256=lo4_filehash(p),
      type="HISTORICAL_AGGREGATE_NOT_AUTOPROMOTED",headers=paste(hdr,collapse=";"),stringsAsFactors=FALSE)
  })
  do.call(rbind,Filter(Negate(is.null),rows))
}
lo4_source_reachability <- function(historical,project) {
  p<-unique(historical$source_file[nzchar(historical$source_file)])
  if(!length(p))return(data.frame(source_file=character(),localized_path=character(),present=logical()))
  root<-"PISA_PIRLS_MASTER_PIPELINE/"
  norm<-gsub("\\\\","/",p)
  pos<-regexpr(root,norm,fixed=TRUE)
  local<-ifelse(pos>0L,file.path(project,substring(norm,pos+nchar(root))),norm)
  hit<-file.exists(local)
  data.frame(source_file=p,localized_path=local,present=hit,
    size_bytes=ifelse(hit,as.numeric(file.info(local)$size),NA_real_),
    scientific_equivalence="NOT_DETERMINED_BY_PRESENCE",stringsAsFactors=FALSE)
}
