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
# The explicit frame-N policy retains every separate PV target count and checks
# it against independently supplied evidence. A changed count file is rejected.
countfile<-tempfile(fileext='.csv')
cc<-data.frame(cell_id=rep(q$metric_key,each=2),pv=rep(1:2,3),n_frame=4L,
 n_target=c(4,4,2,1,2,3),n_definition='ANALYTIC_PEER_FRAME_WITH_SEPARATE_PV_TARGET_COUNTS')
write.csv(cc,countfile,row.names=FALSE)
obj2$meta$sample_count_rule<-'ANALYTIC_PEER_FRAME_WITH_SEPARATE_PV_TARGET_COUNTS'
obj2$meta$sample_count_evidence_path<-countfile
obj2$meta$sample_count_evidence_sha256<-digest::digest(file=countfile,algo='sha256')
stopifnot(identical(lo_compact_count_n(obj2,q),rep(4L,3L)))
cc$n_target[4]<-2L;write.csv(cc,countfile,row.names=FALSE)
stopifnot(inherits(try(lo_compact_count_n(obj2,q),silent=TRUE),'try-error'))
obj2$meta$sample_count_evidence_sha256<-digest::digest(file=countfile,algo='sha256')
stopifnot(inherits(try(lo_compact_count_n(obj2,q),silent=TRUE),'try-error'))
unlink(countfile)
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
# A source-relative language item needs no separately observed test-language
# identity. Missing actual required language data must still fail.
language_obj<-obj;language_obj$meta$language_definition<-'ASSESSMENT_LANGUAGE_RELATIVE_HOME_USE'
language_obj$meta$language_mapping_status<-'SOURCE_LABELS_AND_STUDENT_IDS_VERIFIED'
language_obj$data$DEMO_LANGUAGE<-c('test_language_home','other_language_home','test_language_home','other_language_home')
for(i in 1:80)language_obj$data[[paste0('RW',i)]]<-1
lo4_pv_fields<-function(d,domain)c('PV1','PV2')
language_q<-tasks[4,,drop=FALSE];language_q$module<-'language_exact'
h1<-lo_compact_projection(language_obj,language_q)
rownames(language_q)<-'98765'
stopifnot(identical(h1,lo_compact_projection(language_obj,language_q)))
language_obj$data$TEST_LANGUAGE<-'unused code'
stopifnot(identical(h1,lo_compact_projection(language_obj,language_q)))
language_obj$data$DEMO_LANGUAGE[1]<-'other_language_home'
stopifnot(!identical(h1,lo_compact_projection(language_obj,language_q)))
language_obj$data$DEMO_LANGUAGE<-NULL
stopifnot(inherits(try(lo_compact_projection(language_obj,language_q),silent=TRUE),'try-error'))
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

# A missing SES pupil cannot provide a valid peer denominator to an otherwise
# singleton focal pupil. National baseline N also excludes missing SES.
so<-obj;so$data$SES<-c(1,NA,1,2)
rc2_tails_rank<-function(x,w)list(q1=as.numeric(!is.na(x)&x==1),q4=as.numeric(!is.na(x)&x==2))
sq<-mq[1,,drop=FALSE];sq$module<-'ses_peer_exposure';sq$stat<-'q1_target_pct_q4_peers'
stopifnot(lo_compact_count_n(so,sq)==1L)
sq$module<-'peer_baseline';sq$stat<-'q1_share'
stopifnot(lo_compact_count_n(so,sq)==3L)

cat("PASS active minimal policy and below-basic self-excluded peer estimates, exact N and PV-N HOLD\n")

