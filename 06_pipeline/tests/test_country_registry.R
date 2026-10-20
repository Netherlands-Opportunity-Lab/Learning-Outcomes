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
source("06_pipeline/LO_RUN_CONFIG.R")
cfg<-lo_run_config("all_required","")
stopifnot(identical(lo_run_scope(x,cfg),x))
cfg$selection$countries<-c("NLD","Z99")
phased<-lo_run_scope(x,cfg)
stopifnot(setequal(phased$selected,c("NLD","Z99")),
 setequal(phased$dashboard,c("NLD","Z99")),
 setequal(phased$reference_candidates,c("NLD","Z99")),
 !"AUT"%in%phased$foreign_reference,identical(phased$comparator,x$comparator),
 identical(phased$source_support,x$source_support),
 phased$countries$dashboard_eligible[phased$countries$country=="AUT"],
 !phased$countries$selected_for_production[phased$countries$country=="AUT"])
cfg$selection$countries<-"X98"
stopifnot(inherits(try(lo_run_scope(x,cfg),silent=TRUE),"try-error"))
missing<-base[!(base$country=="AUT" & base$age_group=="age10" & base$domain=="reading" & base$year=="2015"),]
y<-lo_runtime_scope(work,tasks,"all_required",missing)
stopifnot('AUT'%in%y$selected,'AUT'%in%y$dashboard,
 y$countries$admitted_combinations[y$countries$country=='AUT']==5L)
stopifnot(isTRUE(lo_country_production_approval(".","NLD")),
 inherits(try(lo_country_production_approval(".",c("NLD","AUT")),silent=TRUE),"try-error"))
stopifnot(isTRUE(lo_country_production_approval(".",c("NLD","AUT"),c("NLD","AUT"))),
 inherits(try(lo_country_production_approval(".",c("NLD","X98"),c("NLD","AUT")),silent=TRUE),"try-error"))
# A selected graph keeps its full focus combination, not unrelated outcomes.
anchor<-unique(base[base$country=="NLD",c("survey","age_group","domain")]);anchor$years<-"2015;2018;2022"
req<-lo_focus_required_support(base,base[1,],"NLD",anchor)
stopifnot(nrow(req)==3L)
neutral<-base[base$country=='NLD' & base$survey=='PISA' & base$domain=='reading',]
neutral$domain<-'all';neutral$outcome<-'peer_composition';neutral$peer_definition<-'school'
neutral_req<-lo_focus_required_support(base,neutral,'NLD',anchor)
stopifnot(nrow(neutral_req)==3L,all(neutral_req$domain=='all'))
short<-base[base$year!="2015",]
stopifnot(inherits(try(lo_focus_required_support(short,short[1,],"NLD",anchor),silent=TRUE),"try-error"))
one<-base[1,,drop=FALSE]
source_path<-file.path(work,"source.txt");writeLines("synthetic source",source_path)
proof<-file.path(work,"proof.txt");writeLines("synthetic population and cycle evidence",proof)
cert_path<-file.path(work,"cert.json")
cert<-list(status="SOURCE_SUPPORT_VERIFIED",source_sha256=digest::digest(file=source_path,algo="sha256"),
 country=one$country,support_keys=lo_balance_key(one),comparability_evidence="Synthetic evidence only",
 evidence_files=data.frame(path=proof,sha256=digest::digest(file=proof,algo="sha256")))
jsonlite::write_json(cert,cert_path,auto_unbox=TRUE)
one$source_path<-source_path;one$source_sha256<-cert$source_sha256
one$certificate_path<-cert_path;one$certificate_sha256<-digest::digest(file=cert_path,algo="sha256")
one$status<-cert$status
path<-file.path(work,"support.csv");write.csv(one,path,row.names=FALSE)
stopifnot(nrow(lo_read_source_support(path))==1L)
writeLines("changed evidence",proof)
stopifnot(inherits(try(lo_read_source_support(path),silent=TRUE),"try-error"))
unlink(work,recursive=TRUE)
cat("PASS dynamic source scopes, discovery outside COMMON42, no rich-country exception, unshrunk focus anchor\n")
