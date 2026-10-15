# Conditional production adapter using actual V11 estimators. NEVER automatically enabled.
# WARNING: Do not call until module certificates and local Windows integration tests have PASSED.
lo4_choose_cache <- function(project,survey,year,country,task) {
  p<-lo4_cache_candidates(project,survey,year,country)
  if(!length(p))stop("CANONICAL_CACHE_ABSENT: ",survey," ",year," ",country)
  h<-vapply(p,lo4_filehash,character(1))
  if(length(unique(h))==1L) {
    obj<-readRDS(p[1]);invisible(lo4_projection(obj,task[1,,drop=FALSE]))
    return(list(path=p[1],sha256=h[1],object=obj,equivalence="EXACT_FILE_AND_PROJECTION_TESTED"))
  }
  objects<-lapply(p,function(f)tryCatch(readRDS(f),error=function(e)e))
  # Task may contain several modules/domains. Every used scientific projection must match.
  pieces<-split(seq_len(nrow(task)),paste(task$module,task$domain,task$definition,task$peer_definition,sep="|"))
  hashes<-vapply(objects,function(o){
    if(inherits(o,"error"))stop("RDS_READ_FAILED_ON_CONFLICT_CANDIDATE")
    fp<-vapply(pieces,function(ix)lo4_projection(o,task[ix,,drop=FALSE]),character(1))
    lo4_hash(fp)
  },character(1))
  if(length(unique(hashes))!=1L)stop("SCIENTIFIC_INPUT_CONFLICT_HOLD: ",survey," ",year," ",country,
    "; rerun semantic-cache audit and adjudicate original source identity")
  # Identical necessary inputs; alphabetical deterministic choice, *not* newest.
  ix<-order(lo4_norm(p))[1]
  list(path=p[ix],sha256=h[ix],object=objects[[ix]],equivalence="IDENTICAL_USED_ANALYSIS_COLUMNS")
}
lo4_extended_store <- function(bundle,cfg,run,approved,q) {
  if(!nrow(q))return(invisible(list(computed=0L,reused=0L)))
  if(!all(paste(q$survey,q$module)%in%paste(approved$survey,approved$module)))
    stop("Niet-goedgekeurde methodemodule in execute")
  if(any(q$module%in%c("ses_harmonized","migration_generation","migration_peer_exposure")))
    stop("Special modules hebben nog geen geverifieerde directe adapter")
  # Load only definitions from unchanged v5 engine; real pupil data are read in explicitly selected units.
  for(f in c("REPAIRS.R","EXTENSIONS.R","store.R","engine.R"))
    source(file.path(bundle,"engine",f),local=.GlobalEnv,encoding="UTF-8")
  wcfg<-list(root=cfg$project_root)
  lo_engine_boot(file.path(bundle,"engine"),wcfg,file.path(run,"engine_scratch"),synthetic=FALSE)
  store<-file.path(cfg$lo02_root,"registry_v5")
  if(!file.exists(file.path(store,"PROJECT_RESULTS_REGISTRY.sqlite")))stop("Existing LO02 storage ontbreekt; maak geen nieuwe result silo")
  s<-lo_store_open(store);on.exit(lo_store_close(s),add=TRUE)
  lo_store_export(s)
  DBI::dbExecute(s$con,paste0("CREATE TABLE IF NOT EXISTS lo4_result_provenance (",
    "record_version_id TEXT PRIMARY KEY, metric_key TEXT NOT NULL, producer_code_sha256 TEXT NOT NULL,",
    "source_path TEXT NOT NULL, source_sha256 TEXT NOT NULL, input_projection_sha256 TEXT NOT NULL,",
    "module TEXT NOT NULL, recorded_at TEXT NOT NULL)"))
  groups<-split(seq_len(nrow(q)),paste(q$country,q$survey,q$year,sep="|"))
  journal<-list();nnew<-0L;nreuse<-0L
  for(unit in groups){
    task<-q[unit,,drop=FALSE]
    cache<-tryCatch(lo4_choose_cache(cfg$project_root,task$survey[1],task$year[1],task$country[1],task),error=function(e)e)
    if(inherits(cache,"error")){
      journal[[length(journal)+1L]]<-data.frame(unit=paste(task$country[1],task$survey[1],task$year[1]),module="ALL",action="HOLD",reason=conditionMessage(cache))
      next
    }
    obj<-cache$object
    # Only the exact, known country/wave scientific keys may enter this run.
    if(!identical(as.character(obj$meta$survey),task$survey[1]) ||
       !identical(as.character(obj$meta$year),task$year[1]))stop("CANONICAL_IDENTITY_MISMATCH")
    batches<-split(seq_len(nrow(task)),paste(task$module,task$domain,task$definition,task$peer_definition,sep="|"))
    # One load per country × wave; grouped PV/replicate calculations, one writer.
    for(rows in batches){
      block<-task[rows,,drop=FALSE]
      outcome<-tryCatch({
        inputfp<-lo4_projection(obj,block)
        codefp<-lo4_filehash(file.path(bundle,"code","LO04_EXTENDED_EXECUTION.R"))
        sciencefp<-vapply(seq_len(nrow(block)),function(k)lo36_science_fp(as.list(block[k,lo4_keys,drop=FALSE]),inputfp,codefp),character(1))
        # All members of this batch share the same canonical projection but retain individual science IDs.
        existing<-DBI::dbGetQuery(s$con,"SELECT metric_key,science_fingerprint FROM results WHERE is_current=1")
        ix<-match(block$metric_key,existing$metric_key)
        reuse<-!is.na(ix) & existing$science_fingerprint[pmax(1,ix)]==sciencefp
        reuse[is.na(reuse)]<-FALSE
        nreuse<-nreuse+sum(reuse)
        todo<-which(!reuse)
        if(!length(todo)) {
          list(complete=TRUE,computed=0L,reused=sum(reuse))
        } else {
        # Every estimator result includes its domain/definition/peer unit; no mixed-definition computation.
        z<-v10_compute(obj,block[todo,,drop=FALSE])
        if(nrow(z)!=length(todo)||!setequal(z$metric_key,block$metric_key[todo]))stop("Bad estimator output identities")
        z<-z[match(block$metric_key[todo],z$metric_key),,drop=FALSE]
        for(k in seq_len(nrow(z))){
          if(!all(is.finite(as.numeric(z[k,c("estimate","se","ci_low","ci_high")]))))stop("Nonfinite estimate")
          z$input_fingerprint[k]<-inputfp;z$science_fingerprint[k]<-sciencefp[todo[k]]
          z$scientific_status[k]<-"COMPUTED_PENDING_VALIDATION"
          z$publication_status[k]<-"NOT_RELEASED"
          lo_store_put(s,z[k,,drop=FALSE])
          rr<-DBI::dbGetQuery(s$con,"SELECT record_version_id FROM results WHERE metric_key=? AND is_current=1",params=list(z$metric_key[k]))
          if(nrow(rr)!=1L)stop("Result inserted but current record cannot be identified")
          DBI::dbExecute(s$con,"INSERT OR REPLACE INTO lo4_result_provenance VALUES (?,?,?,?,?,?,?,?)",
             params=list(rr$record_version_id[1],z$metric_key[k],codefp,cache$path,cache$sha256,inputfp,block$module[1],as.character(Sys.time())))
          nnew<-nnew+1L
        }
        list(complete=TRUE,computed=length(todo),reused=sum(reuse))
        }
      },error=function(e)e)
      if(inherits(outcome,"error"))
        journal[[length(journal)+1L]]<-data.frame(unit=paste(task$country[1],task$survey[1],task$year[1]),module=block$module[1],action="HOLD",reason=conditionMessage(outcome))
      else journal[[length(journal)+1L]]<-data.frame(unit=paste(task$country[1],task$survey[1],task$year[1]),module=block$module[1],action="BATCH_COMPLETE",reason="Pending scientific validation")
    }
    lo_store_export(s)
    rm(obj,cache);gc(FALSE)
  }
  lo_store_export(s)
  if(length(journal))lo4_csv(do.call(rbind,journal),file.path(run,"EXTENDED_EXECUTION_JOURNAL.csv"))
  list(computed=nnew,reused=nreuse)
}
