# Fresh exact-byte verification; bounded parallel I/O for large evidence sets.
# The checked environment is invocation-local, never a timestamp-based cache.
lo_verify_evidence_files <- function(files,checked=new.env(parent=emptyenv()),
  repo=Sys.getenv('LO_REPO_ROOT',getwd()),temp_dir=tempdir()) {
  if(!is.data.frame(files)||!all(c('path','sha256')%in%names(files)))stop('EVIDENCE_FILE_SCHEMA')
  if(!nrow(files))return(invisible(checked))
  if(anyNA(files[c('path','sha256')])||any(!nzchar(files$path))||
     any(!grepl('^[a-f0-9]{64}$',files$sha256)))stop('EVIDENCE_FILE_IDENTITY')
  keys<-paste(files$path,files$sha256)
  todo<-unique(files[!vapply(keys,exists,logical(1),envir=checked,inherits=FALSE),c('path','sha256'),drop=FALSE])
  if(!nrow(todo))return(invisible(checked))
  script<-file.path(repo,'06_pipeline/LO_EVIDENCE_HASHES.py')
  if(nrow(todo)>=128L&&file.exists(script)) {
    p<-tempfile('evidence_hashes_',tmpdir=temp_dir,fileext='.csv')
    on.exit(if(file.exists(p))unlink(p),add=TRUE)
    write.csv(todo,p,row.names=FALSE,na='')
    output<-suppressWarnings(system2(Sys.getenv('LO_PYTHON','python'),
      shQuote(c(script,'--table',p)),stdout=TRUE,stderr=TRUE))
    status<-attr(output,'status')
    if(!is.null(status)&&status!=0L)stop('EVIDENCE_BYTES_CHANGED: ',paste(tail(output,2L),collapse=' '))
    result<-jsonlite::fromJSON(paste(output,collapse='\n'))
    if(result$status!='EXACT_ATTACHMENT_BYTES_VERIFIED'||result$files!=nrow(todo)||
       result$table_sha256!=digest::digest(file=p,algo='sha256'))stop('EVIDENCE_BATCH_IDENTITY')
  }else for(i in seq_len(nrow(todo))) {
    if(!file.exists(todo$path[i])||digest::digest(file=todo$path[i],algo='sha256')!=todo$sha256[i])
      stop('EVIDENCE_BYTES_CHANGED: ',basename(todo$path[i]))
  }
  for(key in paste(todo$path,todo$sha256))assign(key,TRUE,checked)
  invisible(checked)
}
