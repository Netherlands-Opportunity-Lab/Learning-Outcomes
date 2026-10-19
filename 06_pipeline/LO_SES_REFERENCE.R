# Independent PISA reference for the chosen four-wave SES construct. Input
# scores require separate calibration/raw-source verification. This function
# calls neither the production quartile helper nor its estimators or pooling.
lo_pisa_ses_reference <- function(obj,q) {
  allowed<-c('ses_harmonized','extension_ses_gender','extension_ses_school','ses_peer_exposure','peer_baseline')
  if(!nrow(q)||any(!q$module%in%allowed)||any(q$survey!='PISA')||
     any(q$definition!='Cobreros_fourwave_13item_trend_comparable'))stop('SES_REFERENCE_UNREVIEWED_CONTRACT')
  d<-obj$data;W<-as.matrix(d[c('W',paste0('RW',1:80))]);x<-as.numeric(d$SES)
  if(any(!is.finite(W))||any(W<0)||any(W[,1]<=0))stop('SES_REFERENCE_INVALID_WEIGHTS')
  good<-is.finite(x);n<-nrow(d)
  had<-exists('.Random.seed',.GlobalEnv,inherits=FALSE);old<-if(had)get('.Random.seed',.GlobalEnv)else NULL
  kind<-RNGkind();on.exit({do.call(RNGkind,as.list(kind));if(had)assign('.Random.seed',old,.GlobalEnv)else if(exists('.Random.seed',.GlobalEnv,inherits=FALSE))rm('.Random.seed',envir=.GlobalEnv)},add=TRUE)
  RNGkind('Mersenne-Twister','Inversion','Rejection');set.seed(7)
  order<-order(x[good],runif(sum(good)))
  codes<-matrix(NA_integer_,n,81)
  for(r in 1:81) {
    w<-W[good,r];before<-c(0,head(cumsum(w[order]),-1))/sum(w)
    # Three explicit strict comparisons implement the author's left-open cuts.
    g<-integer(length(w));g[order]<-rowSums(outer(before,c(.25,.5,.75),'>'))
    codes[good,r]<-g
  }
  full<-matrix(NA_real_,10,nrow(q),dimnames=list(NULL,q$metric_key))
  reps<-array(NA_real_,c(80,10,nrow(q)));counts<-integer(nrow(q))
  wm<-function(y,w){ok<-is.finite(y)&is.finite(w)&w>0;sum(y[ok]*w[ok])/sum(w[ok])}
  for(k in seq_len(nrow(q))) {
    task<-q[k,];fixed<-task$domain=='all';m<-if(fixed)1L else 10L
    Y<-if(fixed)matrix(x,n,1)else as.matrix(d[paste0('PV_',switch(task$domain,reading='READ',mathematics='MATH',science='SCIE'), '_',1:10)])
    observed<-rep(TRUE,n)
    if(!fixed) {
      counts_pv<-rowSums(is.finite(Y))
      if(any(!counts_pv%in%c(0L,10L)))stop('SES_REFERENCE_INCOMPLETE_PV')
      observed<-counts_pv==10L
      if(!any(observed))stop('SES_REFERENCE_NO_OBSERVED_PV')
    }
    sex<-rep(TRUE,n)
    if(task$module=='extension_ses_gender') {
      sex<-d$DEMO_GENDER==sub('^q[14]_','',task$group);sex[is.na(sex)]<-FALSE
    }
    tail<-if(task$module=='extension_ses_gender')sub('_.*$','',task$group)else sub('_.*$','',task$stat)
    wanted<-if(tail=='q1')0L else 3L
    gap<-task$stat=='score_gap_q4_minus_q1'
    unit<-as.character(d$SCHOOL)
    if(task$module=='ses_peer_exposure') {
      if(task$peer_definition=='direct_learning_environment')unit<-ifelse(is.na(d$PROGRAM)|!nzchar(d$PROGRAM)|is.na(unit)|!nzchar(unit),NA_character_,paste(unit,d$PROGRAM,sep='::'))
      else if(task$peer_definition!='whole_school')stop('SES_REFERENCE_PEER_ENVIRONMENT')
    }
    N<-good&sex&observed
    if(task$module%in%c('ses_harmonized','extension_ses_gender'))N<-N & if(gap)codes[,1]%in%c(0,3)else codes[,1]==wanted
    if(task$module=='extension_ses_school')N<-N&!is.na(unit)&nzchar(unit)
    if(task$module=='ses_peer_exposure') {
      valid<-good&!is.na(unit)&nzchar(unit)
      sizes<-table(unit[valid]);enough<-rep(FALSE,n);at<-match(unit,names(sizes));found<-!is.na(at)
      enough[found]<-as.numeric(sizes[at[found]])>=2
      N<-valid&enough&codes[,1]==wanted
    }
    counts[k]<-sum(N,na.rm=TRUE)
    a<-matrix(NA_real_,m,81)
    if(task$module%in%c('ses_harmonized','extension_ses_gender')) {
      # Independent matrix evaluation of the same 81 replicate-specific
      # quartile memberships. Reuse one outcome matrix across all weights;
      # never fix quartiles to the full sample or discard a required PV.
      values<-Y
      stat<-sub('^q[14]_','',task$stat)
      if(!gap&&stat%in%c('basic','high','below')) {
        cut<-as.numeric(task$threshold);if(!is.finite(cut))stop('SES_REFERENCE_THRESHOLD')
        values<-if(stat=='below')1*(values<cut)else 1*(values>=cut)
      }else if(!gap&&stat!='mean')stop('SES_REFERENCE_STAT')
      values[!observed,]<-0
      means<-function(tail) {
        keep<-codes==tail;keep[is.na(keep)]<-FALSE
        weights<-W*keep*as.numeric(good&sex&observed)
        sweep(crossprod(values,weights),2,colSums(weights),'/')
      }
      a<-if(gap)means(3L)-means(0L)else means(wanted)
    }else for(r in 1:81)for(j in seq_len(m)) {
      w<-W[,r];y<-Y[,j];g<-codes[,r]
      if(task$module=='extension_ses_school') {
        ok<-good&!is.na(unit)&nzchar(unit)&w>0;wt<-w[ok];v<-y[ok];u<-unit[ok]
        avg<-wm(v,wt);mass<-rowsum(cbind(weight=wt,value=wt*v),u,reorder=FALSE)
        between<-sum(mass[,1]*(mass[,2]/mass[,1]-avg)^2)
        a[j,r]<-100*between/sum(wt*(v-avg)^2)
      }else if(task$module=='peer_baseline') {
        if(!task$stat%in%c('q1_share','q4_share'))stop('SES_REFERENCE_BASELINE_STAT')
        a[j,r]<-100*wm(as.numeric(g==wanted),w)
      }else if(task$module=='ses_peer_exposure') {
        valid<-good&!is.na(unit)&nzchar(unit)&w>0;peer<-if(wanted==0L)3L else 0L
        share<-rep(NA_real_,n)
        mass<-rowsum(cbind(weight=w[valid],positive=w[valid]*(g[valid]==peer)),unit[valid],reorder=FALSE)
        total<-mass[match(unit[valid],rownames(mass)),,drop=FALSE];den<-total[,1]-w[valid]
        share[valid]<-ifelse(den>0,(total[,2]-w[valid]*(g[valid]==peer))/den,NA_real_)
        a[j,r]<-100*wm(share,w*as.numeric(g==wanted))
      }else if(gap) a[j,r]<-wm(y,w*as.numeric(g==3L))-wm(y,w*as.numeric(g==0L))
      else {
        stat<-sub('^q[14]_','',task$stat)
        if(stat%in%c('basic','high','below')) {
          cut<-as.numeric(task$threshold);if(!is.finite(cut))stop('SES_REFERENCE_THRESHOLD')
          y<-if(stat=='below')as.numeric(y<cut)else as.numeric(y>=cut)
        }else if(stat!='mean')stop('SES_REFERENCE_STAT')
        a[j,r]<-wm(y,w*as.numeric(g==wanted)*as.numeric(sex))
      }
    }
    if(any(!is.finite(a)))stop('SES_REFERENCE_NONFINITE: ',task$metric_key)
    # Repeat fixed observed statistics only for rectangular joint storage.
    # Their between-PV component is identically zero.
    full[,k]<-rep(a[,1],length.out=10)
    reps[,,k]<-t(a[rep(seq_len(m),length.out=10),-1,drop=FALSE])
  }
  variance<-vapply(seq_len(nrow(q)),function(k)mean(rowSums((t(reps[,,k])-full[,k])^2)/20)+1.1*var(full[,k]),numeric(1))
  list(results=data.frame(cell_id=q$metric_key,estimate=colMeans(full),standard_error=sqrt(variance),n_unweighted=counts),
    joint=list(cell_ids=q$metric_key,full_pv=full,replicate_pv=reps,factor=1/20,pv_count=10L,
      observed_statistics_repeat_fixed_value=TRUE,quartiles='Replicate-specific weighted cuts; fixed seed7 tie order in original source order'))
}
