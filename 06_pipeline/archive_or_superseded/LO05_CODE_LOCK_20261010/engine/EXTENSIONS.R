# Scientific extensions. Require the established survey-specific v10_pool backend.
# These functions do not load pupils, change calibration, or choose survey variance rules.
lo35_compute_extensions <- function(obj,q,backend) {
 if(!nrow(q))return(q)
 if(length(unique(q$module))!=1L||length(unique(q$domain))!=1L||length(unique(q$definition))!=1L)stop('Task must have one module/domain/definition.')
 m<-q$module[1];domain<-q$domain[1]
 supported<-(m=='core'&&all(q$stat%in%c('total_basic','total_below')))||(m=='gender'&&all(q$stat=='gap'))||(m=='language_frequency_binary'&&all(q$stat=='gap'))
 if(!supported)return(backend$original(obj,q))
 d<-obj$data;pv<-backend$pv_names(d,domain);if(!length(pv))stop('Plausible values ontbreken.')
 g<-NULL
 if(m=='gender'){
  if(any(q$group!='girls_minus_boys')||any(q$definition!='gender'))stop('Unsupported gender contrast definition.')
  g<-backend$gender(obj);allowed<-c('girl','boy')
 }
 if(m=='language_frequency_binary'){
  if(any(q$definition!='frequency_always_almost_vs_sometimes_never')||any(q$group!='sometimes_never_minus_always_almost'))stop('Unsupported frequency definition.')
  raw<-backend$language(obj,TRUE);allowed_raw<-c('always','almost_always','always_or_almost_always','sometimes','never')
  if(any(!is.na(raw)&!raw%in%allowed_raw))stop('Unknown frequency labels; codebook mapping required.')
  g<-ifelse(is.na(raw),NA_character_,ifelse(raw%in%c('always','almost_always','always_or_almost_always'),'always_almost','sometimes_never'));allowed<-c('sometimes_never','always_almost')
 }
 if(!is.null(g)&&any(!is.na(g)&!g%in%allowed))stop('Unknown group labels; no silent recode.')
 one<-function(w){
  out<-matrix(NA_real_,length(pv),nrow(q));colnames(out)<-paste(q$stat,q$group,sep="::")
  for(j in seq_along(pv)){
   y<-backend$num(d[[pv[j]]])
   for(k in seq_len(nrow(q))){
    if(m=='core'){
     threshold<-as.numeric(q$threshold[k]);if(!is.finite(threshold))stop('Threshold missing.')
     v<-if(q$stat[k]=='total_basic')as.numeric(y>=threshold)else as.numeric(y<threshold)
     out[j,k]<-backend$weighted_mean(v,w)
    }else{
     w1<-ifelse(is.na(g),0,w*as.numeric(g==allowed[1]));w2<-ifelse(is.na(g),0,w*as.numeric(g==allowed[2]))
     if(sum(w1,na.rm=TRUE)<=0||sum(w2,na.rm=TRUE)<=0)stop('Empty group in full/replicate sample.')
     out[j,k]<-backend$weighted_mean(y,w1)-backend$weighted_mean(y,w2)
    }
   }
  };out
 }
 # Contrasts are formed inside each PV and each replicate. Pooling preserves covariance.
 pooled<-backend$pool(obj,one)
 q$estimate<-as.numeric(pooled$estimate);q$se<-as.numeric(pooled$se)
 if(any(!is.finite(q$estimate))||any(!is.finite(q$se))||any(q$se<0))stop('Nonfinite pooled estimate/uncertainty.')
 q$ci_low<-q$estimate-1.96*q$se;q$ci_high<-q$estimate+1.96*q$se;q
}
