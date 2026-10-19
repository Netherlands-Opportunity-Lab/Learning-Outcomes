# Inspect the actual samples behind sealed estimates without recalculating them.
# Contrasts require both components; achievement-peer target counts vary by PV.
# Never mistake the entire peer frame for the focal analysis group.
lo_analysis_support_counts <- function(obj,q) {
  stopifnot(nrow(q)==1L)
  d<-obj$data; m<-q$module; n<-nrow(d)
  field<-function(k) {if(!k%in%names(d))stop('SUPPORT_REQUIRED_FIELD: ',k);d[[k]]}
  w<-as.numeric(field('W')); positive<-is.finite(w)&w>0
  school<-as.character(field('SCHOOL')); school_ok<-!is.na(school)&nzchar(school)
  observed<-rep(TRUE,n); masks<-list(total=rep(1,n)); peer<-FALSE
  is_ses<-m%in%c('ses_national','ses_harmonized','ses_peer_exposure','extension_ses_gender',
    'extension_ses_school','extension_ses_class')||(m=='peer_baseline'&&q$stat%in%c('q1_share','q4_share'))
  if(is_ses) {
    observed<-is.finite(as.numeric(field('SES')))
    tails<-lo_exact_ses_tails(obj,q,w)
    if(m%in%c('ses_national','ses_harmonized'))
      masks<-if(q$group=='q4_minus_q1')list(q1=tails$q1,q4=tails$q4)else setNames(list(tails[[q$group]]),q$group)
    if(m=='extension_ses_gender') {
      sex<-as.character(field('DEMO_GENDER'))
      masks<-setNames(list(tails[[sub('_.*$','',q$group)]]*as.numeric(sex==sub('^q[14]_','',q$group))),q$group)
    }
    if(m=='ses_peer_exposure') {
      target<-if(q$stat=='q1_target_pct_q4_peers')'q1'else if(q$stat=='q4_target_pct_q1_peers')'q4'else stop('SUPPORT_SES_PEER_STAT')
      masks<-setNames(list(tails[[target]]),target);peer<-TRUE
    }
  }
  group<-NULL
  if(m=='gender') {
    group<-as.character(field('DEMO_GENDER'))
    masks<-if(q$stat=='gap')list(girl=as.numeric(group=='girl'),boy=as.numeric(group=='boy'))else setNames(list(as.numeric(group==q$group)),q$group)
  }
  if(m%in%c('migration','migration_binary_peer')||(m=='peer_baseline'&&q$stat=='reference_share')) {
    a<-field('MOTHER_BORN_HERE');b<-field('FATHER_BORN_HERE')
    if(!is.logical(a)||!is.logical(b))stop('SUPPORT_PARENT_FIELD_NOT_DECODED')
    migrant<-switch(q$definition,MIGRATION_ANY_PARENT_ABROAD=!a|!b,
      MIGRATION_BOTH_PARENTS_ABROAD=!a&!b,stop('SUPPORT_MIGRATION_DEFINITION'))
    group<-ifelse(is.na(migrant),NA_character_,ifelse(migrant,'migration','reference'))
    if(m=='migration')masks<-if(q$stat=='gap')list(migration=as.numeric(group=='migration'),reference=as.numeric(group=='reference'))else setNames(list(as.numeric(group==q$group)),q$group)
    if(m=='migration_binary_peer') {masks<-list(migration=as.numeric(group=='migration'));peer<-TRUE}
  }
  if(m%in%c('migration_generation','migration_peer_exposure')) {
    group<-as.character(field('DEMO_MIGRATION'))
    if(m=='migration_generation') {
      if(q$stat=='mean_score_gap') {
        target<-switch(q$group,first_minus_native='first_generation',second_minus_native='second_generation',stop('SUPPORT_GENERATION_CONTRAST'))
        masks<-setNames(list(as.numeric(group==target),as.numeric(group=='native')),c(target,'native'))
      }else masks<-setNames(list(as.numeric(group==q$group)),q$group)
    }else {
      target<-switch(q$stat,first_generation_target_pct_native_peers='first_generation',second_generation_target_pct_native_peers='second_generation',stop('SUPPORT_GENERATION_PEER'))
      masks<-setNames(list(as.numeric(group==target)),target);peer<-TRUE
    }
  }
  language<-m%in%c('language_exact','language_frequency_binary','home_language_frequency_peer','home_language_peer_exposure')||
    (m=='peer_baseline'&&q$stat=='test_language_share')
  if(language) {
    group<-as.character(field('DEMO_LANGUAGE'))
    if(obj$meta$survey!='PISA')group<-ifelse(is.na(group),NA_character_,ifelse(group%in%c('always','almost_always','always_or_almost_always'),'test_language_home','other_language_home'))
    if(m%in%c('language_exact','language_frequency_binary')) {
      target<-if(q$group=='always_almost')'test_language_home'else if(q$group=='sometimes_never')'other_language_home'else q$group
      masks<-if(q$stat=='gap')list(other_language_home=as.numeric(group=='other_language_home'),test_language_home=as.numeric(group=='test_language_home'))else setNames(list(as.numeric(group==target)),target)
    }
    if(m%in%c('home_language_frequency_peer','home_language_peer_exposure')) {
      masks<-list(other_language_home=as.numeric(group=='other_language_home'));peer<-TRUE
    }
  }
  if(m=='extension_home_ses') {
    group<-as.character(field('HOME_SES_GROUP'));masks<-setNames(list(as.numeric(group==q$group)),q$group)
  }
  if(!is.null(group))observed<-observed&!is.na(group)
  achievement_peer<-m%in%c('peer_below_basic','high_proficiency_peer_exposure')
  peer<-peer||achievement_peer
  environment<-school
  needs_class<-m%in%c('extension_performance_class','extension_ses_class')
  if((peer&&q$peer_definition=='direct_learning_environment')||needs_class) {
    second<-as.character(field(if(obj$meta$survey=='PISA'&&!needs_class)'PROGRAM'else'CLASS'))
    environment<-ifelse(school_ok&!is.na(second)&nzchar(second),paste(school,second,sep='::'),NA_character_)
  }
  if(peer&& !q$peer_definition%in%c('direct_learning_environment','whole_school'))stop('SUPPORT_PEER_DEFINITION')
  needs_unit<-peer||m%in%c('extension_performance_class','extension_ses_class','extension_performance_school','extension_ses_school')
  if(needs_unit)observed<-observed&!is.na(environment)&nzchar(environment)
  known<-c('core','gender','ses_national','ses_harmonized','ses_peer_exposure','migration','migration_binary_peer',
    'migration_generation','migration_peer_exposure','language_exact','language_frequency_binary',
    'home_language_frequency_peer','home_language_peer_exposure','peer_baseline','peer_below_basic',
    'high_proficiency_peer_exposure','extension_home_ses','extension_ses_gender','extension_performance_class',
    'extension_performance_school','extension_ses_school','extension_ses_class')
  if(!m%in%known)stop('SUPPORT_UNKNOWN_MODULE: ',m)
  pvs<-if(q$domain=='all')NA_character_ else {
    code<-switch(q$domain,reading='READ',mathematics='MATH',science='SCIE',stop('SUPPORT_DOMAIN'))
    paste0('PV_',code,'_',seq_len(if(obj$meta$survey=='PISA'&&obj$meta$year>=2015)10L else 5L))
  }
  output<-list()
  for(j in seq_along(pvs)) {
    score<-if(is.na(pvs[j]))rep(1,n)else as.numeric(field(pvs[j]))
    frame<-positive&observed&is.finite(score)
    if(peer) {
      mass<-rowsum(w[frame],environment[frame],reorder=FALSE)
      other<-rep(0,n);other[frame]<-mass[match(environment[frame],rownames(mass)),1]-w[frame]
      frame<-frame&other>0
    }
    if(achievement_peer) {
      low<-m=='peer_below_basic'
      cut<-if(low) {if(obj$meta$survey=='PISA')unname(c(reading=407.47,mathematics=420.07,science=409.54)[q$domain])else 475} else as.numeric(q$threshold)
      if(!is.finite(cut))stop('SUPPORT_THRESHOLD')
      indicator<-if(low)as.numeric(score<cut)else as.numeric(score>=cut)
      target<-switch(q$group,total=rep(1,n),self_below_basic=indicator,self_at_or_above_basic=1-indicator,
        self_high=indicator,self_below_high=1-indicator,stop('SUPPORT_PEER_TARGET'))
      masks<-setNames(list(target),q$group)
    }
    union<-rep(FALSE,n)
    for(label in names(masks)) {
      member<-as.numeric(masks[[label]]);valid<-frame&is.finite(member)&member>0
      union<-union|valid
      output[[length(output)+1L]]<-data.frame(pv=j,component=label,n=sum(valid),
        school_n=length(unique(school[valid&school_ok])),missing_school_n=sum(valid&!school_ok),
        fractional_n=sum(member[valid]),weight_sum=sum(w[valid]*member[valid]),
        peer_frame_n=sum(frame),stringsAsFactors=FALSE)
    }
    for(k in seq.int(length(output)-length(masks)+1L,length(output)))output[[k]]$union_n<-sum(union)
  }
  do.call(rbind,output)
}

lo_analysis_support_review <- function(repo,tasks,grid,out) {
  source(file.path(repo,'06_pipeline/LO_IEA_BACKGROUND.R'),local=environment())
  source(file.path(repo,'06_pipeline/LO_EXACT_ESTIMATORS.R'),local=environment())
  rc2_tails_rank<-lo_iea_reference_tails
  count_source<-lo_analysis_support_counts;environment(count_source)<-environment()
  g<-grid[grid$status=='SCIENTIFICALLY_VALIDATED',,drop=FALSE]
  if(!nrow(g)||anyDuplicated(g$cell_id)||anyDuplicated(tasks$metric_key))stop('SUPPORT_INVALID_SCOPE')
  at<-match(g$cell_id,tasks$metric_key);if(anyNA(at))stop('SUPPORT_UNAPPROVED_RESULT')
  q<-tasks[at,,drop=FALSE]
  dir.create(out,recursive=TRUE,showWarnings=FALSE);cache<-file.path(out,'source_checks');dir.create(cache,showWarnings=FALSE)
  files<-file.path(repo,'06_pipeline',c('LO_ANALYSIS_SUPPORT_REVIEW.R','LO_IEA_BACKGROUND.R','LO_EXACT_ESTIMATORS.R'))
  code<-vapply(files,function(p)digest::digest(file=p,algo='sha256'),character(1))
  records<-list();proof<-list();hits<-0L
  groups<-split(seq_len(nrow(g)),g$source_path)
  for(path in names(groups)) {
    ix<-groups[[path]];z<-g[ix,,drop=FALSE];task<-q[ix,,drop=FALSE]
    expected<-unique(z$source_edition_sha256)
    if(length(expected)!=1L||digest::digest(file=path,algo='sha256')!=expected)stop('SUPPORT_SOURCE_CHANGED')
    identity<-z[c('cell_id','target_contract_sha256','result_hash','n_unweighted')]
    identity<-identity[order(identity$cell_id),];rownames(identity)<-NULL
    key<-digest::digest(list(source=expected,code=code,targets=identity,tasks=task),algo='sha256')
    cached<-file.path(cache,paste0(key,'.rds'))
    if(file.exists(cached)) {
      saved<-readRDS(cached)
      if(saved$key!=key||saved$rows_sha256!=digest::digest(saved$rows,algo='sha256'))stop('SUPPORT_CACHE_CHANGED')
      rows<-saved$rows;hits<-hits+1L
    }else {
      obj<-readRDS(path);rows<-list()
      for(i in seq_len(nrow(task))) {
        counts<-count_source(obj,task[i,,drop=FALSE])
        isframe<-grepl('PEER_PV_FRAME_N_TARGET_COUNTS_V1',z$method_version[i],fixed=TRUE)
        recorded<-as.numeric(z$n_unweighted[i]);actual<-if(isframe)counts$peer_frame_n else counts$union_n
        rows[[i]]<-data.frame(cell_id=z$cell_id[i],country=z$country[i],survey=z$survey[i],year=z$year[i],
          domain=z$domain[i],module=task$module[i],group=task$group[i],
          source_sha256=expected,target_contract_sha256=z$target_contract_sha256[i],result_hash=z$result_hash[i],
          recorded_n=recorded,n_definition=if(isframe)'PEER_FRAME'else'ANALYTIC_TARGET_OR_COMPONENT_UNION',
          min_component_n=min(counts$n),max_component_n=max(counts$n),min_component_school_n=min(counts$school_n),
          max_missing_school_n=max(counts$missing_school_n),min_component_weight=min(counts$weight_sum),
          pv_count=max(counts$pv),component_count=length(unique(counts$component)),
          recorded_n_matches=all(actual==recorded),
          small_sample_note=if(any(counts$n<30))'FEWER_THAN_30_IN_AT_LEAST_ONE_COMPONENT_OR_PV'else
            if(any(counts$school_n<5))'FEWER_THAN_5_SCHOOLS_IN_AT_LEAST_ONE_COMPONENT_OR_PV'else 'MINIMUM_30_PUPILS_5_SCHOOLS_MET',
          counts_sha256=digest::digest(counts,algo='sha256'),stringsAsFactors=FALSE)
      }
      rows<-do.call(rbind,rows)
      saveRDS(list(key=key,rows=rows,rows_sha256=digest::digest(rows,algo='sha256')),cached)
      rm(obj);gc(FALSE)
    }
    records[[length(records)+1L]]<-rows
    proof[[length(proof)+1L]]<-data.frame(source_sha256=expected,key=key,cache_sha256=digest::digest(file=cached,algo='sha256'))
    if(length(records)%%50L==0L)cat('ANALYSIS_SUPPORT_SOURCES ',length(records),'/',length(groups),'\n',sep='')
  }
  all<-do.call(rbind,records);all<-all[order(all$cell_id),]
  write.csv(all,file.path(out,'ANALYSIS_SUPPORT.csv'),row.names=FALSE,na='')
  write.csv(do.call(rbind,proof),file.path(out,'ANALYSIS_SUPPORT_SOURCES.csv'),row.names=FALSE,na='')
  summary<-list(status=if(all(all$recorded_n_matches))'ACTUAL_ANALYSIS_SUPPORT_REVIEWED'else'ANALYSIS_SUPPORT_COUNT_DIFFERENCES',
    result_cells=nrow(all),sources=length(groups),reused=hits,n_mismatches=sum(!all$recorded_n_matches),
    below_30_pupils=sum(all$min_component_n<30),below_5_schools=sum(all$min_component_school_n<5),
    code_sha256=as.list(code),outputs=list(coverage=digest::digest(file=file.path(out,'ANALYSIS_SUPPORT.csv'),algo='sha256'),
      sources=digest::digest(file=file.path(out,'ANALYSIS_SUPPORT_SOURCES.csv'),algo='sha256')),
    interpretation='Sample size is a separate quality attribute, not missing source data or a zero estimate. These counts do not alone establish reliability or disclosure clearance. PISA reporting uses at least 30 pupils and five schools; this report does not invent an IEA-specific official threshold. No estimate or target was changed.')
  jsonlite::write_json(summary,file.path(out,'ANALYSIS_SUPPORT_REVIEW.json'),auto_unbox=TRUE,pretty=TRUE,digits=17)
  invisible(summary)
}
