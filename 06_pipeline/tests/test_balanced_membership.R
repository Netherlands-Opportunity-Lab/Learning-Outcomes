source("06_pipeline/LO_BALANCED_MEMBERSHIP.R",encoding="UTF-8")
make <- function(country,year,group="total",age="age15",domain="reading") {
  data.frame(country=country,survey=if(age=="age15")"PISA" else if(domain=="reading")"PIRLS" else "TIMSS",
    age_group=age,domain=domain,year=as.character(year),outcome="mean_score",
    split_dimension=if(group=="total")"none" else "gender",split_group=group,
    definition_id="harmonized_definition",ses_definition_id="none",
    peer_definition="none",peer_target_group="none",threshold_id="none",
    unit="score_points",population_comparison_id=paste0(age,"_target_population"),
    method_comparison_id="CERTIFIED_SURVEY_METHOD",estimate=if(country=="NLD")900 else if(country=="AAA")400 else 500,
    standard_error=2,n_unweighted=100,status="SCIENTIFICALLY_VALIDATED",
    source_record_id=paste(country,year,group,age,domain,sep="_"),
    verification_id="synthetic_certificate",stringsAsFactors=FALSE)
}
fails <- function(expr)inherits(tryCatch({force(expr);NULL},error=function(e)e),"error")
cells <- do.call(rbind,lapply(c("NLD","AAA","BBB"),function(c)
  do.call(rbind,lapply(c(2015,2018,2022),function(y)
    rbind(make(c,y,"girl"),make(c,y,"boy"))))))
required <- cells[cells$country=="NLD",lo_balance_columns()]
m <- lo_balanced_membership(cells,required,c("NLD","AAA","BBB"),"NLD")
stopifnot(identical(m$eligible,c(TRUE,TRUE,FALSE)))
p <- lo_balanced_reference_points(cells,required,c("AAA","BBB"),"NLD")$points
stopifnot(nrow(p)==6L,all(p$estimate==450),all(p$n_countries==2L),
          all(p$members=="AAA;BBB"),all(!p$benchmark_se_displayed))
# A missing boy in one wave excludes the country from both group lines/all years.
bad <- cells[!(cells$country=="BBB" & cells$year=="2018" & cells$split_group=="boy"),]
m <- lo_balanced_membership(bad,required,c("AAA","BBB"),"NLD")
stopifnot(identical(m$eligible,c(TRUE,FALSE)),m$missing_cells[2]==1L,
          fails(lo_balanced_reference_points(bad,required,c("AAA","BBB"),"NLD")))
# Extra observations are permitted, incompatible definitions are not.
extra <- rbind(cells,make("AAA",2009,"girl"))
stopifnot(all(lo_balanced_membership(extra,required,c("AAA","BBB"),"NLD")$eligible))
for(field in c("ses_definition_id","peer_definition","population_comparison_id","method_comparison_id")) {
  wrong <- cells;wrong[wrong$country=="AAA",field] <- "INCOMPATIBLE"
  stopifnot(!lo_balanced_membership(wrong,required,"AAA","NLD")$eligible)
}
held <- cells;held$status[held$country=="AAA" & held$year=="2022"] <- "AVAILABLE"
stopifnot(!lo_balanced_membership(held,required,"AAA","NLD")$eligible,
  fails(lo_balanced_membership(cells,required[FALSE,],"AAA","NLD")),
  fails(lo_balanced_membership(cells[cells$country!="NLD",],required,"AAA","NLD")),
  fails(lo_balanced_reference_points(cells,required,"NLD","NLD")),
  fails(lo_balanced_reference_points(cells,required,character(),"NLD")),
  fails(lo_balanced_membership(rbind(cells,cells[1,]),required,"AAA","NLD")))
# Each combination needs >=3 comparable cycles; other combinations are independent.
full <- do.call(rbind,lapply(c("age10","age15"),function(age)
  do.call(rbind,lapply(c("reading","mathematics","science"),function(domain)
    do.call(rbind,lapply(c(2015,2018,2022),function(y)make("NLD",y,age=age,domain=domain)))))))
stopifnot(lo_dashboard_eligibility(full,"NLD")$countries$dashboard_eligible)
short <- full[-1,]
ad<-lo_dashboard_eligibility(short,'NLD')
stopifnot(ad$countries$dashboard_eligible,ad$countries$admitted_combinations==5L,
 !lo_combination_admitted(ad,full[1,],'NLD'))
incomparable <- full;incomparable$population_comparison_id[1] <- "DIFFERENT_TARGET_POPULATION"
ad<-lo_dashboard_eligibility(incomparable,'NLD')
stopifnot(ad$countries$dashboard_eligible,ad$countries$admitted_combinations==5L,
 !lo_combination_admitted(ad,full[1,],'NLD'))
one_combination<-full[full$survey=='PISA' & full$domain=='reading',]
stopifnot(lo_dashboard_eligibility(one_combination,'NLD')$countries$dashboard_eligible)
stopifnot(!lo_dashboard_eligibility(full[FALSE,],"NLD")$countries$dashboard_eligible)
all_core <- do.call(rbind,lapply(c("NLD","AAA","BBB"),function(country) {
  z<-full;z$country<-country;z$source_record_id<-paste(country,z$source_record_id);z
}))
all_data <- rbind(all_core,cells)
stopifnot(all(lo_dashboard_reference_options(all_data,required,c("AAA","BBB"),"NLD")$eligible))
bad_admission <- all_data[!(all_data$country=="BBB" & all_data$age_group=="age10" &
  all_data$domain=="science" & all_data$year=="2015"),]
o<-lo_dashboard_reference_options(bad_admission,required,c("AAA","BBB"),"NLD")
stopifnot(all(o$eligible)) # missing primary science must not veto PISA reading
bad_selected<-all_data[!(all_data$country=='BBB' & all_data$survey=='PISA' &
 all_data$domain=='reading' & all_data$split_group=='total' & all_data$year=='2015'),]
o<-lo_dashboard_reference_options(bad_selected,required,c('AAA','BBB'),'NLD')
stopifnot(identical(o$eligible,c(TRUE,FALSE)),o$reason[2]=='FAIL_SELECTED_COMBINATION_MIN3',
 fails(lo_dashboard_reference_points(bad_selected,required,c('AAA','BBB'),'NLD')))
neutral<-cells;neutral$domain<-'all';neutral$outcome<-'peer_composition'
neutral$split_dimension<-'ses';neutral$peer_definition<-'school';neutral$unit<-'percent'
neutral_required<-neutral[neutral$country=='NLD',lo_balance_columns()]
with_neutral<-rbind(bad_selected,neutral)
stopifnot(all(lo_dashboard_reference_options(with_neutral,neutral_required,c('AAA','BBB'),'NLD')$eligible))
no_study<-with_neutral[!(with_neutral$country=='BBB' & with_neutral$survey=='PISA' &
 with_neutral$outcome=='mean_score' & with_neutral$split_group=='total'),]
stopifnot(!lo_dashboard_reference_options(no_study,neutral_required,'BBB','NLD')$eligible)
missing_peer<-with_neutral[!(with_neutral$country=='BBB' & with_neutral$domain=='all' &
 with_neutral$split_group=='boy' & with_neutral$year=='2018'),]
stopifnot(!lo_dashboard_reference_options(missing_peer,neutral_required,'BBB','NLD')$eligible)
cat('PASS per-combination minimum; fixed joint panel; independent outcomes; exact constructs; no partial means\n')
# Own-country contracts cannot be shortened to finite plotted observations or
# inherited from the Dutch figure template.
source('06_pipeline/LO_BALANCED_MEMBERSHIP.R')
own_tasks<-data.frame(country=c('ITA','ITA','ITA','NLD'),survey='PISA',
  contract_figure_id='TR_MEAN',year=c('2003','2018','2025','2022'))
own_figure<-data.frame(figure_id='DISPLAY',historical_figure_id='TR_MEAN',survey='PISA',required_years='2003;2006;2009;2012;2015;2018;2022;2025')
stopifnot(identical(lo_focus_product_years(own_tasks,'ITA',own_figure),c('2003','2018','2025')),
  length(lo_focus_product_years(own_tasks,'NLD',own_figure))==8L,
  length(lo_focus_product_years(own_tasks,'FRA',own_figure))==0L)
