source('06_pipeline/DRIVE_SYNC.R')
work<-tempfile('large_report_binding_');dir.create(work)
state<-file.path(work,'all_required');dir.create(state)
p<-file.path(state,'PRIVATE_MASTER_GRID.csv');writeLines('cell_id,estimate',p)
remote<-'private_test:project'
hash<-function(p)digest::digest(file=p,algo='sha256')
proof<-list(kind='PRIVATE_GENERATED_AGGREGATE_REVIEW_REPORTS',scope='all_required',
  destination_sha256=digest::digest(remote,algo='sha256',serialize=FALSE),
  files=list(PRIVATE_MASTER_GRID.csv=list(
    status='PRIVATE_DRIVE_DOWNLOAD_AND_FULL_RESTORE_VERIFIED',
    restored_exact_bytes=TRUE,source_bytes=file.info(p)$size,source_sha256=hash(p),
    gzip_sha256=paste(rep('a',64),collapse=''),
    relative_object=paste0('objects/',paste(rep('a',64),collapse=''),'.csv.gz'))))
jsonlite::write_json(proof,file.path(state,'LARGE_REPORT_RESTORE_MANIFEST.json'),auto_unbox=TRUE)
stopifnot(!is.null(lo_drive_verified_large_report(p,state,remote)),
  is.null(lo_drive_verified_large_report(p,state,'private_test:another_project')))
cat('changed source\n',file=p,append=TRUE)
stopifnot(is.null(lo_drive_verified_large_report(p,state,remote)))
writeLines('{}',file.path(state,'LARGE_REPORT_RESTORE_MANIFEST.json'))
stopifnot(is.null(lo_drive_verified_large_report(p,state,remote)))
# Delete only this generated test directory after resolving its containment.
stopifnot(startsWith(normalizePath(work,winslash='/'),
  paste0(normalizePath(tempdir(),winslash='/'),'/')))
unlink(work,recursive=TRUE)
cat('PASS compressed-backup receipt binds exact source bytes, scope and destination\n')
