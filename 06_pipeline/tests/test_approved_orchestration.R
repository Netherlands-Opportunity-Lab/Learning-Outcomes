# Exercise the real START.R orchestration with synthetic Git/runner boundaries.
# No network, real results or source data. Assert immutable stages, finalization,
# checkpoint-before-deposit order, environment restoration and failure stopping.
real_repo<-normalizePath('.',winslash='/')
tmp<-tempfile();dir.create(tmp);dir.create(file.path(tmp,'.git'));dir.create(file.path(tmp,'06_pipeline'))
stopifnot(file.copy('06_pipeline/LO_PROCESS_LOCK.R',file.path(tmp,'06_pipeline/LO_PROCESS_LOCK.R')))
writeLines('',file.path(tmp,'06_pipeline/RUN.R'))
writeLines('',file.path(tmp,'06_pipeline/LO_RUN_CONFIG.R'))
writeLines("lo_remote_checkpoint<-function(...)trace('checkpoint')",file.path(tmp,'06_pipeline/LO_REMOTE_CHECKPOINT.R'))
writeLines("lo_github_results_deposit<-function(...)trace('deposit')",file.path(tmp,'06_pipeline/LO_GITHUB_RESULTS.R'))
config<-file.path(tmp,'run.json');jsonlite::write_json(list(scope='all_required'),config,auto_unbox=TRUE)
keys<-c('LO_REPO_ROOT','LO_START_ACTION','LO_REPRODUCE_COMMIT','LO_ACTION','LO_DEFER_PRIVATE_DRIVE','LO_GITHUB_RESULTS','LO_RUN_CONFIG','LO_FIXED_ROOT')
before<-Sys.getenv(keys,unset=NA_character_)
Sys.setenv(LO_REPO_ROOT=tmp,LO_START_ACTION='produce-approved',LO_ACTION='original-action',LO_DEFER_PRIVATE_DRIVE='original-drive',LO_GITHUB_RESULTS='review',LO_RUN_CONFIG=config,LO_FIXED_ROOT=tmp)
Sys.unsetenv('LO_REPRODUCE_COMMIT')
run<-function(fail_at='') {
  e<-new.env(parent=.GlobalEnv);e$events<-list()
  e$trace<-function(stage) {
    e$events[[length(e$events)+1L]]<-list(stage=stage,commit=Sys.getenv('LO_REPRODUCE_COMMIT'),scope=jsonlite::fromJSON(config)$scope)
    if(identical(stage,fail_at))stop('SIMULATED_STAGE_FAILURE')
  }
  e$Sys.which<-function(x)setNames('synthetic-git',x)
  e$system2<-function(command,args,...) {
    args<-gsub("^['\"]|['\"]$",'',args)
    if('get-url'%in%args)return('https://github.com/Netherlands-Opportunity-Lab/Learning-Outcomes')
    if('--git-common-dir'%in%args)return('.git')
    if('--show-current'%in%args)return('feat/reproducible-storage-and-cleanup-20261010')
    if('pull'%in%args){e$trace('pull');return('Already up to date.')}
    if('HEAD'%in%args)return(paste(rep('a',40),collapse=''))
    stop('UNEXPECTED_GIT_CALL')
  }
  e$source<-function(file,local=FALSE,...) {
    if(basename(file)=='RUN.R') {
      if(isTRUE(getOption('lo.pipeline.functions_only'))) {
        local$lo_pipeline_drive_config_path<-function()file.path(tmp,'absent-drive-config')
      }else e$trace(Sys.getenv('LO_ACTION'))
      return(invisible(NULL))
    }
    base::source(file,local=local,...)
  }
  result<-tryCatch(base::source(file.path(real_repo,'START.R'),local=e),error=identity)
  list(result=result,events=e$events)
}
x<-run();stopifnot(!inherits(x$result,'error'))
stages<-vapply(x$events,`[[`,character(1),'stage')
stopifnot(identical(stages,c('pull','fixed-audit','fixed-produce','fixed-finalize','fixed-status','checkpoint','deposit')),
 all(vapply(x$events[-1],`[[`,character(1),'commit')==paste(rep('a',40),collapse='')),
 all(vapply(x$events,`[[`,character(1),'scope')=='all_required'),
 Sys.getenv('LO_REPRODUCE_COMMIT')=='',Sys.getenv('LO_ACTION')=='original-action',Sys.getenv('LO_DEFER_PRIVATE_DRIVE')=='original-drive')
# A failed computation cannot fall through to final export/deposit. The next
# invocation reacquires the same real startup lock, which must be released.
x<-run('fixed-produce');stopifnot(inherits(x$result,'error'),
 identical(vapply(x$events,`[[`,character(1),'stage'),c('pull','fixed-audit','fixed-produce')))
x<-run();stopifnot(!inherits(x$result,'error'))
for(k in keys)if(is.na(before[[k]]))Sys.unsetenv(k)else do.call(Sys.setenv,setNames(list(before[[k]]),k))
unlink(tmp,recursive=TRUE)
cat('PASS real bootstrap stage ordering, immutable commit/config, finalization, failure propagation and lock release\n')
