source('06_pipeline/LO_EXACT_ESTIMATORS.R')
weighted_mean<-function(x,w){ok<-is.finite(x)&is.finite(w)&w>0;if(!any(ok))return(NA_real_);sum(x[ok]*w[ok])/sum(w[ok])}
old<-function(unit,peer_member,target_member,w) {
 ok<-!is.na(unit)&nzchar(unit)&is.finite(peer_member)&is.finite(target_member)&is.finite(w)&w>0
 if(sum(ok)<30L)return(NA_real_)
 u<-as.character(unit);tw<-ifelse(ok,w,0);pw<-ifelse(ok,w*peer_member,0)
 den<-ave(tw,u,FUN=sum)-ifelse(ok,w,0)
 num<-ave(pw,u,FUN=sum)-ifelse(ok,w*peer_member,0)
 weighted_mean(ifelse(ok&den>0,num/den,NA_real_),w*target_member)
}
set.seed(7);n<-403L;unit<-sample(c(letters,'',NA_character_),n,TRUE)
peer<-sample(c(0,.25,1,NA_real_),n,TRUE);target<-sample(c(0,.5,1,NA_real_),n,TRUE)
w<-runif(n,0,150);w[1:15]<-0;unit[n]<-'singleton';peer[n]<-1;target[n]<-1
for(i in 1:15) {
 wr<-w;wr[sample(n,60)]<-0
 stopifnot(isTRUE(all.equal(old(unit,peer,target,wr),lo_exact_peer_share(unit,peer,target,wr),tolerance=1e-12)))
}
stopifnot(is.na(lo_exact_peer_share(rep('a',29),rep(1,29),rep(1,29),rep(1,29))),
 is.na(lo_exact_peer_share(as.character(1:40),rep(1,40),rep(1,40),rep(1,40))))
cat('PASS independent peer sum parity, fractional groups, missingness, singleton exclusion and original minimum frame\n')
v10_text<-function(x)trimws(as.character(x))
old_categorical<-function(unit,g,positive,target,w) {
 ok<-!is.na(unit)&nzchar(v10_text(unit))&!is.na(g)&is.finite(w)&w>0
 if(!any(ok))return(NA_real_)
 u<-as.character(unit[ok]);ww<-w[ok];gg<-g[ok]
 tw<-ave(ww,u,FUN=sum);pw<-ave(ww*as.numeric(gg==positive),u,FUN=sum)
 weighted_mean((pw-ww*as.numeric(gg==positive))/(tw-ww),ww*as.numeric(gg==target))
}
g<-sample(c('positive','target','other',NA_character_),n,TRUE);unit[17]<-'  '
for(i in 1:15) {
 wr<-w;wr[sample(n,60)]<-0
 stopifnot(isTRUE(all.equal(old_categorical(unit,g,'positive','target',wr),
  lo_exact_categorical_peer(unit,g,'positive','target',wr),tolerance=1e-12)))
}
cat('PASS categorical peers retain known-category frame, whitespace and singleton semantics\n')
old_matrix<-function(unit,peer,target,W) {
 ok<-!is.na(unit)&nzchar(v10_text(unit))&is.finite(peer)&is.finite(target)
 if(!any(ok))return(rep(NA_real_,ncol(W)))
 u<-as.character(unit[ok]);gid<-match(u,unique(u));ww<-W[ok,,drop=FALSE];p<-peer[ok];t<-target[ok]
 total<-rowsum(ww,gid,reorder=TRUE);numer<-rowsum(ww*p,gid,reorder=TRUE)
 share<-(numer[gid,,drop=FALSE]-ww*p)/(total[gid,,drop=FALSE]-ww)
 good<-is.finite(share);tw<-ww*t
 out<-colSums(ifelse(good,tw*share,0))/colSums(ifelse(good,tw,0));out[!is.finite(out)]<-NA_real_;out
}
W<-matrix(w,n,17L);W[sample(length(W),500)]<-0
stopifnot(isTRUE(all.equal(old_matrix(unit,peer,target,W),lo_exact_peer_matrix(unit,peer,target,W),tolerance=1e-12)))
cat('PASS allocation-bounded peer matrices retain every replicate and missing denominator\n')
