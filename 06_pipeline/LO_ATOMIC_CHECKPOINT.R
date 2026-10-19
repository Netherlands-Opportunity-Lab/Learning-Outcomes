# Same-directory replacement. A Windows reader/virus scanner may briefly deny
# delete sharing. Retry only sharing/lock violations, without ever deleting the
# current checkpoint or exposing a missing destination between writes.
lo_atomic_replace <- function(tmp,path,attempts=80L,delay_ms=250L) {
  stopifnot(length(attempts)==1L,is.finite(attempts),attempts>=1,attempts<=120,
            length(delay_ms)==1L,is.finite(delay_ms),delay_ms>=0,delay_ms<=500)
  if(!identical(normalizePath(dirname(tmp),winslash='/',mustWork=TRUE),
                normalizePath(dirname(path),winslash='/',mustWork=TRUE)))stop('CHECKPOINT_NOT_SAME_DIRECTORY')
  if(.Platform$OS.type=='windows'&&file.exists(path)) {
    quote_ps<-function(x)paste0("'",gsub("'","''",normalizePath(x,winslash='/',mustWork=FALSE),fixed=TRUE),"'")
    script<-paste0("$ErrorActionPreference='Stop'; for($attempt=1;$attempt -le ",as.integer(attempts),
      ";$attempt++){try {if([System.IO.File]::Exists(",quote_ps(path),")){[System.IO.File]::Replace(",
      quote_ps(tmp),',',quote_ps(path),',',quote_ps(paste0(path,'.previous')),
      ")}else{[System.IO.File]::Move(",quote_ps(tmp),',',quote_ps(path),
      ")};exit 0}catch{$failure=$_.Exception.GetBaseException();$code=$failure.HResult -band 65535;",
      "if(($code -ne 32 -and $code -ne 33) -or $attempt -eq ",as.integer(attempts),
      "){[Console]::Error.WriteLine($failure.Message);exit 1};Start-Sleep -Milliseconds ",as.integer(delay_ms),"}}")
    status<-suppressWarnings(system2('powershell',c('-NoProfile','-NonInteractive','-Command',shQuote(script))))
    if(status!=0L||file.exists(tmp))stop('CHECKPOINT_ATOMIC_REPLACE_FAILED: current checkpoint retained; retry after reader releases file')
  }else if(!file.rename(tmp,path))stop('CHECKPOINT_ATOMIC_RENAME_FAILED')
  invisible(path)
}

# File.Replace also retains the immediately previous checkpoint on Windows.
lo_atomic_csv <- function(x,path,fast=FALSE) {
  dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
  tmp<-tempfile('checkpoint_',tmpdir=dirname(path),fileext='.csv')
  on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
  if(isTRUE(fast))data.table::fwrite(x,tmp,sep=',',quote=TRUE,qmethod='double',na='',eol='\n',nThread=1L)
  else write.csv(x,tmp,row.names=FALSE,na='')
  lo_atomic_replace(tmp,path)
  invisible(path)
}

# Registry fields are ordinary CSV scalars; no formulas, factors or list columns.
# Match read.csv(..., stringsAsFactors=FALSE, na.strings=character()) semantics.
# One parser thread bounds RAM and avoids oversubscribing the scientific worker.
lo_scientific_registry_read <- function(path,colClasses=NULL) {
  if(!is.null(colClasses)&&!identical(colClasses,'character'))stop('REGISTRY_COLUMN_CLASS_UNSUPPORTED')
  x<-data.table::fread(path,data.table=FALSE,na.strings=NULL,nThread=1L,
    colClasses='character',check.names=TRUE,strip.white=FALSE)
  for(k in names(x)) {
    # The registry writer quotes every string and doubles embedded quotes.
    # fread retains those escape pairs whereas read.csv decodes them.
    quoted<-grepl('""',x[[k]],fixed=TRUE)
    if(any(quoted))x[[k]][quoted]<-gsub('""','"',x[[k]][quoted],fixed=TRUE)
    # read.csv normalizes embedded Windows line endings; fread preserves them.
    i<-grepl('\r\n',x[[k]],fixed=TRUE)
    if(any(i))x[[k]][i]<-gsub('\r\n','\n',x[[k]][i],fixed=TRUE)
    if(is.null(colClasses))x[[k]]<-type.convert(x[[k]],as.is=TRUE,na.strings=character())
  }
  x
}
