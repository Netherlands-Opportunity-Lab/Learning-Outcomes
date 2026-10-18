# Maintenance only: fetch both named branches even in a single-branch clone.
# Bare branch arguments fetch objects into FETCH_HEAD, but do not necessarily
# create origin/<prepared> when remote.origin.fetch only tracks development.
# Explicit destinations leave that saved fetch policy unchanged. No force/reset.
lo_prepared_fetch <- function(run,development_branch,prepared_branch,expected) {
  if(length(expected)!=1L || is.na(expected) || !grepl('^[a-f0-9]{40}$',expected))
    stop('PREPARED_FETCH_EXACT_COMMIT_REQUIRED')
  branches<-c(development_branch,prepared_branch)
  refspecs<-paste0('refs/heads/',branches,':refs/remotes/origin/',branches)
  run(c('fetch','origin',refspecs))
  run(c('merge-base','--is-ancestor',expected,
        paste0('refs/remotes/origin/',prepared_branch)))
  invisible(NULL)
}
