source('06_pipeline/LO_REMOTE_CHECKPOINT.R')
tmp<-tempfile();dir.create(tmp);dir.create(file.path(tmp,'master_reconciliation'))
remote_dir<-tempfile();dir.create(remote_dir)
config<-file.path(tmp,'private.json');jsonlite::write_json(list(data_visibility='PRIVATE_ACCOUNT_ONLY',remote='private:project',rclone_binary='unused'),config,auto_unbox=TRUE)
evidence<-file.path(tmp,'INDEPENDENT_RESULTS.csv');write.csv(data.frame(cell_id='a',estimate=4),evidence,row.names=FALSE)
cert<-file.path(tmp,'CERTIFICATE.json');jsonlite::write_json(list(evidence_files=data.frame(path=evidence,sha256=digest::digest(file=evidence,algo='sha256'))),cert,auto_unbox=TRUE)
rows<-data.frame(cell_id='a',status='SCIENTIFICALLY_VALIDATED',result_hash='result',estimate=4,certification_path=cert,certification_sha256=digest::digest(file=cert,algo='sha256'))
write.csv(rows,file.path(tmp,'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'),row.names=FALSE)
calls<-0L
copy<-function(from,to) {
  calls<<-calls+1L
  resolve<-function(p)if(startsWith(p,'private:project/'))file.path(remote_dir,sub('private:project/','',p,fixed=TRUE))else p
  from<-resolve(from);to<-resolve(to);dir.create(dirname(to),recursive=TRUE,showWarnings=FALSE);stopifnot(file.copy(from,to,overwrite=TRUE))
}
x<-lo_remote_checkpoint('.',tmp,config,copy);stopifnot(x$new==1L,calls==4L)
x<-lo_remote_checkpoint('.',tmp,config,copy);stopifnot(x$new==0L,calls==4L)
rows$cell_id<-'b';write.csv(rows,file.path(tmp,'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv'),row.names=FALSE)
broken<-function(from,to) {copy(from,to);if(startsWith(from,'private:'))writeBin(as.raw(1),to)}
failed<-tryCatch(lo_remote_checkpoint('.',tmp,config,broken),error=identity)
stopifnot(inherits(failed,'error'),length(readRDS(file.path(tmp,'.remote_checkpoints/VERIFIED_INDEX.rds'))$keys)==1L)
x<-lo_remote_checkpoint('.',tmp,config,copy);stopifnot(x$new==1L)
stopifnot(length(readRDS(file.path(tmp,'.remote_checkpoints/VERIFIED_INDEX.rds'))$keys)==2L)
run_dir<-file.path(tmp,'FIXED_PRODUCTION_V1/nld_only/RUN_RECORDS');dir.create(run_dir,recursive=TRUE)
jsonlite::write_json(list(git_commit='verified_test_commit',configuration=list(scope='nld_only')),file.path(run_dir,'run.json'),auto_unbox=TRUE)
before<-calls;x<-lo_remote_checkpoint('.',tmp,config,copy)
stopifnot(x$new==0L,calls==before+4L,length(readRDS(file.path(tmp,'.remote_checkpoints/VERIFIED_INDEX.rds'))$run_record_sha256)==1L)
unlink(c(tmp,remote_dir),recursive=TRUE)
cat('PASS external checkpoint round trip, extracted-file restoration, idempotent resume and corrupted readback rejection\n')
