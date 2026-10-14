source('06_pipeline/LO_PISA_SOURCE_BLOCK.R')
source('06_pipeline/LO_PISA_LEGACY_SOURCE.R')
tmp<-tempfile('legacy_');dir.create(tmp)
sas<-file.path(tmp,'dictionary.sas');txt<-file.path(tmp,'source.txt')
writeLines(c('value GENDERF 1="Female" 2="Male" 9="Missing";','input','CNT 1 - 3','STIDSTD 4 - 6','W_FSTUWT 7 - 10;'),sas)
writeLines(c('NLD001 1.5','BEL002 2.0','NLD003 3.0'),txt)
columns<-lo_pisa_sas_columns(sas)
x<-lo_pisa_fixed_country_rows(txt,columns,'NLD',c('STIDSTD','W_FSTUWT'),chunk_rows=2)
stopifnot(nrow(x)==2,identical(x$STIDSTD,c('001','003')),identical(as.numeric(x$W_FSTUWT),c(1.5,3)),attr(x,'source_rows_scanned')==3L)
stopifnot(identical(lo_pisa_sas_labels(sas,'GENDERF'),c(Female=1,Male=2,Missing=9)))
writeLines('NLD001',txt)
stopifnot(inherits(try(lo_pisa_fixed_country_rows(txt,columns,'NLD','W_FSTUWT'),silent=TRUE),'try-error'))
# Older cycles contain five PVs: Rubin's finite-imputation multiplier is 1.2.
raw<-data.frame(W_FSTUWT=rep(1,4),ST004D01T=haven::labelled(c(1,2,1,2),c(Female=1,Male=2)),
 ST022Q01TA=haven::labelled(c(1,2,1,2),c('Language of test'=1,'Other language'=2)),
 IMMIG=haven::labelled(c(1,2,3,1),c(Native=1,'Second-generation'=2,'First-generation'=3)))
for(j in 1:80)raw[[paste0('W_FSTURWT',j)]]<-1
for(j in 1:5)raw[[paste0('PV',j,'READ')]]<-500+j
q<-data.frame(metric_key='old_mean',survey='PISA',year=2003,domain='reading',module='core',stat='mean',group='total',threshold='')
a<-lo_pisa_independent_selected(raw,q)
stopifnot(a$results$estimate==503,abs(a$results$standard_error-sqrt(3))<1e-12,a$joint$pv_count==5L)
unlink(tmp,recursive=TRUE)
cat('PASS streaming legacy source, dictionary safeguards and five-PV uncertainty\n')
