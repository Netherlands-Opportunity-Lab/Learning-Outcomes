source('06_pipeline/LO_ATOMIC_CHECKPOINT.R')
local({
 out<-tempfile('registry_io_');dir.create(out)
 on.exit(unlink(out,recursive=TRUE),add=TRUE)
 x<-data.frame(cell_id=c('valid_zero','comma,quote"and\nline','literal_NA','tiny'),
  estimate=c(0,501.1234567890123,NA_real_,1e-150),standard_error=c(0,.123456789012345,NA_real_,1e-151),
  n_unweighted=c(42L,12001L,NA_integer_,1L),note=c('', 'NA', 'scientific proof', '9.999999999999999e-5'),
  valid=c(TRUE,TRUE,FALSE,FALSE),stringsAsFactors=FALSE)
 ordinary<-file.path(out,'ordinary.csv');path<-file.path(out,'registry.csv')
 write.csv(x,ordinary,row.names=FALSE,na='')
 baseline<-read.csv(ordinary,stringsAsFactors=FALSE,na.strings=character())
 if(!identical(baseline,lo_scientific_registry_read(ordinary))) {
  print(all.equal(baseline,lo_scientific_registry_read(ordinary),tolerance=0))
  print(lapply(baseline,class));print(lapply(lo_scientific_registry_read(ordinary),class))
  dput(baseline$cell_id);dput(lo_scientific_registry_read(ordinary)$cell_id)
  stop('Registry parser parity failed')
 }
 lo_atomic_csv(baseline,path,fast=TRUE)
 first<-digest::digest(file=path,algo='sha256')
 stopifnot(identical(baseline,lo_scientific_registry_read(path)),
  identical(read.csv(path,colClasses='character',na.strings=character()),
   lo_scientific_registry_read(path,colClasses='character')))
 lo_atomic_csv(baseline,path,fast=TRUE)
 stopifnot(first==digest::digest(file=path,algo='sha256'))
 changed<-baseline;changed$estimate[1]<-2
 lo_atomic_csv(changed,path,fast=TRUE)
 stopifnot(identical(changed,lo_scientific_registry_read(path)))
 if(.Platform$OS.type=='windows')stopifnot(first==digest::digest(file=paste0(path,'.previous'),algo='sha256'))
 cat('PASS registry scalar/type parity; valid zero, missing and literal NA; precision, quoting, atomic replace and identical rerun\n')
})
