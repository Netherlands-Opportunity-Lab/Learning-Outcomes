source('06_pipeline/LO_SOURCE_UNAVAILABILITY.R')
tmp<-tempfile('unavailable_');dir.create(tmp)
proof<-file.path(tmp,'proof.txt');writeLines('Synthetic official field: no valid entries',proof)
g<-data.frame(cell_id=c('missing','available'),target_contract_sha256=c('contract1','contract2'),
 status='TARGET_NOT_YET_ADJUDICATED',hold_reason='')
x<-data.frame(cell_id='missing',target_contract_sha256='contract1',reason='SOURCE_FIELD_EMPTY')
cert<-file.path(tmp,'cert.json')
jsonlite::write_json(list(status='SOURCE_UNAVAILABLE_VERIFIED',cells=x,
 evidence_files=data.frame(path=proof,sha256=digest::digest(file=proof,algo='sha256'))),cert,auto_unbox=TRUE)
x$evidence_path<-cert;x$evidence_sha256<-digest::digest(file=cert,algo='sha256')
path<-file.path(tmp,'registry.csv');write.csv(x,path,row.names=FALSE)
out<-lo_source_unavailability(g,path)
stopifnot(nrow(out)==2L,out$status[1]=='UNAVAILABLE_VERIFIED_SOURCE_FIELD',
 out$status[2]==g$status[2],identical(out$cell_id,g$cell_id))
bad<-g;bad$target_contract_sha256[1]<-'changed'
stopifnot(inherits(try(lo_source_unavailability(bad,path),silent=TRUE),'try-error'))
bad<-g;bad$status[1]<-'SCIENTIFICALLY_VALIDATED'
stopifnot(inherits(try(lo_source_unavailability(bad,path),silent=TRUE),'try-error'))
x$classification<-'SOURCE_MAPPING_REVIEW_REQUIRED'
jsonlite::write_json(list(status=x$classification,cells=x[c('cell_id','target_contract_sha256','reason')],
 evidence_files=data.frame(path=proof,sha256=digest::digest(file=proof,algo='sha256'))),cert,auto_unbox=TRUE)
x$evidence_sha256<-digest::digest(file=cert,algo='sha256');write.csv(x,path,row.names=FALSE)
review<-lo_source_unavailability(g,path)
stopifnot(review$status[1]=='HOLD_SOURCE_MAPPING_REVIEW',!startsWith(review$status[1],'UNAVAILABLE'))
writeLines('Changed source evidence',proof)
stopifnot(inherits(try(lo_source_unavailability(g,path),silent=TRUE),'try-error'))
unlink(tmp,recursive=TRUE)
cat('PASS proven source absence retained in grid, exact contracts, conflict and changed-evidence rejection\n')
