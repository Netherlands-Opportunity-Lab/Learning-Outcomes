# Production dispatcher; only existing LO02 registry is mutated, never old central project storage.
lo4_pisa_v5_execute <- function(bundle,cfg,run,q) {
  if(!nrow(q))return(invisible(NULL))
  ids<-unique(q$metric_key)
  all_selected<-q
  engine<-file.path(bundle,"engine")
  e<-new.env(parent=.GlobalEnv)
  source(file.path(engine,"production.R"),local=e,encoding="UTF-8")
  base_candidates<-e$lo5_candidates
  e$lo5_candidates<-local({allowed<-ids;original<-base_candidates;
    function(z) original(z) & z$metric_key%in%allowed})
  # Safe override of the previous 'two different RDS bytes = crash' behaviour.
  # The actual scientific columns must match (not just filenames/dates).
  e$lo5_cache<-local({
    work<-all_selected
    function(root,country,year){
      xx<-work[work$country==country & work$year==as.character(year) & work$survey=="PISA",,drop=FALSE]
      if(!nrow(xx))stop("Unexpected PISA year/country requested: ",country,"/",year)
      lo4_choose_cache(root,"PISA",year,country,xx)
    }
  })
  out<-file.path(run,"LO02_RELEASED_PISA_CORE_GENDER")
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  wcfg<-list(root=cfg$project_root,output=cfg$lo02_root,workers=1L,
    countries=unique(q$country),waves=sort(unique(as.integer(q$year))),domains=unique(q$domain),mode="execute")
  e$lo5_run(engine,wcfg,out)
  # Durable producer links are exported from exact LO02 task plan; do not assume all rows were computed.
  p<-file.path(out,"PRODUCTIEPLAN.csv")
  if(file.exists(p)){
    results<-lo4_read(p)
    done<-results[results$reason%in%c("COMPUTED_AND_COMMITTED","EXACT_SCIENTIFIC_AND_INPUT_IDENTITY") & nzchar(results$science_fingerprint),,drop=FALSE]
    if(nrow(done)) {
      fingerprints<-vapply(file.path(engine,c("V11.R","BACKEND.R","REPAIRS.R","EXTENSIONS.R")),lo4_filehash,character(1))
      done$producer_code_family_hash<-lo4_hash(fingerprints)
      lo4_csv(done[c("metric_key","country","survey","year","domain","module","source_path","source_sha256","input_fingerprint","science_fingerprint","producer_code_family_hash")],
        file.path(run,"LO02_PISA_PRODUCER_LINKS.csv"))
    }
  }
  invisible(TRUE)
}
lo4_approved_execution <- function(bundle,cfg,run,q,capabilities,planfingerprint) {
  if(cfg$action!="execute_ready"||!identical(cfg$execute_approval,TRUE))stop("Execute approval missing")
  # Plan fingerprint derives from exact task keys and engine, not from UI reference changes.
  if(nzchar(cfg$reviewed_plan_fingerprint) && !identical(planfingerprint,cfg$reviewed_plan_fingerprint))
    stop("PLAN_FINGERPRINT_MISMATCH: refuse execute")
  if(!identical(cfg$write_existing_project_registry,FALSE)||!identical(cfg$delete_files,FALSE))stop("Storage/GC policy disallows writes")
  tests<-file.path(cfg$output_root,"LO05_WINDOWS_ACCEPTANCE_PASS.txt")
  if(!file.exists(tests))stop("Geen ondertekende/geverifieerde Windows-testvrijgave gevonden: ",tests)
  # The acceptance file must bind to exact active engine/code hashes, not to filename alone.
  lines<-readLines(tests,warn=FALSE)
  enginefp<-lo4_hash(vapply(file.path(bundle,"engine",c("V11.R","BACKEND.R","REPAIRS.R","EXTENSIONS.R")),lo4_filehash,character(1)))
  if(!paste0("ENGINE_FINGERPRINT=",enginefp)%in%lines)stop("Acceptance proof is stale after engine change")
  if(!"RESULT=PASS"%in%lines)stop("Windows acceptance has not passed")
  if(!paste0("RUNNER_FINGERPRINT=",lo4_runner_code_fingerprint(bundle))%in%lines)
    stop("Runner-code gewijzigd sinds de Windows-test")
  if(!paste0("TESTED_TASK_KEYS_FINGERPRINT=",lo4_hash(sort(q$metric_key[q$phase%in%c("NLD","OECD19","FULL")])))%in%lines)
    stop("Selectie van taak-IDs gewijzigd sinds de Windows-test")
  if(!paste0("RUN_MODE=",cfg$run_mode)%in%lines)
    stop("Productiemodus gewijzigd sinds de Windows-test")
  if(!paste0("PRODUCTION_PHASE=",cfg$production_phase)%in%lines)
    stop("Productiefase gewijzigd sinds de Windows-test")
  if(!file.exists(file.path(cfg$lo02_root,"registry_v5","PROJECT_RESULTS_REGISTRY.sqlite")))
    stop("Bestaand LO02 registry ontbreekt, stop: geen nieuwe silo aanmaken")
  eligible<-q[q$phase%in%c("NLD","OECD19","FULL"),,drop=FALSE]
  eligible<-eligible[eligible$phase==cfg$production_phase | cfg$production_phase=="FULL",,drop=FALSE]
  v5<-eligible[eligible$survey=="PISA" & eligible$module%in%c("core","gender"),,drop=FALSE]
  if(nrow(v5))lo4_pisa_v5_execute(bundle,cfg,run,v5)
  # Explicit scientific approval needed for every non-v5 module, no silent fall-through.
  gates<-lo4_module_gates(bundle,cfg,capabilities)
  ext<-eligible[!(eligible$survey=="PISA" & eligible$module%in%c("core","gender")),,drop=FALSE]
  permitted<-paste(ext$survey,ext$module)%in%paste(gates$survey,gates$module)
  hold<-ext[!permitted,,drop=FALSE]
  if(nrow(hold)){
    hold$reason<-"NO_APPROVED_SCIENTIFIC_GATE_YET"
    lo4_csv(hold,file.path(run,"UNRELEASED_MODULE_HOLDS.csv"))
  }
  if(any(permitted))lo4_extended_store(bundle,cfg,run,gates,ext[permitted,,drop=FALSE])
  # No central promotion, no automatic delete, no public-release flag.
  lo4_text(c("STATUS=EXECUTED_ONLY_CERTIFIED_ADAPTERS","CENTRAL_PROJECT_STORAGE_MODIFIED=FALSE",
    "PUBLICATION_RELEASE=NO","GC_PERFORMED=FALSE","NEXT=Review local scientific output and reconcile central registry"),
    file.path(run,"EXECUTION_GATES.txt"))
  invisible(TRUE)
}
