source("06_pipeline/LO_SCOPE_DECISIONS.R",encoding="UTF-8")
source("06_pipeline/MASTER_ESTIMATION_GRID.R",encoding="UTF-8")
decisions<-lo_read_scope_decisions(".")
# Repository decisions are human-owned; test policy using independent fixtures.
pending<-decisions
pending$status<-"PENDING";pending$decision_date<-"";pending$user_evidence<-""
task<-data.frame(metric_key="synthetic_high_peer",country="NLD",survey="PISA",
 year="2022",domain="reading",contract_figure_id="EN_PERFORMANCE_PEER_age15_reading",
 peer_definition="whole_school",module="high_proficiency_peer_exposure",
 stat="self_high",group="self_high",definition="high_peer_raw_sample",
 threshold="",unit="percent",calculation_policy="",stringsAsFactors=FALSE)
stopifnot(nrow(lo_scoped_low_peer_tasks(task))==0L,
 nrow(lo_scoped_low_peer_tasks(task,pending))==0L,
 nrow(lo_grid_new_low_peer_tasks(task))==3L)
yes<-pending;yes$status[1L]<-"APPROVED"
stopifnot(inherits(try(lo_scoped_low_peer_tasks(task,yes),silent=TRUE),"try-error"))
yes$decision_date[1L]<-"2026-10-14"
yes$user_evidence[1L]<-"SYNTHETIC TEST ONLY: explicit A01 yes"
chosen<-lo_scoped_low_peer_tasks(task,yes)
stopifnot(nrow(chosen)==3L,all(chosen$module=="peer_below_basic"),
 !any(chosen$metric_key%in%task$metric_key))
for(s in c("REJECTED","DEFERRED")) {
  no<-yes;no$status[1L]<-s
  stopifnot(nrow(lo_scoped_low_peer_tasks(task,no))==0L)
}
bad<-pending;bad$approval_id[2L]<-"A01"
stopifnot(inherits(try(lo_scope_is_approved(bad,"A01"),silent=TRUE),"try-error"))
other<-yes;other$status[1L]<-"PENDING";other$status[2L]<-"APPROVED"
other$decision_date[2L]<-"2026-10-14";other$user_evidence[2L]<-"SYNTHETIC A02 yes"
stopifnot(nrow(lo_scoped_low_peer_tasks(task,other))==0L)
cat("PASS optional scope: proposals do not become required production; explicit approval still needs science gates\n")

# A09 selects derived product requirements, not old fixed-panel pupil tasks.
source("06_pipeline/LO_PRODUCT_TRACE.R",encoding="UTF-8")
rank_yes<-pending
idx<-match("A09",rank_yes$approval_id)
rank_yes[idx,c("status","decision_date","user_evidence")]<-
  list("APPROVED","2026-10-14","SYNTHETIC A09 rank time series and paper ranking")
parent<-task;parent$metric_key<-"synthetic_mean";parent$module<-"core"
parent$stat<-"mean";parent$group<-"total";parent$contract_figure_id<-"TR_MEAN_age15_reading"
legacy_rank<-parent;legacy_rank$metric_key<-"legacy_rank"
legacy_rank$contract_figure_id<-"TR_POSITION_age15_reading"
selected<-lo_scope_active_tasks(rbind(parent,legacy_rank),rank_yes)
stopifnot(identical(selected$metric_key,"synthetic_mean"))
grid<-data.frame(cell_id=parent$metric_key,status="SYNTHETIC_TEST_ONLY",estimate=500)
out<-tempfile();dir.create(out)
trace<-lo_product_trace(".",parent,grid,rank_yes,out)
ids<-c("USER_20261014_A09_DASHBOARD_RANK","USER_20261014_A09_PAPER_RANKING")
stopifnot(all(trace$active_cell_links[match(ids,trace$requirement_id)]==1L))
links<-read.csv(file.path(out,"PRIVATE_ACTIVE_PRODUCT_CELL_TRACE.csv"))
ranklinks<-links[links$requirement_id%in%ids,]
stopifnot(nrow(ranklinks)==2L,all(ranklinks$cell_id=="synthetic_mean"),
 all(grepl("NO_NEW_PUPIL_TASK",ranklinks$derivation)),
 all(trace$status[startsWith(trace$requirement_id,"DASH_TR_POSITION_")]=="SOURCE_NOT_COMPUTE_ORDER"))
trace<-lo_product_trace(".",parent,grid,pending,out)
stopifnot(all(trace$active_cell_links[match(ids,trace$requirement_id)]==0L),
 all(trace$status[match(ids,trace$requirement_id)]=="DERIVATION_NOT_APPROVED"))
appendix<-parent;appendix$metric_key<-"synthetic_high_ses"
appendix$contract_figure_id<-"GP_SES_HIGH_age15_reading"
appendix$module<-"ses_national";appendix$stat<-"q1_high"
idx<-match("A02",rank_yes$approval_id)
rank_yes[idx,c("status","decision_date","user_evidence")]<-
 list("APPROVED","2026-10-14","SYNTHETIC A02 appendix only")
two<-rbind(parent,appendix)
grid2<-data.frame(cell_id=two$metric_key,status="SYNTHETIC_TEST_ONLY",estimate=500)
trace<-lo_product_trace(".",two,grid2,rank_yes,out)
stopifnot(identical(trace$active_cell_links[match(ids,trace$requirement_id)],c(1L,2L)))
unlink(out,recursive=TRUE)
cat("PASS A09 product parent trace without legacy panels or new pupil tasks\n")
