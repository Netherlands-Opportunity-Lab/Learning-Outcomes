# PV-defined target groups have multiple legitimate counts. Preserve those
# counts individually; the one database N describes the fixed analytic frame.
# This opt-in requires independently certified counts, never a rounded mean N.
lo_peer_sample_counts <- function(obj,q) {
  rule<-'ANALYTIC_PEER_FRAME_WITH_SEPARATE_PV_TARGET_COUNTS'
  if(!identical(obj$meta$sample_count_rule,rule))stop('PEER_N_RULE_NOT_CERTIFIED')
  if(any(!q$module%in%c('peer_below_basic','high_proficiency_peer_exposure'))||
     length(unique(q$domain))!=1L||length(unique(q$peer_definition))!=1L)stop('PEER_N_TASK_SCOPE')
  path<-obj$meta$sample_count_evidence_path;sha<-obj$meta$sample_count_evidence_sha256
  if(length(path)!=1L||length(sha)!=1L||!file.exists(path)||
     !identical(digest::digest(file=path,algo='sha256'),sha))stop('PEER_N_CHANGED_COUNT_EVIDENCE')
  expected<-read.csv(path,stringsAsFactors=FALSE)
  columns<-c('cell_id','pv','n_frame','n_target','n_definition')
  if(!all(columns%in%names(expected))||anyDuplicated(paste(expected$cell_id,expected$pv)))stop('PEER_N_INVALID_COUNT_EVIDENCE')
  d<-obj$data;w<-lo_compact_weight(obj);pv<-pv_names(d,q$domain[1]);u<-as.character(unit_for(obj,q$peer_definition[1]))
  if(!length(pv))stop('PEER_N_NO_PV')
  counts<-list();n<-integer(nrow(q))
  for(k in seq_len(nrow(q))) {
    frames<-integer(length(pv))
    for(j in seq_along(pv)) {
      y<-as.numeric(d[[pv[j]]]);valid<-is.finite(w)&w>0&is.finite(y)&!is.na(u)&nzchar(u)
      units<-table(u[valid]);enough<-rep(FALSE,length(u));ix<-match(u,names(units));good<-!is.na(ix)
      enough[good]<-as.numeric(units[ix[good]])>=2L;frame<-valid&enough
      low<-q$module[k]=='peer_below_basic'
      cut<-if(low)thresholds_for(obj$meta$survey,q$domain[k])[['basic']]else as.numeric(q$threshold[k])
      if(length(cut)!=1L||!is.finite(cut))stop('PEER_N_THRESHOLD')
      target<-switch(q$group[k],total=rep(TRUE,length(y)),self_below_basic=y<cut,
        self_at_or_above_basic=y>=cut,self_high=y>=cut,self_below_high=y<cut,stop('PEER_N_UNKNOWN_TARGET'))
      frames[j]<-sum(frame)
      counts[[length(counts)+1L]]<-data.frame(cell_id=q$metric_key[k],pv=j,n_frame=frames[j],n_target=sum(frame&target,na.rm=TRUE),n_definition=rule)
    }
    if(length(unique(frames))!=1L||frames[1]<1L)stop('PEER_N_CHANGING_OR_EMPTY_ANALYTIC_FRAME')
    n[k]<-frames[1]
  }
  actual<-do.call(rbind,counts);at<-match(paste(actual$cell_id,actual$pv),paste(expected$cell_id,expected$pv))
  if(anyNA(at)||any(as.matrix(actual[columns])!=as.matrix(expected[at,columns])))stop('PEER_N_INDEPENDENT_COUNT_MISMATCH')
  n
}

# One source batch per survey x country x wave, one compact SQLite grid.
# All new statistical values remain COMPUTED_PENDING_VALIDATION.
# Source data are never copied, published or deleted by this producer.
lo_compact_active_tasks <- function(tasks) {
  required<-c("metric_key","contract_figure_id","country","survey","year",
     "domain","module","stat","group","definition","peer_definition",
     "threshold","unit","calculation_policy")
  if(!all(required%in%names(tasks))||anyDuplicated(tasks$metric_key))
    stop("COMPACT_SCOPE_CONTRACT_INVALID")
  fam<-sub("_age.*$","",tasks$contract_figure_id)
  # Explicit decisions of 12 October; keep original contract in pinned bundle.
  active<-!fam%in%c("TR_BASIC","GP_SES_HIGH","EN_PERFORMANCE_PEER")
  tasks[active,,drop=FALSE]
}
lo_compact_index_sources <- function(project) {
  # One metadata walk for the entire run; no scanning the same cache trees per cell.
  roots<-lo4_roots(project)
  roots<-roots[!grepl("all_available_cell_cache_v1|standardised_extracts",roots)]
  files<-unique(unlist(lapply(roots,function(r)
    list.files(r,pattern="^canonical_(PISA|PIRLS|TIMSS)_[0-9]{4}_[A-Z0-9]{3}[.]rds$",
               recursive=TRUE,full.names=TRUE,ignore.case=TRUE)),use.names=FALSE))
  if(!length(files))return(list())
  key<-sub("^canonical_","",sub("[.]rds$","",basename(files),ignore.case=TRUE))
  key<-toupper(key)
  split(sort(files),key)
}
lo_compact_weight <- function(obj) {
  d<-obj$data
  if(!"W"%in%names(d))stop("COMPACT_N_NO_PRIMARY_WEIGHTS")
  w<-suppressWarnings(as.numeric(d$W))
  if(length(w)!=nrow(d)||!any(is.finite(w)&w>0))
    stop("COMPACT_N_INVALID_PRIMARY_WEIGHTS")
  w
}
lo_compact_count_n <- function(obj,q) {
  # Count original pupil rows with positive full-sample weight, valid outcome,
  # appropriate focal-group label and (for peers) an actual peer denominator.
  # If different plausible values imply different N, do not fabricate one N.
  d<-obj$data;m<-q$module[[1L]];w<-lo_compact_weight(obj)
  if(m%in%c('peer_below_basic','high_proficiency_peer_exposure') &&
     identical(obj$meta$sample_count_rule,'ANALYTIC_PEER_FRAME_WITH_SEPARATE_PV_TARGET_COUNTS'))
    return(lo_peer_sample_counts(obj,q))
  pv<-if(q$domain[[1L]]=="all") character() else pv_names(d,q$domain[[1L]])
  if(!length(pv)&&q$domain[[1L]]!="all")stop("COMPACT_N_MISSING_PV")
  g<-NULL;tails<-NULL;u<-NULL
  if(m=="gender")g<-v10_gender(obj)
  if(m%in%c("migration","migration_binary_peer"))
    g<-v10_migration(obj,q$definition[[1L]])
  if(m=="language_exact")g<-v10_language(obj)
  if(m%in%c("language_frequency","language_frequency_binary",
            "home_language_frequency_peer")) {
    g<-v10_language(obj,TRUE)
    if(m=="language_frequency_binary")
      g<-ifelse(is.na(g),NA_character_,
        ifelse(g%in%c("always","almost_always","always_or_almost_always"),
          "always_almost","sometimes_never"))
    if(m=="home_language_frequency_peer")
      g<-ifelse(is.na(g),NA_character_,
        ifelse(g%in%c("always","almost_always","always_or_almost_always"),
          "test_language_home","other_language_home"))
  }
  if(m=="home_language_peer_exposure" ||
     (m=="peer_baseline" && q$stat[[1L]]=="test_language_share" &&
       q$definition[[1L]]=="same_as_assessment_language_vs_other"))
       g<-v10_language(obj)
  if(m=="peer_baseline" && q$stat[[1L]]=="test_language_share" &&
     q$definition[[1L]]=="frequency_always_almost_vs_sometimes_never") {
    raw<-v10_language(obj,TRUE)
    g<-ifelse(is.na(raw),NA_character_,
         ifelse(raw%in%c("always","almost_always","always_or_almost_always"),
               "test_language_home","other_language_home"))
  }
  if(m=="peer_baseline" && q$stat[[1L]]=="reference_share")
       g<-v10_migration(obj,q$definition[[1L]])
  if(m%in%c("migration_generation","migration_peer_exposure")) {
    mg<-migration_groups(obj)
    if(!isTRUE(mg$ok))stop(mg$reason)
    g<-mg$group
  }
  if(m%in%c("ses_national","ses_harmonized","ses_peer_exposure") ||
     (m=="peer_baseline" && q$stat[[1L]]%in%c("q1_share","q4_share")))
     tails<-if(any(grepl("Cobreros",q$definition,fixed=TRUE)))lo_exact_ses_tails(obj,q,w) else rc2_tails_rank(d$SES,w)
  if(m%in%c("peer_below_basic","high_proficiency_peer_exposure",
            "migration_binary_peer","migration_peer_exposure","home_language_peer_exposure",
            "home_language_frequency_peer","ses_peer_exposure"))
    u<-unit_for(obj,q$peer_definition[[1L]])
  pv_list<-if(length(pv))pv else "__NO_PV__"
  out<-vapply(seq_len(nrow(q)),function(k) {
    ns<-vapply(pv_list,function(col) {
      y<-if(col=="__NO_PV__")rep(1,nrow(d)) else rc2_num(d[[col]])
      eligible<-is.finite(w)&w>0&is.finite(y)
      group<-q$group[[k]];stat<-q$stat[[k]]
      if(m=="gender") {
        eligible<-eligible&!is.na(g)&
           (if(stat=="gap")g%in%c("girl","boy") else g==group)
      }
      if(m=="migration_peer_exposure") {
        desired<-switch(stat,
          first_generation_target_pct_native_peers="first_generation",
          second_generation_target_pct_native_peers="second_generation",
          stop("COMPACT_N_UNKNOWN_MIGRATION_PEER_TARGET"))
        eligible<-eligible&!is.na(g)&g==desired
      }
      if(m=="migration_generation") {
        eligible<-eligible&!is.na(g)&
          if(stat=="mean_score_gap") {
            focus<-sub("_minus_native$","",group)
            focus<-switch(focus,first="first_generation",second="second_generation",focus)
            g%in%c("native",focus)
          } else g==group
      }
      if(m=="migration") {
        eligible<-eligible&!is.na(g)&
           (if(stat=="gap")g%in%c("migration","reference") else g==group)
      }
      if(m=="language_exact") {
        eligible<-eligible&!is.na(g)&
          (if(stat=="gap")g%in%c("test_language_home","other_language_home")
           else g==group)
      }
      if(m%in%c("language_frequency","language_frequency_binary")) {
        eligible<-eligible&!is.na(g)&
          (if(stat=="gap")g%in%c("always_almost","sometimes_never") else g==group)
      }
      if(m%in%c("ses_national","ses_harmonized")) {
        if(is.null(tails))stop("COMPACT_N_MISSING_SES_QUARTILES")
        if(grepl("^q1_",stat))eligible<-eligible&!is.na(tails$q1)&tails$q1>0
        else if(grepl("^q4_",stat))eligible<-eligible&!is.na(tails$q4)&tails$q4>0
        else eligible<-eligible&
          ((!is.na(tails$q1)&tails$q1>0)|(!is.na(tails$q4)&tails$q4>0))
      }
      if(m=="peer_baseline" && stat%in%c("reference_share","test_language_share"))
        eligible<-eligible&!is.na(g)
      if(m=="peer_baseline" && stat%in%c("q1_share","q4_share")) {
        t<-if(stat=="q1_share")tails$q1 else tails$q4
        eligible<-eligible&!is.na(t)
      }
      if(m=="peer_below_basic") {
        cut<-thresholds_for(obj$meta$survey,q$domain[[1L]])[["basic"]]
        if(length(cut)!=1L||!is.finite(cut))stop("COMPACT_N_MISSING_BASIC_THRESHOLD")
        if(group=="self_below_basic")eligible<-eligible & y<cut
        else if(group=="self_at_or_above_basic")eligible<-eligible & y>=cut
        else if(group!="total")stop("COMPACT_N_UNKNOWN_BELOW_PEER_GROUP")
      }
      if(m=="high_proficiency_peer_exposure") {
        cut<-as.numeric(q$threshold[[k]])
        if(!is.finite(cut))stop("COMPACT_N_MISSING_HIGH_THRESHOLD")
        if(group=="self_high")eligible<-eligible&y>=cut
        else if(group=="self_below_high")eligible<-eligible&y<cut
        else stop("COMPACT_N_UNKNOWN_HIGH_PEER_GROUP")
      }
      if(m=="migration_binary_peer")eligible<-eligible&!is.na(g)&g=="migration"
      if(m%in%c("home_language_peer_exposure","home_language_frequency_peer"))
        eligible<-eligible&!is.na(g)&g=="other_language_home"
      if(m=="ses_peer_exposure") {
        t<-if(stat=="q1_target_pct_q4_peers")tails$q1 else tails$q4
        eligible<-eligible&!is.na(t)&t>0
      }
      if(!is.null(u)) {
        # Valid peers have positive full-sample weight and finite achievement.
        # Require at least one OTHER pupil with valid peer classification.
        peer_ok<-is.finite(w)&w>0&is.finite(y)&!is.na(u)&nzchar(as.character(u))
        if(!is.null(g))peer_ok<-peer_ok&!is.na(g)
        grp<-as.character(u)
        counts<-table(grp[peer_ok])
        possible<-rep(FALSE,length(grp))
        found<-match(grp,names(counts))
        good<-!is.na(found)
        possible[good]<-as.numeric(counts[found[good]])>=2
        eligible<-eligible&peer_ok&possible
      }
      as.integer(sum(eligible,na.rm=TRUE))
    },integer(1L))
    if(length(unique(ns))!=1L || ns[[1L]]<1L) NA_integer_ else ns[[1L]]
  },integer(1L))
  out
}
lo_compact_low_peer <- function(obj,q) {
  if(!nrow(q) || !all(q$module=="peer_below_basic") ||
     length(unique(q$domain))!=1L||
     length(unique(q$peer_definition))!=1L)
    stop("COMPACT_LOW_PEER_BATCH_INVALID")
  d<-obj$data; pv<-pv_names(d,q$domain[[1L]])
  if(!length(pv))stop("COMPACT_LOW_PEER_NO_PV")
  cut<-thresholds_for(obj$meta$survey,q$domain[[1L]])[["basic"]]
  if(length(cut)!=1L||!is.finite(cut))stop("COMPACT_LOW_PEER_THRESHOLD_UNKNOWN")
  unit<-unit_for(obj,q$peer_definition[[1L]])
  des<-rc2_replicate_design(d,obj$meta$survey,obj$meta$year)
  weights<-cbind(des$w,vapply(seq_len(des$n),function(i)
    rc2_repweight(des,i),numeric(nrow(d))))
  f<-matrix(NA_real_,nrow=length(pv),ncol=nrow(q))
  colnames(f)<-paste0("peer_below_basic:",q$group)
  rr<-array(NA_real_,dim=c(des$n,length(pv),nrow(q)))
  for(j in seq_along(pv)) {
    y<-rc2_num(d[[pv[[j]]]])
    below<-ifelse(is.finite(y),as.numeric(y<cut),NA_real_)
    for(k in seq_len(nrow(q))) {
      group<-q$group[[k]]
      target<-switch(group,total=ifelse(is.finite(y),1,NA_real_),
        self_below_basic=below,
        self_at_or_above_basic=1-below,
        stop("COMPACT_LOW_PEER_UNKNOWN_FOCAL_GROUP"))
      estimates<-100*v10_peer_matrix(unit,below,target,weights)
      if(length(estimates)!=des$n+1L || !all(is.finite(estimates)))
        stop("COMPACT_LOW_PEER_MISSING_DENOMINATOR")
      f[j,k]<-estimates[[1L]]
      rr[,j,k]<-estimates[-1L]
    }
  }
  z<-rc2_pool(f,rr,des$factor)
  q$estimate<-as.numeric(z$estimate)
  q$se<-as.numeric(z$se)
  q$ci_low<-q$estimate-1.96*q$se
  q$ci_high<-q$estimate+1.96*q$se
  q
}
# Use the pinned independent demographic-wave PV/replicate implementation.
# It already estimates generation contrasts within each replicate, not from two SEs.
# Preserve locked product identifiers, but pass the precise parent-birthplace
# predicate to the scientific backend and include those variables in input SHA.
lo_compact_backend_tasks <- function(q) {
  x<-q
  is_any<-x$definition=="MIGRATION_ANY_PARENT_ABROAD" &
    x$module%in%c("migration","migration_binary_peer","peer_baseline")
  x$definition[is_any]<-"nl_one_parent_abroad"
  x
}
# Survey-replicated migration peer exposure; strict valid-category
# denominator, no self-peering, direct and whole-school units kept separate.
lo_compact_migration_peers <- function(obj,q) {
  if(!nrow(q)||any(q$module!="migration_peer_exposure")||
     length(unique(q$peer_definition))!=1L)stop("COMPACT_MIGRATION_PEER_SCOPE_INVALID")
  src<-migration_groups(obj)
  if(!isTRUE(src$ok))stop("COMPACT_MIGRATION_PEER_SOURCE: ",src$reason)
  group<-src$group
  units<-unit_for(obj,q$peer_definition[[1L]])
  des<-rc2_replicate_design(obj$data,obj$meta$survey,obj$meta$year)
  W<-cbind(des$w,vapply(seq_len(des$n),function(i)
     rc2_repweight(des,i),numeric(nrow(obj$data))))
  q$estimate<-rep(NA_real_,nrow(q))
  q$se<-rep(NA_real_,nrow(q))
  for(k in seq_len(nrow(q))) {
    target<-switch(q$stat[[k]],
      first_generation_target_pct_native_peers="first_generation",
      second_generation_target_pct_native_peers="second_generation",
      stop("COMPACT_MIGRATION_PEER_UNKNOWN_TARGET"))
    peer<-ifelse(is.na(group),NA_real_,as.numeric(group=="native"))
    focal<-ifelse(is.na(group),NA_real_,as.numeric(group==target))
    est<-100*v10_peer_matrix(units,peer,focal,W)
    if(length(est)!=des$n+1L || any(!is.finite(est)))
      stop("COMPACT_MIGRATION_PEER_UNAVAILABLE_REPLICATES")
    q$estimate[[k]]<-est[[1L]]
    q$se[[k]]<-sqrt(des$factor*sum((est[-1L]-est[[1L]])^2))
  }
  q
}
lo_compact_generations <- function(obj,q) {
  if(any(q$module!="migration_generation") || length(unique(q$domain))!=1L)
    stop("COMPACT_GENERATION_WRONG_SCOPE")
  data<-demographic_wave(obj,unique(q$domain))$results
  if(!nrow(data))stop("COMPACT_GENERATION_NO_VALID_SOURCE_GROUPS")
  data<-data[data$family=="migration_generation",,drop=FALSE]
  match_key<-paste(q$stat,q$group,sep="|")
  got<-paste(data$statistic,data$group,sep="|")
  if(anyDuplicated(got)||anyNA(match(match_key,got)))
    stop("COMPACT_GENERATION_MISSING_OR_AMBIGUOUS_GROUP")
  z<-data[match(match_key,got),,drop=FALSE]
  q$estimate<-z$estimate
  q$se<-z$se
  q
}
lo_compact_projection <- function(obj,q) {
  if(q$module[[1L]]=="language_exact" && identical(obj$meta$survey,"PISA") &&
     identical(obj$meta$language_definition,"ASSESSMENT_LANGUAGE_RELATIVE_HOME_USE") &&
     identical(obj$meta$language_mapping_status,"SOURCE_LABELS_AND_STUDENT_IDS_VERIFIED")) {
    # The verified question already means home language relative to the test.
    # The estimator uses DEMO_LANGUAGE; an unused test-language code must not
    # block older cycles or be invented merely to satisfy a legacy projection.
    d<-obj$data;pv<-lo4_pv_fields(d,q$domain[[1L]])
    fields<-c("W",paste0("RW",1:80),pv,"DEMO_LANGUAGE")
    if(!length(pv)||!all(fields%in%names(d)))stop("COMPACT_LANGUAGE_SOURCE_FIELDS_MISSING")
    return(digest::digest(list(meta=obj$meta,task=lapply(q[c("country","survey","year","domain","definition")],function(x)sort(unique(as.character(x)))),
      columns=lapply(d[fields],digest::digest,algo="sha256")),algo="sha256"))
  }
  if(q$module[[1L]]!="peer_below_basic")return(lo4_projection(obj,q))
  if(!is.list(obj)||!is.data.frame(obj$data))stop("COMPACT_LOW_PEER_NO_SOURCE_DATA")
  d<-obj$data
  pv<-lo4_pv_fields(d,q$domain[[1L]])
  unit <- if(obj$meta$survey=="PISA" && q$peer_definition[[1L]]=="direct_learning_environment")
     c("SCHOOL","PROGRAM") else if(q$peer_definition[[1L]]=="direct_learning_environment")
     c("SCHOOL","CLASS") else "SCHOOL"
  fields<-unique(c("W",grep("^RW[0-9]+$",names(d),value=TRUE),
    intersect(c("JKZONE","JKREP","JKSTRAT","JKPAIR","STRATUM","PSU"),names(d)),pv,unit))
  if(!length(pv)||!all(fields%in%names(d)))
    stop("COMPACT_LOW_PEER_SOURCE_COLUMNS_MISSING")
  digest::digest(list(survey=obj$meta$survey,year=obj$meta$year,
    country=q$country[[1L]],module="peer_below_basic",
    sample_count_rule=obj$meta$sample_count_rule,
    sample_count_evidence_sha256=obj$meta$sample_count_evidence_sha256,
    domain=q$domain[[1L]],peer=q$peer_definition[[1L]],
    columns=vapply(fields,function(k)digest::digest(d[[k]],algo="sha256"),
      character(1L))),algo="sha256")
}
lo_compact_science_rows <- function(q,z,n,inputfp,codefp,method_id) {
  if(nrow(q)!=nrow(z)||!setequal(q$metric_key,z$metric_key))
    stop("COMPACT_ESTIMATOR_CHANGED_KEYS")
  z<-z[match(q$metric_key,z$metric_key),,drop=FALSE]
  if(!all(c("estimate","se")%in%names(z)))
    stop("COMPACT_ESTIMATOR_NO_ESTIMATE_SE")
  est<-suppressWarnings(as.numeric(z$estimate))
  se<-suppressWarnings(as.numeric(z$se))
  if(length(n)!=nrow(q))stop("COMPACT_ESTIMATOR_N_LENGTH")
  good<-is.finite(est)&is.finite(se)&se>=0&is.finite(n)&n>0
  result<-data.frame(cell_id=q$metric_key,survey=q$survey,country=q$country,
    year=q$year,domain=q$domain,module=q$module,
    stat=q$stat,subgroup=q$group,definition=q$definition,unit=q$unit,
    peer_environment=q$peer_definition,threshold=q$threshold,
    estimate=ifelse(good,est,NA_real_),standard_error=ifelse(good,se,NA_real_),
    n_unweighted=ifelse(good,as.integer(n),NA_integer_),
    input_fingerprint=inputfp,producer_fingerprint=codefp,
    method_id=method_id,
    status=ifelse(good,"COMPUTED_PENDING_VALIDATION","HOLD"),
    hold_reason=ifelse(good,"","MISSING_OR_NONUNIQUE_N_OR_NONFINITE_ESTIMATE_SE"),
    stringsAsFactors=FALSE)
  result
}
lo_compact_run <- function(bundle,repo,scope_info,tasks,output_root,
                           max_units=Inf,grid=NULL) {
  for(name in c("LO_SCOPE_DECISIONS.R","MASTER_ESTIMATION_GRID.R",
                "LO_COMPACT_GRID_STORE.R","LO_EXACT_DISPATCH.R"))
    source(file.path(repo,"06_pipeline",name),local=environment(),encoding="UTF-8")
  if(is.null(grid))stop("EXACT_GRID_REQUIRED")
  out<-file.path(output_root,"FIXED_PRODUCTION_V1",scope_info$scope,"compact")
  lo_exact_dispatch(repo,bundle,scope_info,tasks,grid,out,max_units=max_units)
}
