source('06_pipeline/LO_EXACT_ESTIMATORS.R')
weighted_mean<-function(x,w){ok<-is.finite(x)&is.finite(w)&w>0;sum(x[ok]*w[ok])/sum(w[ok])}
unit_for<-function(obj,definition)obj$data$SCHOOL
rc2_tails_rank<-function(x,w)list(q1=as.numeric(x<=10),q4=as.numeric(x>=31))
v10_pool<-function(obj,fn){a<-fn(obj$data$W);b<-fn(obj$data$W*rep(c(1,2),length.out=nrow(obj$data)));list(estimate=as.numeric(a),se=abs(as.numeric(b-a)))}
obj<-list(meta=list(survey='PISA',year=2025),data=data.frame(SES=1:40,W=1,SCHOOL='A'))
q<-data.frame(metric_key=c('q1peers','q4peers'),module='ses_peer_exposure',domain='all',
 definition='books5_fractional',peer_definition='whole_school',stat=c('q1_target_pct_q4_peers','q4_target_pct_q1_peers'))
a<-lo_exact_ses_composition(obj,q)
stopifnot(all(abs(a$estimate-100*10/39)<1e-12),all(is.finite(a$se)))
# A missing-SES record is excluded from both peer and baseline denominators.
obj$data<-rbind(obj$data,data.frame(SES=NA_real_,W=100,SCHOOL='A'))
stopifnot(identical(a,lo_exact_ses_composition(obj,q)))
b<-q;b$module<-'peer_baseline';b$stat<-c('q1_share','q4_share')
stopifnot(all(lo_exact_ses_composition(obj,b)$estimate==25))
# The selected harmonized contract cannot fall back to fractional quartiles.
q$definition<-b$definition<-'Cobreros_fourwave_13item_trend_comparable'
stopifnot(inherits(try(lo_exact_ses_composition(obj,q),silent=TRUE),'try-error'))
cert<-tempfile();writeLines('synthetic calibration',cert)
obj$meta$ses_construct_id<-q$definition[1]
obj$meta$ses_quartile_protocol<-'INNOVAMAT_R_REPLICATE_SEED7_SOURCE_ORDER'
obj$meta$calibration_evidence_path<-cert;obj$meta$calibration_sha256<-digest::digest(file=cert,algo='sha256')
# Full-sample upstream left.open rule puts the boundary observation in Q1.
z<-lo_exact_ses_composition(obj,b)
stopifnot(all(abs(z$estimate-c(27.5,22.5))<1e-12))
stopifnot(all(is.finite(lo_exact_ses_composition(obj,q)$estimate)))
writeLines('changed calibration',cert)
stopifnot(inherits(try(lo_exact_ses_composition(obj,q),silent=TRUE),'try-error'))
unlink(cert)
cat('PASS exact chosen SES quartiles, missingness, self-exclusion and calibration identity\n')
