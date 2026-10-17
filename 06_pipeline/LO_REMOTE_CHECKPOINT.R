# Incremental private scientific checkpoints, committed after each sealed block.
# No canonical pupil datasets, SQLite live copies, directory-wide uploads or
# Git mutations during an immutable run. Results, certificates and joint
# aggregate PV/replicate evidence are recoverable before the next block starts.
lo_remote_checkpoint <- function(repo,root,config=Sys.getenv('LO_DRIVE_SYNC_CONFIG',''),transfer=NULL) {
  tryCatch(lo_remote_checkpoint_impl(repo,root,config,transfer),error=function(e)
    stop('REMOTE_CHECKPOINT_PENDING: ',conditionMessage(e),call.=FALSE))
}
lo_remote_checkpoint_impl <- function(repo,root,config,transfer) {
  source(file.path(repo,'06_pipeline/LO_ATOMIC_CHECKPOINT.R'),local=environment())
  source(file.path(repo,'06_pipeline/LO_PROCESS_LOCK.R'),local=environment())
  source(file.path(repo,'06_pipeline/DRIVE_SYNC.R'),local=environment())
  stage<-file.path(root,'.remote_checkpoints');dir.create(stage,recursive=TRUE,showWarnings=FALSE)
  lock<-lo_process_lock(file.path(stage,'writer.lck'));on.exit(lo_process_unlock(lock),add=TRUE)
  if(!nzchar(config)) {
    home_dir<-Sys.getenv('USERPROFILE',path.expand('~'))
    candidates<-c(file.path(home_dir,'Downloads/LO05_RESULTATEN/.cloud_sync/drive.local.json'),
      file.path(home_dir,'Documents/Downloads/LO05_RESULTATEN/.cloud_sync/drive.local.json'))
    config<-candidates[file.exists(candidates)][1]
  }
  if(length(config)!=1L||is.na(config)||!file.exists(config))stop('REMOTE_CHECKPOINT_CONFIG_REQUIRED')
  cfg<-jsonlite::fromJSON(config)
  if(!identical(cfg$data_visibility,'PRIVATE_ACCOUNT_ONLY')||
     !grepl('^[A-Za-z0-9_-]+:[A-Za-z0-9_./-]+$',cfg$remote)||grepl('..',cfg$remote,fixed=TRUE))
    stop('REMOTE_CHECKPOINT_PRIVATE_DESTINATION_REQUIRED')
  if(is.null(transfer))transfer<-function(from,to)lo_drive_run(cfg$rclone_binary,c('copyto',from,to,'--retries','3'))
  hash<-function(p)digest::digest(file=p,algo='sha256')
  master<-file.path(root,'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv')
  if(!file.exists(master))return(invisible(list(cells=0L,new=0L)))
  all<-read.csv(master,stringsAsFactors=FALSE,na.strings=character(),check.names=FALSE)
  if(anyDuplicated(all$cell_id)||any(all$status!='SCIENTIFICALLY_VALIDATED'))stop('REMOTE_CHECKPOINT_INVALID_REGISTRY')
  keys<-paste(all$cell_id,all$result_hash,all$certification_sha256,sep='::')
  index_path<-file.path(stage,'VERIFIED_INDEX.rds')
  index<-if(file.exists(index_path))readRDS(index_path)else list(schema_version=1L,remote=cfg$remote,keys=character(),packages=list())
  if(!identical(index$remote,cfg$remote))stop('REMOTE_CHECKPOINT_DESTINATION_CHANGED')
  missing<-!keys%in%index$keys
  run_paths<-unlist(lapply(c('nld_only','nld_plus_19','all_required'),function(scope)
    list.files(file.path(root,'FIXED_PRODUCTION_V1',scope,'RUN_RECORDS'),pattern='[.]json$',full.names=TRUE)),use.names=FALSE)
  run_hashes<-vapply(run_paths,hash,character(1))
  run_new<-!run_hashes%in%index$run_record_sha256
  if(!any(missing)&&!any(run_new))return(invisible(list(cells=nrow(all),new=0L,packages=length(index$packages))))
  selected<-all[missing,,drop=FALSE]
  # Traverse only evidence explicitly bound to a certified result. Certificates
  # can reference method certificates, which in turn reference joint evidence.
  files<-list();members<-list();visited<-character();source_dependencies<-list()
  add<-function(path,expected) {
    path<-normalizePath(path,winslash='/',mustWork=TRUE)
    if(path%in%visited)return(invisible(NULL))
    if(!grepl('^[a-f0-9]{64}$',expected)||hash(path)!=expected)stop('REMOTE_CHECKPOINT_EVIDENCE_CHANGED')
    name<-basename(path);ext<-tolower(tools::file_ext(name))
    if(!ext%in%c('r','csv','json') && name!='JOINT_REFERENCE_PV_REPLICATES.rds') {
      visited<<-c(visited,path)
      source_dependencies[[length(source_dependencies)+1L]]<<-list(path=path,sha256=expected,
        archived=FALSE,reason='Non-joint binary source dependency retained locally or rebuilt from retained raw input; aggregate checkpoint excludes pupil data')
      return(invisible(NULL))
    }
    if(!ext%in%c('r','csv','json') && name!='JOINT_REFERENCE_PV_REPLICATES.rds')
      stop('REMOTE_CHECKPOINT_UNAPPROVED_ARTIFACT: ',name)
    if(grepl('canonical|raw_pupil|student_records',name,ignore.case=TRUE)&&name!='RAW_CANONICAL_COLUMN_PARITY.csv')
      stop('REMOTE_CHECKPOINT_PUPIL_DATA_FORBIDDEN: ',name)
    bytes<-file.info(path)$size
    if(!is.finite(bytes)||bytes>64*1024^2)stop('REMOTE_CHECKPOINT_FILE_BOUND')
    visited<<-c(visited,path)
    members[[length(members)+1L]]<<-data.frame(original_path=path,sha256=expected,bytes=bytes)
    if(is.null(files[[expected]]))files[[expected]]<<-readBin(path,'raw',n=bytes)
    if(ext=='json') {
      obj<-jsonlite::fromJSON(path)
      ef<-obj$evidence_files
      if(is.data.frame(ef)&&all(c('path','sha256')%in%names(ef)))
        for(j in seq_len(nrow(ef)))add(ef$path[j],ef$sha256[j])
    }
    invisible(NULL)
  }
  for(i in which(!duplicated(selected$certification_path)))add(selected$certification_path[i],selected$certification_sha256[i])
  # Run records bind the actual Git commit, configuration, code/package hashes
  # and cell result versions. Back up new provenance even if no values changed.
  for(i in which(run_new))add(run_paths[i],run_hashes[i])
  members<-do.call(rbind,members)
  package<-list(schema_version=1L,kind='CERTIFIED_AGGREGATES_AND_JOINT_EVIDENCE',
    raw_or_canonical_pupils=FALSE,results=selected,result_keys=keys[missing],members=members,files=files,
    source_dependencies_not_archived=source_dependencies)
  if(sum(vapply(files,length,integer(1)))>256*1024^2)stop('REMOTE_CHECKPOINT_PACKAGE_BOUND')
  tmp<-tempfile('upload_',tmpdir=stage,fileext='.rds');download<-tempfile('readback_',tmpdir=stage,fileext='.rds')
  on.exit(unlink(c(tmp,download)),add=TRUE)
  saveRDS(package,tmp,compress='gzip',version=3)
  sha<-hash(tmp);remote<-paste0(cfg$remote,'/scientific-checkpoints/objects/',sha,'.rds')
  transfer(tmp,remote);transfer(remote,download)
  if(hash(download)!=sha)stop('REMOTE_CHECKPOINT_READBACK_HASH_MISMATCH')
  recovered<-readRDS(download)
  if(!identical(recovered$results,selected)||!identical(recovered$result_keys,keys[missing]))stop('REMOTE_CHECKPOINT_RESULT_RESTORE_FAILED')
  # Restore actual files from downloaded bytes and verify every inner checksum.
  # The isolated test directory is never a source or live production directory.
  restore<-tempfile('restore_',tmpdir=stage);dir.create(restore)
  on.exit(unlink(restore,recursive=TRUE),add=TRUE)
  for(h in names(recovered$files)) {
    target<-file.path(restore,h);writeBin(recovered$files[[h]],target)
    if(hash(target)!=h)stop('REMOTE_CHECKPOINT_MEMBER_RESTORE_FAILED')
  }
  record<-list(sha256=sha,remote=remote,bytes=file.info(tmp)$size,cells=nrow(selected),
    files=nrow(members),restore='DOWNLOADED_RESULTS_AND_ALL_MEMBER_BYTES_VERIFIED',
    verified_utc=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'))
  index$keys<-c(index$keys,keys[missing]);index$packages[[sha]]<-record
  index$run_record_sha256<-unique(c(index$run_record_sha256,run_hashes[run_new]))
  pointer<-tempfile('index_',tmpdir=stage,fileext='.json');pointer_back<-tempfile('index_readback_',tmpdir=stage)
  on.exit(unlink(c(pointer,pointer_back)),add=TRUE)
  jsonlite::write_json(list(schema_version=1L,certified_cell_versions=length(index$keys),packages=index$packages),pointer,auto_unbox=TRUE,pretty=TRUE)
  pointer_remote<-paste0(cfg$remote,'/scientific-checkpoints/LATEST.json')
  transfer(pointer,pointer_remote);transfer(pointer_remote,pointer_back)
  if(hash(pointer)!=hash(pointer_back))stop('REMOTE_CHECKPOINT_INDEX_READBACK_FAILED')
  save_path<-tempfile('verified_',tmpdir=stage);saveRDS(index,save_path)
  if(.Platform$OS.type=='windows'&&file.exists(index_path)) {
    ps_quote<-function(x)paste0("'",gsub("'","''",normalizePath(x,winslash='/',mustWork=FALSE),fixed=TRUE),"'")
    command<-paste0('[System.IO.File]::Replace(',ps_quote(save_path),',',ps_quote(index_path),',',ps_quote(paste0(index_path,'.previous')),')')
    if(system2('powershell',c('-NoProfile','-NonInteractive','-Command',shQuote(command)))!=0L)
      stop('REMOTE_CHECKPOINT_INDEX_ATOMIC_REPLACE')
  }else if(!file.rename(save_path,index_path))stop('REMOTE_CHECKPOINT_INDEX_ATOMIC_RENAME')
  cat('PRIVATE_DRIVE_CHECKPOINT_VERIFIED: ',nrow(selected),' new cells; ',length(index$keys),' cell versions recoverable remotely\n',sep='')
  invisible(list(cells=nrow(all),new=nrow(selected),packages=length(index$packages),receipt=record))
}
