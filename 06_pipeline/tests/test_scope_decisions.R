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
