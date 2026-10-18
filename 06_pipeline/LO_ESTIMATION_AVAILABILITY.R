# Check whether the approved conditional estimand has a positive denominator
# in every required PV and survey replicate. This is not a zero estimate, a
# replacement sample, or permission to drop a PV/replicate. Missing cells stay
# in the target grid and keep their complete reference/balance requirements.
lo_estimation_availability <- function(obj,q) {
  d<-obj$data;s<-obj$meta$survey;y<-as.integer(obj$meta$year)
  if(!s%in%c('PISA','PIRLS','TIMSS')||length(y)!=1L||is.na(y))stop('AVAILABILITY_SOURCE_IDENTITY')
  if(!nrow(q))return(list(tasks=q,unavailable=data.frame(),diagnostics=data.frame()))
  if(anyDuplicated(q$metric_key)||any(q$survey!=s)||any(as.integer(q$year)!=y))stop('AVAILABILITY_TASK_IDENTITY')
  if(s=='PISA') W<-as.matrix(d[c('W',paste0('RW',1:80))]) else {
    if(!all(c('W','JKZONE','JKREP')%in%names(d))||anyNA(d$JKZONE)||anyNA(d$JKREP)||
      any(!is.finite(d$JKZONE))||any(!d$JKREP%in%c(0,1)))stop('AVAILABILITY_INVALID_DESIGN')
    spec<-expand.grid(zone=sort(unique(d$JKZONE)),keep=if(y>=2015)c(0,1)else 1)
    W<-matrix(d$W,nrow(d),nrow(spec)+1L)
    for(i in seq_len(nrow(spec))) {
      at<-d$JKZONE==spec$zone[i]
      W[at,i+1L]<-W[at,1L]*ifelse(d$JKREP[at]==spec$keep[i],2,0)
    }
  }
  if(any(!is.finite(W))||any(W<0)||any(W[,1]<=0))stop('AVAILABILITY_INVALID_WEIGHTS')
  M<-if(s=='PISA'&&y>=2015)10L else 5L
  diagnostics<-list();reasons<-rep('',nrow(q))
  required_column<-function(name) {
    if(!name%in%names(d)||length(d[[name]])!=nrow(d))stop('AVAILABILITY_SOURCE_COLUMN_MISSING: ',name)
    d[[name]]
  }
  for(k in seq_len(nrow(q))) {
    z<-q[k,];m<-z$module;g<-NULL;groups<-NULL;peer<-FALSE;achievement_peer<-FALSE
    if(m%in%c('peer_below_basic','high_proficiency_peer_exposure')) {
      achievement_peer<-TRUE;peer<-TRUE
    }else if(m%in%c('migration','migration_binary_peer')||
             (m=='peer_baseline'&&z$stat=='reference_share')) {
      a<-required_column('MOTHER_BORN_HERE');b<-required_column('FATHER_BORN_HERE')
      if(!is.logical(a)||!is.logical(b))stop('AVAILABILITY_UNVERIFIED_PARENT_CODES')
      migrant<-switch(z$definition,MIGRATION_ANY_PARENT_ABROAD=!a|!b,
        MIGRATION_BOTH_PARENTS_ABROAD=!a&!b,stop('AVAILABILITY_MIGRATION_DEFINITION'))
      g<-ifelse(is.na(migrant),NA_character_,ifelse(migrant,'migration','reference'))
    }else if(m%in%c('migration_generation','migration_peer_exposure'))g<-required_column('DEMO_MIGRATION')
    else if(m%in%c('language_frequency_binary','home_language_frequency_peer','home_language_peer_exposure')||
            (m=='peer_baseline'&&z$stat=='test_language_share')) {
      g<-required_column('DEMO_LANGUAGE')
      if(s!='PISA') {
        if(any(!is.na(g)&!g%in%c('always','almost_always','always_or_almost_always','sometimes','never')))
          stop('AVAILABILITY_UNVERIFIED_LANGUAGE_CODES')
        g<-ifelse(is.na(g),NA_character_,ifelse(g%in%c('always','almost_always','always_or_almost_always'),'test_language_home','other_language_home'))
      }
    }else if(m=='extension_home_ses')g<-required_column('HOME_SES_GROUP')
    else next # Other approved estimators retain their existing strict checks.
    if(!achievement_peer) {
      accepted<-if(m%in%c('migration_generation','migration_peer_exposure'))c('native','first_generation','second_generation')else
        if(m=='extension_home_ses')c('higher','middle','lower')else
        if(m%in%c('migration','migration_binary_peer')||(m=='peer_baseline'&&z$stat=='reference_share'))c('migration','reference')else c('test_language_home','other_language_home')
      if(any(!is.na(g)&!g%in%accepted))stop('AVAILABILITY_UNVERIFIED_GROUP_CODES')
      peer<-m%in%c('migration_binary_peer','migration_peer_exposure','home_language_frequency_peer','home_language_peer_exposure')
      if(peer) {
        target_group<-switch(m,migration_binary_peer='migration',
          migration_peer_exposure=if(z$stat=='first_generation_target_pct_native_peers')'first_generation'else if(z$stat=='second_generation_target_pct_native_peers')'second_generation'else stop('AVAILABILITY_PEER_STAT'),
          home_language_frequency_peer='other_language_home',home_language_peer_exposure='other_language_home')
        groups<-list(target=target_group)
      }else if(m=='peer_baseline')groups<-list(observed=unique(g[!is.na(g)]))
      else if(z$stat%in%c('gap','mean_score_gap')) {
        groups<-switch(m,migration=list(focus='migration',reference='reference'),
          language_frequency_binary=list(focus='other_language_home',reference='test_language_home'),
          migration_generation=list(focus=switch(z$group,first_minus_native='first_generation',second_minus_native='second_generation',stop('AVAILABILITY_MIGRATION_CONTRAST')),reference='native'),
          stop('AVAILABILITY_CONTRAST_NOT_SUPPORTED'))
      }else groups<-list(target=if(m=='language_frequency_binary')switch(z$group,always_almost='test_language_home',sometimes_never='other_language_home',stop('AVAILABILITY_LANGUAGE_GROUP'))else z$group)
    }
    if(peer) {
      unit<-as.character(required_column('SCHOOL'))
      if(z$peer_definition=='direct_learning_environment') {
        second<-as.character(required_column(if(s=='PISA')'PROGRAM'else'CLASS'))
        unit<-ifelse(is.na(unit)|!nzchar(unit)|is.na(second)|!nzchar(second),NA_character_,paste(unit,second,sep='::'))
      }else if(z$peer_definition!='whole_school')stop('AVAILABILITY_PEER_ENVIRONMENT')
    }
    passes<-if(achievement_peer||(!peer&&z$domain!='all'))seq_len(M)else 1L
    for(pv in passes) {
      if(achievement_peer) {
        code<-switch(z$domain,reading='READ',mathematics='MATH',science='SCIE',stop('AVAILABILITY_DOMAIN'))
        score<-as.numeric(required_column(paste0('PV_',code,'_',pv)))
        low<-m=='peer_below_basic'
        if(low) {
          expected<-if(s=='PISA')'PISA_BELOW_LEVEL2'else'IEA_BELOW_INTERMEDIATE_475'
          if(z$threshold!=expected)stop('AVAILABILITY_THRESHOLD_ID')
          cut<-if(s=='PISA')unname(c(reading=407.47,mathematics=420.07,science=409.54)[z$domain])else 475
        }else cut<-as.numeric(z$threshold)
        if(!is.finite(cut))stop('AVAILABILITY_THRESHOLD')
        ind<-if(low)as.numeric(score<cut)else as.numeric(score>=cut)
        target<-switch(z$group,total=rep(1,nrow(d)),self_below_basic=ind,self_at_or_above_basic=1-ind,
          self_high=ind,self_below_high=1-ind,stop('AVAILABILITY_TARGET'))
        observed<-is.finite(score)
        masks<-list(target=target)
      }else {
        observed<-!is.na(g)
        if(!peer&&z$domain!='all') {
          code<-switch(z$domain,reading='READ',mathematics='MATH',science='SCIE',stop('AVAILABILITY_DOMAIN'))
          observed<-observed&is.finite(as.numeric(required_column(paste0('PV_',code,'_',pv))))
        }
        masks<-lapply(groups,function(v)as.numeric(observed&g%in%v))
      }
      for(label in names(masks)) {
        target<-masks[[label]]
        ok<-observed&is.finite(target)
        if(peer)ok<-ok&!is.na(unit)&nzchar(unit)
        if(any(ok)) {
          w<-W[ok,,drop=FALSE]
          eligible<-matrix(TRUE,nrow(w),ncol(w))
          if(peer) {
            sums<-rowsum(w,unit[ok],reorder=FALSE)
            eligible<-(sums[match(unit[ok],rownames(sums)),,drop=FALSE]-w)>0
          }
          mass<-colSums(ifelse(eligible,w*target[ok],0))
          n_target<-sum(eligible[,1]&target[ok]>0&w[,1]>0)
        }else {mass<-rep(0,ncol(W));n_target<-0L}
        if(any(!is.finite(mass))||any(mass<0))stop('AVAILABILITY_INVALID_DENOMINATOR')
        empty<-which(mass<=0)-1L # 0 is the full sample; positive IDs are replicates.
        if(length(empty)) {
          reason<-if(0L%in%empty)'NO_OBSERVED_ANALYTIC_TARGET_IN_REQUIRED_PV'else'EMPTY_TARGET_IN_REQUIRED_SURVEY_REPLICATE'
          reasons[k]<-reason
          diagnostics[[length(diagnostics)+1L]]<-data.frame(cell_id=z$metric_key,pv=pv,
            component=label,n_full_target=n_target,full_weight=mass[1],
            empty_weight_indices=paste(empty,collapse=';'),reason=reason,
            treatment='UNAVAILABLE_NOT_ZERO_NO_PV_OR_REPLICATE_DROPPED')
        }
      }
    }
  }
  unavailable<-q[nzchar(reasons),,drop=FALSE]
  unavailable$absence_reason<-reasons[nzchar(reasons)]
  list(tasks=q[!nzchar(reasons),,drop=FALSE],unavailable=unavailable,
       diagnostics=if(length(diagnostics))do.call(rbind,diagnostics)else data.frame())
}

# Write immutable, hash-bound diagnostic evidence only for exact unavailable
# targets. The full target grid and balanced reference requirements are retained.
lo_record_estimation_availability <- function(repo,root,obj,q,source_evidence) {
  checked<-lo_estimation_availability(obj,q)
  if(!nrow(checked$unavailable))return(checked$tasks)
  helper<-file.path(repo,'06_pipeline/LO_ESTIMATION_AVAILABILITY.R')
  key<-digest::digest(list(q=q,object=digest::digest(obj,algo='sha256'),
    code=digest::digest(file=helper,algo='sha256'),diagnostics=checked$diagnostics),algo='sha256')
  out<-file.path(root,'international/availability',key)
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  diagnostic<-file.path(out,'ANALYTIC_AVAILABILITY.csv')
  if(!file.exists(diagnostic))write.csv(checked$diagnostics,diagnostic,row.names=FALSE,na='')
  else if(!isTRUE(all.equal(read.csv(diagnostic),checked$diagnostics,check.attributes=FALSE)))stop('AVAILABILITY_CHECKPOINT_CHANGED')
  code<-file.path(out,'AVAILABILITY_VERIFIER.R')
  if(!file.exists(code))stopifnot(file.copy(helper,code))
  stopifnot(digest::digest(file=code,algo='sha256')==digest::digest(file=helper,algo='sha256'))
  selected<-file.path(out,'EXACT_SELECTED_TASKS.csv')
  if(!file.exists(selected))write.csv(q,selected,row.names=FALSE,na='')
  stopifnot(isTRUE(all.equal(read.csv(selected,colClasses='character',na.strings=character()),q,check.attributes=FALSE)))
  for(reason in unique(checked$unavailable$absence_reason)) {
    absent<-checked$unavailable[checked$unavailable$absence_reason==reason,,drop=FALSE]
    lo_international_absence(repo,root,absent,reason,c(source_evidence,diagnostic,code,selected),
      classification='ESTIMATION_UNAVAILABLE_VERIFIED')
  }
  checked$tasks
}
