source("06_pipeline/LO_COMPACT_RECOMPUTE.R",encoding="UTF-8")
source("06_pipeline/LO_COMPACT_GRID_STORE.R",encoding="UTF-8")
sha<-function(c)paste(rep(c,64L),collapse="")
tasks<-data.frame(metric_key=c("a","b","c","d"),
 contract_figure_id=c("TR_BASIC_age10_reading","GP_SES_HIGH_age10_reading",
                      "EN_PERFORMANCE_PEER_age10_reading","TR_BELOW_age10_reading"),
 country="NLD",survey="PISA",year="2022",domain="reading",module="core",
 stat="mean",group="total",definition="total",
 peer_definition="",threshold="",unit="score_points",calculation_policy="",
 stringsAsFactors=FALSE)
active<-lo_compact_active_tasks(tasks)
stopifnot(nrow(active)==1L,identical(active$metric_key,"d"),
          all(tasks$metric_key==c("a","b","c","d")))
# One source-available group of four synthetic pupils and two identical plausible values.
d<-data.frame(W=c(1,1,1,1), PV1=c(400,600,300,500),
              PV2=c(400,600,300,500),SCHOOL=c("A","A","B","B"))
obj<-list(data=d,meta=list(survey="PISA",year=2022L))
pv_names<-function(d,domain)c("PV1","PV2")
rc2_num<-function(x)as.numeric(x)
thresholds_for<-function(survey,domain)c(basic=450)
unit_for<-function(obj,peer_definition)obj$data$SCHOOL
rc2_replicate_design<-function(d,survey,year)list(w=d$W,n=2L,factor=1)
rc2_repweight<-function(des,r)des$w
v10_peer_matrix<-function(unit,peer,target,W) {
  out<-rep(NA_real_,ncol(W))
  for(j in seq_len(ncol(W))) {
    w<-W[,j];valid<-is.finite(peer)&is.finite(target)&w>0&!is.na(unit)
    values<-numeric(length(w));values[]<-NA_real_
    for(i in which(valid)) {
      peers<-which(valid&unit==unit[[i]]&seq_along(w)!=i)
      if(length(peers))values[[i]]<-sum(w[peers]*peer[peers])/sum(w[peers])
    }
    focus<-valid&target>0&is.finite(values)
    if(any(focus))out[[j]]<-sum(w[focus]*values[focus])/sum(w[focus])
  }
  out
}
rc2_pool<-function(f,rr,factor)list(estimate=colMeans(f),se=rep(0,ncol(f)))
q<-tasks[rep(4L,3L),,drop=FALSE]
q$metric_key<-c("peer_total","peer_low","peer_high")
q$module<-"peer_below_basic"
q$unit<-"percent"
q$group<-c("total","self_below_basic","self_at_or_above_basic")
q$peer_definition<-"whole_school"
p<-lo_compact_low_peer(obj,q)
stopifnot(identical(as.numeric(p$estimate),c(50,0,100)),
          all(p$se==0))
n<-lo_compact_count_n(obj,q)
stopifnot(identical(as.integer(n),c(4L,2L,2L)))
r<-lo_compact_science_rows(q,p,n,sha("a"),sha("b"),"TEST_SYNTHETIC_ONLY")
stopifnot(all(r$status=="COMPUTED_PENDING_VALIDATION"),all(r$n_unweighted>0))
# Different PV-dependent focal group counts cannot silently produce one false N.
obj2<-obj
obj2$data$PV2[[1L]]<-600
stopifnot(is.na(lo_compact_count_n(obj2,q)[[2L]]))
# Singletons have no eligible peer denominator. N cannot be fabricated.
obj3<-obj;obj3$data$SCHOOL<-c("A","B","C","D")
stopifnot(all(is.na(lo_compact_count_n(obj3,q))))
# The historical any-parent ID must invoke the actual any-parent science
# predicate, including both parent birthplace columns in its input SHA.
contract<-tasks[4L,,drop=FALSE]
contract$definition<-"MIGRATION_ANY_PARENT_ABROAD"
contract$module<-"migration"
contract$metric_key<-"immutable_original_metric_key"
mapped<-lo_compact_backend_tasks(contract)
stopifnot(mapped$definition=="nl_one_parent_abroad",
          identical(mapped$metric_key,contract$metric_key),
          contract$definition=="MIGRATION_ANY_PARENT_ABROAD")
# Exact pooled-score observation counts for source-labelled generations.
obj$data$DEMO_MIGRATION<-c("native","first_generation","second_generation","native")
migration_groups<-function(obj)list(ok=TRUE,group=obj$data$DEMO_MIGRATION)
gens<-tasks[rep(4L,5L),,drop=FALSE]
gens$module<-"migration_generation"
gens$stat<-c(rep("mean_score",3L),rep("mean_score_gap",2L))
gens$group<-c("native","first_generation","second_generation",
              "first_generation_minus_native","second_generation_minus_native")
gens$metric_key<-paste0("g",seq_len(nrow(gens)))
gn<-lo_compact_count_n(obj,gens)
stopifnot(identical(as.integer(gn),c(2L,1L,1L,3L,3L)))
cat("PASS source migration contract mapping and generation-level unweighted N\\n")
# Migration exposure uses strictly source-labelled native peers, with
# each focal pupil removed from her own peer denominator.
mq<-tasks[rep(4L,2L),,drop=FALSE]
mq$metric_key<-c("migration_peer_first","migration_peer_second")
mq$module<-"migration_peer_exposure"
mq$domain<-"all"
mq$unit<-"percent"
mq$stat<-c("first_generation_target_pct_native_peers",
           "second_generation_target_pct_native_peers")
mq$peer_definition<-"whole_school"
mp<-lo_compact_migration_peers(obj,mq)
stopifnot(identical(as.numeric(mp$estimate),c(100,100)),
          all(mp$se==0),
          identical(as.integer(lo_compact_count_n(obj,mq)),c(1L,1L)))
cat("PASS valid-category migration peer exposure and exact survey N\\n")

cat("PASS active minimal policy and below-basic self-excluded peer estimates, exact N and PV-N HOLD\n")
