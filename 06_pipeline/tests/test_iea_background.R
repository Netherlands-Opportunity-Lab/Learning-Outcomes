source('06_pipeline/LO_IEA_SOURCE_BLOCK.R')
source('06_pipeline/LO_IEA_BACKGROUND.R')
# An entire category straddles both quartiles: ties receive fractional mass,
# independent of student ordering, and missing books never enter the target.
x<-c(1,1,2,2,2,2,3,NA);w<-c(1,2,1,1,1,1,1,10)
t<-lo_iea_reference_tails(x,w)
stopifnot(sum(w*t$q1)==2,sum(w*t$q4)==2,t$q1[1]==t$q1[2],t$q4[8]==0)
o<-c(8,3,6,2,7,1,5,4);u<-lo_iea_reference_tails(x[o],w[o])
stopifnot(identical(t$q1[o],u$q1),identical(t$q4[o],u$q4))
z<-haven::labelled(c(1:5,9,NA),c('0-10'=1,'11-25'=2,'26-100'=3,'101-200'=4,'More than 200'=5,'Omitted'=9))
stopifnot(identical(lo_iea_books(z),c(as.numeric(1:5),NA_real_,NA_real_)))
attr(z,'labels')[1]<-2
stopifnot(inherits(try(lo_iea_books(z),silent=TRUE),'try-error'))
cat('PASS IEA books labels, fractional quartile ties and missing response exclusion\n')
