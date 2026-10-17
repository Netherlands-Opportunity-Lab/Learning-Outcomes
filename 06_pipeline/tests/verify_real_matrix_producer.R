# Optional real-data acceptance check against retained independent certificates.
repo<-Sys.getenv('LO_REPO_ROOT');root<-Sys.getenv('LO_FIXED_ROOT');bundle<-Sys.getenv('LO05_BUNDLE')
if(!all(nzchar(c(repo,root,bundle))))stop('Explicit LO_REPO_ROOT, LO_FIXED_ROOT and LO05_BUNDLE required')
for(f in c('LO_EXACT_BOOT.R','LO_COMPACT_RECOMPUTE.R','LO_APPROVED_EXTENSIONS.R','LO_SOURCE_REPAIR.R','LO_EXACT_ESTIMATORS.R'))source(file.path(repo,'06_pipeline',f))
for(f in c('LO04_COMMON.R','LO04_CACHE.R'))source(file.path(bundle,'code',f))
for(f in c('REPAIRS.R','EXTENSIONS.R'))source(file.path(bundle,'engine',f))
lo_exact_boot(bundle)
captures<-NULL
v10_pool<-function(obj,fn) {
 des<-rc2_replicate_design(obj$data,obj$meta$survey,obj$meta$year)
 full<-as.matrix(fn(des$w));rr<-array(NA_real_,c(des$n,nrow(full),ncol(full)))
 for(r in seq_len(des$n))rr[r,,]<-fn(rc2_repweight(des,r))
 captures<<-list(full=full,reps=rr,factor=des$factor,design=des)
 rc2_pool(full,rr,des$factor)
}
latest_block<-function(family,prefix) {
 dirs<-list.dirs(file.path(root,'international/blocks',family),recursive=FALSE)
 dirs<-dirs[startsWith(basename(dirs),prefix)&file.exists(file.path(dirs,'CONTROLLER_CLOSURE.json'))]
 stopifnot(length(dirs)>0);dirs[which.max(file.info(file.path(dirs,'CONTROLLER_CLOSURE.json'))$mtime)]
}
blocks<-c(ARE_PIRLS2021_CORE=latest_block('IEA','ARE_PIRLS_2021_'),
 ARE_PIRLS2021_BOOKS=latest_block('IEA_BOOKS','ARE_PIRLS_2021_'),
 NLD_PISA2018=file.path(root,'modern_pisa/2018'),NLD_TIMSS2023_BOOKS=file.path(root,'iea_books/TIMSS_2023'))
proof<-list()
for(kind in names(blocks)) {
 out<-blocks[[kind]];src<-jsonlite::fromJSON(file.path(out,'SOURCE_VERIFICATION.json'))
 path<-if(!is.null(src$canonical_filename))file.path(out,src$canonical_filename)else file.path(out,paste0('canonical_PISA_',src$year,'_',src$country,'_verified.rds'))
 stopifnot(file.exists(path),digest::digest(file=path,algo='sha256')==src$canonical_sha256)
 obj<-readRDS(path);q<-read.csv(file.path(out,'EXACT_SELECTED_TASKS.csv'),colClasses='character',na.strings=character())
 q<-q[q$module%in%c('core','gender','ses_national','ses_harmonized',lo_extension_modules()),]
 ref<-read.csv(file.path(out,'INDEPENDENT_RESULTS.csv'));joint<-readRDS(file.path(out,'JOINT_REFERENCE_PV_REPLICATES.rds'))
 groups<-split(seq_len(nrow(q)),paste(q$module,q$domain,q$definition,q$peer_definition,q$threshold,sep='|'))
 diff_est<-diff_se<-diff_joint<-0;n<-0;elapsed<-system.time(for(ix in groups) {
  tasks<-q[ix,];result<-lo_exact_selected_estimate(obj,lo_compact_backend_tasks(tasks))
  at<-match(tasks$metric_key,ref$cell_id);stopifnot(!anyNA(at))
  diff_est<-max(diff_est,abs(result$estimate-ref$estimate[at]));diff_se<-max(diff_se,abs(result$se-ref$standard_error[at]))
  j<-match(tasks$metric_key,joint$cell_ids);stopifnot(!anyNA(j),captures$factor==joint$factor)
  for(k in seq_along(j)) {
   full<-rep(captures$full[,k],length.out=nrow(joint$full_pv))
   rr<-matrix(captures$reps[,,k],nrow=dim(captures$reps)[1]);rr<-rr[,rep(seq_len(ncol(rr)),length.out=nrow(joint$full_pv)),drop=FALSE]
   if(obj$meta$survey!='PISA') {
     spec<-expand.grid(zone=sort(unique(obj$data$JKZONE)),keep=if(as.integer(obj$meta$year)>=2015)c(0,1)else 1)
     at_rep<-match(paste(spec$zone,spec$keep),paste(captures$design$zones,captures$design$keep))
     stopifnot(!anyNA(at_rep));rr<-rr[at_rep,,drop=FALSE]
   }
   diff_joint<-max(diff_joint,abs(full-joint$full_pv[,j[k]]),abs(rr-joint$replicate_pv[,,j[k]]))
  }
  n<-n+nrow(tasks)
 })[['elapsed']]
 proof[[kind]]<-list(cells=n,pupils=nrow(obj$data),seconds=elapsed,estimate_max=diff_est,SE_max=diff_se,joint_max=diff_joint)
 print(proof[[kind]]);flush.console()
 stopifnot(diff_est<1e-9,diff_se<1e-9,diff_joint<1e-9)
}
jsonlite::write_json(proof,file.path(root,'international/MATRIX_PRODUCER_PARITY.json'),auto_unbox=TRUE,pretty=TRUE,digits=17)
cat('REAL_MATRIX_PRODUCER_FULL_JOINT_PARITY_PASS\n')
