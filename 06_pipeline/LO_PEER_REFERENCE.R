# Independent weighted leave-one-out reference. This consumes source columns
# whose identity has already been verified against official pupil records.
# No calls to the production peer estimator, replicate builder or PV pooling.
lo_peer_independent_reference <- function(obj,q) {
  d<-obj$data;s<-obj$meta$survey;year<-as.integer(obj$meta$year)
  if(!nrow(q)||any(!q$module%in%c('peer_below_basic','high_proficiency_peer_exposure'))||
     any(q$survey!=s)|any(as.integer(q$year)!=year))stop('PEER_REFERENCE_TASK_IDENTITY')
  if(s=='PISA') {
    W<-as.matrix(d[c('W',paste0('RW',1:80))]);factor<-1/20
  }else {
    spec<-expand.grid(zone=sort(unique(d$JKZONE)),keep=if(year>=2015)c(0,1)else 1)
    W<-matrix(d$W,nrow(d),nrow(spec)+1L);factor<-if(year>=2015).5 else 1
    for(i in seq_len(nrow(spec))){a<-d$JKZONE==spec$zone[i];W[a,i+1]<-W[a,1]*ifelse(d$JKREP[a]==spec$keep[i],2,0)}
  }
  if(any(!is.finite(W))||any(W<0)||any(W[,1]<=0))stop('PEER_REFERENCE_INVALID_WEIGHTS')
  M<-if(s=='PISA'&&year>=2015)10L else 5L;R<-ncol(W)-1L
  full<-matrix(NA_real_,M,nrow(q),dimnames=list(NULL,q$metric_key))
  reps<-array(NA_real_,c(R,M,nrow(q)),dimnames=list(NULL,NULL,q$metric_key))
  counts<-vector('list',nrow(q)*M);frames<-integer(nrow(q))
  # The peer fraction is independent of the focal group. Build it once for
  # each exact domain/threshold/environment and PV, then evaluate every
  # requested focal group. Keep output and joint-array order identical to q.
  keys<-paste(q$module,q$domain,q$peer_definition,q$threshold,sep='|')
  for(key in unique(keys)) {
    selected<-which(keys==key)
    z<-q[selected[1],];code<-switch(z$domain,reading='READ',mathematics='MATH',science='SCIE',stop('PEER_REFERENCE_DOMAIN'))
    unit<-as.character(d$SCHOOL)
    if(z$peer_definition=='direct_learning_environment') {
      second<-if(s=='PISA')as.character(d$PROGRAM)else as.character(d$CLASS)
      unit<-ifelse(is.na(unit)|!nzchar(unit)|is.na(second)|!nzchar(second),NA_character_,paste(unit,second,sep='::'))
    }else if(z$peer_definition!='whole_school')stop('PEER_REFERENCE_UNKNOWN_ENVIRONMENT')
    low<-z$module=='peer_below_basic'
    if(low) {
      expected<-if(s=='PISA')'PISA_BELOW_LEVEL2'else 'IEA_BELOW_INTERMEDIATE_475'
      if(z$threshold!=expected)stop('PEER_REFERENCE_LOW_THRESHOLD_ID')
      cut<-if(s=='PISA')unname(c(reading=407.47,mathematics=420.07,science=409.54)[z$domain])else 475
    }else cut<-as.numeric(z$threshold)
    if(!is.finite(cut))stop('PEER_REFERENCE_MISSING_THRESHOLD')
    for(j in seq_len(M)) {
      y<-as.numeric(d[[paste0('PV_',code,'_',j)]])
      ok<-is.finite(y)&!is.na(unit)&nzchar(unit)
      y<-y[ok];u<-unit[ok];w<-W[ok,,drop=FALSE]
      high<-z$module=='high_proficiency_peer_exposure'
      indicator<-if(high)as.numeric(y>=cut)else as.numeric(y<cut)
      # Build each unit's peer means, subtracting each pupil's contribution.
      total<-rowsum(w,u,reorder=FALSE);positive<-rowsum(w*indicator,u,reorder=FALSE)
      at<-match(u,rownames(total));denom<-total[at,,drop=FALSE]-w
      numer<-positive[at,,drop=FALSE]-w*indicator
      fraction<-ifelse(denom>0,numer/denom,NA_real_)
      eligible<-is.finite(fraction)
      for(k in selected) {
        target<-switch(q$group[k],total=rep(1,length(y)),self_below_basic=indicator,
          self_at_or_above_basic=1-indicator,self_high=indicator,self_below_high=1-indicator,
          stop('PEER_REFERENCE_UNKNOWN_FOCAL_GROUP'))
        weighted_target<-w*target
        values<-100*colSums(ifelse(eligible,fraction*weighted_target,0))/colSums(ifelse(eligible,weighted_target,0))
        if(any(!is.finite(values)))stop('PEER_REFERENCE_EMPTY_REPLICATE_OR_TARGET: ',q$metric_key[k])
        full[j,k]<-values[1];reps[,j,k]<-values[-1]
        counts[[(k-1L)*M+j]]<-data.frame(cell_id=q$metric_key[k],pv=j,n_frame=sum(eligible[,1]),n_target=sum(eligible[,1]&target>0),
          n_definition='ANALYTIC_PEER_FRAME_WITH_SEPARATE_PV_TARGET_COUNTS')
      }
    }
    for(k in selected) {
      ns<-vapply(counts[(k-1L)*M+seq_len(M)],function(x)x$n_frame,integer(1))
      if(length(unique(ns))!=1L)stop('PEER_REFERENCE_PV_FRAME_CHANGES')
      frames[k]<-ns[1]
    }
  }
  variance<-vapply(seq_len(nrow(q)),function(k)mean(rowSums((t(reps[,,k])-full[,k])^2)*factor)+(1+1/M)*var(full[,k]),numeric(1))
  list(results=data.frame(cell_id=q$metric_key,estimate=colMeans(full),standard_error=sqrt(variance),n_unweighted=frames),
    counts=do.call(rbind,counts),joint=list(cell_ids=q$metric_key,full_pv=full,replicate_pv=reps,factor=factor,pv_count=M,
      self_exclusion=TRUE,frame_definition='Observed valid achievement and peer environment with at least one other eligible pupil',
      target_counts='Recorded separately for every plausible value; n_unweighted is the analytic peer frame, not a fabricated fixed latent-group count'))
}
