# Bounded, real-source numerical probes for the public scientific bundle.
# Rscript scripts/verify_public_raw_probes.R <private-config.json> <new-output-dir>
# The configuration binds exact approved task rows, expected aggregates and
# official raw files. Expected aggregates are read only AFTER fresh estimation.
# This is a targeted platform probe, not a claim of full-source replication.
(function() {
  args<-commandArgs(TRUE);stopifnot(length(args)==2L)
  repo<-normalizePath('.',winslash='/');config_path<-normalizePath(args[1],winslash='/')
  output<-args[2];if(dir.exists(output))stop('RAW_PROBE_REQUIRES_NEW_EMPTY_DIRECTORY')
  config<-jsonlite::fromJSON(config_path,simplifyVector=FALSE)
  sha<-function(p)digest::digest(file=p,algo='sha256')
  check<-function(item) {
    stopifnot(length(item$path)==1L,file.exists(item$path),
      identical(sha(item$path),item$sha256))
    item$path
  }
  tasks_path<-check(config$tasks)
  # Pin the expected file now, but never use its values to calculate a result.
  expected_path<-check(config$expected)
  tasks<-read.csv(tasks_path,colClasses='character',na.strings=character())
  stopifnot(nrow(tasks)>0L,!anyDuplicated(tasks$metric_key),
    all(tasks$module%in%c('core','gender','extension_performance_school',
                         'extension_performance_class')))
  Sys.setenv(LO_FRESH_REPLICATION='1',LO_REPO_ROOT=repo)
  source('06_pipeline/BUNDLE_DISCOVERY.R')
  bundle<-lo_bundle_discover();stopifnot(isTRUE(lo_bundle_verify(bundle)))
  for(f in c('LO_IEA_SOURCE_BLOCK.R','LO_PISA_LEGACY_SOURCE.R',
             'LO_EXACT_BOOT.R','LO_EXACT_ESTIMATORS.R','LO_COMPACT_RECOMPUTE.R',
             'LO_APPROVED_EXTENSIONS.R','LO_GENDER_POOL_POLICY.R'))
    source(file.path(repo,'06_pipeline',f),encoding='UTF-8')
  for(f in c('LO04_COMMON.R','LO04_CACHE.R'))source(file.path(bundle,'code',f))
  for(f in c('REPAIRS.R','EXTENSIONS.R'))source(file.path(bundle,'engine',f))
  lo_exact_boot(bundle)
  dir.create(output,recursive=TRUE)
  output<-normalizePath(output,winslash='/')
  start<-proc.time()[3];actual<-list();contexts<-list()
  for(ctx in config$contexts) {
    id<-paste(ctx$country,ctx$survey,ctx$year,sep='_')
    raw<-check(ctx$raw)
    q<-tasks[tasks$country==ctx$country&tasks$survey==ctx$survey&
               tasks$year==as.character(ctx$year),,drop=FALSE]
    stopifnot(nrow(q)>0)
    out<-file.path(output,id);started<-proc.time()[3]
    cat('FRESH_RAW_PROBE',id,nrow(q),'\n');flush.console()
    v<-if(ctx$survey=='PISA')lo_pisa_prepare_legacy(raw,check(ctx$control),
          as.integer(ctx$year),ctx$country,out)else
       lo_iea_prepare_country(raw,ctx$survey,as.integer(ctx$year),out,
          ctx$country,as.integer(ctx$source_country),
          allowed_grades=as.integer(unlist(ctx$allowed_grades)),
          population_note=ctx$population_note,population_evidence=ctx$population_evidence)
    batches<-split(seq_len(nrow(q)),paste(q$module,q$domain,q$definition,q$threshold,sep='|'))
    rows<-lapply(batches,function(ix) {
      s<-q[ix,,drop=FALSE];science<-lo_compact_backend_tasks(s)
      z<-lo_exact_selected_estimate(v$object,science)
      data.frame(cell_id=z$metric_key,estimate=z$estimate,standard_error=z$se,
        n_unweighted=lo_compact_count_n(v$object,science))
    })
    actual[[id]]<-do.call(rbind,rows)
    contexts[[id]]<-list(country=ctx$country,survey=ctx$survey,year=ctx$year,
      raw_sha256=sha(raw),source_receipt_sha256=sha(file.path(out,'SOURCE_VERIFICATION.json')),
      cells=nrow(q),pupils=nrow(v$object$data),seconds=unname(proc.time()[3]-started))
    rm(v);gc(verbose=FALSE)
  }
  results<-do.call(rbind,actual);stopifnot(setequal(results$cell_id,tasks$metric_key))
  write.csv(results,file.path(output,'FRESH_RESULTS.csv'),row.names=FALSE)
  stopifnot(identical(sha(expected_path),config$expected$sha256))
  expected<-read.csv(expected_path,stringsAsFactors=FALSE)
  at<-match(results$cell_id,expected$cell_id);stopifnot(!anyNA(at))
  comparison<-data.frame(cell_id=results$cell_id,
    estimate_difference=abs(results$estimate-expected$estimate[at]),
    se_difference=abs(results$standard_error-expected$standard_error[at]),
    n_equal=results$n_unweighted==expected$n_unweighted[at])
  write.csv(comparison,file.path(output,'NUMERICAL_PARITY.csv'),row.names=FALSE)
  stopifnot(all(comparison$estimate_difference<1e-9),
    all(comparison$se_difference<1e-9),all(comparison$n_equal))
  code<-c('scripts/verify_public_raw_probes.R',
    '06_pipeline/LO_IEA_SOURCE_BLOCK.R','06_pipeline/LO_PISA_LEGACY_SOURCE.R',
    '06_pipeline/LO_EXACT_ESTIMATORS.R','06_pipeline/LO_COMPACT_RECOMPUTE.R')
  proof<-list(status='TARGETED_OFFICIAL_RAW_NUMERICAL_REPLICATION_PASS',
    full_source_replication=FALSE,result_cache_used=FALSE,legacy_bundle_used=FALSE,
    cells=nrow(results),contexts=contexts,seconds=unname(proc.time()[3]-start),
    platform=R.version$platform,R_version=R.version.string,
    config_sha256=sha(config_path),tasks_sha256=sha(tasks_path),
    expected_sha256=sha(expected_path),results_sha256=sha(file.path(output,'FRESH_RESULTS.csv')),
    parity_sha256=sha(file.path(output,'NUMERICAL_PARITY.csv')),
    public_bundle_manifest_sha256=sha(file.path(bundle,'MANIFEST_SHA256.csv')),
    code_sha256=as.list(setNames(vapply(code,sha,character(1)),code)),
    max_estimate_difference=max(comparison$estimate_difference),
    max_se_difference=max(comparison$se_difference),
    tolerance=1e-9,n_required_exact=TRUE)
  jsonlite::write_json(proof,file.path(output,'RAW_REPLICATION_PROBE.json'),
    pretty=TRUE,auto_unbox=TRUE,digits=17)
  cat('PUBLIC_RAW_PROBES_PASS',nrow(results),'cells; no old result caches or private source bundle\n')
})()
