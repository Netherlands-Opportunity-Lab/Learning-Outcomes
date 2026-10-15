# Optional bounded real-data smoke tests; never a full method validation or production.
# This file is sourced only from LO04 action=scientific_smoke (no registry writes).
lo4_science_smoke <- function(bundle,cfg,run,tasks) {
  # No implicit raw import; existing canonical caches only.
  for(f in c("REPAIRS.R","EXTENSIONS.R","store.R","engine.R"))
    source(file.path(bundle,"engine",f),local=.GlobalEnv,encoding="UTF-8")
  lo_engine_boot(file.path(bundle,"engine"),list(root=cfg$project_root),file.path(run,"science_smoke_engine"),synthetic=FALSE)
  tests<-data.frame(survey=c("PISA","PISA","PISA","PIRLS","PIRLS","TIMSS","TIMSS"),
    year=c("2018","2018","2018","2021","2021","2023","2023"),
    module=c("core","ses_national","migration","core","language_frequency_binary","core","ses_peer_exposure"),
    stat=c("mean","q1_mean","mean","mean","mean","mean","q1_target_pct_q4_peers"),
    stringsAsFactors=FALSE)
  done<-list()
  for(i in seq_len(nrow(tests))){
    t<-tests[i,,drop=FALSE]
    q<-tasks[tasks$country=="NLD"&tasks$survey==t$survey & tasks$year==t$year &
            tasks$module==t$module & tasks$stat==t$stat,,drop=FALSE]
    if(nrow(q))q<-q[1,,drop=FALSE]
    res<-tryCatch({
      if(!nrow(q))stop("Testtaak ontbreekt in contract")
      obj<-lo4_choose_cache(cfg$project_root,t$survey,t$year,"NLD",q)$object
      ans<-v10_compute(obj,q)
      if(nrow(ans)!=1L||!identical(ans$metric_key,q$metric_key)||
         !all(is.finite(as.numeric(ans[1,c("estimate","se","ci_low","ci_high")])))||
         ans$se<0)stop("Schatting, SE of output key ongeldig")
      list(status="SMOKE_PASS_ONLY_NOT_SCIENCE_VALIDATED",reason="",estimate=ans$estimate,se=ans$se)
    },error=function(e)list(status="SMOKE_HOLD",reason=conditionMessage(e),estimate=NA_real_,se=NA_real_))
    done[[length(done)+1L]]<-data.frame(t,status=res$status,reason=res$reason,
       estimate=res$estimate,se=res$se,stringsAsFactors=FALSE)
  }
  z<-do.call(rbind,done)
  lo4_csv(z,file.path(run,"REAL_SURVEY_MODULE_SMOKE.csv"))
  z
}
