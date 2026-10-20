# Contract tests for the isolated launcher, using a synthetic producer only.
args<-commandArgs(TRUE)
launcher<-if(length(args))args[1]else'scripts/START_FRESH_SOURCE_REPLICATION.R'
stopifnot(requireNamespace('jsonlite',quietly=TRUE),requireNamespace('digest',quietly=TRUE))
fixture<-tempfile('fresh-launcher-');dir.create(fixture)
fixture<-normalizePath(fixture,winslash='/',mustWork=TRUE)
stopifnot(startsWith(fixture,paste0(normalizePath(tempdir(),winslash='/'),'/')))
repo<-file.path(fixture,'repo');dir.create(repo)
dir.create(file.path(repo,'06_pipeline/review_20261013/release47_20261020'),recursive=TRUE)
write_json<-function(x,p)jsonlite::write_json(x,p,auto_unbox=TRUE,pretty=TRUE)
sha<-function(p)digest::digest(file=p,algo='sha256')
phase<-file.path(repo,'06_pipeline/review_20261013/release47_20261020/RELEASE_PHASE_DECISION.json')
write_json(list(current_countries=c('NLD','USA'),deferred_countries='KOR'),phase)
config<-file.path(fixture,'config.json')
write_json(list(scope='all_required',selection=list(countries=c('NLD','USA'))),config)
raw<-file.path(fixture,'synthetic-source.txt');writeLines('synthetic source only',raw)
bindings<-file.path(fixture,'bindings.csv')
write.csv(data.frame(sha256=sha(raw),path=raw),bindings,row.names=FALSE)
root<-file.path(fixture,'new-run')
drive<-file.path(fixture,'drive.json')
write_json(list(data_visibility='PRIVATE_ACCOUNT_ONLY',remote='private:project/fresh-current47-test',
                local_results_root=root),drive)
reference<-file.path(fixture,'expected.csv')
write.csv(data.frame(cell_id=c('valid','missing'),status=c('SCIENTIFICALLY_VALIDATED','UNAVAILABLE_VERIFIED_SOURCE_FIELD'),
  estimate=c('1.25',''),standard_error=c('0.25',''),n_unweighted=c('5',''),
  hold_reason=c('','NO_SOURCE_FIELD')),reference,row.names=FALSE)
writeLines('lo_production_free_bytes<-function(path)10*1024^3',file.path(repo,'06_pipeline/LO_PRODUCTION_SPACE.R'))
writeLines(c(
  "stopifnot(Sys.getenv('LO_FRESH_REPLICATION')=='1',Sys.getenv('LO_GITHUB_RESULTS')=='off')",
  "root<-Sys.getenv('LO_FIXED_ROOT'); state<-file.path(root,'FIXED_PRODUCTION_V1/all_required')",
  "dir.create(state,recursive=TRUE,showWarnings=FALSE)",
  "jsonlite::write_json(list(sha256=list(fresh_source_replication='ENABLED')),file.path(state,'FIXED_INPUT_MANIFEST.json'),auto_unbox=TRUE)",
  "write.csv(data.frame(cell_id=c('missing','valid'),status=c('UNAVAILABLE_VERIFIED_SOURCE_FIELD','SCIENTIFICALLY_VALIDATED'),estimate=c('',1.25),standard_error=c('',0.25),n_unweighted=c('',5),hold_reason=c('NO_SOURCE_FIELD','')),file.path(state,'PRIVATE_MASTER_GRID.csv'),row.names=FALSE)"
),file.path(repo,'START.R'))
settings<-list(repository=repo,code_commit=strrep('a',40),output_root=root,
  configuration_path=config,configuration_sha256=sha(config),source_bindings=bindings,
  source_bindings_sha256=sha(bindings),author_repository=file.path(fixture,'author'),
  drive_config=drive,drive_config_sha256=sha(drive),python='unused-in-fixture',git='mock-git',
  reference_grid=reference,reference_grid_sha256=sha(reference),minimum_free_bytes=8*1024^3)
settings_file<-file.path(fixture,'settings.json');write_json(settings,settings_file)
e<-new.env(parent=.GlobalEnv)
syscalls<-0L
e$system2<-function(command,args,...) {
  syscalls<<-syscalls+1L
  if(any(grepl('author',args,fixed=TRUE)))'1da4b26097e84e732973af672355a1c3103d5d33'else strrep('a',40)
}
source(launcher,local=e)
run<-e$lo_start_fresh_source_replication
fail<-function(expr,pattern) {
  err<-tryCatch({force(expr);NULL},error=identity)
  stopifnot(inherits(err,'error'),grepl(pattern,conditionMessage(err),fixed=TRUE))
}
preview<-run(settings_file,preview=TRUE)
stopifnot(preview$ready_for_space,preview$estimations_run==0L,!dir.exists(root),syscalls==2L)
old<-Sys.getenv(c('LO_FIXED_ROOT','LO_REPRODUCE_COMMIT','LO_GITHUB_RESULTS'),unset=NA_character_)
proof<-run(settings_file)
stopifnot(proof$status=='FULL_SELECTED_GRID_NUMERICAL_PARITY_PASS',
  identical(Sys.getenv(names(old),unset=NA_character_),old))
proof2<-run(settings_file)
stopifnot(proof2$status==proof$status) # Resume contract and row-order independent comparison.
settings$minimum_free_bytes<-9*1024^3;write_json(settings,settings_file)
fail(run(settings_file),'FRESH_RESUME_CONTRACT_CHANGED')
settings$minimum_free_bytes<-11*1024^3;write_json(settings,settings_file)
fail(run(settings_file),'FRESH_RUN_SPACE_BUDGET_NOT_MET')
settings$minimum_free_bytes<-8*1024^3;settings$output_root<-file.path(repo,'forbidden')
write_json(settings,settings_file);fail(run(settings_file),'FRESH_OUTPUT_OVERLAPS')
settings$output_root<-root;write_json(settings,settings_file)
writeLines('changed configuration',config);fail(run(settings_file),'FRESH_SETTINGS_BYTES_CHANGED')
write_json(list(scope='all_required',selection=list(countries=c('NLD','USA','KOR'))),config)
settings$configuration_sha256<-sha(config);write_json(settings,settings_file)
fail(run(settings_file),'FRESH_RUN_MUST_USE_EXACT_CURRENT47_SELECTION')
unlink(fixture,recursive=TRUE)
cat('Fresh launcher: isolated selection, preview, parity, resume, environment restoration, input invalidation and space guards PASS; no pupil data used.\n')
