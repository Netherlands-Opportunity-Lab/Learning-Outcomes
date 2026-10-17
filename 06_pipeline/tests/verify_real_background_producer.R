# Optional real-data acceptance check against retained independent certificates.
repo<-Sys.getenv('LO_REPO_ROOT');root<-Sys.getenv('LO_FIXED_ROOT');bundle<-Sys.getenv('LO05_BUNDLE')
if(!all(nzchar(c(repo,root,bundle))))stop('Explicit LO_REPO_ROOT, LO_FIXED_ROOT and LO05_BUNDLE required')
for(f in c('LO_EXACT_BOOT.R','LO_COMPACT_RECOMPUTE.R','LO_APPROVED_EXTENSIONS.R','LO_SOURCE_REPAIR.R','LO_EXACT_ESTIMATORS.R'))source(file.path(repo,'06_pipeline',f))
for(f in c('LO04_COMMON.R','LO04_CACHE.R'))source(file.path(bundle,'code',f))
for(f in c('REPAIRS.R','EXTENSIONS.R'))source(file.path(bundle,'engine',f))
lo_exact_boot(bundle)
original_pool<-rc2_pool
captured<-list()
rc2_pool<-function(full,reps,factor,...) {
 for(k in seq_len(ncol(full)))captured[[length(captured)+1L]]<<-list(full=full[,k],reps=matrix(reps[,,k],nrow=dim(reps)[1]),factor=factor)
 original_pool(full,reps,factor,...)
}
latest<-function(family,prefix) {
 d<-list.dirs(file.path(root,'international/blocks',family),recursive=FALSE)
 d<-d[startsWith(basename(d),prefix)&file.exists(file.path(d,'CONTROLLER_CLOSURE.json'))]
 stopifnot(length(d)>0);d[which.max(file.info(file.path(d,'CONTROLLER_CLOSURE.json'))$mtime)]
}
blocks<-c(ARE_PIRLS2021_BACKGROUND=latest('BACKGROUND_IEA','ARE_PIRLS_2021_'),
 NLD_PISA2022_BACKGROUND=file.path(root,'background_pisa/PISA_2022'),
 NLD_PISA2022_PEERS=file.path(root,'peers/PISA_2022'),
 NLD_PIRLS2021_PEERS=file.path(root,'peers/PIRLS_2021'))
proof<-list()
for(kind in names(blocks)) {
 out<-blocks[[kind]];src<-jsonlite::fromJSON(file.path(out,'SOURCE_VERIFICATION.json'))
 path<-file.path(out,src$canonical_filename)
 stopifnot(file.exists(path),digest::digest(file=path,algo='sha256')==src$canonical_sha256)
 obj<-readRDS(path);q<-read.csv(file.path(out,'EXACT_SELECTED_TASKS.csv'),colClasses='character',na.strings=character())
 # This unchanged fixed-background producer pools directly without rc2_pool;
 # its exact replicate parity is covered by test_compact_recompute.R.
 q<-q[q$module!='migration_peer_exposure',]
 ref<-read.csv(file.path(out,'INDEPENDENT_RESULTS.csv'));joint<-readRDS(file.path(out,'JOINT_REFERENCE_PV_REPLICATES.rds'))
 groups<-split(seq_len(nrow(q)),paste(q$module,q$domain,q$definition,q$peer_definition,q$threshold,sep='|'))
 des<-rc2_replicate_design(obj$data,obj$meta$survey,obj$meta$year)
 diff_est<-diff_se<-diff_joint<-0;n<-0
 elapsed<-system.time(for(ix in groups) {
  s<-q[ix,];m<-s$module[1];science<-lo_compact_backend_tasks(s);captured<-list()
  a<-if(m=='peer_below_basic')lo_compact_low_peer(obj,s)else
   if(startsWith(m,'extension_'))lo_exact_selected_estimate(obj,science)else
   if(m%in%c('migration','migration_generation','language_exact','language_frequency_binary','migration_binary_peer','home_language_peer_exposure','home_language_frequency_peer'))lo_exact_background_linear(obj,science)else
   if(m=='migration_peer_exposure')lo_compact_migration_peers(obj,s)else
   if(m=='ses_peer_exposure'||(m=='peer_baseline'&&all(s$stat%in%c('q1_share','q4_share'))))lo_exact_ses_composition(obj,science)else v10_compute(obj,science)
  at<-match(s$metric_key,ref$cell_id);stopifnot(!anyNA(at))
  diff_est<-max(diff_est,abs(a$estimate-ref$estimate[at]));diff_se<-max(diff_se,abs(a$se-ref$standard_error[at]))
  actual_n<-if(startsWith(m,'extension_'))lo_extension_count_n(obj,science)else lo_compact_count_n(obj,science)
  stopifnot(identical(as.integer(actual_n),as.integer(ref$n_unweighted[at])))
  j<-match(s$metric_key,joint$cell_ids);stopifnot(!anyNA(j),length(captured)==length(j))
  for(k in seq_along(j)) {
   stopifnot(captured[[k]]$factor==joint$factor)
   full<-rep(captured[[k]]$full,length.out=nrow(joint$full_pv))
   rr<-captured[[k]]$reps;rr<-rr[,rep(seq_len(ncol(rr)),length.out=nrow(joint$full_pv)),drop=FALSE]
   if(obj$meta$survey!='PISA') {
    spec<-expand.grid(zone=sort(unique(obj$data$JKZONE)),keep=if(as.integer(obj$meta$year)>=2015)c(0,1)else 1)
    at_rep<-match(paste(spec$zone,spec$keep),paste(des$zones,des$keep));stopifnot(!anyNA(at_rep));rr<-rr[at_rep,,drop=FALSE]
   }
   diff_joint<-max(diff_joint,abs(full-joint$full_pv[,j[k]]),abs(rr-joint$replicate_pv[,,j[k]]))
  }
  n<-n+nrow(s)
 })[['elapsed']]
 proof[[kind]]<-list(cells=n,pupils=nrow(obj$data),seconds=elapsed,estimate_max=diff_est,SE_max=diff_se,joint_max=diff_joint)
 print(proof[[kind]]);flush.console();stopifnot(diff_est<1e-9,diff_se<1e-9,diff_joint<1e-9)
}
jsonlite::write_json(proof,file.path(root,'international/CHUNKED_BACKGROUND_PRODUCER_PARITY.json'),auto_unbox=TRUE,pretty=TRUE,digits=17)
cat('REAL_CHUNKED_BACKGROUND_FULL_JOINT_PARITY_PASS\n')

