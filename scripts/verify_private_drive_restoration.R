# Restore every remote aggregate checkpoint in bounded batches. No pupil files,
# remote mutations, deletion of live results, or reliance on cached package bytes.
# Rscript scripts/verify_private_drive_restoration.R <private-drive-config.json>
#   <scientific-registry.csv> <new-private-output-directory>
(function() {
  args<-commandArgs(TRUE);stopifnot(length(args)==3L)
  if(!file.exists(args[1]))stop('PRIVATE_DRIVE_CONFIG_FILE_NOT_FOUND')
  config<-jsonlite::fromJSON(args[1]);registry<-normalizePath(args[2],winslash='/')
  stopifnot(identical(config$data_visibility,'PRIVATE_ACCOUNT_ONLY'),
    grepl('^[A-Za-z0-9_-]+:[A-Za-z0-9_./-]+$',config$remote),
    !grepl('..',config$remote,fixed=TRUE),file.exists(config$rclone_binary))
  out<-args[3];if(dir.exists(out))stop('RESTORE_PROBE_REQUIRES_NEW_DIRECTORY')
  dir.create(out,recursive=TRUE);out<-normalizePath(out,winslash='/')
  source('06_pipeline/DRIVE_SYNC.R')
  sha<-function(p)digest::digest(file=p,algo='sha256')
  original_registry_sha<-sha(registry)
  absence_path<-file.path(dirname(registry),'SOURCE_UNAVAILABLE_CELLS.csv')
  stopifnot(file.exists(absence_path));expected_absence_sha<-sha(absence_path)
  expected<-read.csv(registry,stringsAsFactors=FALSE,na.strings=character(),check.names=FALSE)
  stopifnot(!anyDuplicated(expected$cell_id),all(expected$status=='SCIENTIFICALLY_VALIDATED'))
  expected_keys<-paste(expected$cell_id,expected$result_hash,expected$certification_sha256,sep='::')
  key<-function(d)paste(d$cell_id,d$result_hash,d$certification_sha256,sep='::')
  download<-function(from,to)lo_drive_run(config$rclone_binary,c('copyto',from,to,'--retries','3','--quiet'))
  pointer<-file.path(out,'PRIVATE_REMOTE_LATEST.json')
  download(paste0(config$remote,'/scientific-checkpoints/LATEST.json'),pointer)
  index<-jsonlite::fromJSON(pointer,simplifyVector=FALSE)
  hashes<-names(index$packages);stopifnot(length(hashes)>0L,all(grepl('^[a-f0-9]{64}$',hashes)))
  records<-new.env(hash=TRUE,parent=emptyenv());seen_files<-new.env(hash=TRUE,parent=emptyenv())
  package_receipts<-list();dependency_records<-list();versions<-0L
  batch<-file.path(out,'batch');dir.create(batch)
  member<-file.path(out,'restored_member.bin')
  start<-proc.time()[3];peak_batch_bytes<-0;largest_member<-0
  # Keep the exact numeric value, rather than a rounded as.character rendition.
  canonical<-function(d) {
    as.data.frame(lapply(d,function(x) {
      z<-if(is.numeric(x))vapply(x,function(v)if(is.na(v))''else sprintf('%.17g',v),character(1))else as.character(x)
      z[is.na(z)]<-'';z
    }),stringsAsFactors=FALSE,check.names=FALSE)
  }
  expected_canonical<-canonical(expected)
  for(from in seq.int(1L,length(hashes),by=32L)) {
    take<-hashes[from:min(length(hashes),from+31L)]
    filelist<-file.path(out,'PRIVATE_BATCH_FILES.txt');writeLines(paste0(take,'.rds'),filelist)
    lo_drive_run(config$rclone_binary,c('copy',paste0(config$remote,'/scientific-checkpoints/objects'),
      batch,'--files-from',filelist,'--transfers','8','--checkers','16','--retries','3','--quiet'))
    paths<-file.path(batch,paste0(take,'.rds'))
    stopifnot(all(file.exists(paths)))
    peak_batch_bytes<-max(peak_batch_bytes,sum(file.info(paths)$size))
    for(h in take) {
      p<-file.path(batch,paste0(h,'.rds'));stopifnot(sha(p)==h)
      package<-readRDS(p)
      stopifnot(identical(package$kind,'CERTIFIED_AGGREGATES_AND_JOINT_EVIDENCE'),
        identical(package$raw_or_canonical_pupils,FALSE),
        identical(key(package$results),package$result_keys))
      versions<-versions+nrow(package$results)
      for(j in seq_len(nrow(package$members))) {
        m<-package$members[j,];bytes<-package$files[[m$sha256]]
        stopifnot(is.raw(bytes),length(bytes)==m$bytes,
          identical(digest::digest(bytes,algo='sha256',serialize=FALSE),m$sha256))
        if(!exists(m$sha256,seen_files,inherits=FALSE)) {
          writeBin(bytes,member);stopifnot(sha(member)==m$sha256)
          largest_member<-max(largest_member,file.info(member)$size)
          assign(m$sha256,TRUE,seen_files)
          # This exact absent-cell register is preserved from remote bytes;
          # other bound certificates/joint arrays are restored and hash-checked.
          if(basename(m$original_path)=='SOURCE_UNAVAILABLE_CELLS.csv'&&m$sha256==expected_absence_sha)
            file.copy(member,file.path(out,paste0('PRIVATE_ABSENCE_',m$sha256,'.csv')),overwrite=FALSE)
          unlink(member)
        }
      }
      wanted<-which(package$result_keys%in%expected_keys)
      if(length(wanted)) {
        restored<-canonical(package$results[wanted,,drop=FALSE])
        if(!setequal(names(restored),names(expected)))stop('RESTORE_RESULT_SCHEMA_CHANGED')
        restored<-restored[,names(expected),drop=FALSE]
        for(j in seq_len(nrow(restored))) {
          id<-restored$cell_id[j];at<-match(id,expected$cell_id)
          if(!identical(unname(unlist(restored[j,])),unname(unlist(expected_canonical[at,]))))
            stop('RESTORE_RESULT_RECORD_MISMATCH: ',id)
          assign(id,restored[j,,drop=FALSE],records)
        }
      }
      package_receipts[[h]]<-list(sha256=h,bytes=file.info(p)$size,
        cells=nrow(package$results),member_count=nrow(package$members),
        status='DOWNLOADED_UNPACKED_ALL_MEMBER_BYTES_RESTORED_AND_VERIFIED')
      dependency_records[[h]]<-package$source_dependencies_not_archived
      rm(package);unlink(p)
    }
    jsonlite::write_json(package_receipts,file.path(out,'PACKAGE_RESTORE_RECEIPTS.json'),
      auto_unbox=TRUE,pretty=TRUE)
    cat('DRIVE_RESTORE_CHECKED',min(length(hashes),from+31L),'/',length(hashes),
      'packages;',length(ls(records,all.names=TRUE)),'current result versions\n');flush.console()
    gc(verbose=FALSE)
  }
  stopifnot(versions==as.integer(index$certified_cell_versions),
    setequal(ls(records,all.names=TRUE),expected$cell_id),
    identical(sha(registry),original_registry_sha),
    identical(sha(absence_path),expected_absence_sha),
    file.exists(file.path(out,paste0('PRIVATE_ABSENCE_',expected_absence_sha,'.csv'))))
  restored<-do.call(rbind,lapply(expected$cell_id,function(id)get(id,records,inherits=FALSE)))
  rownames(restored)<-NULL;stopifnot(identical(restored,expected_canonical))
  recovered_path<-file.path(out,'PRIVATE_RESTORED_SCIENTIFIC_REGISTRY.csv')
  write.csv(restored,recovered_path,row.names=FALSE,na='')
  jsonlite::write_json(dependency_records,file.path(out,'PRIVATE_RETAINED_SOURCE_DEPENDENCIES.json'),
    auto_unbox=TRUE,pretty=TRUE)
  proof<-list(status='ALL_REMOTE_CHECKPOINTS_AND_CURRENT_RESULT_RECORDS_RESTORED',
    expected_registry_sha256=original_registry_sha,
    restored_absence_registry_sha256=expected_absence_sha,
    remote_pointer_sha256=sha(pointer),remote_packages=length(hashes),
    historical_cell_versions=versions,current_cells=nrow(restored),
    unique_evidence_members=length(ls(seen_files,all.names=TRUE)),
    compressed_bytes=sum(vapply(package_receipts,function(p)p$bytes,numeric(1))),
    peak_batch_bytes=peak_batch_bytes,largest_restored_member_bytes=largest_member,
    seconds=unname(proc.time()[3]-start),source_pupil_bytes_restored=FALSE,
    source_dependency_policy='Necessary raw sources are retained or reacquired by pinned source hash; not stored in aggregate checkpoints',
    restored_registry_sha256=sha(recovered_path),
    package_receipts_sha256=sha(file.path(out,'PACKAGE_RESTORE_RECEIPTS.json')),
    code_sha256=sha('scripts/verify_private_drive_restoration.R'))
  jsonlite::write_json(proof,file.path(out,'COMPLETE_RESTORE_PROOF.json'),
    auto_unbox=TRUE,pretty=TRUE,digits=17)
  cat('COMPLETE_DRIVE_RESTORATION_PASS',nrow(restored),'current cell records\n')
})()
