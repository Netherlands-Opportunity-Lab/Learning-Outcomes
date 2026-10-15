# One exact column projection per modern PISA wave. The verified CNT selector
# preserves every requested pupil in source order. Partitioning computes no
# statistic and cannot turn a regional record into a national population.
lo_pisa_partition_sources <- function(repo,manifest_path,out) {
  m<-read.csv(manifest_path,colClasses='character',na.strings=character())
  m<-m[m$survey=='PISA'&as.integer(m$year)>=2015,]
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  source(file.path(repo,'06_pipeline/LO_PRODUCTION_SPACE.R'))
  sha<-function(p)digest::digest(file=p,algo='sha256')
  registers<-list()
  for(y in unique(m$year)) {
    z<-m[m$year==y,];path<-unique(z$raw_path);hash<-unique(z$raw_sha256)
    stopifnot(length(path)==1L,length(hash)==1L,sha(path)==hash)
    marker<-file.path(out,paste0('PISA_',y,'_PARTITIONS.json'))
    if(file.exists(marker)) {
      old<-jsonlite::fromJSON(marker)
      if(old$raw_sha256==hash&&setequal(old$files$country,z$source_country)&&
         all(file.exists(old$files$path))&&all(vapply(old$files$path,sha,character(1))==old$files$sha256)) {
        registers[[path]]<-old;cat('REUSE_RAW_PARTITIONS',y,'\n');next
      }
    }
    if(lo_production_free_bytes(out)<4*1024^3)stop('PISA_PARTITION_SPACE_RESERVE')
    header<-names(haven::read_sav(path,n_max=0))
    pv<-unlist(lapply(c('READ','MATH','SCIE'),function(k)paste0('PV',1:10,k)))
    base<-c('CNT','CNTSTUID','CNTSCHID','AGE','ST004D01T','ST004','ST004D01D','MALE',
      'ST022Q01TA','LANGTEST_COG','IMMIG','ESCS','PROGN','W_FSTUWT',paste0('W_FSTURWT',1:80),pv)
    ses<-if(as.integer(y)<=2018)c(sprintf('ST011Q%02dTA',c(2,4,5,6,9)),sprintf('ST012Q%02dTA',1:3),sprintf('ST012Q%02dNA',6:9),'ST013Q01TA')else
      c(sprintf('ST250Q%02dJA',c(1,2,3,5)),sprintf('ST251Q%02dJA',c(1,3,6,7)),sprintf('ST254Q%02dJA',1:5),'ST255Q01JA')
    parents<-if(y=='2025')c('BICT_P1','BICT_P2','BICT_S')else c('ST019BQ01T','ST019CQ01T','ST019AQ01T')
    fields<-intersect(unique(c(base,parents,ses,'HISEI','PAREDINT','HISCED','OECD')),header)
    cat('READ_WAVE_ONCE',y,length(fields),'columns\n');flush.console()
    elapsed<-system.time(raw<-haven::read_sav(path,col_select=tidyselect::all_of(fields)))[['elapsed']]
    index<-readRDS(unique(z$index_path))
    stopifnot(index$raw_sha256==hash,identical(as.character(raw$CNT),index$selector))
    records<-list()
    for(country in z$source_country) {
      d<-raw[as.character(raw$CNT)==country,,drop=FALSE]
      stopifnot(nrow(d)>0,!anyDuplicated(d$CNTSTUID),!anyNA(d$CNTSTUID))
      f<-file.path(out,paste0('RAW_PISA_',y,'_',country,'_',substr(hash,1,16),'.rds'))
      tmp<-tempfile('partition_',tmpdir=out);saveRDS(d,tmp,compress=FALSE)
      if(file.exists(f)) {stopifnot(sha(f)==sha(tmp));unlink(tmp)}else if(!file.rename(tmp,f))stop('PARTITION_ATOMIC_COMMIT_FAILED')
      records[[country]]<-data.frame(country=country,path=normalizePath(f,winslash='/'),sha256=sha(f),n=nrow(d))
      rm(d)
    }
    receipt<-list(status='EXACT_RAW_COLUMN_AND_COUNTRY_PARTITIONS',year=as.integer(y),raw_path=path,raw_sha256=hash,
      fields=fields,source_rows=nrow(raw),read_seconds=elapsed,object_bytes=as.numeric(object.size(raw)),
      selector_sha256=sha(unique(z$index_path)),producer_sha256=sha(file.path(repo,'06_pipeline/LO_PISA_PARTITION.R')),files=do.call(rbind,records))
    jsonlite::write_json(receipt,marker,auto_unbox=TRUE,pretty=TRUE,digits=17)
    registers[[path]]<-receipt;cat('RAW_PARTITIONS_COMPLETE',y,length(records),'\n');flush.console()
    rm(raw,index);gc(FALSE)
  }
  invisible(registers)
}
