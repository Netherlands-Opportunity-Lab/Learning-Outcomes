# Exact selected statistics with common PV/replicate pooling. No broad legacy
# module vector is evaluated and then discarded. Contrasts use joint replicates.
lo_exact_selected_estimate <- function(obj,q) {
  d<-obj$data;m<-unique(q$module)
  if(length(m)!=1L||length(unique(q$domain))!=1L)stop("EXACT_ESTIMATOR_MIXED_BATCH")
  ext<-startsWith(m,"extension_")
  allowed<-c("core","ses_national","gender",lo_extension_modules())
  if(!m%in%allowed)stop("EXACT_ESTIMATOR_UNSUPPORTED_MODULE")
  fixed<-m%in%c("extension_ses_school","extension_ses_class")
  pp<-if(fixed)"__SES__" else pv_names(d,q$domain[1])
  if(!length(pp))stop("EXACT_ESTIMATOR_MISSING_PV")
  if(grepl("_class$",m)) {
    # Canonical CLASS may be a school-program proxy in PISA. Require explicit
    # certified actual-class semantics before using it as a classroom ID.
    if(!identical(obj$meta$class_identity,"ACTUAL_CLASS_NESTED_WITHIN_SCHOOL"))
      stop("EXACT_CLASS_NOT_COMPARABLE")
  }
  if(m=="extension_home_ses") {
    if(obj$meta$survey=="TIMSS" && as.integer(obj$meta$year)==2023L &&
       obj$meta$v9_country%in%c("NLD","AUS","USA"))
      stop("EXACT_HOME_QUESTIONNAIRE_NOT_ADMINISTERED")
    if(!identical(obj$meta$home_ses_construct,"IEA_OFFICIAL_HOME_SES") ||
       !"HOME_SES_GROUP"%in%names(d))stop("EXACT_HOME_SES_SOURCE_MAPPING_REQUIRED")
    if((obj$meta$survey=="PIRLS" && as.integer(obj$meta$year)<2021L)||
       (obj$meta$survey=="TIMSS" && as.integer(obj$meta$year)<2023L))
      stop("EXACT_HOME_SES_NOT_OFFICIAL_IN_CYCLE")
    if(any(!is.na(d$HOME_SES_GROUP)&!d$HOME_SES_GROUP%in%c("lower","middle","higher")))
      stop("EXACT_HOME_SES_GROUP_MAPPING_INVALID")
  }
  gender<-if(m%in%c("gender","extension_ses_gender"))v10_gender(obj) else NULL
  needs_ses<-m%in%c("ses_national","extension_ses_gender","extension_ses_school","extension_ses_class")
  if(needs_ses && (!"SES"%in%names(d)||!any(is.finite(d$SES))))stop("EXACT_SES_MISSING")
  one<-function(w) {
    tails<-if(m%in%c("ses_national","extension_ses_gender"))rc2_tails_rank(d$SES,w) else NULL
    z<-matrix(NA_real_,length(pp),nrow(q));colnames(z)<-q$metric_key
    for(j in seq_along(pp)) {
      y<-if(fixed)rc2_num(d$SES) else rc2_num(d[[pp[j]]])
      for(k in seq_len(nrow(q))) {
        stat<-q$stat[k];group<-q$group[k];wk<-w;value<-y
        if(m=="ses_national") {
          if(stat%in%c("score_gap_q4_minus_q1","basic_gap_q4_minus_q1","high_gap_q4_minus_q1")) {
            if(stat!="score_gap_q4_minus_q1") {
              cut<-as.numeric(q$threshold[k]);if(!is.finite(cut))stop("EXACT_THRESHOLD_MISSING")
              value<-as.numeric(y>=cut)
            }
            z[j,k]<-weighted_mean(value,w*tails$q4)-weighted_mean(value,w*tails$q1)
            next
          }
          tail<-sub("_.*$","",stat)
          if(!tail%in%c("q1","q4"))stop("EXACT_SES_STAT_UNKNOWN")
          wk<-w*tails[[tail]];stat<-sub("^q[14]_","",stat)
        }
        if(m=="extension_ses_gender") {
          tail<-sub("_.*$","",group);sex<-sub("^q[14]_","",group)
          if(!tail%in%c("q1","q4")||!sex%in%c("girl","boy"))stop("EXACT_JOINT_GROUP_UNKNOWN")
          wk<-w*tails[[tail]]*as.numeric(gender==sex)
        }
        if(m=="gender") {
          if(stat=="gap") {
            z[j,k]<-weighted_mean(y,w*as.numeric(gender=="girl"))-weighted_mean(y,w*as.numeric(gender=="boy"));next
          }
          wk<-w*as.numeric(gender==group)
        }
        if(m=="extension_home_ses")wk<-w*as.numeric(d$HOME_SES_GROUP==group)
        if(stat=="between_variance_share") {
          cluster<-if(grepl("_class$",m))ifelse(is.na(d$SCHOOL)|is.na(d$CLASS),NA_character_,
            paste(d$SCHOOL,d$CLASS,sep="::")) else d$SCHOOL
          if(length(cluster)!=nrow(d))stop("EXACT_CLUSTER_ID_MISSING")
          z[j,k]<-rc2_between(y,cluster,w);next
        }
        if(stat%in%c("below","total_below","high","total_high","basic")) {
          cut<-as.numeric(q$threshold[k]);if(!is.finite(cut))stop("EXACT_THRESHOLD_MISSING")
          value<-if(stat%in%c("below","total_below"))as.numeric(y<cut) else as.numeric(y>=cut)
          z[j,k]<-weighted_mean(value,wk)
        } else z[j,k]<-switch(stat,mean=weighted_mean(value,wk),
          p10=v10_weighted_quantile(value,wk,.1),p50=v10_weighted_quantile(value,wk,.5),
          p90=v10_weighted_quantile(value,wk,.9),p90_p10=diff(v10_weighted_quantile(value,wk,c(.1,.9))),
          stop("EXACT_SELECTED_STAT_UNSUPPORTED: ",stat))
      }
    };z
  }
  pooled<-v10_pool(obj,one)
  q$estimate<-pooled$estimate;q$se<-pooled$se
  q$ci_low<-q$estimate-1.96*q$se;q$ci_high<-q$estimate+1.96*q$se
  q
}

lo_extension_projection <- function(obj,q) {
  d<-obj$data;m<-q$module[1]
  fields<-unique(c("W",grep("^RW[0-9]+$",names(d),value=TRUE),
    intersect(c("JKZONE","JKREP"),names(d)),
    if(q$domain[1]!="all")pv_names(d,q$domain[1]),
    if(m%in%c("extension_ses_gender","extension_ses_school","extension_ses_class"))"SES",
    if(m=="extension_ses_gender")intersect(c("DEMO_GENDER","GENDER","SEX"),names(d)),
    if(m=="extension_home_ses")"HOME_SES_GROUP",
    if(grepl("_(school|class)$",m))"SCHOOL",if(grepl("_class$",m))"CLASS"))
  if(!all(fields%in%names(d)))stop("EXTENSION_SOURCE_COLUMNS_MISSING")
  digest::digest(list(meta=obj$meta,columns=lapply(d[fields],digest::digest,algo="sha256")),algo="sha256")
}
lo_extension_count_n <- function(obj,q) {
  d<-obj$data;w<-lo_compact_weight(obj);m<-q$module[1]
  pp<-if(q$domain[1]=="all")"SES" else pv_names(d,q$domain[1])
  vapply(seq_len(nrow(q)),function(k) {
    ns<-vapply(pp,function(pv) {
      ok<-is.finite(w)&w>0&is.finite(d[[pv]])
      if(m=="extension_home_ses")ok<-ok&!is.na(d$HOME_SES_GROUP)&d$HOME_SES_GROUP==q$group[k]
      if(m=="extension_ses_gender") {
        tails<-rc2_tails_rank(d$SES,w);tail<-sub("_.*$","",q$group[k]);sex<-sub("^q[14]_","",q$group[k])
        g<-v10_gender(obj);ok<-ok&is.finite(d$SES)&tails[[tail]]>0&!is.na(g)&g==sex
      }
      if(grepl("_(school|class)$",m))ok<-ok&!is.na(d$SCHOOL)&nzchar(d$SCHOOL)
      if(grepl("_class$",m))ok<-ok&!is.na(d$CLASS)&nzchar(d$CLASS)
      as.integer(sum(ok,na.rm=TRUE))
    },integer(1))
    if(!length(ns)||length(unique(ns))!=1L)NA_integer_ else ns[1]
  },integer(1))
}
