# LO05: immutabele, inhoudsgeadresseerde snapshots en een enkele SQLite-provenance-index.
# Bronstores uitsluitend lezen. Oude bronbestanden pas na een bewezen hersteltest opruimen.
lo5_existing_source <- function(paths) {
  p <- paths[file.exists(paths)]
  if (length(p)) lo4_norm(p[1]) else ""
}
lo5_as_text <- function(x,n) {
  if(is.null(x)) return(rep("",n))
  z<-as.character(x)
  z[is.na(z)]<-""
  z
}
lo5_safe_table <- function(con) {
  DBI::dbExecute(con,paste0("CREATE TABLE IF NOT EXISTS source_snapshots (",
    "source_id TEXT NOT NULL, source_sha256 TEXT NOT NULL, snapshot_path TEXT NOT NULL,",
    "snapshot_sha256 TEXT NOT NULL, nrows INTEGER NOT NULL, recorded_at TEXT NOT NULL,",
    "PRIMARY KEY(source_id,source_sha256))"))
  DBI::dbExecute(con,paste0("CREATE TABLE IF NOT EXISTS result_versions (",
    "source_id TEXT NOT NULL, source_sha256 TEXT NOT NULL, row_number INTEGER NOT NULL,",
    "metric_key TEXT NOT NULL, record_version_id TEXT NOT NULL, scientific_status TEXT,",
    "publication_status TEXT, estimate TEXT, se TEXT, code_id TEXT, input_fingerprint TEXT,",
    "snapshot_path TEXT NOT NULL, PRIMARY KEY(source_id,source_sha256,row_number))"))
  DBI::dbExecute(con,"CREATE INDEX IF NOT EXISTS idx_result_metric ON result_versions(metric_key)")
  DBI::dbExecute(con,"CREATE INDEX IF NOT EXISTS idx_record_version ON result_versions(record_version_id)")
  DBI::dbExecute(con,paste0("CREATE TABLE IF NOT EXISTS product_requirements (",
    "metric_key TEXT NOT NULL, figure_id TEXT, contract_figure_id TEXT,",
    "products TEXT, source_slides TEXT, dashboard_control TEXT, paper_exhibit TEXT,",
    "PRIMARY KEY(metric_key,figure_id,contract_figure_id,products))"))
  DBI::dbExecute(con,paste0("CREATE TABLE IF NOT EXISTS run_checks (",
    "check_name TEXT PRIMARY KEY, check_status TEXT NOT NULL, detail TEXT)"))
  invisible(TRUE)
}
lo5_stage_source <- function(con,root,id,file,data) {
  if(!nzchar(file)||!is.data.frame(data)||!nrow(data))return(list(source=id,status="SOURCE_MISSING_OR_EMPTY",rows=0L))
  if(!"metric_key"%in%names(data))return(list(source=id,status="NO_METRIC_KEY",rows=nrow(data)))
  source_sha<-lo4_filehash(file)
  old<-DBI::dbGetQuery(con,"SELECT snapshot_path,snapshot_sha256,nrows FROM source_snapshots WHERE source_id=? AND source_sha256=?",params=list(id,source_sha))
  if(nrow(old)) {
    p<-old$snapshot_path[1]
    if(!file.exists(p)||!identical(lo4_filehash(p),old$snapshot_sha256[1]))stop("CONSOLIDATED_SNAPSHOT_BROKEN: ",id)
    if(old$nrows[1]!=nrow(data))stop("SNAPSHOT_ROW_COUNT_CHANGED: ",id)
    return(list(source=id,status="REUSE_VERIFIED_SNAPSHOT",rows=nrow(data)))
  }
  # Alle oorspronkelijke bronkolommen blijven behouden in een immutabele Parquet-snapshot.
  dir.create(file.path(root,"snapshots"),recursive=TRUE,showWarnings=FALSE)
  snapshot<-file.path(root,"snapshots",paste0(id,"_",substr(source_sha,1,20),".parquet"))
  # Herstart na crash tussen rename en SQLite-commit: een bestaande maar
  # nog niet geregistreerde snapshot wordt inhoudelijk gecontroleerd, niet
  # overschreven of opnieuw berekend.
  orphan_exists<-file.exists(snapshot)
  tmp<-tempfile(pattern="snapshot_",tmpdir=dirname(snapshot),fileext=".parquet")
  on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
  # as.character voorkomt gemengde schema-types tussen de oude generaties.
  cleaned<-as.data.frame(lapply(data,lo5_as_text,n=nrow(data)),stringsAsFactors=FALSE,check.names=FALSE)
  if(!orphan_exists)arrow::write_parquet(cleaned,tmp,compression="zstd")
  verify<-as.data.frame(arrow::read_parquet(if(orphan_exists)snapshot else tmp,mmap=FALSE))
  if(nrow(verify)!=nrow(data)||!identical(lo5_as_text(verify$metric_key,nrow(verify)),lo5_as_text(data$metric_key,nrow(data))))
    stop("SNAPSHOT_VERIFICATION_FAILED: ",id)
  if(!orphan_exists && !file.rename(tmp,snapshot))stop("IMMUTABLE_SNAPSHOT_RENAME_FAILED: ",id)
  hash<-lo4_filehash(snapshot)
  n<-nrow(data)
  rv<-if("record_version_id"%in%names(data))lo5_as_text(data$record_version_id,n) else rep("",n)
  rv[!nzchar(rv)]<-paste0("legacy:",id,":",source_sha,":",which(!nzchar(rv)))
  vec<-function(field)if(field%in%names(data))lo5_as_text(data[[field]],n) else rep("",n)
  meta<-data.frame(source_id=rep(id,n),source_sha256=rep(source_sha,n),row_number=seq_len(n),
    metric_key=vec("metric_key"),record_version_id=rv,
    scientific_status=vec("scientific_status"),publication_status=vec("publication_status"),
    estimate=vec("estimate"),se=vec("se"),
    code_id=if("producer_code_id"%in%names(data))vec("producer_code_id") else vec("analysis_version"),
    input_fingerprint=if("input_fingerprint"%in%names(data))vec("input_fingerprint") else vec("science_fingerprint"),
    snapshot_path=rep(lo4_norm(snapshot),n),stringsAsFactors=FALSE)
  if(any(!nzchar(meta$metric_key)))stop("BLANK_METRIC_KEY_IN_MIGRATION: ",id)
  DBI::dbWithTransaction(con,{
    DBI::dbWriteTable(con,"result_versions",meta,append=TRUE,row.names=FALSE)
    DBI::dbExecute(con,"INSERT INTO source_snapshots VALUES (?,?,?,?,?,?)",
      params=list(id,source_sha,lo4_norm(snapshot),hash,n,as.character(Sys.time())))
  })
  list(source=id,status="MIGRATED_VERIFIED",rows=n)
}
# Historische productpins bevatten koppelingen naar exacte resultaatversies.
# Houd ze strikt apart van wetenschappelijke resultaatwaarden.
lo5_preserve_product_pins <- function(con,root,cfg,central) {
  x<-central$sqlite$data$lifecycle_product_result_links
  original<-file.path(cfg$project_root,"00_PROJECT_REGISTRY/PROJECT_RESULTS_REGISTRY.sqlite")
  if(!is.data.frame(x)||!nrow(x)){
    original<-file.path(cfg$project_root,"03_RESULTS/metadata/PRODUCT_RESULT_LINKS.parquet")
    x<-tryCatch(lo4_safe_read_parquet(original),error=function(e)NULL)
  }
  if(!is.data.frame(x)||!nrow(x)||!"metric_key"%in%names(x))return("HISTORICAL_PRODUCT_PINS_NOT_AVAILABLE")
  x<-as.data.frame(lapply(x,lo5_as_text,n=nrow(x)),stringsAsFactors=FALSE,check.names=FALSE)
  sha<-lo4_filehash(original)
  p<-file.path(root,"snapshots",paste0("historical_product_pins_",substr(sha,1,20),".parquet"))
  if(!file.exists(p)){
    tmp<-tempfile(tmpdir=dirname(p),fileext=".parquet")
    on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
    arrow::write_parquet(x,tmp,compression="zstd")
    if(nrow(arrow::read_parquet(tmp,mmap=FALSE))!=nrow(x))stop("PRODUCT_PIN_ROUNDTRIP_FAILED")
    if(!file.rename(tmp,p))stop("PRODUCT_PIN_SNAPSHOT_ATOMIC_RENAME_FAILED")
  }
  DBI::dbExecute(con,paste0("CREATE TABLE IF NOT EXISTS product_version_pins (",
    "source_sha256 TEXT NOT NULL, row_number INTEGER NOT NULL, metric_key TEXT NOT NULL,",
    "record_version_id TEXT, snapshot_path TEXT NOT NULL, PRIMARY KEY(source_sha256,row_number))"))
  n<-DBI::dbGetQuery(con,"SELECT COUNT(*) AS n FROM product_version_pins WHERE source_sha256=?",params=list(sha))$n[1]
  if(n==nrow(x))return("PRODUCT_PINS_VERIFIED_EXISTING")
  if(n>0L)stop("PARTIAL_PRODUCT_PIN_MIGRATION_DETECTED")
  pin<-data.frame(source_sha256=rep(sha,nrow(x)),row_number=seq_len(nrow(x)),
    metric_key=x$metric_key,record_version_id=if("record_version_id"%in%names(x))x$record_version_id else rep("",nrow(x)),
    snapshot_path=rep(lo4_norm(p),nrow(x)),stringsAsFactors=FALSE)
  DBI::dbWithTransaction(con,DBI::dbWriteTable(con,"product_version_pins",pin,append=TRUE,row.names=FALSE))
  "PRODUCT_PINS_MIGRATED_VERIFIED"
}

lo5_consolidate <- function(bundle,cfg,central,lo02,historic,run) {
  root<-file.path(cfg$output_root,"consolidated")
  dir.create(root,recursive=TRUE,showWarnings=FALSE)
  con<-DBI::dbConnect(RSQLite::SQLite(),file.path(root,"RESULT_PROVENANCE.sqlite"))
  on.exit(DBI::dbDisconnect(con),add=TRUE)
  DBI::dbExecute(con,"PRAGMA busy_timeout=10000")
  lo5_safe_table(con)
  oldpath<-function(rel)lo5_existing_source(file.path(cfg$project_root,rel))
  lo02_source <- if(identical(lo02$status,"LO02_ARCHIVED_RETURN_ONLY_READONLY"))
    file.path(bundle,"evidence/LO02_RETURN_20261010_CURRENT_RESULTS.csv.gz")
    else lo5_existing_source(c(file.path(cfg$lo02_root,"registry_v5/CURRENT_RESULTS.parquet"),
       file.path(bundle,"evidence/LO02_RETURN_20261010_CURRENT_RESULTS.csv.gz")))
  src<-list(
    list("central_current",oldpath(c("03_RESULTS/current/CURRENT_RESULTS.parquet","03_RESULTS/current/CURRENT_RESULTS.csv.gz")),central$current),
    list("central_history",oldpath("03_RESULTS/history/RESULT_HISTORY.parquet"),central$history),
    list("lo02_current",lo02_source,lo02$current),
    list("lo02_history",lo5_existing_source(file.path(cfg$lo02_root,"registry_v5/RESULT_HISTORY.parquet")),lo02$history),
    list("legacy_lo01",file.path(bundle,"evidence/LO01_HISTORICAL_CANDIDATES.csv.gz"),historic)
  )
  report<-lapply(src,function(z) {
    tryCatch(lo5_stage_source(con,root,z[[1]],z[[2]],z[[3]]),error=function(e)
      list(source=z[[1]],status=paste0("MIGRATION_HOLD: ",conditionMessage(e)),rows=0L))
  })
  z<-do.call(rbind,lapply(report,as.data.frame,stringsAsFactors=FALSE))
  pins_status<-tryCatch(lo5_preserve_product_pins(con,root,cfg,central),error=function(e)
      paste0("HISTORICAL_PRODUCT_PINS_HOLD: ",conditionMessage(e)))
  lo4_text(pins_status,file.path(run,"HISTORICAL_PRODUCT_PINS_STATUS.txt"))
  # Product-to-result links blijven apart, zodat een figuur nooit uit gewijzigde schattingen gaat rekenen.
  products<-lo4_read(file.path(bundle,"PRODUCT_FIGUUR_RESULTAAT.csv.gz"),
    c("metric_key","figure_id","contract_figure_id","products"))
  req<-products[,c("metric_key","figure_id","contract_figure_id","products","source_slides","dashboard_control","paper_exhibit"),drop=FALSE]
  req[]<-lapply(req,lo5_as_text,n=nrow(req))
  if(anyDuplicated(req))req<-unique(req)
  if(!nrow(DBI::dbGetQuery(con,"SELECT metric_key FROM product_requirements LIMIT 1"))) {
    DBI::dbWithTransaction(con,DBI::dbWriteTable(con,"product_requirements",req,append=TRUE,row.names=FALSE))
  } else {
    existing<-DBI::dbGetQuery(con,"SELECT metric_key,figure_id,contract_figure_id,products FROM product_requirements")
    a<-paste(existing$metric_key,existing$figure_id,existing$contract_figure_id,existing$products,sep="\r")
    b<-paste(req$metric_key,req$figure_id,req$contract_figure_id,req$products,sep="\r")
    if(!setequal(a,b)) {
      DBI::dbWithTransaction(con,{
        DBI::dbExecute(con,"DELETE FROM product_requirements")
        DBI::dbWriteTable(con,"product_requirements",req,append=TRUE,row.names=FALSE)
      })
    }
  }
  integrity<-DBI::dbGetQuery(con,"PRAGMA integrity_check")[[1]][1]
  if(!identical(integrity,"ok"))stop("PROVENANCE_SQLITE_INTEGRITY_FAIL")
  # Niets in de upstream registries wordt veranderd; de nieuwe index is aanvankelijk kandidaatbron.
  totals<-DBI::dbGetQuery(con,paste0("SELECT source_id, COUNT(*) AS n_records, ",
    "COUNT(DISTINCT metric_key) AS n_distinct_metrics FROM result_versions GROUP BY source_id"))
  lo4_csv(totals,file.path(run,"CONSOLIDATED_SOURCE_COUNTS.csv"))
  expected_available <- vapply(src,function(item) nzchar(item[[2]]) && file.exists(item[[2]]),logical(1))
  if(any(expected_available & z$status=="SOURCE_MISSING_OR_EMPTY")){
    # Een bestaand maar niet leesbaar history/current bestand mag niet
    # geruisloos als lege bron worden beschouwd.
    z$status[expected_available & z$status=="SOURCE_MISSING_OR_EMPTY"]<-"EXISTING_SOURCE_WAS_NOT_IMPORTED_HOLD"
  }
  lo4_csv(z,file.path(run,"CONSOLIDATION_STATUS.csv"))
  ok <- all(z$status%in%c("MIGRATED_VERIFIED","REUSE_VERIFIED_SNAPSHOT","SOURCE_MISSING_OR_EMPTY")) &&
    central$status=="CENTRAL_CURRENT_MATCHES_SQLITE" &&
    lo02$status%in%c("LO02_LIVE_SQLITE_PARQUET_MATCH","LO02_ARCHIVED_RETURN_ONLY_READONLY") &&
    all(c("central_current","lo02_current","legacy_lo01")%in%
      z$source[z$status%in%c("MIGRATED_VERIFIED","REUSE_VERIFIED_SNAPSHOT")])
  list(ok=ok,
    path=file.path(root,"RESULT_PROVENANCE.sqlite"),counts=totals,migration=z)
}
lo5_requirement_audit <- function(bundle,joined,run) {
  p<-lo4_read(file.path(bundle,"PRODUCT_FIGUUR_RESULTAAT.csv.gz"),c("metric_key","figure_id","products"))
  sel<-joined[joined$phase%in%c("NLD","OECD19","FULL"),,drop=FALSE]
  i<-match(p$metric_key,sel$metric_key)
  p$scope_phase<-ifelse(is.na(i),"NOT_IN_CURRENT_PRODUCTION_SELECTION",sel$phase[pmax(1,i)])
  p$planning_action<-ifelse(is.na(i),"OUTSIDE_SCOPE",sel$planning_action[pmax(1,i)])
  p$scientific_use_status<-ifelse(is.na(i),"NOT_ASSESSED",sel$provenance_decision[pmax(1,i)])
  lo4_csv(p,file.path(run,"PRODUCT_REQUIREMENTS_TRACE.csv"))
  summary<-aggregate(rep.int(1L,nrow(p)),by=list(figure_id=p$figure_id,
    phase=p$scope_phase,planning_action=p$planning_action),FUN=sum)
  names(summary)[4]<-"n_records"
  lo4_csv(summary,file.path(run,"FIGURE_COVERAGE.csv"))
  invisible(summary)
}

# Versies die NA de berekening zijn toegevoegd worden meteen in dezelfde
# centrale provenance-index opgenomen. Geen tweede centrale registratie.
lo5_refresh_new_results <- function(bundle,cfg,run) {
  root<-file.path(cfg$output_root,"consolidated")
  con<-DBI::dbConnect(RSQLite::SQLite(),file.path(root,"RESULT_PROVENANCE.sqlite"))
  on.exit(DBI::dbDisconnect(con),add=TRUE)
  lo5_safe_table(con)
  latest<-lo4_lo02_live(cfg$lo02_root,bundle)
  results<-list()
  for(family in c("current","history")) {
    path<-file.path(cfg$lo02_root,"registry_v5",
      if(family=="current")"CURRENT_RESULTS.parquet" else "RESULT_HISTORY.parquet")
    data<-latest[[family]]
    results[[length(results)+1L]]<-lo5_stage_source(con,root,paste0("lo02_",family),path,data)
  }
  DBI::dbExecute(con,paste0("CREATE TABLE IF NOT EXISTS candidate_checkpoints (",
    "checkpoint_path TEXT PRIMARY KEY, checkpoint_sha256 TEXT NOT NULL,",
    "phase TEXT NOT NULL, module TEXT NOT NULL, input_projection_sha256 TEXT,",
    "scientific_status TEXT NOT NULL)"))
  for(ph in cfg$phases) {
    journal<-file.path(run,paste0("PHASE_",ph),"CANDIDATES_JOURNAL.csv")
    if(!file.exists(journal))next
    rows<-lo4_read(journal)
    if(!all(c("candidate_file","module","input_fp")%in%names(rows)))next
    rows<-rows[nzchar(rows$candidate_file)&file.exists(rows$candidate_file),,drop=FALSE]
    if(!nrow(rows))next
    for(i in seq_len(nrow(rows))) {
      f<-lo4_norm(rows$candidate_file[i]);sha<-lo4_filehash(f)
      existing<-DBI::dbGetQuery(con,"SELECT checkpoint_sha256 FROM candidate_checkpoints WHERE checkpoint_path=?",params=list(f))
      if(nrow(existing)){
        if(!identical(existing$checkpoint_sha256[1],sha))stop("CANDIDATE_CHECKPOINT_MUTATED: ",f)
        next
      }
      DBI::dbExecute(con,"INSERT INTO candidate_checkpoints VALUES (?,?,?,?,?,?)",
        params=list(f,sha,ph,rows$module[i],rows$input_fp[i],"PENDING_SCIENTIFIC_VALIDATION"))
    }
  }
  if(!identical(DBI::dbGetQuery(con,"PRAGMA integrity_check")[[1]][1],"ok"))stop("POSTPRODUCTION_SQLITE_FAILED")
  z<-do.call(rbind,lapply(results,as.data.frame,stringsAsFactors=FALSE))
  lo4_csv(z,file.path(run,"POSTPRODUCTION_CONSOLIDATION.csv"))
  if(any(grepl("HOLD|FAIL",z$status)))stop("POSTPRODUCTION_CONSOLIDATION_HELD")
  invisible(z)
}
