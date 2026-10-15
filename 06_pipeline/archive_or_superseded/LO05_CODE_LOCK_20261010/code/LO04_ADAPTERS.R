# The full module map is present, but no previously untested estimator is auto-released.
lo4_capabilities <- function(tasks) {
  pairs<-unique(tasks[c("survey","module")])
  direct<-c("core","gender","ses_national","migration","language_exact",
    "language_frequency","language_frequency_binary","peer_baseline",
    "ses_peer_exposure","home_language_peer_exposure","home_language_frequency_peer",
    "migration_binary_peer","high_proficiency_peer_exposure")
  pairs$adapter_engine<-ifelse(pairs$survey=="PISA" & pairs$module%in%c("core","gender"),
    "LO02_V5_RELEASED_ESTIMATOR",ifelse(pairs$module%in%direct,
      "V11_EXISTING_METHOD_ADAPTER_NOT_SCIENTIFICALLY_RELEASED",
      ifelse(pairs$module=="ses_harmonized","V11_COBREROS_SPECIAL_ROUTE_NOT_SCIENTIFICALLY_RELEASED",
        "LEGACY_OR_SPECIAL_MODULE_NO_VERIFIED_ENGINE_ADAPTER")))
  pairs$automatic_execute_permission<-"NO"
  pairs$validation_needed<-ifelse(pairs$module%in%c("ses_national","ses_harmonized","ses_peer_exposure"),
    "SES_CONSTRUCT_AND_PV_REPLICATE_AND_COBREROS_ANCHORS",
    ifelse(grepl("peer|exposure",pairs$module),"PEER_UNIT_DENOMINATOR_EXCLUDE_SELF_AND_UNCERTAINTY",
      ifelse(grepl("language|migration",pairs$module),"REVIEWED_SOURCE_CODEBOOK_AND_GROUP_MEANING",
        "OFFICIAL_COUNTRY_WAVE_PV_REPLICATE_AND_SAMPLE_VALIDATION")))
  pairs
}
lo4_module_gates <- function(bundle,cfg,pairs) {
  # A user-edited flag cannot turn an unvalidated handler into a released module.
  if(!nzchar(cfg$approved_module_gate_file))return(pairs[FALSE,,drop=FALSE])
  p<-lo4_norm(cfg$approved_module_gate_file)
  if(!file.exists(p))stop("Module certificate file ontbreekt: ",p)
  g<-lo4_read(p,c("survey","module","method_code_sha256","scientific_test_id","independent_review","release_status"))
  if(anyDuplicated(paste(g$survey,g$module))||any(!nzchar(g$scientific_test_id)))stop("Ambiguous or incomplete module certificates")
  g<-g[g$release_status=="APPROVED" & g$independent_review=="PASS",,drop=FALSE]
  if(!nrow(g))return(g)
  code_hash<-lo4_filehash(file.path(bundle,"code","LO04_EXTENDED_EXECUTION.R"))
  g<-g[g$method_code_sha256==code_hash,,drop=FALSE]
  g
}
lo4_approval_template <- function(pairs,bundle) {
  # No default approvals: this is a template for a future independently reviewed gate.
  out<-pairs[c("survey","module","adapter_engine","validation_needed")]
  out$method_code_sha256<-lo4_filehash(file.path(bundle,"code","LO04_EXTENDED_EXECUTION.R"))
  out$scientific_test_id<-""
  out$independent_review<-"NOT_PERFORMED"
  out$release_status<-"HOLD"
  out
}
lo4_plan_adapter <- function(q,pairs) {
  ix<-match(paste(q$survey,q$module),paste(pairs$survey,pairs$module))
  q$adapter_engine<-pairs$adapter_engine[ix]
  q$validation_needed<-pairs$validation_needed[ix]
  eligible<-q$phase%in%c("NLD","OECD19","FULL")
  notfound<-eligible & q$planning_action=="HOLD"
  q$planning_reason[notfound & q$adapter_engine=="LO02_V5_RELEASED_ESTIMATOR"]<-"READY_FOR_LOCAL_CACHE_AND_TEST_PREFLIGHT"
  q$planning_reason[notfound & grepl("V11_EXISTING",q$adapter_engine)]<-"ADAPTER_INTEGRATED_AWAITING_WIN_TEST_AND_METHOD_VALIDATION"
  q$planning_reason[notfound & grepl("COBREROS_SPECIAL",q$adapter_engine)]<-"COBREROS_SPECIAL_ENGINE_NEEDS_PINNED_REPLICATION_GATE"
  q$planning_reason[notfound & grepl("LEGACY_OR_SPECIAL",q$adapter_engine)]<-"NO_TESTED_DIRECT_ADAPTER_OLD_RESULTS_RETAINED_FOR_REVIEW"
  q
}
