source("06_pipeline/LO_SCOPE_DECISIONS.R")
source("06_pipeline/LO_APPROVED_EXTENSIONS.R")
source("06_pipeline/LO_EXACT_ESTIMATORS.R")
source("06_pipeline/LO_COMPACT_RECOMPUTE.R")
dec<-lo_read_scope_decisions(".")
dec$status<-"APPROVED";dec$decision_date<-"2026-10-14";dec$user_evidence<-"SYNTHETIC TEST"
t<-data.frame(country="NLD",survey="TIMSS",year="2023",domain="math",module=c("core","ses_national"),
 stat=c("mean","q1_mean"),group=c("total","q1"),definition=c("total","books5_fractional"),
 peer_definition="",threshold="",unit="score_points",calculation_policy="",metric_key=c("base","ses"),
 outcome="mean_score",contract_figure_id=c("TR_MEAN_age10_math","GP_SES_LEVELS_age10_math"))
x<-lo_extension_tasks(t,dec)
# Actual all_required finalization has no countries outside the selected scope.
# Empty references and legitimate core-only selections must preserve zero rows.
stopifnot(nrow(lo_extension_tasks(t[FALSE,,drop=FALSE],dec))==0L)
core_only<-lo_extension_tasks(t[t$module=='core',,drop=FALSE],dec)
stopifnot(nrow(core_only)>0L,!any(grepl('extension_ses',core_only$module)))
source('06_pipeline/MASTER_ESTIMATION_GRID.R')
source('06_pipeline/LO_BALANCED_EXPORT.R')
empty_reference<-lo_reference_only_grid(t,data.frame(),
  list(selected='NLD',reference_candidates='NLD'),dec)
stopifnot(nrow(empty_reference)==0L,identical(names(empty_reference),lo_grid_schema()))
source('06_pipeline/LO_GENDER_POOL_POLICY.R')
source('06_pipeline/LO_BALANCED_MEMBERSHIP.R')
source('06_pipeline/LO_COUNTRY_TASKS.R')
local({
  # The constructor must find the certified pooled foreign ID in nld_only.
  # Artifact verification itself is exercised by the separate archive tests.
  d<-tempfile('reference_pool_');dir.create(d);on.exit(unlink(d,recursive=TRUE))
  h<-paste(rep('a',64),collapse='')
  jsonlite::write_json(list(country='AUS',year=2025,canonical_sha256=h,
    gender_status='PARTIAL_SOURCE_GENDER_GIRL_UNRESOLVED',
    source_value_labels=list(MALE=list('Female / Other'=0,Male=1))),
    file.path(d,'SOURCE_VERIFICATION.json'),auto_unbox=TRUE)
  b<-t[1,,drop=FALSE];b$survey<-'PISA';b$year<-'2025';b$domain<-'reading'
  b$module<-'gender';b$stat<-'mean_score';b$group<-'girl';b$definition<-'gender'
  b$contract_figure_id<-'GP_GENDER_age15_reading'
  b$metric_key<-'NLD|PISA|2025|reading|gender|mean_score|girl'
  id<-paste0(sub('^NLD','AUS',b$metric_key),';',lo_gender_pool_id())
  support<-as.data.frame(setNames(rep(list(rep('fixture',3L)),length(lo_balance_columns())),
    lo_balance_columns()),stringsAsFactors=FALSE)
  support$country<-'AUS';support$survey<-'PISA';support$age_group<-'age15'
  support$year<-c('2018','2022','2025');support$domain<-'reading'
  support$outcome<-'mean_score';support$split_dimension<-'none'
  support$split_group<-'total';support$peer_definition<-'none'
  support$source_path<-file.path(d,support$year,'fixture.rds')
  support$source_path[support$year=='2025']<-file.path(d,'fixture.rds');support$source_sha256<-h
  lo_grid_archive_fill<-function(grid,candidates,verify_files) {
    stopifnot(verify_files,identical(grid$cell_id,candidates$cell_id));grid
  }
  ref<-lo_reference_only_grid;environment(ref)<-environment()
  one_wave<-ref(b,data.frame(cell_id=id),list(selected='NLD',reference_candidates=c('NLD','AUS'),
    source_support=support[support$year=='2025',,drop=FALSE]),dec)
  stopifnot(nrow(one_wave)==0L)
  got<-ref(b,data.frame(cell_id=id),list(selected='NLD',reference_candidates=c('NLD','AUS'),source_support=support),dec)
  stopifnot(nrow(got)==1L,got$cell_id==id)
})
stopifnot(nrow(x)==15L,!anyDuplicated(x$metric_key),
 all(lo_extension_availability(x)$status=="UNAVAILABLE_HOME_QUESTIONNAIRE_NOT_ADMINISTERED"))
old<-t;old$survey<-"PIRLS";old$year<-"2006"
stopifnot(all(lo_extension_availability(lo_extension_tasks(old,dec))$status=="OFFICIAL_SCALE_NOT_IN_EARLIER_CYCLE"))
no<-dec;no$status<-"PENDING"
stopifnot(nrow(lo_extension_tasks(t,no))==0,nrow(lo_scope_active_tasks(x,no))==0)
no<-dec;no$status[no$approval_id=="A06"]<-"DEFERRED"
stopifnot(!any(lo_scope_active_tasks(x,no)$module=="extension_ses_gender"))
# Transparent source-free oracle: full sample + two deliberately different
# replicate weights. Pooling tests elsewhere exercise the pinned survey engine.
weighted_mean<-function(y,w){ok<-is.finite(y)&is.finite(w)&w>0;sum(y[ok]*w[ok])/sum(w[ok])}
rc2_num<-as.numeric
pv_names<-function(d,domain)grep("^PV",names(d),value=TRUE)
v10_gender<-function(obj)obj$data$GENDER
rc2_tails_rank<-function(x,w)list(q1=as.numeric(x==min(x)),q4=as.numeric(x==max(x)))
v10_pool<-function(obj,fn) {
 a<-fn(obj$data$W);b<-fn(obj$data$W*c(2,1,1,2));c<-fn(obj$data$W*c(1,2,2,1))
 data.frame(estimate=colMeans(a),se=sqrt(colMeans((b-a)^2+(c-a)^2)+(1+1/nrow(a))*apply(a,2,var)))
}
o<-list(meta=list(survey="PISA",year=2022),data=data.frame(W=1,PV1=c(300,500,600,700),
 PV2=c(320,520,620,720),SES=c(1,1,2,2),GENDER=c("girl","boy","girl","boy")))
q<-t[1,,drop=FALSE];q$survey<-"PISA";q$module<-"core";q$stat<-"total_below";q$threshold<-"407.47"
a<-lo_exact_selected_estimate(o,q)
stopifnot(a$estimate==.25,is.finite(a$se),a$se>0)
q$module<-"gender";q$stat<-"gap";q$threshold<-"";q$group<-"girls_minus_boys";q$definition<-"gender"
a<-lo_exact_selected_estimate(o,q)
stopifnot(a$estimate== -150,is.finite(a$se),a$se>0)
q$module<-"ses_national";q$stat<-"score_gap_q4_minus_q1"
a<-lo_exact_selected_estimate(o,q)
stopifnot(a$estimate==250,is.finite(a$se))
q$module<-"extension_ses_gender";q$stat<-"mean";q$group<-"q1_girl"
stopifnot(lo_exact_selected_estimate(o,q)$estimate==310,lo_extension_count_n(o,q)==1)
before<-lo_extension_projection(o,q);o$data$GENDER[1]<-"boy"
stopifnot(before!=lo_extension_projection(o,q))
q$module<-"extension_performance_class";q$stat<-"between_variance_share"
stopifnot(inherits(try(lo_exact_selected_estimate(o,q),silent=TRUE),"try-error"))
q$module<-"extension_home_ses";q$stat<-"mean"
stopifnot(inherits(try(lo_exact_selected_estimate(o,q),silent=TRUE),"try-error"))
q$module<-"migration_generation";q$stat<-"mean_score_gap";q$group<-"first_generation_minus_native"
migration_groups<-function(obj)list(ok=TRUE,group=c("native","first_generation","second_generation","first_generation"))
stopifnot(lo_exact_generations(o,q)$estimate==300)
q$group<-"first_minus_native"
stopifnot(lo_exact_generations(o,q)$estimate==300)
q$group<-"second_minus_native"
stopifnot(lo_exact_generations(o,q)$estimate==300)
harm<-t;harm$survey<-"PISA";harm$year<-"2025";harm$module[2]<-"ses_harmonized"
harm$definition[2]<-"Cobreros_fourwave_13item_trend_comparable"
hx<-lo_extension_tasks(harm,dec)
stopifnot(all(c("extension_ses_gender","extension_ses_school","extension_ses_class")%in%hx$module))
q$module<-"extension_ses_gender";q$stat<-"mean";q$group<-"q1_girl";q$definition<-harm$definition[2]
stopifnot(inherits(try(lo_exact_selected_estimate(o,q),silent=TRUE),"try-error"))
cal<-tempfile();writeLines("synthetic calibrated construct evidence",cal)
o$meta$ses_construct_id<-q$definition
o$meta$ses_quartile_protocol<-"INNOVAMAT_R_REPLICATE_SEED7_SOURCE_ORDER"
o$meta$calibration_evidence_path<-cal;o$meta$calibration_sha256<-digest::digest(file=cal,algo="sha256")
set.seed(42);before_rng<-.Random.seed
tails<-lo_exact_ses_tails(o,q,o$data$W)
stopifnot(identical(before_rng,.Random.seed),all(tails$q1%in%c(0,1)),all(tails$q4%in%c(0,1)))
# Boundary equality and tied values follow the upstream left.open rule.
set.seed(7);ord<-order(o$data$SES,runif(nrow(o$data)))
codes<-integer(nrow(o$data));codes[ord]<-findInterval(c(0,.25,.5,.75),c(.25,.5,.75),left.open=TRUE)
stopifnot(identical(tails$q1,as.numeric(codes==0)),identical(tails$q4,as.numeric(codes==3)))
unlink(cal)
cat("PASS approved extension contracts, missing-year reasons, exact low outcome and joint contrasts\n")
