# Independent background/composition verification. The replicate matrix, group
# contrasts, leave-one-out fractions and pooling are independent of the producer.
# Source mappings must already carry their raw-field and exact pupil-ID proof.
lo_background_reference <- function(obj,q) {
 d<-obj$data;s<-obj$meta$survey;y<-as.integer(obj$meta$year)
 allowed<-c('migration','migration_generation','migration_binary_peer','migration_peer_exposure',
   'language_frequency_binary','home_language_frequency_peer','home_language_peer_exposure',
   'ses_peer_exposure','peer_baseline','extension_home_ses')
 if(!nrow(q)||any(!q$module%in%allowed)||any(q$survey!=s)||any(as.integer(q$year)!=y))stop('BACKGROUND_REFERENCE_SCOPE')
 if(s=='PISA'){W<-as.matrix(d[c('W',paste0('RW',1:80))]);factor<-1/20}else {
  spec<-expand.grid(zone=sort(unique(d$JKZONE)),keep=if(y>=2015)c(0,1)else 1)
  W<-matrix(d$W,nrow(d),nrow(spec)+1L);factor<-if(y>=2015).5 else 1
  for(i in seq_len(nrow(spec))){a<-d$JKZONE==spec$zone[i];W[a,i+1]<-W[a,1]*ifelse(d$JKREP[a]==spec$keep[i],2,0)}
 }
 stopifnot(all(is.finite(W)),all(W>=0),all(W[,1]>0))
 M<-if(s=='PISA'&&y>=2015)10L else 5L;R<-ncol(W)-1L
 full<-matrix(NA_real_,M,nrow(q));reps<-array(NA_real_,c(R,M,nrow(q)));ns<-integer(nrow(q))
 wm<-function(a,w){ok<-is.finite(a)&is.finite(w)&w>0;sum(a[ok]*w[ok])/sum(w[ok])}
 for(k in seq_len(nrow(q))) {
  z<-q[k,];m<-z$module;fixed<-z$domain=='all';g<-NULL
  if(grepl('MIGRATION_(ANY|BOTH)_PARENTS?_ABROAD',z$definition)||z$definition=='MIGRATION_ANY_PARENT_ABROAD') {
   a<-d$MOTHER_BORN_HERE;b<-d$FATHER_BORN_HERE
   stopifnot(is.logical(a),is.logical(b),length(a)==nrow(d),length(b)==nrow(d))
   migrant<-if(z$definition=='MIGRATION_ANY_PARENT_ABROAD')!a|!b else !a&!b
   g<-ifelse(is.na(migrant),NA_character_,ifelse(migrant,'migration','reference'))
  }else if(m%in%c('migration_generation','migration_peer_exposure'))g<-d$DEMO_MIGRATION
  else if(m=='extension_home_ses')g<-d$HOME_SES_GROUP
  else if(m%in%c('home_language_peer_exposure','home_language_frequency_peer','language_frequency_binary')||z$stat=='test_language_share') {
   g<-d$DEMO_LANGUAGE
   if(s!='PISA')g<-ifelse(is.na(g),NA_character_,ifelse(g%in%c('always','almost_always','always_or_almost_always'),'test_language_home','other_language_home'))
  }
  if(!fixed){code<-switch(z$domain,reading='READ',mathematics='MATH',science='SCIE');Y<-as.matrix(d[paste0('PV_',code,'_',seq_len(M))])}else Y<-matrix(1,nrow(d),M)
  ispeer<-m%in%c('migration_binary_peer','migration_peer_exposure','home_language_peer_exposure','home_language_frequency_peer','ses_peer_exposure')
  if(ispeer){unit<-as.character(d$SCHOOL);if(z$peer_definition=='direct_learning_environment'){
   v<-as.character(d[[if(s=='PISA')'PROGRAM'else'CLASS']]);unit<-ifelse(is.na(unit)|is.na(v)|!nzchar(unit)|!nzchar(v),NA_character_,paste(unit,v,sep='::'))
  }else if(z$peer_definition!='whole_school')stop('BACKGROUND_ENVIRONMENT')}
  A<-matrix(NA_real_,if(fixed)1L else M,ncol(W));count<-integer(nrow(A))
  for(j in seq_len(nrow(A)))for(r in seq_len(ncol(W))) {
   w<-W[,r];outcome<-Y[,j];eligible<-rep(TRUE,nrow(d))
   if(m=='peer_baseline'&&z$stat%in%c('q1_share','q4_share')||m=='ses_peer_exposure') {
    if(z$definition!='books5_fractional')stop('BACKGROUND_REFERENCE_NONBOOK_SES')
    tails<-lo_iea_reference_tails(d$SES,w);eligible<-is.finite(d$SES)
    if(m=='peer_baseline')value<-100*wm(tails[[sub('_share$','',z$stat)]],w*eligible)
    else {target<-tails[[if(z$stat=='q1_target_pct_q4_peers')'q1'else'q4']];peer<-tails[[if(z$stat=='q1_target_pct_q4_peers')'q4'else'q1']]}
   }else if(ispeer) {
    eligible<-!is.na(g)
    desired<-switch(m,migration_binary_peer='migration',migration_peer_exposure=if(z$stat=='first_generation_target_pct_native_peers')'first_generation'else'second_generation',
     home_language_peer_exposure='other_language_home',home_language_frequency_peer='other_language_home')
    positive<-switch(m,migration_binary_peer='reference',migration_peer_exposure='native','test_language_home')
    target<-as.numeric(g==desired);peer<-as.numeric(g==positive)
   }else if(m=='peer_baseline') {
    if(z$stat=='high_share'){value<-100*wm(as.numeric(outcome>=as.numeric(z$threshold)),w);eligible<-is.finite(outcome)}else {
     positive<-switch(z$stat,reference_share='reference',test_language_share='test_language_home',stop('BACKGROUND_BASELINE_STAT'))
     eligible<-!is.na(g);value<-100*wm(as.numeric(g==positive),w)
    }
   }else {
    if(m=='language_frequency_binary'){a<-'other_language_home';b<-'test_language_home';desired<-if(z$group=='always_almost')b else a}
    else if(m=='migration'){a<-'migration';b<-'reference';desired<-z$group}
    else if(m=='migration_generation'){a<-if(z$group=='first_minus_native')'first_generation'else'second_generation';b<-'native';desired<-z$group}
    else if(m=='extension_home_ses') {desired<-z$group;if(z$stat=='below')outcome<-as.numeric(outcome<as.numeric(z$threshold))else if(z$stat=='high')outcome<-as.numeric(outcome>=as.numeric(z$threshold))}
    if(z$stat%in%c('gap','mean_score_gap')){eligible<-!is.na(g)&g%in%c(a,b);value<-wm(outcome,w*(g==a))-wm(outcome,w*(g==b))}
    else {eligible<-!is.na(g)&g==desired;value<-wm(outcome,w*eligible)}
   }
   if(ispeer) {
    ok<-eligible&!is.na(unit)&nzchar(unit)&is.finite(peer)&is.finite(target)&w>0
    fraction<-rep(NA_real_,nrow(d))
    for(ix in split(which(ok),unit[ok])) {
     den<-sum(w[ix])-w[ix];fraction[ix]<-ifelse(den>0,(sum(w[ix]*peer[ix])-w[ix]*peer[ix])/den,NA_real_)
    }
    value<-100*wm(fraction,w*target);eligible<-is.finite(fraction)&target>0
   }
   A[j,r]<-value
   if(r==1L)count[j]<-sum(eligible&is.finite(outcome)&w>0,na.rm=TRUE)
  }
  if(any(!is.finite(A))||length(unique(count))!=1L)stop('BACKGROUND_REFERENCE_INVALID_RESULT: ',z$metric_key)
  if(fixed)A<-A[rep(1,M),,drop=FALSE]
  full[,k]<-A[,1];reps[,,k]<-t(A[,-1,drop=FALSE]);ns[k]<-count[1]
 }
 variances<-vapply(seq_len(nrow(q)),function(k)mean(rowSums((t(reps[,,k])-full[,k])^2)*factor)+(1+1/M)*var(full[,k]),numeric(1))
 list(results=data.frame(cell_id=q$metric_key,estimate=colMeans(full),standard_error=sqrt(variances),n_unweighted=ns),
  joint=list(cell_ids=q$metric_key,full_pv=full,replicate_pv=reps,factor=factor,pv_count=M,
   fixed_background_uses_no_achievement_PV=TRUE,peer_self_exclusion=TRUE,unknown_background_excluded=TRUE))
}
