# Preserve the two large aggregate review reports that the ordinary bounded
# report sync skips. Stream gzip, read back from private Drive, restore bytes,
# then publish a hash-addressed manifest. Never handle pupil/school records.
# Rscript scripts/backup_large_review_reports.R <private-config> <fixed-state> <new-output>
(function() {
  args<-commandArgs(TRUE);stopifnot(length(args)==3L,file.exists(args[1]))
  cfg<-jsonlite::fromJSON(args[1]);state<-normalizePath(args[2],winslash='/')
  stopifnot(identical(cfg$data_visibility,'PRIVATE_ACCOUNT_ONLY'),
    grepl('^[A-Za-z0-9_-]+:[A-Za-z0-9_./-]+$',cfg$remote),
    !grepl('..',cfg$remote,fixed=TRUE),file.exists(cfg$rclone_binary))
  if(!basename(state)%in%c('nld_only','nld_plus_19','all_required'))stop('UNKNOWN_FIXED_SCOPE')
  source('06_pipeline/DRIVE_SYNC.R')
  sha<-function(p)digest::digest(file=p,algo='sha256')
  out<-args[3];job<-list(state=state,config_sha256=sha(args[1]))
  if(dir.exists(out)) {
    marker<-file.path(out,'PRIVATE_JOB.json')
    if(!file.exists(marker)||!identical(jsonlite::fromJSON(marker),job))
      stop('REPORT_BACKUP_OUTPUT_BELONGS_TO_ANOTHER_JOB')
  }else {
    dir.create(out,recursive=TRUE)
    jsonlite::write_json(job,file.path(out,'PRIVATE_JOB.json'),auto_unbox=TRUE,pretty=TRUE)
  }
  out<-normalizePath(out,winslash='/')
  transfer<-function(a,b)lo_drive_run(cfg$rclone_binary,c('copyto',a,b,'--retries','3','--quiet'))
  copy_stream<-function(from,to,decompress=FALSE,compress=FALSE) {
    input<-if(decompress)gzfile(from,'rb')else file(from,'rb')
    output<-if(compress)gzfile(to,'wb',compression=6)else file(to,'wb')
    on.exit({close(input);close(output)},add=TRUE)
    repeat {block<-readBin(input,'raw',n=1024L^2);if(!length(block))break;writeBin(block,output)}
  }
  records<-list()
  for(name in c('PRIVATE_MASTER_GRID.csv','PRIVATE_ARCHIVE_EVIDENCE.csv')) {
    source_path<-if(name=='PRIVATE_ARCHIVE_EVIDENCE.csv')
      file.path(state,'FINAL_FIXED_PIPELINE',name)else file.path(state,name)
    stopifnot(file.exists(source_path))
    before<-sha(source_path);compressed<-file.path(out,paste0(name,'.gz'))
    copy_stream(source_path,compressed,compress=TRUE)
    stopifnot(sha(source_path)==before)
    package_sha<-sha(compressed)
    remote<-paste0(cfg$remote,'/release-support/objects/',package_sha,'.csv.gz')
    transfer(compressed,remote)
    back<-file.path(out,'readback.csv.gz');restore<-file.path(out,'restored.csv')
    transfer(remote,back);stopifnot(sha(back)==package_sha)
    copy_stream(back,restore,decompress=TRUE)
    stopifnot(sha(restore)==before,sha(source_path)==before)
    records[[name]]<-list(name=name,source_bytes=file.info(source_path)$size,
      source_sha256=before,gzip_bytes=file.info(compressed)$size,gzip_sha256=package_sha,
      relative_object=paste0('objects/',package_sha,'.csv.gz'),
      restored_exact_bytes=TRUE,status='PRIVATE_DRIVE_DOWNLOAD_AND_FULL_RESTORE_VERIFIED')
    jsonlite::write_json(records,file.path(out,'VERIFIED_PROGRESS.json'),auto_unbox=TRUE,pretty=TRUE)
    unlink(c(back,restore))
    cat('LARGE_AGGREGATE_REPORT_RESTORED',name,'\n')
  }
  manifest<-list(schema_version=1,scope=basename(state),
    kind='PRIVATE_GENERATED_AGGREGATE_REVIEW_REPORTS',
    destination_sha256=digest::digest(cfg$remote,algo='sha256',serialize=FALSE),
    files=records,code_sha256=sha('scripts/backup_large_review_reports.R'))
  manifest_path<-file.path(out,'LARGE_REPORT_RESTORE_MANIFEST.json')
  jsonlite::write_json(manifest,manifest_path,auto_unbox=TRUE,pretty=TRUE)
  remote_manifest<-paste0(cfg$remote,'/release-support/manifests/',sha(manifest_path),'.json')
  transfer(manifest_path,remote_manifest)
  back<-file.path(out,'MANIFEST_READBACK.json');transfer(remote_manifest,back)
  stopifnot(sha(back)==sha(manifest_path))
  cat('LARGE_REVIEW_REPORT_BACKUP_AND_RESTORE_PASS',sha(manifest_path),'\n')
})()
