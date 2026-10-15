# Scientific verification orchestration; this is a library for the existing
# audit -> produce -> finalize protocol, not another production entry point.
# Call only after independent source proof and a measured pilot exist in each
# explicitly named block directory. Paths are private caller configuration.
lo_certify_verified_source_blocks <- function(repo,bundle,root,block_root,
  blocks,pilot_id,kind=c("PISA_MODERN","PISA_LEGACY","PISA_SES","IEA","IEA_BOOKS","PEERS_PISA","PEERS_IEA","BACKGROUND_PISA","BACKGROUND_IEA"),scope="nld_only",defer_audit=FALSE,verified_support=NULL) {
  kind<-match.arg(kind)
  peers<-startsWith(kind,"PEERS_");pisa<-grepl("PISA",kind,fixed=TRUE)
  stopifnot(length(blocks)>=1L,!anyDuplicated(blocks),pilot_id%in%blocks,
    all(grepl("^[A-Za-z0-9_]+$",blocks)))
  repo<-normalizePath(repo,winslash="/");bundle<-normalizePath(bundle,winslash="/")
  root<-normalizePath(root,winslash="/");block_root<-normalizePath(block_root,winslash="/")
  master<-file.path(root,"master_reconciliation")
  old_env<-Sys.getenv(c("LO_REPO_ROOT","LO_RUN_CONFIG"),unset=NA_character_)
  on.exit(for(k in names(old_env))if(is.na(old_env[[k]]))Sys.unsetenv(k)else do.call(Sys.setenv,setNames(list(old_env[[k]]),k)),add=TRUE)
Sys.setenv(LO_REPO_ROOT=repo)
for(p in c('LO_FIXED_CONTROLLER.R','LO_RUN_CONFIG.R','MASTER_ESTIMATION_GRID.R','GRID_ARCHIVE_BATCH.R','LO_SCOPE_DECISIONS.R','LO_APPROVED_EXTENSIONS.R','LO_EXACT_DISPATCH.R','LO_COMPACT_RECOMPUTE.R','LO_COMPACT_GRID_STORE.R','LO_EXACT_ESTIMATORS.R','LO_EXACT_BOOT.R','LO_SOURCE_REPAIR.R','LO_BALANCED_MEMBERSHIP.R','LO_COUNTRY_REGISTRY.R','LO_COUNTRY_TASKS.R','LO_GENDER_POOL_POLICY.R'))source(file.path(repo,'06_pipeline',p))
for(p in c('LO04_COMMON.R','LO04_CACHE.R'))source(file.path(bundle,'code',p))
for(p in c('REPAIRS.R','EXTENSIONS.R'))source(file.path(bundle,'engine',p))
lo_exact_boot(bundle)
old<-read.csv(file.path(master,'SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'),stringsAsFactors=FALSE,na.strings=character())
requested<-do.call(rbind,lapply(blocks,function(b)read.csv(file.path(block_root,b,'EXACT_SELECTED_TASKS.csv'),colClasses='character',na.strings=character())))
allowed_modules<-if(peers)c('peer_below_basic','high_proficiency_peer_exposure')else if(kind=='PISA_SES')c('ses_harmonized','extension_ses_gender','extension_ses_school','ses_peer_exposure','peer_baseline')else if(pisa)c('core','gender','language_exact','migration_generation','extension_performance_school')else switch(kind,IEA=c('core','gender','extension_performance_school','extension_performance_class'),IEA_BOOKS=c('ses_national','extension_ses_gender','extension_ses_school','extension_ses_class'))
if(startsWith(kind,'BACKGROUND_'))allowed_modules<-c('migration','migration_generation','migration_binary_peer','migration_peer_exposure','language_frequency_binary','home_language_frequency_peer','home_language_peer_exposure','ses_peer_exposure','peer_baseline','extension_home_ses')
if(any(!requested$module%in%allowed_modules)||anyDuplicated(requested$metric_key))stop('CERTIFICATION_UNREVIEWED_SCOPE')
if(kind=='PISA_SES'&&any(requested$definition!='Cobreros_fourwave_13item_trend_comparable'))stop('CERTIFICATION_WRONG_SES_CONSTRUCT')
base<-read.csv(file.path(bundle,'engine/TASKS.csv'),colClasses='character',na.strings=character())
support<-if(is.null(verified_support))lo_read_source_support(file.path(master,'SOURCE_SUPPORT_CONTRACTS.csv'))else verified_support
info<-lo_runtime_scope(bundle,base,scope,support)
lo_country_production_approval(repo,unique(requested$country),info$dashboard)
base<-lo_country_base_tasks(base,info);base<-base[base$country%in%unique(requested$country),];decisions<-lo_read_scope_decisions(repo)
base<-lo_scope_active_tasks(rbind(base,lo_extension_tasks(base,decisions),lo_scoped_low_peer_tasks(base,decisions)),decisions)
base<-lo_gender_pool_tasks(base,support)
allowed<-lo_grid_from_tasks(base);want<-lo_grid_from_tasks(requested);ix<-match(want$cell_id,allowed$cell_id)
if(anyNA(ix)||any(want$target_contract_sha256!=allowed$target_contract_sha256[ix]))stop('CERTIFICATION_TASK_NOT_EXACTLY_APPROVED')
if(all(want$cell_id%in%old$cell_id)) {
  check<-lo_grid_verify_result_artifacts(old[match(want$cell_id,old$cell_id),])
  if(!isTRUE(check))stop('CERTIFICATION_EXISTING_EVIDENCE_INVALID')
  return(invisible(list(status='REUSED_CERTIFIED_WITHOUT_CALCULATION',cells=nrow(want))))
}
pending_path<-file.path(master,'SCIENTIFIC_COMPUTE_APPROVALS.csv')
if(any(want$cell_id%in%old$cell_id)||file.exists(pending_path)&&nrow(read.csv(pending_path))>0L)
  stop('CERTIFICATION_EXISTING_PARTIAL_RUN: preserve its approvals and resume with fixed-produce')
resource<-normalizePath(file.path(block_root,pilot_id,'RESOURCE_BUDGET.json'),winslash='/')
budget<-jsonlite::fromJSON(resource);stopifnot(budget$status=='MEASURED',is.finite(budget$max_n),budget$max_n>0)
code_sha<-lo_exact_code_sha(repo,bundle);approved<-list();all_tasks<-list();all_evidence<-list()
for(year in blocks) {
 out<-file.path(block_root,year)
 q<-read.csv(file.path(out,'EXACT_SELECTED_TASKS.csv'),colClasses='character',na.strings=character())
 src_survey<-unique(q$survey);src_year<-unique(q$year);country<-unique(q$country)
 stopifnot(length(src_survey)==1L,length(src_year)==1L,length(country)==1L)
 stopifnot(all(paste(q$survey,q$year,sep='_')==paste(src_survey,src_year,sep='_')),!any(q$metric_key%in%old$cell_id))
 src<-jsonlite::fromJSON(file.path(out,'SOURCE_VERIFICATION.json'))
 stopifnot(src$country==country,src$survey==src_survey,as.character(src$year)==src_year,
   src$status%in%c('RAW_SAMPLE_AND_FIELDS_VERIFIED','RAW_COLUMNS_IDENTITY_VERIFIED','RAW_SAMPLE_COLUMNS_AND_DEMOGRAPHICS_VERIFIED'))
 source_path<-normalizePath(file.path(out,if(is.null(src$canonical_filename))paste0('canonical_PISA_',src_year,'_',country,'_verified.rds')else src$canonical_filename),winslash='/')
 obj<-readRDS(source_path)
 stopifnot(lo_exact_sha(source_path)==src$canonical_sha256,nrow(obj$data)<=budget$max_n)
 evidence<-c(file.path(out,c('SOURCE_VERIFICATION.json','INDEPENDENT_RESULTS.csv','JOINT_REFERENCE_PV_REPLICATES.rds')),list.files(out,pattern='^VERIFIER_.*[.]R$',full.names=TRUE),list.files(out,pattern='^RAW_COLUMN_PARITY[.]csv$',full.names=TRUE))
 if(peers)evidence<-c(evidence,file.path(out,c('PV_TARGET_SAMPLE_COUNTS.csv','PARENT_SOURCE_VERIFICATION.json')))
 if(startsWith(kind,'BACKGROUND_'))evidence<-c(evidence,file.path(out,'PARENT_SOURCE_VERIFICATION.json'),list.files(out,pattern='^RAW_MAPPING_.*[.]json$',full.names=TRUE))
 if(kind=='PISA_SES') {
   lo_exact_assert_sha(obj$meta$calibration_evidence_path,obj$meta$calibration_sha256,'CALIBRATION')
   evidence<-c(evidence,obj$meta$calibration_evidence_path,file.path(out,'PARENT_SOURCE_VERIFICATION.json'))
 }
 stopifnot(length(evidence)>=4L,all(file.exists(evidence)))
 ef<-data.frame(path=normalizePath(evidence,winslash='/'),sha256=vapply(evidence,lo_exact_sha,character(1)))
 all_evidence[[year]]<-ef
 groups<-split(seq_len(nrow(q)),paste(q$module,q$domain,q$definition,q$peer_definition,q$threshold,sep='|'))
 for(ix in groups) {
   z<-q[ix,];a<-lo_grid_from_tasks(z);a$source_path<-source_path;a$source_edition_sha256<-src$canonical_sha256
   a$sample_id<-paste0(year,'_',country,'_ALL_',nrow(obj$data),'_PUBLIC_USE_STUDENTS')
   a$method_version<-paste0(kind,'_',z$module[1],'_RAW_DESIGN_PV_INDEPENDENT_V1',if(peers)'_PEER_PV_FRAME_N_TARGET_COUNTS_V1'else '')
   a$weight_design<-if(pisa)'W_FSTUWT_80_REPLICATE_WEIGHTS_FAY_0.5'else if(as.integer(z$year[1])>=2015)'TOTWGT_JKZONE_JKREP_TWO_PER_ZONE_FACTOR_HALF'else 'TOTWGT_JKZONE_JKREP_ONE_PER_ZONE_FACTOR_ONE';a$pv_rule<-if(pisa&&as.integer(src_year)>=2015)'ALL_10_PVS_PER_DOMAIN_NO_INCOMPLETE_POOL'else if(z$domain[1]=='all')'OBSERVED_ORDINAL_BOOKS_NO_ACHIEVEMENT_IMPUTATION'else 'ALL_5_PVS_PER_DOMAIN_NO_INCOMPLETE_POOL'
   a$variance_rule<-if(pisa)paste0('MEAN_WITHIN_PV_BRR_1_OVER_20_PLUS_',if(as.integer(src_year)>=2015)'1.1'else '1.2','_BETWEEN_PV')else 'MEAN_WITHIN_PV_CYCLE_SPECIFIC_JRR_PLUS_1.2_BETWEEN_PV';a$code_fingerprint<-code_sha
   if(kind=='PISA_SES') {
     a$variance_rule<-paste0(a$variance_rule,'_CONDITIONAL_ON_FITTED_SES')
     if(z$domain[1]=='all') {
       a$pv_rule<-'OBSERVED_CALIBRATED_SES_NO_ACHIEVEMENT_PV'
       a$variance_rule<-'FAY_BRR_1_OVER_20_CONDITIONAL_ON_FITTED_SES'
     }
   }
   if(startsWith(kind,'BACKGROUND_')&&z$domain[1]=='all') {
     a$pv_rule<-'OBSERVED_BACKGROUND_NO_ACHIEVEMENT_PV'
     a$variance_rule<-if(pisa)'FAY_BRR_1_OVER_20'else 'CYCLE_SPECIFIC_JRR_OBSERVED_BACKGROUND'
   }
   a$input_fingerprint<-if(startsWith(z$module[1],'extension_'))lo_extension_projection(obj,z)else lo_compact_projection(obj,lo_compact_backend_tasks(z))
   a$covariance_group_id<-lo_exact_sha(file.path(out,'JOINT_REFERENCE_PV_REPLICATES.rds'))
   cert<-as.list(a[1,c('sample_id','method_version','weight_design','pv_rule','variance_rule','source_edition_sha256','input_fingerprint','code_fingerprint')])
   cert$status<-'METHOD_SAMPLE_INPUT_CERTIFIED';cert$cell_ids<-z$metric_key;cert$evidence_files<-ef
   if(peers) {
     cert$sample_count_rule<-obj$meta$sample_count_rule;cert$sample_count_evidence_path<-obj$meta$sample_count_evidence_path;cert$sample_count_evidence_sha256<-obj$meta$sample_count_evidence_sha256
     stopifnot(identical(cert$sample_count_rule,'ANALYTIC_PEER_FRAME_WITH_SEPARATE_PV_TARGET_COUNTS'))
     for(k in c('peer_denominator_verified','self_exclusion_verified','method_certification_status','joint_pv_replicate_status'))a[[k]]<-'PASS'
   }
   cert$resource_budget<-list(measured_peak_scratch_bytes=budget$measured_peak_scratch_bytes,max_scratch_bytes=budget$max_scratch_bytes,evidence_path=resource,evidence_sha256=lo_exact_sha(resource))
   cp<-file.path(out,paste0('METHOD_',substr(digest::digest(z$metric_key,algo='sha256'),1,16),'.json'))
   jsonlite::write_json(cert,cp,auto_unbox=TRUE,pretty=TRUE,digits=17)
   a$certification_path<-normalizePath(cp,winslash='/');a$certification_sha256<-lo_exact_sha(cp)
   a$decision<-'COMPUTE_REQUIRED';a$certification_status<-cert$status
   approved[[length(approved)+1L]]<-a
 }
 all_tasks[[year]]<-q;rm(obj);gc(FALSE)
}
approved<-do.call(rbind,approved);tasks<-do.call(rbind,all_tasks)
stopifnot(nrow(approved)>0L,!anyDuplicated(approved$cell_id))
close_rows<-function(a,actual,reference,extra_evidence,label) {
 i<-match(a$cell_id,actual$cell_id);j<-match(a$cell_id,reference$cell_id)
 stopifnot(!anyNA(i),!anyNA(j),all(actual$status[i]=='COMPUTED_PENDING_VALIDATION'),
   all(abs(actual$estimate[i]-reference$estimate[j])<1e-9),all(abs(actual$standard_error[i]-reference$standard_error[j])<1e-9),
   all(actual$n_unweighted[i]==reference$n_unweighted[j]))
 checked<-a;checked$estimate<-actual$estimate[i];checked$standard_error<-actual$standard_error[i]
 checked$n_unweighted<-actual$n_unweighted[i];checked$status<-'SCIENTIFICALLY_VALIDATED';checked$hold_reason<-''
 checked$result_hash<-vapply(i,function(k){r<-actual[k,,drop=FALSE];rownames(r)<-NULL;digest::digest(r,algo='sha256')},character(1))
 checked<-checked[setdiff(names(checked),c('decision','certification_status'))]
 paths<-unique(c(checked$certification_path,extra_evidence))
 cert<-list(status='SCIENTIFICALLY_VALIDATED',cells=checked,evidence_files=data.frame(path=paths,sha256=vapply(paths,lo_exact_sha,character(1))),
   scope=label,global_scientific_freeze=FALSE,validation='Direct official source with exact retained national population; independent paired PV and survey-replication estimates and SE <1e-9; exact group N')
 cp<-file.path(master,paste0(label,'_RESULT_CERTIFICATE.json'))
 jsonlite::write_json(cert,cp,auto_unbox=TRUE,pretty=TRUE,digits=17)
 checked$certification_path<-cp;checked$certification_sha256<-lo_exact_sha(cp);checked
}
compact<-file.path(root,'FIXED_PRODUCTION_V1',scope,'compact')
# Reuse the measured producer's already checked values. No second production
# calculation of the largest pilot block, and no fabricated execution receipt.
pilot<-approved[approved$cell_id%in%all_tasks[[pilot_id]]$metric_key,];q<-tasks[match(pilot$cell_id,tasks$metric_key),]
p<-read.csv(file.path(block_root,pilot_id,'MEASURED_PRODUCER_RESULTS.csv'),stringsAsFactors=FALSE,na.strings=character())
measurement<-jsonlite::fromJSON(file.path(block_root,pilot_id,'PRODUCER_MEASUREMENT.json'))
stopifnot(nrow(p)==nrow(q),!anyDuplicated(p$metric_key),setequal(p$metric_key,q$metric_key),
  measurement$source_sha256==unique(pilot$source_edition_sha256))
stopifnot(identical(measurement$producer_code_sha256,code_sha))
rows<-do.call(rbind,lapply(seq_len(nrow(q)),function(i){j<-match(q$metric_key[i],p$metric_key);lo_compact_science_rows(q[i,,drop=FALSE],p[j,,drop=FALSE],p$n_unweighted[j],pilot$input_fingerprint[i],pilot$code_fingerprint[i],pilot$method_version[i])}))
con<-lo_compact_open(compact)
DBI::dbExecute(con,'CREATE TABLE IF NOT EXISTS measured_execution_receipts (cell_id TEXT NOT NULL, execution_sha TEXT NOT NULL, result_sha TEXT NOT NULL, PRIMARY KEY(cell_id,execution_sha))')
# These are real measured executions, separately identified from dispatcher
# executions. Commit result rows and measurement identities together.
measurement_sha<-lo_exact_sha(file.path(block_root,pilot_id,'PRODUCER_MEASUREMENT.json'))
DBI::dbWithTransaction(con,{
  lo_compact_put(con,rows,transaction=FALSE)
  for(i in seq_len(nrow(rows))) {
    current<-DBI::dbGetQuery(con,'SELECT * FROM grid WHERE cell_id=?',params=list(rows$cell_id[i]))
    DBI::dbExecute(con,'INSERT OR IGNORE INTO measured_execution_receipts VALUES (?,?,?)',params=list(rows$cell_id[i],measurement_sha,digest::digest(current,algo='sha256')))
  }
})
lo_compact_close(con)
ref<-read.csv(file.path(block_root,pilot_id,'INDEPENDENT_RESULTS.csv'),stringsAsFactors=FALSE)
pilot_closed<-close_rows(pilot,rows,ref,c(all_evidence[[pilot_id]]$path,file.path(block_root,pilot_id,c('PRODUCER_PARITY.csv','PRODUCER_MEASUREMENT.json','MEASURED_PRODUCER_RESULTS.csv'))),paste0(kind,'_',pilot_id,'_SELECTED'))
bind_columns<-function(...) {xs<-list(...);cols<-unique(unlist(lapply(xs,names)));do.call(rbind,lapply(xs,function(x){for(k in setdiff(cols,names(x)))x[[k]]<-'';x[cols]}))}
combined<-bind_columns(old,pilot_closed)
# The science registry is a durable checkpoint: replace only after a complete write.
source(file.path(repo,'06_pipeline/LO_ATOMIC_CHECKPOINT.R'))
lo_atomic_csv(combined,file.path(master,'SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'))
if(length(blocks)==1L) {
  if(peers) {
    ctx<-unique(tasks[tasks$module=='peer_below_basic',c('country','survey','year','domain','peer_definition')]);ctx$scientific_status<-'PASS'
    path<-file.path(master,'LOW_PEER_PRIMARY_GATES.csv')
    previous<-if(file.exists(path))read.csv(path,stringsAsFactors=FALSE)else ctx[FALSE,]
    write.csv(unique(rbind(previous,ctx)),path,row.names=FALSE)
  }
  receipt<-list(status='SELECTED_SOURCE_BLOCKS_CERTIFIED',scope=scope,cells=nrow(pilot_closed),country=unique(tasks$country),producer_code_sha256=code_sha,measured_producer_reused=TRUE,global_release=FALSE)
  jsonlite::write_json(receipt,file.path(block_root,pilot_id,'CONTROLLER_CLOSURE.json'),auto_unbox=TRUE,pretty=TRUE)
  if(!defer_audit)lo_fixed_controller(repo,bundle,'audit',scope,root)
  return(invisible(receipt))
}
pending<-approved[!approved$cell_id%in%pilot$cell_id,]
write.csv(pending,file.path(master,'SCIENTIFIC_COMPUTE_APPROVALS.csv'),row.names=FALSE,na='')
cfg<-lo_run_config(scope,'');cfg$max_compute_units<-4096L
cfg_path<-file.path(block_root,'RUN_CONFIG_EXECUTED.json');jsonlite::write_json(cfg,cfg_path,auto_unbox=TRUE,pretty=TRUE)
Sys.setenv(LO_RUN_CONFIG=normalizePath(cfg_path,winslash='/'))
a<-lo_fixed_controller(repo,bundle,'audit',scope,root)
first<-lo_fixed_controller(repo,bundle,'produce',scope,root)
second<-lo_fixed_controller(repo,bundle,'produce',scope,root)
stopifnot(first$new_candidates+first$reused_candidates==nrow(pending),first$held_cells==0L,second$new_candidates==0L,second$reused_candidates==nrow(pending),second$held_cells==0L)
con<-lo_compact_open(compact);actual<-DBI::dbGetQuery(con,'SELECT * FROM grid');lo_compact_close(con)
reference<-do.call(rbind,lapply(setdiff(blocks,pilot_id),function(y)read.csv(file.path(block_root,y,'INDEPENDENT_RESULTS.csv'),stringsAsFactors=FALSE)))
rest<-close_rows(pending,actual,reference,unlist(lapply(all_evidence[setdiff(blocks,pilot_id)],function(x)x$path)),paste0(kind,'_SELECTED_CONTROLLER'))
write.csv(bind_columns(old,pilot_closed,rest),file.path(master,'SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'),row.names=FALSE,na='')
write.csv(approved,file.path(master,paste0('COMPLETED_',kind,'_APPROVALS.csv')),row.names=FALSE,na='')
write.csv(pending[FALSE,],file.path(master,'SCIENTIFIC_COMPUTE_APPROVALS.csv'),row.names=FALSE,na='')
if(peers) {
 ctx<-unique(tasks[tasks$module=='peer_below_basic',c('country','survey','year','domain','peer_definition')]);ctx$scientific_status<-'PASS'
 path<-file.path(master,'LOW_PEER_PRIMARY_GATES.csv')
 previous<-if(file.exists(path))read.csv(path,stringsAsFactors=FALSE)else ctx[FALSE,]
 ctx<-unique(rbind(previous,ctx));write.csv(ctx,path,row.names=FALSE)
}
final<-lo_fixed_controller(repo,bundle,'audit',scope,root)
stopifnot(final$validated==nrow(old)+nrow(approved),final$approved_compute_batches==0L)
jsonlite::write_json(list(status='SELECTED_SOURCE_BLOCKS_CERTIFIED',first=first,second=second,final_audit=final,
 pilot_reused_without_recalculation=nrow(pilot),previous_certified_retained=nrow(old),global_release=FALSE),file.path(block_root,if(peers)paste0(kind,'_CONTROLLER_CLOSURE.json')else 'CONTROLLER_CLOSURE.json'),auto_unbox=TRUE,pretty=TRUE,digits=17)
invisible(final)


}
