# Exact selected statistics with common PV/replicate pooling. No broad legacy
# module vector is evaluated and then discarded. Contrasts use joint replicates.
lo_exact_ses_tails <- function(obj,q,w) {
  if(!any(grepl("Cobreros",q$definition,fixed=TRUE)))return(rc2_tails_rank(obj$data$SES,w))
  if(!identical(obj$meta$ses_construct_id,q$definition[1]) ||
     !identical(obj$meta$ses_quartile_protocol,"INNOVAMAT_R_REPLICATE_SEED7_SOURCE_ORDER") ||
     is.null(obj$meta$calibration_evidence_path)||is.null(obj$meta$calibration_sha256)||
     !file.exists(obj$meta$calibration_evidence_path)||
     !identical(digest::digest(file=obj$meta$calibration_evidence_path,algo="sha256"),obj$meta$calibration_sha256))
    stop("EXACT_HARMONIZED_SES_CALIBRATION_REQUIRED")
  # Innovamat R core.R quantile_codes: random tie order with seed 7, followed
  # by cut points recalculated for each replicate. Fractional ties belong to
  # the separate national/books specification and must not replace this rule.
  keep<-is.finite(obj$data$SES)&is.finite(obj$data$W)&obj$data$W>0
  x<-obj$data$SES[keep];z<-w[keep]
  if(!length(x)||any(!is.finite(z))||any(z<0)||sum(z)<=0)stop("EXACT_HARMONIZED_QUARTILE_EMPTY")
  had<-exists(".Random.seed",.GlobalEnv,inherits=FALSE)
  old<-if(had)get(".Random.seed",.GlobalEnv)else NULL
  old_kind<-RNGkind()
  on.exit({do.call(RNGkind,as.list(old_kind));if(had)assign(".Random.seed",old,.GlobalEnv)else if(exists(".Random.seed",.GlobalEnv,inherits=FALSE))rm(".Random.seed",envir=.GlobalEnv)},add=TRUE)
  RNGkind("Mersenne-Twister","Inversion","Rejection");set.seed(7)
  o<-order(x,runif(length(x)));before<-c(0,head(cumsum(z[o]),-1))/sum(z)
  group<-integer(length(x));group[o]<-findInterval(before,c(.25,.5,.75),left.open=TRUE)
  q1<-q4<-rep(0,length(w));q1[keep]<-as.numeric(group==0L);q4[keep]<-as.numeric(group==3L)
  list(q1=q1,q4=q4)
}
# Both SES composition and its country baseline must use the chosen calibrated
# quartiles. The legacy generic producer otherwise silently used fractional
# national quartiles even for a Cobreros contract.
lo_exact_ses_composition <- function(obj,q) {
  m<-unique(q$module)
  if(length(m)!=1L||!m%in%c('ses_peer_exposure','peer_baseline')||
     any(q$domain!='all')||length(unique(q$definition))!=1L||
     length(unique(q$peer_definition))!=1L)stop('EXACT_SES_COMPOSITION_SCOPE')
  allowed<-if(m=='peer_baseline')c('q1_share','q4_share') else
    c('q1_target_pct_q4_peers','q4_target_pct_q1_peers')
  if(any(!q$stat%in%allowed))stop('EXACT_SES_COMPOSITION_STAT')
  d<-obj$data
  unit<-if(m=='ses_peer_exposure')as.character(unit_for(obj,q$peer_definition[1]))else NULL
  one<-function(w) {
    tails<-lo_exact_ses_tails(obj,q,w)
    valid<-is.finite(d$SES)&is.finite(w)&w>0
    for(k in names(tails))tails[[k]][!valid]<-NA_real_
    z<-matrix(NA_real_,1,nrow(q),dimnames=list(NULL,q$metric_key))
    for(k in seq_len(nrow(q))) {
      if(m=='peer_baseline') {
        z[1,k]<-100*weighted_mean(tails[[sub('_share$','',q$stat[k])]],w)
      } else {
        target<-if(q$stat[k]=='q1_target_pct_q4_peers')tails$q1 else tails$q4
        peer<-if(q$stat[k]=='q1_target_pct_q4_peers')tails$q4 else tails$q1
        # Retain the established 30-valid-observation estimator condition.
        ok<-valid&!is.na(unit)&nzchar(unit)&is.finite(target)&is.finite(peer)
        if(sum(ok)<30L)stop('EXACT_SES_PEER_INSUFFICIENT_VALID_FRAME')
        total<-rowsum(w[ok],unit[ok],reorder=FALSE)
        mass<-rowsum(w[ok]*peer[ok],unit[ok],reorder=FALSE)
        at<-match(unit[ok],rownames(total))
        denom<-total[at,1]-w[ok]
        fraction<-ifelse(denom>0,(mass[at,1]-w[ok]*peer[ok])/denom,NA_real_)
        z[1,k]<-100*weighted_mean(fraction,w[ok]*target[ok])
      }
    }
    z
  }
  a<-v10_pool(obj,one);q$estimate<-as.numeric(a$estimate);q$se<-as.numeric(a$se);q
}

lo_exact_selected_estimate <- function(obj,q) {
  d<-obj$data;m<-unique(q$module)
  if(length(m)!=1L||length(unique(q$domain))!=1L)stop("EXACT_ESTIMATOR_MIXED_BATCH")
  ext<-startsWith(m,"extension_")
  allowed<-c("core","ses_national","ses_harmonized","gender",lo_extension_modules())
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
  needs_ses<-m%in%c("ses_national","ses_harmonized","extension_ses_gender","extension_ses_school","extension_ses_class")
  if(needs_ses && (!"SES"%in%names(d)||!any(is.finite(d$SES))))stop("EXACT_SES_MISSING")
  if(needs_ses && any(grepl("Cobreros",q$definition,fixed=TRUE))) {
    # Never silently substitute the canonical official ESCS column for the
    # human-selected author-calibrated construct, including new appendices.
    if(length(unique(q$definition))!=1L || !identical(obj$meta$ses_construct_id,q$definition[1]) ||
       is.null(obj$meta$calibration_evidence_path) || is.null(obj$meta$calibration_sha256) ||
       !file.exists(obj$meta$calibration_evidence_path) ||
       !identical(digest::digest(file=obj$meta$calibration_evidence_path,algo="sha256"),obj$meta$calibration_sha256))
      stop("EXACT_HARMONIZED_SES_CALIBRATION_REQUIRED")
  }
  one<-function(w) {
    tails<-if(m%in%c("ses_national","ses_harmonized","extension_ses_gender"))lo_exact_ses_tails(obj,q,w) else NULL
    z<-matrix(NA_real_,length(pp),nrow(q));colnames(z)<-q$metric_key
    for(j in seq_along(pp)) {
      y<-if(fixed)rc2_num(d$SES) else rc2_num(d[[pp[j]]])
      for(k in seq_len(nrow(q))) {
        stat<-q$stat[k];group<-q$group[k];wk<-w;value<-y
        if(m%in%c("ses_national","ses_harmonized")) {
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
            if(group!="girls_minus_boys" || q$definition[k]!="gender")stop("EXACT_GENDER_GAP_DIRECTION_UNKNOWN")
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
        tails<-lo_exact_ses_tails(obj,q,w);tail<-sub("_.*$","",q$group[k]);sex<-sub("^q[14]_","",q$group[k])
        g<-v10_gender(obj);ok<-ok&is.finite(d$SES)&tails[[tail]]>0&!is.na(g)&g==sex
      }
      if(grepl("_(school|class)$",m))ok<-ok&!is.na(d$SCHOOL)&nzchar(d$SCHOOL)
      if(grepl("_class$",m))ok<-ok&!is.na(d$CLASS)&nzchar(d$CLASS)
      as.integer(sum(ok,na.rm=TRUE))
    },integer(1))
    if(!length(ns)||length(unique(ns))!=1L)NA_integer_ else ns[1]
  },integer(1))
}

lo_exact_generations <- function(obj,q) {
  g<-migration_groups(obj)
  if(!isTRUE(g$ok))stop("EXACT_MIGRATION_GENERATION_MAPPING_REQUIRED")
  pp<-pv_names(obj$data,q$domain[1])
  if(!length(pp))stop("EXACT_MIGRATION_PV_MISSING")
  one<-function(w) {
    z<-matrix(NA_real_,length(pp),nrow(q));colnames(z)<-q$metric_key
    for(j in seq_along(pp))for(k in seq_len(nrow(q))) {
      y<-rc2_num(obj$data[[pp[j]]]);group<-q$group[k]
      if(q$stat[k]=="mean_score")z[j,k]<-weighted_mean(y,w*as.numeric(g$group==group))
      else if(q$stat[k]=="mean_score_gap") {
        group<-sub("_minus_native$","",group)
        group<-switch(group,first="first_generation",second="second_generation",group)
        if(!grepl("_minus_native$",q$group[k]))stop("EXACT_MIGRATION_GAP_DIRECTION_UNKNOWN")
        z[j,k]<-weighted_mean(y,w*as.numeric(g$group==group))-weighted_mean(y,w*as.numeric(g$group=="native"))
      } else stop("EXACT_MIGRATION_STAT_NOT_APPROVED")
    };z
  }
  a<-v10_pool(obj,one);q$estimate<-a$estimate;q$se<-a$se;q
}
