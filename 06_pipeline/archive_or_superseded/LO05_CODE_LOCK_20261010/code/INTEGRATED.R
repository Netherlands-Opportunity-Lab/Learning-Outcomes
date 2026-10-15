# Eén orkestrator voor inventariseren -> Windows tests -> veilig hergebruik ->
# vrijgegeven PISA core/gender -> overige wetenschappelijke KANDIDATEN in quarantaine.
# Geen nieuwe silo met 'definitieve' waarden; historische stores blijven beschermd.
lo_integrated_require <- function(bundle) {
  for (f in c("LO04_COMMON.R","LO04_HISTORY.R","LO04_CACHE.R","LO04_ADAPTERS.R",
              "LO04_EXTENDED_EXECUTION.R","LO04_EXECUTION.R","LO04_WINDOWS_TESTS.R",
              "LO04_SCIENCE_SMOKE.R","LO04_GC.R",
              "LO05_CONSOLIDATION.R","LO05_LIFECYCLE.R")) {
    source(file.path(bundle,"code",f),local=.GlobalEnv,encoding="UTF-8")
  }
  lo4_require(c("digest","DBI","RSQLite","arrow"))
  # Override the legacy fingerprint: the only active launcher is now LEARNING_OUTCOMES_RUN.R.
  lo4_runner_code_fingerprint <<- function(b) {
    paths<-c(file.path(b,"LEARNING_OUTCOMES_RUN.R"),
             file.path(b,"PROJECT_CONFIG.R"),
             list.files(file.path(b,"code"),pattern="\\.R$",full.names=TRUE))
    lo4_hash(vapply(sort(paths),lo4_filehash,character(1)))
  }
}

lo_integrated_cfg <- function(bundle) {
  cfg <- dget(file.path(bundle,"PROJECT_CONFIG.R"))
  stopifnot(is.list(cfg))
  # Runtime mode selectors: no need to edit the checksum-protected config file.
  override <- getOption("learning_outcomes.mode",NULL)
  if(!is.null(override)) {
    if(!override%in%c("NLD_ONLY","NLD_PLUS_OECD_PPP","OECD_PPP_ONLY",
                       "OTHER_INTERNATIONAL","FULL_INTERNATIONAL"))stop("Ongeldige learning_outcomes.mode")
    cfg$run_mode<-override
    cfg$phases<-switch(override,NLD_ONLY="NLD",NLD_PLUS_OECD_PPP=c("NLD","OECD19"),
      OECD_PPP_ONLY="OECD19",OTHER_INTERNATIONAL="FULL",FULL_INTERNATIONAL=c("NLD","OECD19","FULL"))
  }
  operation<-getOption("learning_outcomes.action",NULL)
  if(!is.null(operation))cfg$action<-operation
  cleanup<-getOption("learning_outcomes.gc_policy",NULL)
  if(!is.null(cleanup))cfg$gc_policy<-cleanup
  if (!identical(cfg$focus_country,"NLD") ||
      !identical(cfg$expected_reference_country_count,19L)) stop("Focus/referentielanden onjuist")
  if (!identical(cfg$reference_id,"OECD_PPP_GT_CZE_2024_RECONSTRUCTED"))
    stop("Referentiedefinitie gewijzigd")
  if (!cfg$action %in% c("production","test_only","plan_only"))stop("Onbekende actie")
  if (!identical(cfg$workers,1L) || !identical(cfg$delete_files,FALSE) ||
      !identical(cfg$write_existing_project_registry,FALSE) ||
      !identical(cfg$allow_unverified_promotion,FALSE)) stop("Veiligheidscontract verbroken")
  if (!identical(cfg$allow_raw_imports,FALSE))stop("Raw imports moeten uitblijven")
  if (anyDuplicated(cfg$phases) || !all(cfg$phases %in% c("NLD","OECD19","FULL")))
    stop("Productiefase ongeldig")
  if ("FULL"%in%cfg$phases && !cfg$run_mode%in%c("FULL_INTERNATIONAL","OTHER_INTERNATIONAL"))
    stop("FULL vereist expliciete internationale scope")
  if (!cfg$run_mode%in%c("NLD_ONLY","NLD_PLUS_OECD_PPP","OECD_PPP_ONLY",
                         "FULL_INTERNATIONAL","OTHER_INTERNATIONAL")) stop("Onbekende productiemodus")
  if (is.null(cfg$gc_policy) || !cfg$gc_policy%in%c("auto_exact_duplicate_run_exports","report_only"))
    stop("GC-beleid ontbreekt of is ongeldig")
  for (n in c("project_root","lo02_root","output_root"))
    cfg[[n]] <- lo4_norm(cfg[[n]])
  if (!dir.exists(cfg$project_root))stop("Projectroot ontbreekt: ",cfg$project_root)
  cfg$bundle_dir<-lo4_norm(bundle)
  lo4_disjoint(cfg$output_root,c(cfg$project_root,cfg$lo02_root,bundle))
  cfg
}

lo_integrated_atomic_rds <- function(x,path) {
  dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
  if (file.exists(path))stop("Checkpoint bestaat al (geen overschrijven): ",path)
  tmp <- tempfile(pattern="lo_candidate_",tmpdir=dirname(path))
  on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
  saveRDS(x,tmp,compress=TRUE)
  if (!file.rename(tmp,path))stop("Checkpoint atomair opslaan mislukt: ",path)
  invisible(path)
}

lo_integrated_candidate_run <- function(bundle,cfg,phase,phase_tasks,logdir) {
  # Produceert aanvullende berekeningen met bestaande V11 estimators, maar
  # NIET in CURRENT_RESULTS: dat vereist aparte wetenschappelijke validatie.
  permitted <- c("core","gender","ses_national","migration","language_exact",
     "language_frequency","language_frequency_binary","peer_baseline",
     "ses_peer_exposure","home_language_peer_exposure","home_language_frequency_peer",
     "migration_binary_peer","high_proficiency_peer_exposure")
  tasks <- phase_tasks[phase_tasks$module %in% permitted &
       !(phase_tasks$survey=="PISA" & phase_tasks$module %in% c("core","gender")),,drop=FALSE]
  if (!nrow(tasks))return(data.frame())
  scratch <- file.path(logdir,"candidate_engine")
  for (f in c("REPAIRS.R","EXTENSIONS.R","store.R","engine.R"))
    source(file.path(bundle,"engine",f),local=.GlobalEnv,encoding="UTF-8")
  lo_engine_boot(file.path(bundle,"engine"),list(root=cfg$project_root),scratch,synthetic=FALSE)
  codehash <- lo4_hash(vapply(file.path(bundle,"engine",
    c("V11.R","BACKEND.R","REPAIRS.R","EXTENSIONS.R")),lo4_filehash,character(1)))
  store <- file.path(cfg$output_root,"candidate_checkpoints")
  dir.create(store,recursive=TRUE,showWarnings=FALSE)
  journal <- list();counter <- 0L
  groups <- split(seq_len(nrow(tasks)),paste(tasks$country,tasks$survey,tasks$year,sep="|"))
  # Deterministic order, avoids arbitrary list.files() ordering.
  groups <- groups[order(names(groups))]
  for (u in groups) {
    task <- tasks[u,,drop=FALSE]
    id <- paste(task$country[1],task$survey[1],task$year[1],sep="|")
    cat("[",phase,"] Kandidaatunit ",id,"\n",sep="");flush.console()
    batches <- split(seq_len(nrow(task)),paste(task$module,task$domain,
          task$definition,task$peer_definition,sep="|"))
    # Each candidate RDS is read once. Conflicting inputs are adjudicated PER MODULE,
    # so a missing peer/SES variable cannot block independent core statistics.
    paths<-lo4_cache_candidates(cfg$project_root,task$survey[1],task$year[1],task$country[1])
    if(!length(paths)) {
      journal[[length(journal)+1L]]<-data.frame(unit=id,phase=phase,
       module="ALL",action="HOLD",n=nrow(task),reason="NO_CANONICAL_CACHE_FOR_UNIT",
       input_fp="",candidate_file="",stringsAsFactors=FALSE)
      next
    }
    path_sha<-vapply(paths,lo4_filehash,character(1))
    objlist<-lapply(paths,function(path)tryCatch(readRDS(path),error=function(e)e))
    for (ix in batches) {
      block <- task[ix,,drop=FALSE];mod<-block$module[1]
      # It is unsafe to reuse fingerprints that omit the actual group/peer inputs.
      attempt <- tryCatch({
        hashes <- vapply(objlist,function(obj) {
          if(inherits(obj,"error"))stop("UNREADABLE_CANONICAL_CANDIDATE")
          lo4_projection(obj,block)
        },character(1))
        if(length(unique(hashes))!=1L)stop("SCIENTIFIC_INPUT_CONFLICT_FOR_THIS_MODULE")
        which_obj<-order(lo4_norm(paths))[1]
        obj<-objlist[[which_obj]]
        canonical_sha<-path_sha[which_obj]
        canonical_path<-paths[which_obj]
        fp <- hashes[which_obj]
        batch_key <- lo4_hash(list(code=codehash,input=fp,
          task_keys=sort(block$metric_key),schema="candidate_v1"))
        file <- file.path(store,paste0(batch_key,".rds"))
        if (file.exists(file)) {
          old <- readRDS(file)
          if (!identical(old$batch_key,batch_key) ||
              !setequal(old$results$metric_key,block$metric_key))
            stop("EXISTING_CANDIDATE_CHECKPOINT_CONFLICT")
          list(action="REUSED_CANDIDATE_CHECKPOINT",file=file,fp=fp)
        } else {
        z <- v10_compute(obj,block)
        if (!is.data.frame(z)||!setequal(z$metric_key,block$metric_key)||
            anyDuplicated(z$metric_key))stop("V11_OUTPUT_CONTRACT_MISMATCH")
        if (!all(c("estimate","se","ci_low","ci_high")%in%names(z)))
          stop("V11_OUTPUT_COLUMNS_MISSING")
        finite <- vapply(z[c("estimate","se","ci_low","ci_high")],
                         function(x)all(is.finite(as.numeric(x))),logical(1))
        if (!all(finite) || any(as.numeric(z$se)<0))stop("V11_NONFINITE_OR_NEGATIVE_SE")
        z$scientific_status<-"CANDIDATE_PENDING_SCIENTIFIC_VALIDATION"
        z$publication_status<-"NOT_RELEASED"
        z$input_projection_sha256<-fp
        z$producer_code_family_sha256<-codehash
        z$canonical_sha256<-canonical_sha
        z$canonical_path<-canonical_path
        lo_integrated_atomic_rds(list(batch_key=batch_key,results=z,
          input_fp=fp,producer_hash=codehash,
          created_at=as.character(Sys.time())),file)
        list(action="COMPUTED_CANDIDATE_ONLY",file=file,fp=fp)
        }
      },error=function(e)e)
      if (inherits(attempt,"error")) {
        journal[[length(journal)+1L]]<-data.frame(unit=id,phase=phase,
          module=mod,action="HOLD",n=nrow(block),reason=conditionMessage(attempt),
          input_fp="",candidate_file="",stringsAsFactors=FALSE)
      } else {
        journal[[length(journal)+1L]]<-data.frame(unit=id,phase=phase,
          module=mod,action=attempt$action,n=nrow(block),reason="NOT_RELEASED",
          input_fp=attempt$fp,candidate_file=attempt$file,stringsAsFactors=FALSE)
      }
      counter<-counter+1L
      if (counter%%10L==0L) {
        # This index is per-run, but the individual RDS checkpoints persist across restarts.
        lo4_csv(do.call(rbind,journal),file.path(logdir,sprintf("CANDIDATES_PROGRESS_%05d.csv",counter)))
      }
    }
    rm(objlist,paths,path_sha);gc(FALSE)
  }
  if (!length(journal))return(data.frame())
  z<-do.call(rbind,journal)
  lo4_csv(z,file.path(logdir,"CANDIDATES_JOURNAL.csv"))
  z
}

lo_integrated_single_phase <- function(bundle,cfg,run,phase,selected,joined,
    modules,central,lo02,ref,sciencefp) {
  p <- file.path(run,paste0("PHASE_",phase))
  dir.create(p,recursive=TRUE,showWarnings=FALSE)
  x <- selected[selected$phase==phase,,drop=FALSE]
  if (!nrow(x))return(data.frame(phase=phase,status="EMPTY_PHASE",n=0L))
  cat("\n=== ",phase,": ",nrow(x)," contracttaken ===\n",sep="");flush.console()
  cfg2<-cfg;cfg2$production_phase<-phase;cfg2$action<-"windows_tests"
  tests <- tryCatch(lo4_windows_tests(bundle,cfg2,p,selected,central,lo02,ref,sciencefp),error=function(e)e)
  pass<-identical(tests,TRUE)
  if(inherits(tests,"error"))
    lo4_text(conditionMessage(tests),file.path(p,"WINDOWS_TEST_FAILURE.txt"))
  if(!pass || cfg$action=="test_only")
    return(data.frame(phase=phase,status=if(pass)"WINDOWS_TESTED_NO_PRODUCTION" else "WINDOWS_TEST_FAILED_PRODUCTION_HELD",n=nrow(x)))
  # This action uses the existing LO02 core/gender estimator and its exact input fingerprints.
  cfg2$action<-"execute_ready";cfg2$execute_approval<-TRUE
  cfg2$approved_module_gate_file<-"" # No science auto-promotion via config flags.
  q<-joined[joined$phase==phase,,drop=FALSE]
  result<-tryCatch(lo4_approved_execution(bundle,cfg2,p,q,modules,
       lo4_hash(list(code=sciencefp,scope=lo4_hash(x$metric_key),
           mode=cfg$run_mode,phase=phase))),error=function(e)e)
  if(inherits(result,"error")) {
    lo4_text(conditionMessage(result),file.path(p,"RELEASED_EXECUTION_FAILURE.txt"))
    return(data.frame(phase=phase,status="RELEASED_ENGINE_ERROR_HOLD",n=nrow(x)))
  }
  # Existing computations in other modules are for RESEARCH REVIEW, never current/public.
  candidate <- data.frame()
  if(isTRUE(cfg$candidate_calculation)) {
    candidate <- tryCatch(lo_integrated_candidate_run(bundle,cfg,phase,x,p),error=function(e)e)
    if(inherits(candidate,"error")) {
      lo4_text(conditionMessage(candidate),file.path(p,"CANDIDATE_FAILURE.txt"))
      candidate<-data.frame()
    }
  }
  plan_path<-file.path(p,"LO02_RELEASED_PISA_CORE_GENDER","PRODUCTIEPLAN.csv")
  actual<-if(file.exists(plan_path))tryCatch(lo4_read(plan_path),error=function(e)data.frame()) else data.frame()
  n_computed<-if(nrow(actual))sum(actual$reason=="COMPUTED_AND_COMMITTED",na.rm=TRUE) else 0L
  n_reused<-if(nrow(actual))sum(actual$reason=="EXACT_SCIENTIFIC_AND_INPUT_IDENTITY",na.rm=TRUE) else 0L
  n_held<-if(nrow(actual))sum(actual$action=="HOLD" & actual$metric_key%in%x$metric_key,na.rm=TRUE) else NA_integer_
  data.frame(phase=phase,status="RELEASED_PISA_ATTEMPTED_CANDIDATES_NOT_RELEASED",
    n=nrow(x),v5_computed=n_computed,v5_reused=n_reused,v5_held=n_held,
    candidate_batches=if(nrow(candidate))nrow(candidate)else 0L)
}

lo_integrated_main <- function(bundle) {
  lo_integrated_require(bundle)
  cfg<-lo_integrated_cfg(bundle)
  lo4_manifest_check(bundle)
  tasks<-lo4_read(file.path(bundle,"engine","TASKS.csv"),c(lo4_keys,"metric_key"))
  lo4_assert_metric_keys(tasks)
  if(nrow(tasks)!=79448L)stop("Taakcontractdrift: ",nrow(tasks))
  ref<-lo4_references(bundle)
  # Reuse the original 300 series, not a full country * metric Cartesian product.
  scoped<-lo4_scope(tasks,ref,modifyList(cfg,list(action="plan")))
  sel<-scoped[scoped$phase%in%c("NLD","OECD19","FULL"),,drop=FALSE]
  central<-lo4_old_central(cfg$project_root)
  lo02<-lo4_lo02_live(cfg$lo02_root,bundle)
  historic<-lo4_historical(bundle)
  joined<-lo4_join_status(scoped,central,lo02,historic)
  modules<-lo4_capabilities(tasks)
  joined<-lo4_plan_adapter(joined,modules)
  # Regressie voor crash 2026-10-10: tel uitsluitend kolommen uit DEZELFDE
  # verrijkte, geselecteerde tabel. 'scoped' heeft geen planning_action.
  plan_selected<-joined[joined$phase%in%c("NLD","OECD19","FULL"),,drop=FALSE]
  if(nrow(plan_selected)!=nrow(sel) ||
     !identical(sort(plan_selected$metric_key),sort(sel$metric_key)) ||
     length(plan_selected$phase)!=length(plan_selected$planning_action) ||
     anyNA(plan_selected$planning_action))
    stop("PLAN_JOIN_LENGTH_OR_KEYS_MISMATCH: stop BEFORE any production")
  run<-lo4_unique_run(cfg$output_root)
  cat("\nEEN ACTIEVE RUNNER. Retourmap: ",run,"\n",sep="");flush.console()
  sciencefp<-lo4_hash(vapply(file.path(bundle,"engine",
                  c("V11.R","BACKEND.R","REPAIRS.R","EXTENSIONS.R")),
                  lo4_filehash,character(1)))
  # Bestaande grote SQLite/Parquet-stores blijven onaangeraakt.
  # Eén nieuwe, immutabele consolidatie-index hergebruikt dezelfde snapshots.
  provenance<-"CONSOLIDATED_SQLITE_INDEX_AND_VERIFIED_IMMUTABLE_PARQUET_SNAPSHOTS"
  lo4_csv(joined[joined$phase%in%c("NLD","OECD19","FULL"),,drop=FALSE],
          file.path(run,"PRODUCTIE_GRID.csv"))
  lo4_csv(data.frame(label=c("SCIENTIFIC_ENGINE","REFERENCE","FULL_SELECTION"),
      fingerprint=c(sciencefp,lo4_hash(sort(ref$foreign)),lo4_hash(sort(sel$metric_key)))),
      file.path(run,"RELEASE_FINGERPRINTS.csv"))
  lo4_csv(lo4_cache_audit(cfg$project_root,sel,deep=FALSE),
      file.path(run,"NLD_CACHES_FOUND.csv"))
  lo4_gc_preflight(cfg$project_root,bundle,run)
  allcounts<-as.data.frame(table(plan_selected$phase,plan_selected$planning_action),stringsAsFactors=FALSE)
  names(allcounts)<-c("phase","action","n")
  if(sum(allcounts$n)!=nrow(plan_selected))stop("PLAN_COUNT_REGRESSION_FAIL")
  lo4_csv(allcounts,file.path(run,"PLAN_COUNTS.csv"))
  # Voordat iets wordt berekend: registreer ongewijzigde versies met hun
  # volledige oorspronkelijke kolommen als immutabele Parquet-snapshots.
  consolidation<-tryCatch(lo5_consolidate(bundle,cfg,central,lo02,historic,run),error=function(e)e)
  if(inherits(consolidation,"error")){
    lo4_text(conditionMessage(consolidation),file.path(run,"CONSOLIDATION_FAILURE.txt"))
    consolidation<-list(ok=FALSE,migration=data.frame(status="MIGRATION_HOLD"),path="")
  }
  lo5_requirement_audit(bundle,joined,run)
  if(!isTRUE(consolidation$ok)) {
    # Geen productierun of verwijdering als consolidatie integriteitsproblemen meldt.
    cfg$action<-"plan_only"
    lo4_text("PRODUCTION_HELD_UNTIL_CONSOLIDATION_REPAIRED",file.path(run,"MIGRATION_HOLD.txt"))
  }
  lo4_text(c(paste0("ACTION=",cfg$action),paste0("SIDECAR=",provenance),
      paste0("CENTRAL_READONLY_STATUS=",central$status),
      paste0("LO02_STATUS=",lo02$status),
      paste0("NLD_TASKS=",sum(sel$phase=="NLD")),
      paste0("FOREIGN_TASKS=",sum(sel$phase=="OECD19")),
      paste0("FOREIGN_N=",length(ref$foreign))),file.path(run,"PREFLIGHT.txt"))
  phaseout<-list()
  if(cfg$action!="plan_only") {
    for(ph in cfg$phases) {
      p<-tryCatch(lo_integrated_single_phase(bundle,cfg,run,ph,sel,joined,
              modules,central,lo02,ref,sciencefp),error=function(e)e)
      if(inherits(p,"error")) {
        phaseout[[length(phaseout)+1L]]<-data.frame(phase=ph,
         status=paste0("UNEXPECTED_FAILURE: ",conditionMessage(p)),n=NA_integer_)
        break
      }
      phaseout[[length(phaseout)+1L]]<-p
      if(grepl("FAILED|ERROR",p$status[1]))break
    }
  }
  if(length(phaseout)) {
    # Een lege/afgebroken fase kan andere rapportkolommen hebben.
    allnames<-unique(unlist(lapply(phaseout,names)))
    phaseout<-lapply(phaseout,function(z) {
      for(n in setdiff(allnames,names(z)))z[[n]]<-NA
      z[allnames]
    })
    lo4_csv(do.call(rbind,phaseout),file.path(run,"PHASE_STATUS.csv"))
  }
  # Resultaten die na de preflight zijn geproduceerd zitten ook direct in
  # dezelfde index, niet pas na een volgende aparte migratiescript-run.
  if(isTRUE(consolidation$ok) && cfg$action=="production") {
    refresh<-tryCatch(lo5_refresh_new_results(bundle,cfg,run),error=function(e)e)
    if(inherits(refresh,"error")) {
      lo4_text(conditionMessage(refresh),file.path(run,"POSTPRODUCTION_CONSOLIDATION_FAILURE.txt"))
      consolidation$ok<-FALSE
    }
  }
  # Opschonen uitsluitend na geverifieerde consolidatie; alleen exacte
  # dubbele oudere run-exports, geen unieke resultaten of canonical caches.
  gc_cfg<-cfg
  # Verwijdering pas na de eerste volledig uitgevoerde productieroute;
  # een plan-only, test-only of mislukte Windows-test mag niets verwijderen.
  gc_safe_phase <- cfg$action=="production" && length(phaseout)>0L &&
    !any(vapply(phaseout,function(z)any(grepl("FAILED|ERROR|UNEXPECTED",z$status)),logical(1)))
  if(!gc_safe_phase)gc_cfg$gc_policy<-"report_only"
  gcstatus<-tryCatch(lo5_gc(gc_cfg,consolidation,run),error=function(e)e)
  if(inherits(gcstatus,"error")){
    lo4_text(conditionMessage(gcstatus),file.path(run,"GC_FAILURE.txt"))
    gcstatus<-list(deleted=0L,bytes=0)
  }
  summary<-c("RUNNER=LEARNING_OUTCOMES_INTEGRATED_V2_20261010",
     paste0("ACTION=",cfg$action),paste0("SELECTED_TASKS=",nrow(sel)),
     paste0("NLD_TASKS=",sum(sel$phase=="NLD")),
     paste0("OECD19_TASKS=",sum(sel$phase=="OECD19")),
     "CENTRAL_7_OCT_STORAGE_CHANGED=FALSE",
     paste0("CONSOLIDATED_PROVENANCE_STATUS=",if(isTRUE(consolidation$ok))"VERIFIED_SNAPSHOTS"else"MIGRATION_HOLD"),
     paste0("GC_EXACT_DUPLICATES_DELETED=",gcstatus$deleted),
     paste0("GC_BYTES_FREED=",gcstatus$bytes),
     "UNIQUE_HISTORICAL_CACHES_PROTECTED=TRUE",
     "NONCORE_CANDIDATES_ARE_NOT_VALIDATED=TRUE",
     "SCIENTIFIC_FINAL_FREEZE=NOT_ACHIEVED",
     paste0("OUTPUT_DIRECTORY=",run),
     "NEXT=Inspect produced LO02 metrics and quarantine candidates; adjudicate holds before release")
  if(length(phaseout))summary<-c(summary,paste0("PHASE_",vapply(phaseout,`[[`,character(1),"phase"),"=",
                      vapply(phaseout,`[[`,character(1),"status")))
  lo4_text(summary,file.path(run,"STATUS.txt"))
  lo4_zip(run,c("STATUS.txt","PREFLIGHT.txt","PLAN_COUNTS.csv",
    "CONSOLIDATION_STATUS.csv","CONSOLIDATED_SOURCE_COUNTS.csv",
    "PRODUCT_REQUIREMENTS_TRACE.csv","FIGURE_COVERAGE.csv", "HISTORICAL_PRODUCT_PINS_STATUS.txt",
    "GC_CANDIDATES.csv","GC_DELETION_LOG.csv","GC_FAILURE.txt",
    "CONSOLIDATION_FAILURE.txt","MIGRATION_HOLD.txt",
    "POSTPRODUCTION_CONSOLIDATION.csv","POSTPRODUCTION_CONSOLIDATION_FAILURE.txt",
    "RELEASE_FINGERPRINTS.csv","NLD_CACHES_FOUND.csv","PHASE_STATUS.csv",
    "PHASE_NLD/WINDOWS_INTEGRATION_TESTS.csv",
    "PHASE_NLD/LO02_RELEASED_PISA_CORE_GENDER/AANTALLEN.csv",
    "PHASE_NLD/CANDIDATES_JOURNAL.csv","PHASE_NLD/RELEASED_EXECUTION_FAILURE.txt",
    "PHASE_NLD/WINDOWS_TEST_FAILURE.txt","PHASE_NLD/CANDIDATE_FAILURE.txt",
    "PHASE_OECD19/WINDOWS_INTEGRATION_TESTS.csv",
    "PHASE_OECD19/LO02_RELEASED_PISA_CORE_GENDER/AANTALLEN.csv",
    "PHASE_OECD19/CANDIDATES_JOURNAL.csv",
    "PHASE_OECD19/RELEASED_EXECUTION_FAILURE.txt",
    "PHASE_OECD19/WINDOWS_TEST_FAILURE.txt",
    "PHASE_OECD19/CANDIDATE_FAILURE.txt"),name="LEARNING_OUTCOMES_RETURN.zip")
  cat(paste(summary,collapse="\n"),"\n",sep="")
  cat("Upload retour: ",file.path(run,"LEARNING_OUTCOMES_RETURN.zip"),"\n",sep="")
  invisible(list(run=run,summary=summary))
}
