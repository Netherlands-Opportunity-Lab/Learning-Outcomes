# Production-stage preparation/certification inside the existing fixed pipeline.
# All statistics use the existing exact producers. Reference implementations
# remain separate; each successful source/family block is a durable checkpoint.
lo_international_measure <- function(repo,bundle,obj,q,out) {
  for(f in c('LO_EXACT_BOOT.R','LO_EXACT_ESTIMATORS.R','LO_EXACT_DISPATCH.R','LO_COMPACT_RECOMPUTE.R','LO_APPROVED_EXTENSIONS.R','LO_SOURCE_REPAIR.R'))source(file.path(repo,'06_pipeline',f))
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
      if(module=='migration_generation')lo_exact_generations(obj,s)else
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
  for(f in c('LO_ATOMIC_CHECKPOINT.R','LO_COUNTRY_REGISTRY.R','LO_COUNTRY_TASKS.R','LO_BALANCED_MEMBERSHIP.R',
    'MASTER_ESTIMATION_GRID.R','LO_SCOPE_DECISIONS.R','LO_APPROVED_EXTENSIONS.R','LO_CERTIFY_SOURCE_BLOCKS.R',
    'LO_IEA_SOURCE_BLOCK.R','LO_IEA_BACKGROUND.R','LO_PISA_SOURCE_BLOCK.R','LO_PISA_LEGACY_SOURCE.R','LO_PEER_REFERENCE.R'))source(file.path(repo,'06_pipeline',f))
  master<-file.path(root,'master_reconciliation');international<-file.path(root,'international')
  manifest<-read.csv(file.path(international,'SOURCE_RUN_MANIFEST.csv'),colClasses='character',na.strings=character())
  support<-lo_read_source_support(file.path(master,'SOURCE_SUPPORT_CONTRACTS.csv'))
  base<-read.csv(file.path(bundle,'engine/TASKS.csv'),colClasses='character',na.strings=character())
  info<-lo_runtime_scope(bundle,base,scope,support);lo_country_production_approval(repo,info$selected,info$dashboard)
  t<-lo_country_base_tasks(base,info);dec<-lo_read_scope_decisions(repo)
  t<-lo_scope_active_tasks(rbind(t,lo_extension_tasks(t,dec),lo_scoped_low_peer_tasks(t,dec)),dec)
  if(!is.null(countries))t<-t[t$country%in%countries,]
  # NLD is already certified in the shared registry; source-specific unresolved
  # cells remain governed by its explicit source-unavailability evidence.
  t<-t[t$country!='NLD',]
  partitions<-list();indices<-list()
  for(f in list.files(file.path(international,'raw_partitions'),pattern='_PARTITIONS.json$',full.names=TRUE)) {
    x<-jsonlite::fromJSON(f);partitions[[x$raw_path]]<-x
  }
  for(f in list.files(international,pattern='_BYTE_INDEX.json$',full.names=TRUE)) {
    x<-jsonlite::fromJSON(f);indices[[x$raw_path]]<-x
  }
  previous<-options(lo.pisa.partitions=partitions,lo.pisa.byte_indices=indices);on.exit(options(previous),add=TRUE)
  contexts<-unique(t[c('country','survey','year')]);failures<-list();completed<-0L
  if(!is.null(context_ids))contexts<-contexts[paste(contexts$country,contexts$survey,contexts$year,sep='_')%in%context_ids,]
  for(i in seq_len(nrow(contexts))) {
    ctx<-contexts[i,];country<-ctx$country;s<-ctx$survey;y<-as.integer(ctx$year);id<-paste(country,s,y,sep='_')
    parent<-file.path(international,'sources',id);srcfile<-file.path(parent,'SOURCE_VERIFICATION.json')
    if(!file.exists(srcfile))stop('INTERNATIONAL_SOURCE_CHECKPOINT_MISSING: ',id)
    src<-jsonlite::fromJSON(srcfile);canonical<-file.path(parent,src$canonical_filename)
    stopifnot(digest::digest(file=canonical,algo='sha256')==src$canonical_sha256)
    obj<-readRDS(canonical);q0<-t[t$country==country&t$survey==s&as.integer(t$year)==y,]
    r<-manifest[manifest$country==country&manifest$survey==s&as.integer(manifest$year)==y,];stopifnot(nrow(r)==1L)
    families<-if(s=='PISA')c('PISA_CORE','PEERS_PISA')else c('IEA','IEA_BOOKS','PEERS_IEA')
    if(!is.null(families_keep))families<-intersect(families,families_keep)
    raw<-NULL
    for(family in families)tryCatch((function() {
      modules<-switch(family,PISA_CORE=c('core','gender','language_exact','migration_generation','extension_performance_school'),
        IEA=c('core','gender','extension_performance_school','extension_performance_class'),
        IEA_BOOKS=c('ses_national','extension_ses_gender','extension_ses_school','extension_ses_class'),
        c('peer_below_basic','high_proficiency_peer_exposure'))
      old<-read.csv(file.path(master,'SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'),colClasses='character',na.strings=character())
      q<-q0[q0$module%in%modules&!q0$metric_key%in%old$cell_id,];if(!nrow(q))return(invisible(NULL))
      # Missing labels cannot be reconstructed from a pooled Female/Other code.
      if(s=='PISA') {
        has_girl<-any(obj$data$DEMO_GENDER=='girl',na.rm=TRUE);has_boy<-any(obj$data$DEMO_GENDER=='boy',na.rm=TRUE)
        q<-q[!(q$module=='gender'&((!has_girl&q$group%in%c('girl','girls_minus_boys'))|(!has_boy&q$group%in%c('boy','girls_minus_boys')))),]
      }
      if(!nrow(q))return(invisible(NULL))
      outroot<-file.path(international,'blocks',family);out<-file.path(outroot,id);dir.create(out,recursive=TRUE,showWarnings=FALSE)
      science_obj<-obj;peers<-startsWith(family,'PEERS_')
      if(peers&&s=='PISA') {
        numeric_country<-unique(manifest$source_country[manifest$country==country&manifest$survey!='PISA'])
        numeric_country<-numeric_country[!numeric_country%in%'5784'];stopifnot(length(numeric_country)==1L)
        program<-as.character(science_obj$data$PROGRAM)
        science_obj$data$PROGRAM[!is.na(program)&!grepl(paste0('^0*',as.integer(numeric_country),'[0-9]+$'),program)]<-NA
      }
      key<-digest::digest(list(q=q,parent=src$canonical_sha256,reference=vapply(file.path(repo,'06_pipeline',c('LO_INTERNATIONAL_PRODUCTION.R','LO_IEA_SOURCE_BLOCK.R','LO_IEA_BACKGROUND.R','LO_PISA_SOURCE_BLOCK.R','LO_PEER_REFERENCE.R')),function(p)digest::digest(file=p,algo='sha256'),character(1))),algo='sha256')
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
        }else {
          if(is.null(raw)) {
            if(s!='PISA')raw<<-haven::read_sav(r$raw_path)else if(y>=2015) {
              reg<-partitions[[r$raw_path]];raw<<-lo_pisa_country_rows(r$raw_path,r$source_country,reg$fields)
            }else raw<<-lo_pisa_prepare_legacy(r$raw_path,r$control_path,y,r$source_country,file.path(parent,'reference_raw'))$raw
          }
          a<-if(s=='PISA')lo_pisa_independent_selected(raw,q)else if(family=='IEA_BOOKS')lo_iea_independent_books(raw,q)else lo_iea_independent_selected(raw,q)
        }
        output<-file.path(out,paste0('canonical_',id,'_',substr(digest::digest(science_obj,algo='sha256'),1,16),'.rds'))
        if(!file.exists(output))saveRDS(science_obj,output,compress=FALSE)
        current<-src;current$canonical_filename<-basename(output);current$canonical_sha256<-digest::digest(file=output,algo='sha256')
        jsonlite::write_json(current,file.path(out,'SOURCE_VERIFICATION.json'),pretty=TRUE,auto_unbox=TRUE,digits=17)
        file.copy(srcfile,file.path(out,'PARENT_SOURCE_VERIFICATION.json'),overwrite=TRUE)
        write.csv(q,file.path(out,'EXACT_SELECTED_TASKS.csv'),row.names=FALSE,na='')
        write.csv(a$results,file.path(out,'INDEPENDENT_RESULTS.csv'),row.names=FALSE)
        saveRDS(a$joint,file.path(out,'JOINT_REFERENCE_PV_REPLICATES.rds'),compress='gzip')
        for(f in c('LO_INTERNATIONAL_PRODUCTION.R','LO_IEA_SOURCE_BLOCK.R','LO_IEA_BACKGROUND.R','LO_PISA_SOURCE_BLOCK.R','LO_PEER_REFERENCE.R')) {
          p<-file.path(repo,'06_pipeline',f);file.copy(p,file.path(out,paste0('VERIFIER_',substr(digest::digest(file=p,algo='sha256'),1,16),'.R')),overwrite=TRUE)
        }
        files<-list.files(out,full.names=TRUE)
        jsonlite::write_json(list(key=key,files=data.frame(path=basename(files),sha256=vapply(files,function(p)digest::digest(file=p,algo='sha256'),character(1)))),seal,pretty=TRUE,auto_unbox=TRUE)
      }
      cat('INTERNATIONAL_PRODUCER',id,family,nrow(q),'\n');flush.console()
      lo_international_measure(repo,bundle,science_obj,q,out)
      kind<-if(family=='PISA_CORE')if(y>=2015)'PISA_MODERN'else'PISA_LEGACY'else family
      lo_certify_verified_source_blocks(repo,bundle,root,outroot,id,id,kind,scope=scope,defer_audit=TRUE,verified_support=support)
      completed<<-completed+nrow(q);cat('INTERNATIONAL_CERTIFIED',id,family,nrow(q),'total_new',completed,'\n');flush.console()
    })(),error=function(e) {
      failures[[length(failures)+1L]]<<-data.frame(country=country,survey=s,year=y,family=family,reason=conditionMessage(e))
      lo_atomic_csv(do.call(rbind,failures),file.path(international,'PRODUCTION_REPAIRS_REQUIRED.csv'))
      cat('INTERNATIONAL_REPAIR_REQUIRED',id,family,conditionMessage(e),'\n');flush.console()
    })
    rm(obj,raw);gc(FALSE)
  }
  invisible(list(certified_new=completed,repairs=failures))
}
