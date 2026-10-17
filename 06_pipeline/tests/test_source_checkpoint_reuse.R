source('06_pipeline/LO_BALANCED_MEMBERSHIP.R')
source('06_pipeline/LO_INTERNATIONAL_SOURCES.R')
w<-tempfile('source_reuse_');dir.create(w)
sha<-function(p)digest::digest(file=p,algo='sha256')
receipt<-file.path(w,'receipt.json');contract<-file.path(w,'contract.json')
writeLines('immutable source receipt',receipt);writeLines('complete pinned source contract',contract)
x<-as.data.frame(setNames(rep(list('none'),length(lo_balance_columns())),lo_balance_columns()))
x$country<-'AAA';x$year<-'2021';x$survey<-'PIRLS';x$domain<-'reading'
x$source_path<-receipt;x$source_sha256<-sha(receipt);x$status<-'SOURCE_SUPPORT_VERIFIED'
ef<-normalizePath(c(receipt,contract),winslash='/')
cert<-list(status='SOURCE_SUPPORT_VERIFIED',country='AAA',source_sha256=x$source_sha256,
 support_keys=lo_balance_key(x),comparability_evidence='Independent immutable population and PV check',
 evidence_files=data.frame(path=ef,sha256=vapply(ef,sha,character(1))))
cp<-file.path(w,'cert.json');jsonlite::write_json(cert,cp,auto_unbox=TRUE)
old<-x;old$certificate_path<-cp;old$certificate_sha256<-sha(cp)
stopifnot(lo_international_cached_support(old,x,receipt,contract),
 !lo_international_cached_support(old[FALSE,],x,receipt,contract))
fails<-function(z)inherits(tryCatch({force(z);NULL},error=function(e)e),'error')
changed<-x;changed$domain<-'science'
stopifnot(fails(lo_international_cached_support(old,changed,receipt,contract)))
changed<-old;changed$certificate_sha256<-strrep('0',64)
stopifnot(fails(lo_international_cached_support(changed,x,receipt,contract)))
changed<-x;changed$source_sha256<-strrep('1',64)
stopifnot(fails(lo_international_cached_support(old,changed,receipt,contract)))
writeLines('changed contract',contract)
stopifnot(fails(lo_international_cached_support(old,x,receipt,contract)))
unlink(w,recursive=TRUE)
cat('PASS immutable source proof reuse; source/contract/support/certificate changes rejected\n')
