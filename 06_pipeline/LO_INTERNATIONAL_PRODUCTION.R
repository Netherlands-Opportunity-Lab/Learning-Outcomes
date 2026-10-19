# Production-stage preparation/certification inside the existing fixed pipeline.
# All statistics use the existing exact producers. Reference implementations
# remain separate; each successful source/family block is a durable checkpoint.
lo_international_measure <- function(repo,bundle,obj,q,out) {
  for(f in c('LO_EXACT_BOOT.R','LO_EXACT_ESTIMATORS.R','LO_EXACT_DISPATCH.R','LO_COMPACT_RECOMPUTE.R','LO_APPROVED_EXTENSIONS.R','LO_SOURCE_REPAIR.R','LO_GENDER_POOL_POLICY.R'))source(file.path(repo,'06_pipeline',f))
  for(f in c('LO04_COMMON.R','LO04_CACHE.R'))source(file.path(bundle,'code',f))
  for(f in c('REPAIRS.R','EXTENSIONS.R'))source(file.path(bundle,'engine',f))
  lo_exact_boot(bundle)
  code<-lo_exact_code_sha(repo,bundle);src<-jsonlite::fromJSON(file.path(out,'SOURCE_VERIFICATION.json'))
  source(file.path(repo,'06_pipeline/LO_PRODUCTION_SPACE.R'))
  if(lo_production_free_bytes(out)<3*1024^3)stop('INTERNATIONAL_BEFORE_COMPUTE_SPACE_RESERVE')
  size<-function(p){f<-list.files(p,recursive=TRUE,full.names=TRUE);sum(file.info(f)$size,na.rm=TRUE)}
  peak<-size(out)+size(tempdir());start<-proc.time()[3];new<-reused<-0L
  groups<-split(seq_len(nrow(q)),paste(q$module,q$domain,q$definition,q$peer_definition,q$threshold,sep='|'))
  answers<-lapply(groups,function(ix) {
    s<-q[ix,];key<-digest::digest(list(tasks=s,source=src$canonical_sha256,code=code),algo='sha256')
    checkpoint<-file.path(out,paste0('PRODUCER_BLOCK_',key,'.rds'))
    if(file.exists(checkpoint)) {
      saved<-readRDS(checkpoint)
      if(saved$key!=key||saved$result_sha256!=digest::digest(saved$result,algo='sha256'))stop('INTERNATIONAL_PRODUCER_CHECKPOINT_CHANGED')
      reused<<-reused+nrow(s);return(saved$result)
    }
    module<-s$module[1];science<-lo_compact_backend_tasks(s)
    a<-if(module=='peer_below_basic')lo_compact_low_peer(obj,s)else
      if(startsWith(module,'extension_')||module%in%c('core','ses_national','ses_harmonized','gender'))lo_exact_selected_estimate(obj,science)else
      if(module%in%c('migration','migration_generation','language_exact','language_frequency_binary',
        'migration_binary_peer','home_language_peer_exposure','home_language_frequency_peer'))lo_exact_background_linear(obj,science)else
      if(module=='migration_peer_exposure')lo_compact_migration_peers(obj,s)else
      if(module=='ses_peer_exposure'||(module=='peer_baseline'&&all(science$stat%in%c('q1_share','q4_share'))))lo_exact_ses_composition(obj,science)else v10_compute(obj,science)
    a$n_unweighted<-if(startsWith(module,'extension_'))lo_extension_count_n(obj,science)else lo_compact_count_n(obj,science)
    a<-a[c('metric_key','estimate','se','n_unweighted')]
    stopifnot(setequal(a$metric_key,s$metric_key),all(is.finite(a$estimate)),all(is.finite(a$se)),all(a$se>=0),all(a$n_unweighted>0))
    envelope<-list(key=key,result=a,result_sha256=digest::digest(a,algo='sha256'))
    tmp<-tempfile('producer_',tmpdir=out);saveRDS(envelope,tmp,compress=FALSE)
    if(!file.rename(tmp,checkpoint))stop('INTERNATIONAL_PRODUCER_ATOMIC_COMMIT_FAILED')
    new<<-new+nrow(s);peak<<-max(peak,size(out)+size(tempdir()));a
  })
  actual<-do.call(rbind,answers);ref<-read.csv(file.path(out,'INDEPENDENT_RESULTS.csv'))
  i<-match(actual$metric_key,ref$cell_id)
  proof<-data.frame(cell_id=actual$metric_key,estimate_diff=abs(actual$estimate-ref$estimate[i]),se_diff=abs(actual$se-ref$standard_error[i]),n_equal=actual$n_unweighted==ref$n_unweighted[i])
  write.csv(proof,file.path(out,'PRODUCER_PARITY.csv'),row.names=FALSE)
  stopifnot(!anyNA(i),all(proof$estimate_diff<1e-9),all(proof$se_diff<1e-9),all(proof$n_equal))
  write.csv(actual,file.path(out,'MEASURED_PRODUCER_RESULTS.csv'),row.names=FALSE)
  measurement<-list(status='EXACT_SELECTED_PRODUCER_PARITY_PASS',n=nrow(obj$data),cells=nrow(q),seconds=unname(proc.time()[3]-start),
    source_sha256=src$canonical_sha256,producer_code_sha256=code,new_cells=new,reused_cells=reused,
    max_estimate_difference=max(proof$estimate_diff),max_se_difference=max(proof$se_diff))
  jsonlite::write_json(measurement,file.path(out,'PRODUCER_MEASUREMENT.json'),pretty=TRUE,auto_unbox=TRUE,digits=17)
  # These audited estimators operate in memory. Checkpoint files are monotonic;
  # measure their volume after each exact group plus the R temporary directory.
  # This is a file-space bound, not an operating-system RAM quota.
  budget<-list(status='MEASURED',max_n=nrow(obj$data),measured_peak_scratch_bytes=peak,
    max_scratch_bytes=max(2*peak,128*1024^2),measurement='Temporary directory and monotonic checkpoint footprint sampled after every exact in-memory estimator group',
    producer_code_sha256=code)
  jsonlite::write_json(budget,file.path(out,'RESOURCE_BUDGET.json'),pretty=TRUE,auto_unbox=TRUE,digits=17)
  invisible(measurement)
}

lo_international_produce <- function(repo,bundle,root,scope='all_required',countries=NULL,context_ids=NULL,families_keep=NULL) {
  for(f in c('LO_ATOMIC_CHECKPOINT.R','LO_COUNTRY_REGISTRY.R','LO_COUNTRY_TASKS.R','LO_BALANCED_MEMBERSHIP.R','LO_GENDER_POOL_POLICY.R','LO_REMOTE_CHECKPOINT.R',
    'MASTER_ESTIMATION_GRID.R','LO_SCOPE_DECISIONS.R','LO_APPROVED_EXTENSIONS.R','LO_CERTIFY_SOURCE_BLOCKS.R',
    'LO_IEA_SOURCE_BLOCK.R','LO_IEA_BACKGROUND.R','LO_PISA_SOURCE_BLOCK.R','LO_PISA_LEGACY_SOURCE.R','LO_PEER_REFERENCE.R',
    'LO_INTERNATIONAL_BACKGROUND.R','LO_BACKGROUND_REFERENCE.R','LO_SES_REFERENCE.R','LO_RUN_CONFIG.R','LO_ESTIMATION_AVAILABILITY.R','LO_PISA_PROGRAM_IDENTITY.R'))source(file.path(repo,'06_pipeline',f))
  master<-file.path(root,'master_reconciliation');international<-file.path(root,'international')
  manifest<-read.csv(file.path(international,'SOURCE_RUN_MANIFEST.csv'),colClasses='character',na.strings=character())
  support<-lo_read_source_support(file.path(master,'SOURCE_SUPPORT_CONTRACTS.csv'),repo=repo)
  base<-read.csv(file.path(bundle,'engine/TASKS.csv'),colClasses='character',na.strings=character())
  info<-lo_runtime_scope(bundle,base,scope,support);lo_country_production_approval(repo,info$selected,info$dashboard)
  t<-lo_country_base_tasks(base,info);dec<-lo_read_scope_decisions(repo)
  t<-lo_scope_active_tasks(rbind(t,lo_extension_tasks(t,dec),lo_scoped_low_peer_tasks(t,dec)),dec)
  t<-lo_gender_pool_tasks(t,support)
  cfg<-lo_run_config(scope);t<-lo_run_select(t,cfg)
  if(!is.null(countries))t<-t[t$country%in%countries,]
  # NLD is already certified in the shared registry; source-specific unresolved
  # cells remain governed by its explicit source-unavailability evidence.
  t<-t[t$country!='NLD'|lo_gender_pooled(t),]
  # Back up prior sealed results before any new calculations; retry pending
  # transfers on resume without recomputing their scientific blocks.
  lo_remote_checkpoint(repo,root)
  remote_checkpoint<-lo_remote_checkpoint_batch(repo,root,cfg$checkpoint)
  source(file.path(repo,'06_pipeline/LO_INTERNATIONAL_WORKLIST.R'))
  audited_path<-file.path(root,'FIXED_PRODUCTION_V1',scope,'PRIVATE_MASTER_GRID.csv')
  if(!file.exists(audited_path))stop('INTERNATIONAL_WORKLIST_AUDIT_REQUIRED')
  audited<-read.csv(audited_path,colClasses='character',na.strings=character())
  worklist<-lo_international_worklist(t,audited)
  approval_guard<-lo_international_certification_guard(repo,root,scope,worklist)
  t<-worklist$tasks
  # Audit has already verified these exact certificates and input identities.
  # Avoid source loading and SES preparation when all selected cells are done.
  t<-t[!t$metric_key%in%audited$cell_id[audited$status=='SCIENTIFICALLY_VALIDATED'],,drop=FALSE]
  if(!nrow(t))return(invisible(list(certified_new=0L,repairs=list())))
  partitions<-list();indices<-list()
  for(f in list.files(file.path(international,'raw_partitions'),pattern='_PARTITIONS.json$',full.names=TRUE)) {
    x<-jsonlite::fromJSON(f);partitions[[x$raw_path]]<-x
  }
  for(f in list.files(international,pattern='_BYTE_INDEX.json$',full.names=TRUE)) {
    x<-jsonlite::fromJSON(f);indices[[x$raw_path]]<-x
  }
  previous<-options(lo.pisa.partitions=partitions,lo.pisa.byte_indices=indices);on.exit(options(previous),add=TRUE)
  home<-read.csv(file.path(international,'HOME_SOURCE_MANIFEST.csv'),colClasses='character',na.strings=character())
  ses<-NULL
  if(is.null(families_keep)||'PISA_SES'%in%families_keep) {
    source(file.path(repo,'06_pipeline/LO_INTERNATIONAL_SES.R'))
    author<-Sys.getenv('LO_COBREROS_ROOT','');if(!nzchar(author))stop('LO_COBREROS_ROOT_REQUIRED')
    ses<-lo_prepare_international_ses(repo,author,root,partitions,info$selected)
  }
  contexts<-unique(t[c('country','survey','year')]);failures<-list();completed<-0L;units<-0L
  repairs_path<-file.path(international,'PRODUCTION_REPAIRS_REQUIRED.csv')
  if(file.exists(repairs_path)) {
    history<-file.path(international,'repair_history');dir.create(history,showWarnings=FALSE)
    previous<-file.path(history,paste0(digest::digest(file=repairs_path,algo='sha256'),'.csv'))
    if(!file.exists(previous))stopifnot(file.copy(repairs_path,previous))
  }
  # This is the error log of this attempt. Historical errors remain immutable;
  # absence of a current error never counts as a completed scientific cell.
  lo_atomic_csv(data.frame(country=character(),survey=character(),year=integer(),family=character(),reason=character()),repairs_path)
  if(!is.null(context_ids))contexts<-contexts[paste(contexts$country,contexts$survey,contexts$year,sep='_')%in%context_ids,]
  for(i in seq_len(nrow(contexts))) {
    ctx<-contexts[i,];country<-ctx$country;s<-ctx$survey;y<-as.integer(ctx$year);id<-paste(country,s,y,sep='_')
    if(i>1L&&country!=contexts$country[i-1L])remote_checkpoint(force=TRUE)
    remote_checkpoint(changed=TRUE)
    q0<-t[t$country==country&t$survey==s&as.integer(t$year)==y,]
    review<-lo_population_review(repo);restricted<-lo_population_review_rows(q0,review)
    if(any(!is.na(restricted))) {
      policy<-file.path(repo,'06_pipeline/review_20261013/POPULATION_CORRECTIONS.json')
      frozen_policy<-file.path(international,'absence',paste0('POLICY_',digest::digest(file=policy,algo='sha256'),'.json'))
      dir.create(dirname(frozen_policy),recursive=TRUE,showWarnings=FALSE)
      if(!file.exists(frozen_policy))stopifnot(file.copy(policy,frozen_policy))
      for(k in unique(restricted[!is.na(restricted)])) {
        selected<-!is.na(restricted)&restricted==k
        lo_international_absence(repo,root,q0[selected,],
          paste('OFFICIAL_TREND_COMPARABILITY_QUALIFICATION',review$review_id[k],review$actual_population[k],sep=': '),
          frozen_policy)
      }
      q0<-q0[is.na(restricted),,drop=FALSE]
      if(!nrow(q0))next
    }
    parent<-file.path(international,'sources',id)
    if(country=='NLD') {
      origin<-unique(support$source_path[support$country==country&support$survey==s&as.integer(support$year)==y])
      if(length(origin)!=1L)stop('NLD_SOURCE_IDENTITY_AMBIGUOUS')
      parent<-dirname(origin)
    }
    srcfile<-file.path(parent,'SOURCE_VERIFICATION.json')
    if(!file.exists(srcfile))stop('INTERNATIONAL_SOURCE_CHECKPOINT_MISSING: ',id)
    src<-jsonlite::fromJSON(srcfile);canonical<-file.path(parent,src$canonical_filename)
    stopifnot(digest::digest(file=canonical,algo='sha256')==src$canonical_sha256)
    obj<-readRDS(canonical)
    if(s=='PISA') {
      unavailable_class<-q0$module%in%c('extension_performance_class','extension_ses_class')
      if(any(unavailable_class))lo_international_absence(repo,root,q0[unavailable_class,],'PISA public-use sample has no comparable sampled actual-class identifier; school programme is not an actual classroom',srcfile)
    }
    r<-manifest[manifest$country==country&manifest$survey==s&as.integer(manifest$year)==y,];stopifnot(nrow(r)==1L)
    families<-if(s=='PISA')c('PISA_CORE','BACKGROUND_PISA','PEERS_PISA',if(y>=2015)'PISA_SES')else c('IEA','IEA_BOOKS','BACKGROUND_IEA','PEERS_IEA')
    if(!is.null(families_keep))families<-intersect(families,families_keep)
    raw<-NULL
    if(any(lo_gender_pooled(q0))) {
      reg<-partitions[[r$raw_path]]
      if(is.null(reg))stop('GENDER_POOL_VERIFIED_PARTITION_REQUIRED')
      raw<-lo_pisa_country_rows(r$raw_path,r$source_country,reg$fields)
    }
    source(file.path(repo,'06_pipeline/LO_CERTIFY_BASELINES.R'))
    lo_certify_population_baselines(repo,root,scope,q0)
    for(family in families)tryCatch((function() {
      if(units>=cfg$max_compute_units)return(invisible(NULL))
      modules<-switch(family,PISA_CORE=c('core','gender','language_exact','migration_generation','extension_performance_school'),
        IEA=c('core','gender','extension_performance_school','extension_performance_class'),
        IEA_BOOKS=c('ses_national','extension_ses_gender','extension_ses_school','extension_ses_class'),
        PISA_SES=c('ses_harmonized','extension_ses_gender','extension_ses_school','ses_peer_exposure','peer_baseline'),
        BACKGROUND_PISA=c('migration','migration_binary_peer','migration_peer_exposure','home_language_peer_exposure','peer_baseline'),
        BACKGROUND_IEA=c('migration','migration_generation','migration_binary_peer','migration_peer_exposure','language_frequency_binary','home_language_frequency_peer','ses_peer_exposure','peer_baseline','extension_home_ses'),
        c('peer_below_basic','high_proficiency_peer_exposure'))
      old<-read.csv(file.path(master,'SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'),colClasses='character',na.strings=character())
      q<-q0[q0$module%in%modules&!q0$metric_key%in%old$cell_id,];if(!nrow(q))return(invisible(NULL))
      if(family=='BACKGROUND_PISA')q<-q[q$definition!='Cobreros_fourwave_13item_trend_comparable',]
      if(family=='PISA_SES')q<-q[q$definition=='Cobreros_fourwave_13item_trend_comparable',]
      missing_domain<-rep(FALSE,nrow(q))
      for(domain in intersect(c('reading','mathematics','science'),unique(q$domain))) {
        code<-switch(domain,reading='READ',mathematics='MATH',science='SCIE')
        if(!paste0('PV_',code,'_1')%in%names(obj$data))missing_domain<-missing_domain|q$domain==domain
      }
      if(any(missing_domain))lo_international_absence(repo,root,q[missing_domain,],'Domain absent or officially invalid in this source edition',srcfile)
      q<-q[!missing_domain,]
      # Missing labels cannot be reconstructed from a pooled Female/Other code.
      if(s=='PISA') {
        pool_available<-any(lo_gender_pooled(q))
        has_girl<-any(obj$data$DEMO_GENDER=='girl',na.rm=TRUE);has_boy<-any(obj$data$DEMO_GENDER=='boy',na.rm=TRUE)
        missing_sex<-(q$module=='gender'&((!has_girl&q$group%in%c('girl','girls_minus_boys'))|(!has_boy&q$group%in%c('boy','girls_minus_boys'))))|
          (q$module=='extension_ses_gender'&((!has_girl&grepl('_girl$',q$group))|(!has_boy&grepl('_boy$',q$group))))
        missing_sex<-missing_sex & !lo_gender_pooled(q)
        if(any(missing_sex))lo_international_absence(repo,root,q[missing_sex,],'No separately identifiable requested gender in verified source; pooled Female/Other is not Female',srcfile,'SOURCE_MAPPING_REVIEW_REQUIRED')
        q<-q[!missing_sex,]
      }
      if(!nrow(q))return(invisible(NULL))
      group_id<-paste(q$module,q$domain,q$definition,q$peer_definition,q$threshold,sep='|')
      take<-head(unique(group_id),cfg$max_compute_units-units);q<-q[group_id%in%take,]
      outroot<-file.path(international,'blocks',family);out<-file.path(outroot,id);dir.create(out,recursive=TRUE,showWarnings=FALSE)
      science_obj<-lo_gender_pool_object(obj,raw,q);peers<-startsWith(family,'PEERS_')
      if(s=='PISA') {
        program_review<-lo_pisa_program_review(repo,r,science_obj$data$PROGRAM)
        science_obj$data$PROGRAM<-program_review$values
        science_obj$meta$program_identity_evidence<-program_review[setdiff(names(program_review),'values')]
        if(!any(!is.na(science_obj$data$PROGRAM)&nzchar(science_obj$data$PROGRAM))) {
          no_program<-q$peer_definition=='direct_learning_environment'
          if(any(no_program))lo_international_absence(repo,root,q[no_program,],'No valid national programme identifier for the selected school-programme peer environment',srcfile)
          q<-q[!no_program,]
        }
      }
      if(startsWith(family,'BACKGROUND_')) {
        h<-home[home$country==country&home$survey==s&home$year==y,]
        hp<-if(nrow(h)==1L)h$path else ''
        if(nzchar(hp))stopifnot(digest::digest(file=hp,algo='sha256')==h$sha256)
        bg<-lo_international_background(repo,science_obj,q,r,out,hp);science_obj<-bg$object;q<-bg$tasks
        if(!is.null(bg$absent))for(reason in unique(bg$absent$absence_reason))lo_international_absence(repo,root,bg$absent[bg$absent$absence_reason==reason,],reason,c(srcfile,bg$proof))
      }
      if(family=='PISA_SES') {
        sx<-ses$files[ses$files$country==country&ses$files$year==y,];stopifnot(nrow(sx)==1L,digest::digest(file=sx$path,algo='sha256')==sx$sha256)
        scores<-readRDS(sx$path);ids<-as.character(scores$cntstuid)
        stopifnot(!anyDuplicated(ids),setequal(ids,science_obj$data$SOURCE_STUDENT_ID))
        science_obj$data<-science_obj$data[match(ids,science_obj$data$SOURCE_STUDENT_ID),];rownames(science_obj$data)<-NULL
        stopifnot(identical(as.numeric(science_obj$data$W),as.numeric(scores$w_fstuwt)))
        science_obj$data$SES<-scores$SES;science_obj$meta$ses_construct_id<-'Cobreros_fourwave_13item_trend_comparable'
        science_obj$meta$ses_quartile_protocol<-'INNOVAMAT_R_REPLICATE_SEED7_SOURCE_ORDER'
        science_obj$meta$calibration_evidence_path<-ses$certificate_path;science_obj$meta$calibration_sha256<-digest::digest(file=ses$certificate_path,algo='sha256')
      }
      if(!nrow(q))return(invisible(NULL))
      # One undefined subgroup must not discard valid siblings. Preserve exact
      # unavailable targets with source/code/denominator proof before computing.
      evidence<-c(srcfile,file.path(parent,src$canonical_filename))
      if(startsWith(family,'BACKGROUND_'))evidence<-c(evidence,bg$proof)
      if(family=='PISA_SES')evidence<-c(evidence,sx$path,ses$certificate_path)
      q<-lo_record_estimation_availability(repo,root,science_obj,q,evidence)
      if(!nrow(q)){remote_checkpoint(changed=TRUE);return(invisible(NULL))}
      verifier_files<-c('LO_INTERNATIONAL_PRODUCTION.R','LO_IEA_SOURCE_BLOCK.R','LO_IEA_BACKGROUND.R','LO_PISA_SOURCE_BLOCK.R','LO_PEER_REFERENCE.R','LO_INTERNATIONAL_BACKGROUND.R','LO_BACKGROUND_REFERENCE.R','LO_SES_REFERENCE.R','LO_INTERNATIONAL_SES.R','LO_GENDER_POOL_POLICY.R','LO_ESTIMATION_AVAILABILITY.R','LO_PISA_PROGRAM_IDENTITY.R')
      key<-digest::digest(list(q=q,parent=src$canonical_sha256,object=digest::digest(science_obj,algo='sha256'),reference=vapply(file.path(repo,'06_pipeline',verifier_files),function(p)digest::digest(file=p,algo='sha256'),character(1))),algo='sha256')
      block_id<-paste0(id,'_',substr(key,1,16));out<-file.path(outroot,block_id);dir.create(out,recursive=TRUE,showWarnings=FALSE)
      if(startsWith(family,'BACKGROUND_'))file.copy(bg$proof,file.path(out,basename(bg$proof)),overwrite=FALSE)
      seal<-file.path(out,'REFERENCE_HASH_MANIFEST.json')
      if(file.exists(seal)) {
        saved<-jsonlite::fromJSON(seal)
        if(saved$key!=key||any(vapply(saved$files$path,function(p)digest::digest(file=file.path(out,p),algo='sha256'),character(1))!=saved$files$sha256))stop('INTERNATIONAL_REFERENCE_CHECKPOINT_CHANGED')
        current<-jsonlite::fromJSON(file.path(out,'SOURCE_VERIFICATION.json'))
        science_obj<-readRDS(file.path(out,current$canonical_filename))
      }else {
        cat('INTERNATIONAL_REFERENCE',id,family,nrow(q),'\n');flush.console()
        if(peers) {
          a<-lo_peer_independent_reference(science_obj,q)
          count_path<-file.path(out,'PV_TARGET_SAMPLE_COUNTS.csv');write.csv(a$counts,count_path,row.names=FALSE)
          science_obj$meta$sample_count_rule<-'ANALYTIC_PEER_FRAME_WITH_SEPARATE_PV_TARGET_COUNTS'
          science_obj$meta$sample_count_evidence_path<-normalizePath(count_path,winslash='/')
          science_obj$meta$sample_count_evidence_sha256<-digest::digest(file=count_path,algo='sha256')
          science_obj$meta$verified_parent_canonical_sha256<-src$canonical_sha256
        }else if(startsWith(family,'BACKGROUND_'))a<-lo_background_reference(science_obj,q)
        else if(family=='PISA_SES')a<-lo_pisa_ses_reference(science_obj,q)
        else {
          if(is.null(raw)) {
            if(s!='PISA')raw<<-haven::read_sav(r$raw_path)else if(y>=2015) {
              reg<-partitions[[r$raw_path]];raw<<-lo_pisa_country_rows(r$raw_path,r$source_country,reg$fields)
            }else raw<<-lo_pisa_prepare_legacy(r$raw_path,r$control_path,y,r$source_country,file.path(parent,'reference_raw'))$raw
          }
          a<-if(s=='PISA')lo_pisa_independent_selected(raw,q)else if(family=='IEA_BOOKS')lo_iea_independent_books(raw,q)else lo_iea_independent_selected(raw,q)
        }
        output<-file.path(out,paste0('canonical_',id,'_',substr(digest::digest(science_obj,algo='sha256'),1,16),'.rds'))
        if(!file.exists(output))saveRDS(science_obj,output,compress='gzip')
        current<-src
        if(any(lo_gender_pooled(q))) {
          current$gender_policy<-science_obj$meta$gender_policy
          current$gender_definition<-science_obj$meta$gender_definition
          current$gender_label_nl<-science_obj$meta$gender_label_nl
          current$gender_counts<-science_obj$meta$gender_counts
        }
        current$canonical_filename<-basename(output);current$canonical_sha256<-digest::digest(file=output,algo='sha256')
        jsonlite::write_json(current,file.path(out,'SOURCE_VERIFICATION.json'),pretty=TRUE,auto_unbox=TRUE,digits=17)
        file.copy(srcfile,file.path(out,'PARENT_SOURCE_VERIFICATION.json'),overwrite=TRUE)
        write.csv(q,file.path(out,'EXACT_SELECTED_TASKS.csv'),row.names=FALSE,na='')
        write.csv(a$results,file.path(out,'INDEPENDENT_RESULTS.csv'),row.names=FALSE)
        saveRDS(a$joint,file.path(out,'JOINT_REFERENCE_PV_REPLICATES.rds'),compress='gzip')
        for(f in verifier_files) {
          p<-file.path(repo,'06_pipeline',f);file.copy(p,file.path(out,paste0('VERIFIER_',substr(digest::digest(file=p,algo='sha256'),1,16),'.R')),overwrite=TRUE)
        }
        files<-list.files(out,full.names=TRUE)
        jsonlite::write_json(list(key=key,files=data.frame(path=basename(files),sha256=vapply(files,function(p)digest::digest(file=p,algo='sha256'),character(1)))),seal,pretty=TRUE,auto_unbox=TRUE)
      }
      cat('INTERNATIONAL_PRODUCER',id,family,nrow(q),'\n');flush.console()
      lo_international_measure(repo,bundle,science_obj,q,out)
      kind<-if(family=='PISA_CORE')if(y>=2015)'PISA_MODERN'else'PISA_LEGACY'else family
      lo_certify_verified_source_blocks(repo,bundle,root,outroot,block_id,block_id,kind,scope=scope,defer_audit=TRUE,verified_support=support,approval_guard=approval_guard)
      units<<-units+length(unique(paste(q$module,q$domain,q$definition,q$peer_definition,q$threshold,sep='|')))
      completed<<-completed+nrow(q);cat('INTERNATIONAL_CERTIFIED',id,family,nrow(q),'total_new',completed,'\n');flush.console()
      if(family%in%c('IEA','PISA_CORE'))lo_certify_population_baselines(repo,root,scope,q0)
      remote_checkpoint(new_cells=nrow(q),changed=TRUE)
    })(),error=function(e) {
      if(grepl('REMOTE_CHECKPOINT|PRIVATE_DRIVE_SYNC_PENDING',conditionMessage(e)))stop(e)
      failures[[length(failures)+1L]]<<-data.frame(country=country,survey=s,year=y,family=family,reason=conditionMessage(e))
      lo_atomic_csv(do.call(rbind,failures),file.path(international,'PRODUCTION_REPAIRS_REQUIRED.csv'))
      cat('INTERNATIONAL_REPAIR_REQUIRED',id,family,conditionMessage(e),'\n');flush.console()
      remote_checkpoint(force=TRUE)
    })
    rm(obj,raw);gc(FALSE)
  }
  remote_checkpoint(force=TRUE)
  invisible(list(certified_new=completed,repairs=failures))
}
