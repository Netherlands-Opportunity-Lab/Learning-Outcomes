# Load the pinned statistical functions without initializing legacy downloads,
# broad cache searches, inventories, calibration repositories or source fallback.
lo_exact_boot <- function(bundle) {
  old<-options(pisa.fast.functions_only=TRUE,pisa.completion.functions_only=TRUE)
  on.exit(options(old),add=TRUE)
  # Windows may start in C after an inherited C.UTF-8 locale is rejected.
  # The pinned source is valid UTF-8 and includes non-ASCII scientific labels.
  ctype<-Sys.getlocale("LC_CTYPE")
  if(.Platform$OS.type=="windows" && !isTRUE(l10n_info()[["UTF-8"]])) {
    if(!nzchar(Sys.setlocale("LC_CTYPE","English_United States.utf8")))stop("EXACT_UTF8_LOCALE_REQUIRED")
    on.exit(Sys.setlocale("LC_CTYPE",ctype),add=TRUE)
  }
  source(file.path(bundle,"engine","V11.R"),local=.GlobalEnv,encoding="UTF-8")
  expressions<-as.list(parse(file.path(bundle,"engine","BACKEND.R")))
  for(n in c("rc2_replicate_design","rc2_repweight","rc2_pool","rc2_num","rc2_bind",
             "rc2_tails_rank","rc2_between")) {
    defs<-Filter(function(x)is.call(x)&&as.character(x[[1]])%in%c("<-","=")&&
      is.symbol(x[[2]])&&as.character(x[[2]])==n,expressions)
    if(!length(defs))stop("EXACT_PINNED_ENGINE_FUNCTION_MISSING: ",n)
    eval(defs[[1]],.GlobalEnv)
  }
  assign("rc2_pool_engine_v8",get("rc2_pool",.GlobalEnv),.GlobalEnv)
  eval(parse(text=get("V10_BACKEND_FUNCTIONS",.GlobalEnv)),.GlobalEnv)
  if(exists('lo_exact_peer_share',mode='function'))
    assign('peer_share',lo_exact_peer_share,.GlobalEnv)
  if(exists('lo_exact_categorical_peer',mode='function'))
    assign('v10_peer',lo_exact_categorical_peer,.GlobalEnv)
  if(exists('lo_exact_peer_matrix',mode='function'))
    assign('v10_peer_matrix',lo_exact_peer_matrix,.GlobalEnv)
  if(exists("lo_exact_language_groups",mode="function"))
    assign("language_groups",lo_exact_language_groups,.GlobalEnv)
  if(exists(".lo36_original_compute",.GlobalEnv,inherits=FALSE))
    rm(".lo36_original_compute",envir=.GlobalEnv)
  lo36_install_compute(.GlobalEnv,lo35_compute_extensions)
  invisible(TRUE)
}
