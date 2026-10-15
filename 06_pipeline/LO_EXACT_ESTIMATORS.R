# Exact selected statistics with common PV/replicate pooling. No broad legacy
# module vector is evaluated and then discarded. Contrasts use joint replicates.
lo_exact_peer_matrix <- function(unit,peer,target,W) {
  ok<-!is.na(unit)&nzchar(v10_text(unit))&is.finite(peer)&is.finite(target)
  if(!any(ok))return(rep(NA_real_,ncol(W)))
  u<-as.character(unit[ok]);gid<-match(u,unique(u))
  ww<-W[ok,,drop=FALSE];p<-peer[ok];focal<-target[ok]
  total<-rowsum(ww,gid,reorder=TRUE);positive<-rowsum(ww*p,gid,reorder=TRUE)
  share<-(positive[gid,,drop=FALSE]-ww*p)/(total[gid,,drop=FALSE]-ww)
  invalid<-!is.finite(share);tw<-ww*focal
  share[invalid]<-0;tw[invalid]<-0
  value<-colSums(tw*share)/colSums(tw)
  value[!is.finite(value)]<-NA_real_;value
}

lo_exact_categorical_peer <- function(unit,g,positive,target,w) {
  ok<-!is.na(unit)&nzchar(v10_text(unit))&!is.na(g)&is.finite(w)&w>0
  if(!any(ok))return(NA_real_)
  u<-as.character(unit[ok]);weights<-w[ok];member<-as.numeric(g[ok]==positive)
  mass<-rowsum(cbind(weight=weights,positive=weights*member),u,reorder=FALSE)
  totals<-mass[match(u,rownames(mass)),,drop=FALSE]
  fraction<-(totals[,2]-weights*member)/(totals[,1]-weights)
  weighted_mean(fraction,weights*as.numeric(g[ok]==target))
}

# Linear background statistics share the same outcome matrix across weights.
# Bound the live weight matrix to sixteen columns; preserve every official
# replicate, each PV, missing-value denominator and joint contrast.
lo_exact_background_linear <- function(obj,q,weight_chunk=16L) {
  m<-unique(q$module);domain<-unique(q$domain)
  allowed<-c('migration','migration_generation','language_exact','language_frequency_binary',
    'migration_binary_peer','home_language_peer_exposure','home_language_frequency_peer')
  if(length(m)!=1L||!m%in%allowed||length(domain)!=1L||length(unique(q$definition))!=1L)
    stop('EXACT_LINEAR_BACKGROUND_SCOPE')
  if(length(weight_chunk)!=1L||!is.finite(weight_chunk)||weight_chunk<1L||weight_chunk>16L)
    stop('EXACT_LINEAR_WEIGHT_CHUNK')
  peer<-m%in%c('migration_binary_peer','home_language_peer_exposure','home_language_frequency_peer')
  if(peer&&(domain!='all'||length(unique(q$peer_definition))!=1L))stop('EXACT_LINEAR_PEER_SCOPE')
  if(peer) {
    expected<-switch(m,migration_binary_peer='migration_target_pct_reference_peers',
      home_language_peer_exposure='other_language_target_pct_test_language_home_peers',
      home_language_frequency_peer='less_often_target_pct_always_almost_peers')
    if(any(q$stat!=expected))stop('EXACT_LINEAR_BACKGROUND_STAT_NOT_APPROVED')
  }
  if(m%in%c('migration','migration_binary_peer'))g<-v10_migration(obj,q$definition[1])
  else if(m=='migration_generation') {
    mapped<-migration_groups(obj);if(!isTRUE(mapped$ok))stop('EXACT_MIGRATION_GENERATION_MAPPING_REQUIRED')
    g<-mapped$group
  }else {
    g<-v10_language(obj,m%in%c('language_frequency_binary','home_language_frequency_peer'))
    if(m%in%c('language_frequency_binary','home_language_frequency_peer'))
      g<-ifelse(is.na(g),NA_character_,ifelse(g%in%c('always','almost_always','always_or_almost_always'),
        if(m=='language_frequency_binary')'always_almost'else'test_language_home',
        if(m=='language_frequency_binary')'sometimes_never'else'other_language_home'))
  }
  des<-rc2_replicate_design(obj$data,obj$meta$survey,obj$meta$year)
  if(peer) {Y<-matrix(1,nrow(obj$data),1L);unit<-unit_for(obj,q$peer_definition[1])}
  else {
    pp<-pv_names(obj$data,domain);if(!length(pp))stop('EXACT_LINEAR_MISSING_PV')
    Y<-as.matrix(as.data.frame(lapply(obj$data[pp],rc2_num)))
  }
  valid<-is.finite(Y);Y[!valid]<-0
  A<-array(NA_real_,c(ncol(Y),des$n+1L,nrow(q)))
  membership<-function(label) {z<-as.numeric(g==label);z[!is.finite(z)]<-0;z}
  for(indices in split(0:des$n,ceiling(seq_along(0:des$n)/as.integer(weight_chunk)))) {
    W<-vapply(indices,function(r)if(r==0L)des$w else rc2_repweight(des,r),numeric(nrow(Y)))
    if(any(!is.finite(W))||any(W<0))stop('EXACT_LINEAR_INVALID_WEIGHT')
    means<-function(label) {
      wk<-W*membership(label)
      t(crossprod(wk,Y)/crossprod(wk,valid))
    }
    for(k in seq_len(nrow(q))) {
      st<-q$stat[k];gr<-q$group[k]
      if(peer) {
        positive<-if(m=='migration_binary_peer')'reference'else'test_language_home'
        target<-if(m=='migration_binary_peer')'migration'else'other_language_home'
        # Unknown background categories stay outside the peer denominator.
        p<-ifelse(is.na(g),NA_real_,as.numeric(g==positive))
        focal<-ifelse(is.na(g),NA_real_,as.numeric(g==target))
        value<-matrix(100*v10_peer_matrix(unit,p,focal,W),1L)
      }else if(st%in%c('mean','mean_score'))value<-means(gr)
      else if(m=='migration'&&st=='gap')value<-means('migration')-means('reference')
      else if(m=='language_exact'&&st=='gap')value<-means('other_language_home')-means('test_language_home')
      else if(m=='language_frequency_binary'&&st=='gap')value<-means('sometimes_never')-means('always_almost')
      else if(m=='migration_generation'&&st=='mean_score_gap'&&gr%in%c('first_minus_native','second_minus_native'))
        value<-means(if(gr=='first_minus_native')'first_generation'else'second_generation')-means('native')
      else stop('EXACT_LINEAR_BACKGROUND_STAT_NOT_APPROVED')
      A[,indices+1L,k]<-value
    }
  }
  full<-matrix(A[,1,],nrow=ncol(Y),dimnames=list(NULL,q$metric_key))
  reps<-aperm(A[,-1,,drop=FALSE],c(2,1,3))
  z<-rc2_pool(full,reps,des$factor)
  q$estimate<-as.numeric(z$estimate);q$se<-as.numeric(z$se)
  q$ci_low<-q$estimate-1.96*q$se;q$ci_high<-q$estimate+1.96*q$se;q
}

lo_exact_peer_share <- function(unit,peer_member,target_member,w) {
  ok<-!is.na(unit)&nzchar(unit)&is.finite(peer_member)&is.finite(target_member)&is.finite(w)&w>0
  if(sum(ok)<30L)return(NA_real_)
  u<-as.character(unit[ok]);weights<-w[ok]
  mass<-rowsum(cbind(weight=weights,positive=weights*peer_member[ok]),u,reorder=FALSE)
  total<-mass[match(u,rownames(mass)),,drop=FALSE]
  denominator<-total[,1]-weights
  value<-ifelse(denominator>0,(total[,2]-weights*peer_member[ok])/denominator,NA_real_)
  weighted_mean(value,weights*target_member[ok])
}

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
  if(exists("lo_gender_pool_guard",mode="function"))lo_gender_pool_guard(obj,q)
  else if(any(grepl("FEMALE_OR_OTHER_WHEN_UNSEPARATED_20261015",q$metric_key,fixed=TRUE)))stop("GENDER_POOL_POLICY_NOT_LOADED")
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
  # Outcome columns and cluster identities do not change between replicates.
  # Keep the existing survey-weight builder and PV pooling, but evaluate every
  # PV of each exact selected statistic in a single matrix operation.
  Y<-if(fixed)matrix(rc2_num(d$SES),ncol=1L)else as.matrix(as.data.frame(lapply(d[pp],rc2_num)))
  complete_values<-all(is.finite(Y))
  transformed<-new.env(parent=emptyenv())
  cut_values<-function(cut,below=FALSE) {
    key<-paste(if(below)'below'else'at_or_above',format(cut,digits=17),sep=':')
    if(!exists(key,transformed,inherits=FALSE))
      assign(key,if(below)Y<cut else Y>=cut,transformed)
    get(key,transformed,inherits=FALSE)
  }
  cluster<-NULL
  if(any(q$stat=='between_variance_share')) {
    cluster<-if(grepl('_class$',m))ifelse(is.na(d$SCHOOL)|is.na(d$CLASS),NA_character_,
      paste(d$SCHOOL,d$CLASS,sep='::'))else as.character(d$SCHOOL)
    if(length(cluster)!=nrow(d))stop('EXACT_CLUSTER_ID_MISSING')
  }
  quantile_stats<-intersect(q$stat,c('p10','p50','p90','p90_p10'))
  probs<-numeric();orders<-NULL
  if(length(quantile_stats)) {
    if(m!='core')stop('EXACT_QUANTILE_GROUP_NOT_REVIEWED')
    probs<-sort(unique(unlist(lapply(quantile_stats,function(s)if(s=='p90_p10')c(.1,.9)else as.numeric(sub('p','',s))/100))))
    orders<-lapply(seq_len(ncol(Y)),function(j)order(Y[,j],na.last=NA))
  }
  means<-function(value,w) {
    w[!is.finite(w)|w<=0]<-0
    if(complete_values)return(as.numeric(crossprod(w,value))/sum(w))
    ok<-is.finite(value);value[!ok]<-0
    as.numeric(crossprod(w,value))/as.numeric(crossprod(w,ok))
  }
  between<-function(w) {
    # Preserve per-PV missing-value semantics, including the original minimum
    # of ten observations, when a caller supplies incomplete outcome matrices.
    if(any(!is.finite(Y)))return(vapply(seq_len(ncol(Y)),function(j)rc2_between(Y[,j],cluster,w),numeric(1)))
    ok<-is.finite(w)&w>0&!is.na(cluster)&nzchar(cluster)
    if(sum(ok)<10L)return(rep(NA_real_,ncol(Y)))
    w<-w[ok];v<-Y[ok,,drop=FALSE];mass<-rowsum(cbind(w,v*w),cluster[ok],reorder=FALSE)
    mu<-colSums(v*w)/sum(w)
    total<-colSums(sweep(v,2,mu,'-')^2*w)/sum(w)
    group_mean<-mass[,-1,drop=FALSE]/mass[,1]
    result<-100*colSums(sweep(group_mean,2,mu,'-')^2*mass[,1])/sum(w)/total
    result[!is.finite(total)|total<=0]<-NA_real_;result
  }
  one<-function(w) {
    tails<-if(m%in%c('ses_national','ses_harmonized','extension_ses_gender'))lo_exact_ses_tails(obj,q,w)else NULL
    z<-matrix(NA_real_,ncol(Y),nrow(q),dimnames=list(NULL,q$metric_key))
    quantiles<-NULL
    if(length(probs)) {
      quantiles<-matrix(NA_real_,ncol(Y),length(probs),dimnames=list(NULL,as.character(probs)))
      for(j in seq_len(ncol(Y))) {
        at<-orders[[j]];at<-at[is.finite(Y[at,j])&is.finite(w[at])&w[at]>0]
        if(length(at)) {
          cw<-cumsum(w[at])/sum(w[at])
          quantiles[j,]<-vapply(probs,function(p)Y[at[which(cw>=p)[1]],j],numeric(1))
        }
      }
    }
    for(k in seq_len(nrow(q))) {
      stat<-q$stat[k];group<-q$group[k];wk<-w;value<-Y
      if(m%in%c('ses_national','ses_harmonized')) {
        if(stat%in%c('score_gap_q4_minus_q1','basic_gap_q4_minus_q1','high_gap_q4_minus_q1')) {
          if(stat!='score_gap_q4_minus_q1') {
            cut<-as.numeric(q$threshold[k]);if(!is.finite(cut))stop('EXACT_THRESHOLD_MISSING')
            value<-cut_values(cut)
          }
          z[,k]<-means(value,w*tails$q4)-means(value,w*tails$q1);next
        }
        tail<-sub('_.*$','',stat)
        if(!tail%in%c('q1','q4'))stop('EXACT_SES_STAT_UNKNOWN')
        wk<-w*tails[[tail]];stat<-sub('^q[14]_','',stat)
      }
      if(m=='extension_ses_gender') {
        tail<-sub('_.*$','',group);sex<-sub('^q[14]_','',group)
        if(!tail%in%c('q1','q4')||!sex%in%c('girl','boy'))stop('EXACT_JOINT_GROUP_UNKNOWN')
        wk<-w*tails[[tail]]*as.numeric(gender==sex)
      }
      if(m=='gender') {
        if(stat=='gap') {
          if(group!='girls_minus_boys'||q$definition[k]!='gender')stop('EXACT_GENDER_GAP_DIRECTION_UNKNOWN')
          z[,k]<-means(Y,w*as.numeric(gender=='girl'))-means(Y,w*as.numeric(gender=='boy'));next
        }
        wk<-w*as.numeric(gender==group)
      }
      if(m=='extension_home_ses')wk<-w*as.numeric(d$HOME_SES_GROUP==group)
      if(stat=='between_variance_share'){z[,k]<-between(w);next}
      if(stat%in%c('below','total_below','high','total_high','basic')) {
        cut<-as.numeric(q$threshold[k]);if(!is.finite(cut))stop('EXACT_THRESHOLD_MISSING')
        value<-cut_values(cut,stat%in%c('below','total_below'))
        z[,k]<-means(value,wk)
      }else z[,k]<-switch(stat,mean=means(value,wk),p10=quantiles[,'0.1'],p50=quantiles[,'0.5'],
        p90=quantiles[,'0.9'],p90_p10=quantiles[,'0.9']-quantiles[,'0.1'],stop('EXACT_SELECTED_STAT_UNSUPPORTED: ',stat))
    }
    z
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
