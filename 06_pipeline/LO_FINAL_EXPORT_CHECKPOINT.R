# Resume expensive aggregate exports only AFTER fresh source/evidence checking.
# The identity includes the reviewed runtime/policies and all actual export
# inputs. Every output byte is rehashed. No mtime or count-only acceptance.
lo_final_export_checkpoint <- function(state,stage,identity,outputs,verified,
                                       compute,read_result) {
  if(!grepl('^[a-z_]+$',stage)||any(grepl('[/\\\\]|[.][.]',outputs)))
    stop('FINAL_EXPORT_CHECKPOINT_PATH')
  dir.create(state,recursive=TRUE,showWarnings=FALSE)
  receipt<-file.path(state,paste0('FINAL_EXPORT_CHECKPOINT_',stage,'.json'))
  paths<-file.path(state,outputs)
  input_sha<-digest::digest(identity,algo='sha256')
  hashes<-function()setNames(vapply(paths,function(p)
    if(file.exists(p))digest::digest(file=p,algo='sha256')else 'ABSENT',character(1)),outputs)
  previous<-if(file.exists(receipt))tryCatch(jsonlite::fromJSON(receipt),error=function(e)NULL)else NULL
  if(isTRUE(verified)&&!is.null(previous)&&identical(previous$schema_version,1L)&&
     identical(previous$input_sha256,input_sha)&&
     identical(previous$outputs,outputs)&&
     identical(unname(unlist(previous$output_sha256)),unname(hashes()))) {
    cat('FINAL_EXPORT_REUSED: ',stage,'; exact inputs/code/policies and output bytes verified\n',sep='')
    return(read_result())
  }
  value<-compute()
  if(!all(file.exists(paths)))stop('FINAL_EXPORT_CHECKPOINT_MISSING_OUTPUT')
  if(isTRUE(verified)) {
    record<-list(schema_version=1L,input_sha256=input_sha,outputs=outputs,
                 output_sha256=as.list(hashes()),evidence_freshly_verified=TRUE)
    tmp<-tempfile('export_receipt_',tmpdir=state,fileext='.json')
    on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
    jsonlite::write_json(record,tmp,auto_unbox=TRUE,pretty=TRUE)
    lo_atomic_replace(tmp,receipt)
  }
  value
}
