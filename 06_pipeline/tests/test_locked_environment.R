# Run only after renv::restore() into the clean CI project library.
# Keep R expressions in a file: both Bash and PowerShell expand '$' in -e text.
.libPaths(c(renv::paths$library(project='.'),.libPaths()))
source('06_pipeline/LO_ENVIRONMENT.R')
stopifnot(lo_environment_check('.',strict=TRUE)$all_match)
source('06_pipeline/tests/test_exact_dispatch.R')
source('06_pipeline/tests/test_pisa_source_block.R')
source('06_pipeline/tests/test_iea_source_block.R')
source('06_pipeline/tests/test_iea_background.R')
source('06_pipeline/tests/test_pisa_legacy_source.R')
cat('PASS restored exact environment and scientific execution contracts\n')
