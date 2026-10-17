source("06_pipeline/LO_SOURCE_REPAIR.R")
o<-list(meta=list(survey="PISA",year=2022L,v9_country="NLD"),
 data=data.frame(SOURCE_STUDENT_ID=c("3","1","2","4"),W=c(3,1,2,4)))
r<-data.frame(CNT="NLD",CNTSTUID=1:4,AGE=c(15.5,16,15.7,9999),W_FSTUWT=1:4)
r$ST022Q01TA<-haven::labelled(c(1,2,99,1),c("Language of the test"=1,"Other language"=2,"No Response"=99))
r$LANGTEST_COG<-haven::labelled(rep(322,4),c(Dutch=322))
x<-lo_repair_pisa2022_rows(o,r)
stopifnot(identical(x$data$AGE,c(15.7,15.5,16,NA_real_)),
 identical(x$data$DEMO_LANGUAGE,c(NA_character_,"test_language_home","other_language_home","test_language_home")),
 abs(x$meta$language_weighted_coverage-.7)<1e-12,lo_exact_language_groups(x)$ok)
bad<-r;bad$CNTSTUID[1]<-2
stopifnot(inherits(try(lo_repair_pisa2022_rows(o,bad),silent=TRUE),"try-error"))
bad<-r;attr(bad$ST022Q01TA,"labels")<-NULL
stopifnot(inherits(try(lo_repair_pisa2022_rows(o,bad),silent=TRUE),"try-error"))
bad<-r;bad$W_FSTUWT[2]<-3
stopifnot(inherits(try(lo_repair_pisa2022_rows(o,bad),silent=TRUE),"try-error"))
x$meta$language_definition<-"Dutch ethnicity"
stopifnot(!lo_exact_language_groups(x)$ok)
cat("PASS labelled raw source repair, exact ID/weight alignment, no language-identity substitution\n")
