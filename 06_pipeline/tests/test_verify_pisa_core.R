source("06_pipeline/LO_VERIFY_PISA_CORE.R")
tmp<-tempfile();dir.create(tmp)
raw<-data.frame(CNT=c(rep("NLD",4),"DEU"),CNTSTUID=1:5,W_FSTUWT=c(1,2,3,4,1))
for(i in 1:80)raw[[paste0("W_FSTURWT",i)]]<-raw$W_FSTUWT*if(i%%2)c(.5,1.5,.5,1.5,1) else c(1.5,.5,1.5,.5,1)
for(i in 1:10)raw[[paste0("PV",i,"MATH")]]<-c(350,450,550,650,500)+i
source_path<-file.path(tmp,"raw.sav");haven::write_sav(raw,source_path)
d<-data.frame(SOURCE_STUDENT_ID=1:4,W=raw$W_FSTUWT[1:4])
for(i in 1:80)d[[paste0("RW",i)]]<-raw[[paste0("W_FSTURWT",i)]][1:4]
for(i in 1:10)d[[paste0("PV_MATH_",i)]]<-raw[[paste0("PV",i,"MATH")]][1:4]
obj<-list(meta=list(survey="PISA",year=2022L,v9_country="NLD"),data=d)
canonical<-file.path(tmp,"canonical.rds");saveRDS(obj,canonical)
q<-data.frame(survey="PISA",year="2022",country="NLD",module="core",domain="mathematics",
 stat=c("mean","total_below","total_high"),threshold=c("","420.07","606.99"),metric_key=c("mean","below","high"))
z<-lo_verify_pisa2022_core(source_path,canonical,q,file.path(tmp,"ok"))
stopifnot(abs(z$estimate[1]-555.5)<1e-10,abs(z$estimate[2]-.1)<1e-10,abs(z$estimate[3]-.4)<1e-10,
 all(z$n_unweighted==4L),all(z$standard_error>0))
wrong<-q;wrong$threshold[2]<-"400"
stopifnot(inherits(try(lo_verify_pisa2022_core(source_path,canonical,wrong,file.path(tmp,"wrong_cut")),silent=TRUE),"try-error"))
obj$data$RW1[1]<-99;saveRDS(obj,canonical)
stopifnot(inherits(try(lo_verify_pisa2022_core(source_path,canonical,q,file.path(tmp,"bad")),silent=TRUE),"try-error"))
unlink(tmp,recursive=TRUE)
cat("Independent raw source, sample, PV and replicate parity checks PASS\n")
