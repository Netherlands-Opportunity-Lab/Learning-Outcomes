source('06_pipeline/LO_PISA_PROGRAM_IDENTITY.R')
labels<-c('United Kingdom (excl.Scotland): General'='08270010',
 'United Kingdom (Scotland): Secondary'='08260010','Belgium: General'='00560010',
 'Kosovo: General'='03830010','Invalid'='99999999')
z<-lo_pisa_valid_programs(c('8270010','08260010','00560010','99999999',NA),labels,'GBR','United Kingdom')
stopifnot(identical(is.na(z$values),c(FALSE,FALSE,TRUE,TRUE,TRUE)),length(z$allowed_codes)==2L)
z<-lo_pisa_valid_programs(c('3830010','4110010'),labels,'KSV','Kosovo')
stopifnot(!is.na(z$values[1]),is.na(z$values[2]))
stopifnot(inherits(try(lo_pisa_valid_programs('001',labels,'XXX','Unknown'),silent=TRUE),'try-error'))
labels<-c('DUBAI: General'='7840001','ARE (ex. Dubai): General'='7842001',
 'Switzerland: Lower secondary'='07560001','Switzerland: Missing'='07560099')
stopifnot(all(!is.na(lo_pisa_valid_programs(c('7840001','7842001'),labels,'ARE','United Arab Emirates',2009)$values)),
 !is.na(lo_pisa_valid_programs('07560001',labels,'LIE','Liechtenstein',2012)$values),
 is.na(lo_pisa_valid_programs('07560099',labels,'LIE','Liechtenstein',2012)$values),
 inherits(try(lo_pisa_valid_programs('07560001',labels,'LIE','Liechtenstein',2015),silent=TRUE),'try-error'))
cat('PASS own PISA country labels, multiple UK programme prefixes, cycle-specific Kosovo code and missing values\n')
