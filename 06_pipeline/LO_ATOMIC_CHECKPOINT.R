# Same-volume replacement. On Windows file.rename cannot replace an existing
# file; File.Replace is atomic and retains the immediately previous checkpoint.
lo_atomic_csv <- function(x,path) {
  dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
  tmp<-tempfile('checkpoint_',tmpdir=dirname(path),fileext='.csv')
  on.exit(if(file.exists(tmp))unlink(tmp),add=TRUE)
  write.csv(x,tmp,row.names=FALSE,na='')
  if(.Platform$OS.type=='windows'&&file.exists(path)) {
    quote_ps<-function(x)paste0("'",gsub("'","''",normalizePath(x,winslash='/',mustWork=FALSE),fixed=TRUE),"'")
    script<-paste0('[System.IO.File]::Replace(',quote_ps(tmp),',',quote_ps(path),',',quote_ps(paste0(path,'.previous')),')')
    status<-system2('powershell',c('-NoProfile','-NonInteractive','-Command',shQuote(script)))
    if(status!=0L||file.exists(tmp))stop('CHECKPOINT_ATOMIC_REPLACE_FAILED')
  }else if(!file.rename(tmp,path))stop('CHECKPOINT_ATOMIC_RENAME_FAILED')
  invisible(path)
}
