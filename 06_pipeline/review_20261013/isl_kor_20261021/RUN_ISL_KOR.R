# Targeted, resumable execution using the existing scientific pipeline.
# The local launcher supplies private paths; this versioned file contains none.
local({
  repo <- Sys.getenv('LO_REPO_ROOT')
  stopifnot(nzchar(repo), file.exists(file.path(repo,'START.R')))
  cfg <- file.path(repo,'06_pipeline/review_20261013/isl_kor_20261021/RUN_CONFIG.json')
  x <- jsonlite::fromJSON(cfg)
  stopifnot(identical(sort(x$selection$countries),c('ISL','KOR')),
    !any(c('MIGRATION_GENERATION_SOURCE_LABELLED','MIGRATION_BOTH_PARENTS_ABROAD') %in% x$selection$definitions))
  Sys.setenv(LO_RUN_CONFIG=cfg, LO_START_ACTION='produce-approved',
    LO_GITHUB_RESULTS='review', LO_GITHUB_RESULTS_NAME='isl_kor_20261021')
  Sys.unsetenv(c('LO_SCOPE','LO_REPRODUCE_COMMIT','LO_ACTION'))
  message('Only Iceland and South Korea are selected. Completed valid cells are reused.')
  message('The current47 release remains frozen. This creates a separate aggregate review snapshot.')
  source(file.path(repo,'START.R'),local=new.env(parent=.GlobalEnv),encoding='UTF-8')
})
