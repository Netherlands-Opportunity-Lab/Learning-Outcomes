source("06_pipeline/LO_EXACT_BOOT.R")
w<-tempfile("bounded_boot_");dir.create(file.path(w,"engine"),recursive=TRUE)
helpers<-c("rc2_replicate_design","rc2_repweight","rc2_pool","rc2_num","rc2_bind","rc2_tails_rank","rc2_between")
writeLines(paste0(helpers," <- function(...) 'synthetic'"),file.path(w,"engine/BACKEND.R"))
writeLines(c('V10_BACKEND_FUNCTIONS <- "pv_names <- function(...) character()"',
 'v10_init_backend <- function(...) stop("MUST_NOT_INVENTORY_OR_INIT_LEGACY")',
 'v10_compute <- function(...) NULL'),file.path(w,"engine/V11.R"))
lo35_compute_extensions<-function(...)NULL
lo36_install_compute<-function(engine,extensions)stopifnot(exists("pv_names",engine))
before<-list.files(w,recursive=TRUE)
lo_exact_boot(w)
stopifnot(identical(before,list.files(w,recursive=TRUE)),all(vapply(helpers,exists,logical(1),envir=.GlobalEnv)))
unlink(w,recursive=TRUE)
cat("PASS pinned function boot without legacy initializer, source search or cache creation\n")
