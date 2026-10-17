# A national high-attainment proportion is already a certified core outcome.
# The peer chart's national baseline is that SAME estimate in percentage units;
# it has no school/class eligibility restriction and needs no pupil recalculation.
lo_derive_population_baselines <- function(tasks,validated) {
 q<-tasks[tasks$module=='peer_baseline'&tasks$stat=='high_share'&tasks$group=='total'&
   tasks$definition=='high_peer_raw_sample'&!tasks$metric_key%in%validated$cell_id,,drop=FALSE]
 if(!nrow(q))return(list(tasks=q,rows=lo_grid_from_tasks(q),parents=validated[FALSE,]))
 base<-tasks[tasks$module=='core'&tasks$stat=='total_high'&tasks$group=='total',,drop=FALSE]
 key<-function(x)paste(x$country,x$survey,x$year,x$domain,x$threshold,sep='|')
 if(anyDuplicated(key(base)))stop('BASELINE_AMBIGUOUS_CORE_PARENT')
 at<-match(key(q),key(base));if(anyNA(at))stop('BASELINE_EXACT_THRESHOLD_PARENT_MISSING')
 parent<-validated[match(base$metric_key[at],validated$cell_id),,drop=FALSE]
 if(anyNA(parent$cell_id)||any(parent$status!='SCIENTIFICALLY_VALIDATED'))stop('BASELINE_PARENT_NOT_CERTIFIED')
 if(any(q$unit!='percent')||any(base$unit[at]!='proportion'))stop('BASELINE_UNIT_CONTRACT')
 if(any(parent$estimate<0|parent$estimate>1)||any(parent$standard_error<0))stop('BASELINE_INVALID_PARENT_VALUE')
 a<-lo_grid_from_tasks(q)
 for(k in c('source_path','source_edition_sha256','sample_id','weight_design','pv_rule','input_fingerprint','certification_path','certification_sha256'))a[[k]]<-parent[[k]]
 a$estimate<-100*parent$estimate;a$standard_error<-100*parent$standard_error;a$n_unweighted<-parent$n_unweighted
 a$variance_rule<-paste0('EXACT_LINEAR_SCALE_100_OF_PARENT: ',parent$variance_rule)
 a$method_version<-'DERIVED_CORE_HIGH_PROPORTION_TO_NATIONAL_PERCENT_V1'
 a$status<-'SCIENTIFICALLY_VALIDATED';a$hold_reason<-''
 list(tasks=q,rows=a,parents=parent)
}
