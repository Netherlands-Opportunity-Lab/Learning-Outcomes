# Run only with LO04 runner action=windows_tests. No production microdata outputs are published.
lo4_windows_tests <- function(bundle,cfg,run,plan,central,lo02,ref,sciencefp) {
  checks<-list()
  add<-function(name,status,detail="") {
    checks[[length(checks)+1L]]<<-data.frame(check=name,status=status,detail=as.character(detail),stringsAsFactors=FALSE)
    cat(name," ",status," ",detail,"\n",sep="")
  }
  for(f in c(list.files(file.path(bundle,"code"),pattern="\\.R$",full.names=TRUE),
              file.path(bundle,"engine",c("V11.R","BACKEND.R","REPAIRS.R","EXTENSIONS.R","production.R","store.R","engine.R","tests.R")),
              file.path(bundle,"LEARNING_OUTCOMES_RUN.R"))){
    test<-tryCatch({parse(f);TRUE},error=function(e)e)
    if(identical(test,TRUE))add(paste0("R_PARSE_",basename(f)),"PASS") else add(paste0("R_PARSE_",basename(f)),"FAIL",conditionMessage(test))
  }
  add("EXACT_19_COUNTRY_FOREIGN_REFERENCE",if(length(ref$foreign)==19L&&!"NLD"%in%ref$foreign&& !"CZE"%in%ref$foreign)"PASS"else"FAIL")
  add("PLAN_KEYS_UNIQUE",if(!anyDuplicated(plan$metric_key))"PASS"else"FAIL")
  add("OLD_CENTRAL_READONLY_CONSISTENCY",if(central$status=="CENTRAL_CURRENT_MATCHES_SQLITE")"PASS"else"HOLD",central$status)
  add("LO02_READONLY_CONSISTENCY",if(lo02$status=="LO02_LIVE_SQLITE_PARQUET_MATCH")"PASS"else"HOLD",lo02$status)
  # This is a deep *scientific-input-column* test, never a 'newest file wins' heuristic.
  test_plan<-plan[plan$survey=="PISA" & plan$country=="NLD" & plan$module%in%c("core","gender"),,drop=FALSE]
  cache<-tryCatch(lo4_cache_audit(cfg$project_root,test_plan,deep=TRUE),error=function(e)e)
  if(inherits(cache,"error"))add("NLD_CACHE_SEMANTIC_ADJUDICATION","FAIL",conditionMessage(cache))
  else{
    lo4_csv(cache,file.path(run,"NLD_CACHE_SEMANTIC_AUDIT.csv"))
    # A conflict in one year must not force recomputation or invalidate clean years.
    # The production cache chooser independently HOLDs each conflicting unit.
    good<-cache$comparison%in%c("SCIENTIFIC_INPUT_PROJECTION_EQUIVALENT","SINGLE_CANDIDATE_PROJECTION_TESTED","EXACT_FILE_DUPLICATE")
    bad<-unique(cache$year[grepl("CONFLICT|REQUIRES_SOURCE_REPAIR",cache$comparison)])
    absent<-unique(cache$year[grepl("ABSENT",cache$comparison)])
    add("NLD_CACHE_SEMANTIC_ADJUDICATION",if(any(good))"PASS"else"HOLD",
      paste0("good_years=",paste(unique(cache$year[good]),collapse=","),
             ";conflicting_years=",paste(bad,collapse=","),
             ";absent_years=",paste(absent,collapse=","),
             ";missing/conflicting years remain per-year HOLDS"))
  }
  # Prior LO02 Windows self-tests; synthetic isolated state, NOT real scientific module approval.
  old<-getwd();setwd(run);on.exit(setwd(old),add=TRUE)
  testdir<-file.path(run,"ISOLATED_SYNTHETIC_INTEGRATION")
  dir.create(testdir,recursive=TRUE,showWarnings=FALSE)
  b<-tryCatch({
    for(f in c("REPAIRS.R","EXTENSIONS.R","store.R","engine.R","tests.R"))
      source(file.path(bundle,"engine",f),local=.GlobalEnv,encoding="UTF-8")
    r<-lo_integration_tests(file.path(bundle,"engine"),list(root=cfg$project_root),testdir)
    r
  },error=function(e)e)
  if(inherits(b,"error"))add("LO02_SQLITE_PARQUET_INTERRUPT_RESUME_SYNTHETIC","FAIL",conditionMessage(b))
  else add("LO02_SQLITE_PARQUET_INTERRUPT_RESUME_SYNTHETIC",if(all(b$status=="PASS"))"PASS"else"FAIL",
           paste(sum(b$status=="PASS"),"/",nrow(b),sep=""))
  # A method function being present does NOT prove that PISA/PIRLS/TIMSS output is valid.
  add("PIRLS_TIMSS_SES_LANGUAGE_MIGRATION_PEER_RELEASE","HOLD","Real survey design/canonical/official benchmark smoke tests not yet independently approved")
  add("COBREROS_34_36_AUTHOR_REPLICATION_RELEASE","HOLD","Pinned research calibration / sample / linkage uncertainty gates open")
  add("PROJECT_OLD_V11_MIGRATION_AND_GC","HOLD","No deletion; old V11 caches protected pending cold-restart comparison")
  report<-do.call(rbind,checks)
  lo4_csv(report,file.path(run,"WINDOWS_INTEGRATION_TESTS.csv"))
  lo4_text(capture.output(sessionInfo()),file.path(run,"WINDOWS_SESSION_INFO.txt"))
  # No permission token on any infrastructure HOLD or FAIL. This is deliberate.
  essential<-c("EXACT_19_COUNTRY_FOREIGN_REFERENCE","PLAN_KEYS_UNIQUE",
              "OLD_CENTRAL_READONLY_CONSISTENCY","LO02_READONLY_CONSISTENCY",
              "NLD_CACHE_SEMANTIC_ADJUDICATION","LO02_SQLITE_PARQUET_INTERRUPT_RESUME_SYNTHETIC")
  got<-report$status[match(essential,report$check)]
  pass<-length(got)==length(essential) && all(!is.na(got) & got=="PASS") &&
     !any(report$status[grepl("^R_PARSE_",report$check)]!="PASS")
  # Explicitly non-automatic: a successful selftest report is evidence, not a user release decision.
  if(pass) {
    # Automatically store only an INFRASTRUCTURE acceptance receipt.
    # The user must separately request execute; no scientific publication is implied.
    p<-file.path(run,"LOCAL_INFRASTRUCTURE_TESTS_PASS_NOT_SCIENCE_RELEASE.txt")
    runnerfp<-lo4_runner_code_fingerprint(bundle)
    lo4_text(c("RESULT=PASS","SCIENCE_FULL_SCOPE_RELEASE=FALSE",
               paste0("ENGINE_FINGERPRINT=",sciencefp),
               paste0("RUNNER_FINGERPRINT=",runnerfp),
               paste0("TESTED_TASK_KEYS_FINGERPRINT=",lo4_hash(sort(plan$metric_key[plan$phase==cfg$production_phase | cfg$production_phase=="FULL"]))),
               paste0("RUN_MODE=",cfg$run_mode),paste0("PRODUCTION_PHASE=",cfg$production_phase),
               paste0("RUN_ID=",basename(run)),"VALID_FOR_EXECUTE_OF_ALREADY_TESTED_PISA_ONLY=TRUE"),p)
    file.copy(p,file.path(cfg$output_root,"LO05_WINDOWS_ACCEPTANCE_PASS.txt"),overwrite=TRUE)
  }
  pass
}
