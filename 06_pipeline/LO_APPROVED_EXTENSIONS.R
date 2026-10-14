# Additional human-approved contracts use the same exact grid and dispatcher.
# These specifications authorize targets, never data availability or science QA.
lo_extension_modules <- function() c("extension_home_ses","extension_ses_gender",
  "extension_performance_school","extension_performance_class",
  "extension_ses_school","extension_ses_class")
lo_extension_approval <- function(module) unname(c(extension_home_ses="A04",
  extension_ses_gender="A06",extension_performance_school="A11",
  extension_performance_class="A12",extension_ses_school="A13",
  extension_ses_class="A14")[module])
lo_extension_tasks <- function(tasks,decisions) {
  parts<-list()
  add<-function(x,id,family,module,stat,group,definition,unit,peer="",threshold="") {
    if(!nrow(x)||!lo_scope_is_approved(decisions,id))return(invisible(NULL))
    x$module<-module;x$stat<-stat;x$group<-group;x$definition<-definition
    x$unit<-unit;x$peer_definition<-peer;x$threshold<-threshold
    x$calculation_policy<-paste0("EXPLICIT_",id,"_20261014")
    x$outcome<-stat
    x$contract_figure_id<-paste0(family,"_age",ifelse(x$survey=="PISA",15,10),"_",x$domain)
    x$metric_key<-apply(x[c("country","survey","year","domain","module","stat",
      "group","definition","peer_definition","threshold","unit","calculation_policy")],1,paste,collapse="|")
    parts[[length(parts)+1L]]<<-x
  }
  core<-tasks[tasks$module=="core" & tasks$stat=="mean",,drop=FALSE]
  for(level in c("school","class")) {
    add(core,if(level=="school")"A11" else "A12",paste0("EX_PERFORMANCE_",toupper(level)),
      paste0("extension_performance_",level),"between_variance_share","total",
      "weighted_descriptive_between_share","percent",level)
    ses<-tasks[tasks$module%in%c("ses_national","ses_harmonized") & tasks$stat=="q1_mean",,drop=FALSE]
    # SES has no achievement domain: deduplicate repeated maths/science rows.
    ses$domain<-"all"
    ses<-ses[!duplicated(ses[c("country","survey","year","definition")]),,drop=FALSE]
    add(ses,if(level=="school")"A13" else "A14",paste0("EX_SES_",toupper(level)),
      paste0("extension_ses_",level),"between_variance_share","total",ses$definition,"percent",level)
  }
  ses<-tasks[tasks$module%in%c("ses_national","ses_harmonized") & tasks$stat%in%c("q1_mean","q4_mean","q1_basic","q4_basic","q1_high","q4_high"),,drop=FALSE]
  for(gender in c("girl","boy")) {
    stat<-sub("^q[14]_","",ses$stat);stat[stat=="basic"]<-"below"
    add(ses,"A06","EX_SES_GENDER","extension_ses_gender",stat,
      paste(ses$group,gender,sep="_"),ses$definition,ses$unit,threshold=ses$threshold)
  }
  home<-core[core$survey%in%c("PIRLS","TIMSS"),,drop=FALSE]
  for(group in c("lower","middle","higher"))for(stat in c("mean","below","high")) {
    if(stat=="high"&&!lo_scope_is_approved(decisions,"A02"))next
    threshold<-if(stat=="mean")"" else if(stat=="below")"475" else "625"
    add(home,"A04","EX_HOME_SES","extension_home_ses",stat,group,
      "IEA_OFFICIAL_HOME_SES_CYCLE_SPECIFIC",if(stat=="mean")"score_points" else "proportion",threshold=threshold)
  }
  if(!length(parts))return(tasks[FALSE,,drop=FALSE])
  x<-do.call(rbind,parts);x<-x[!duplicated(x$metric_key),,drop=FALSE]
  if(any(x$metric_key%in%tasks$metric_key))stop("EXTENSION_COLLIDES_WITH_BASE")
  x
}

lo_extension_availability <- function(tasks) {
  x<-unique(tasks[tasks$module=="extension_home_ses",c("country","survey","year")])
  first<-ifelse(x$survey=="PIRLS",2021L,2023L)
  x$construct<-"IEA_OFFICIAL_HOME_SES"
  x$status<-ifelse(as.integer(x$year)<first,"OFFICIAL_SCALE_NOT_IN_EARLIER_CYCLE",
    "REQUIRES_COUNTRY_SOURCE_RESPONSE_CHECK")
  x$reason<-ifelse(as.integer(x$year)<first,
    "Older Home Resources for Learning is a different construct; do not splice or backfill",
    "Published scale does not prove national parent response, raw variable availability or comparability")
  absent<-x$survey=="TIMSS" & x$year=="2023" & x$country%in%c("NLD","AUS","USA")
  x$status[absent]<-"UNAVAILABLE_HOME_QUESTIONNAIRE_NOT_ADMINISTERED"
  x$reason[absent]<-"IEA TIMSS 2023 School Climate Health report p6 footnote b and p17: Home Questionnaire not administered"
  x$evidence_url<-ifelse(x$survey=="PIRLS","https://files.eric.ed.gov/fulltext/ED676159.pdf",
    "https://timssandpirls.bc.edu/timss2019/methods/pdf/T19_MP_Ch16-AppA-context-scales-grade-4.pdf")
  x$evidence_url[absent]<-"https://files.eric.ed.gov/fulltext/ED679640.pdf"
  x
}
