source("06_pipeline/LO_BALANCED_MEMBERSHIP.R")
source("06_pipeline/LO_COUNTRY_REGISTRY.R")
base<-expand.grid(country=c("NLD","AUT","Z99"),age_group=c("age10","age15"),
 domain=c("reading","mathematics","science"),year=c("2015","2018","2022"),stringsAsFactors=FALSE)
base$survey<-ifelse(base$age_group=="age15","PISA",ifelse(base$domain=="reading","PIRLS","TIMSS"))
for(k in setdiff(lo_balance_columns(),names(base)))base[[k]]<-"none"
base$outcome<-"mean_score";base$split_group<-"total";base$unit<-"score_points"
base$population_comparison_id<-"certified_population";base$method_comparison_id<-"certified_method"
work<-tempfile("country_registry_");dir.create(work)
write.csv(data.frame(country=c("NLD","AUT"),strictly_above_czechia="TRUE"),
 file.path(work,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"),row.names=FALSE)
tasks<-data.frame(country=c("NLD","AUT","Z99","X98"))
x<-lo_runtime_scope(work,tasks,"all_required",base)
stopifnot(setequal(x$selected,c("NLD","AUT","Z99")),setequal(x$dashboard,c("NLD","AUT","Z99")),
 "X98"%in%x$countries$country,!x$countries$dashboard_eligible[x$countries$country=="X98"])
stopifnot(identical(lo_runtime_scope(work,tasks,"nld_only",base)$selected,"NLD"),
 setequal(lo_runtime_scope(work,tasks,"nld_plus_19",base)$selected,c("NLD","AUT")))
missing<-base[!(base$country=="AUT" & base$age_group=="age10" & base$domain=="reading" & base$year=="2015"),]
y<-lo_runtime_scope(work,tasks,"all_required",missing)
stopifnot(!"AUT"%in%y$selected,!"AUT"%in%y$dashboard)
stopifnot(isTRUE(lo_country_production_approval(".","NLD")),
 inherits(try(lo_country_production_approval(".",c("NLD","AUT")),silent=TRUE),"try-error"))
# A selected graph/zoom cannot shrink the full focus core.
anchor<-unique(base[base$country=="NLD",c("survey","age_group","domain")]);anchor$years<-"2015;2018;2022"
req<-lo_focus_required_support(base,base[1,],"NLD",anchor)
stopifnot(nrow(req)==18L)
short<-base[base$year!="2015",]
stopifnot(inherits(try(lo_focus_required_support(short,short[1,],"NLD",anchor),silent=TRUE),"try-error"))
unlink(work,recursive=TRUE)
cat("PASS dynamic source scopes, discovery outside COMMON42, no rich-country exception, unshrunk focus anchor\n")
