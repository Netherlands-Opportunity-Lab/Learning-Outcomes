source("06_pipeline/LO_SCOPE_LOCK.R",encoding="UTF-8")
source("06_pipeline/LO_SCOPE_DECISIONS.R",encoding="UTF-8")
source("06_pipeline/MASTER_ESTIMATION_GRID.R",encoding="UTF-8")
source("06_pipeline/GRID_ARCHIVE_BATCH.R",encoding="UTF-8")
source("06_pipeline/LO_EXISTING_RESULT_REGISTRY.R",encoding="UTF-8")
source("06_pipeline/LO_FIXED_VALIDATION.R",encoding="UTF-8")
source("06_pipeline/LO_SOURCE_UNAVAILABILITY.R",encoding="UTF-8")
source("06_pipeline/LO_FIXED_PRODUCERS.R",encoding="UTF-8")
source("06_pipeline/LO_FINAL_DASHBOARD_EXPORT.R",encoding="UTF-8")
work<-tempfile("lo_fixed_");dir.create(work)
bundle<-file.path(work,"bundle");dir.create(bundle)
common<-c(sprintf("X%02d",1:41),"NLD")
compare<-c("NLD",sprintf("X%02d",1:11),sprintf("Y%02d",1:8))
write.csv(data.frame(route_code=common,common42_member="True",
   country_id=paste0("iso3:",common),
   country_name_nl=common,country_name_en=common),
   file.path(bundle,"COMMON42_REGISTER.csv"),row.names=FALSE)
write.csv(data.frame(country=compare,strictly_above_czechia="TRUE"),
   file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv"),row.names=FALSE)
p1<-lo_locked_scope(bundle,"nld_only")
p2<-lo_locked_scope(bundle,"nld_plus_19")
p3<-lo_locked_scope(bundle,"all_required")
stopifnot(length(p1$selected)==1L,length(p2$selected)==20L,
    length(p3$selected)==50L,
    length(p3$additional_reference)==8L,
    all(p2$selected%in%p3$selected))
tasks<-data.frame(metric_key=c("m1","m2","m3"),
 country=c("NLD","X01","X41"),survey=c("PISA","PIRLS","TIMSS"),
 year=c("2025","2021","2023"),domain="reading",module="core",
 stat="mean",group="total",definition="total",
 peer_definition="",threshold="",contract_figure_id=c("TR_MEAN_age15_reading","TR_MEAN_age10_reading","TR_MEAN_age10_reading"),
 unit="score_points",calculation_policy="",stringsAsFactors=FALSE)
stopifnot(nrow(lo_scope_filter_tasks(tasks,p1))==1L,
  nrow(lo_scope_filter_tasks(tasks,p2))==2L,
  nrow(lo_scope_filter_tasks(tasks,p3))==3L)
write.csv(data.frame(requirement_id=sprintf("Q%02d",1:8),
  requirement="Evidence required"),
  file.path(bundle,"OPEN_PAPER_REQUIREMENTS.csv"),row.names=FALSE)
q<-lo_final_quality_gate(bundle,tasks,
      file.path(work,"missing_approvals.csv"),file.path(work,"validation"))
stopifnot(q$active_missing==3L,q$paper_gates_pass==0L,
   q$scientific_freeze=="HOLD")
# Proven absence is reported consistently in audit and finalize without
# shrinking the original target count or granting release.
absent<-lo_grid_from_tasks(tasks[1,,drop=FALSE])[c('cell_id','target_contract_sha256')]
absent$reason<-'Synthetic source has no requested field'
proof<-file.path(work,'source_absence_proof.txt');writeLines('synthetic absence',proof)
cert<-file.path(work,'source_absence.json')
jsonlite::write_json(list(status='SOURCE_UNAVAILABLE_VERIFIED',cells=absent,
 evidence_files=data.frame(path=proof,sha256=digest::digest(file=proof,algo='sha256'))),cert,auto_unbox=TRUE)
absent$evidence_path<-cert;absent$evidence_sha256<-digest::digest(file=cert,algo='sha256')
absence_file<-file.path(work,'SOURCE_UNAVAILABLE_CELLS.csv');write.csv(absent,absence_file,row.names=FALSE)
with_absence<-lo_final_quality_gate(bundle,tasks,file.path(work,'missing_approvals.csv'),file.path(work,'absence_validation'))
stopifnot(with_absence$scope_contracts==3L,with_absence$active_missing==2L,
 with_absence$documented_unavailable_source_fields==1L,with_absence$scientific_freeze=='HOLD')
writeLines('changed evidence',proof)
stopifnot(inherits(try(lo_final_quality_gate(bundle,tasks,file.path(work,'missing_approvals.csv'),file.path(work,'changed_absence')),silent=TRUE),'try-error'))
unlink(absence_file)
# A pending proposal must not force new peer estimates in the final gate.
scope_decisions<-lo_read_scope_decisions(".")
scope_decisions$status<-"PENDING"
scope_decisions$decision_date<-scope_decisions$user_evidence<-""
oldpeer<-tasks[1L,,drop=FALSE];oldpeer$metric_key<-"synthetic_high_peer"
oldpeer$contract_figure_id<-"EN_PERFORMANCE_PEER_age15_reading"
oldpeer$peer_definition<-"whole_school"
with_peer<-rbind(tasks,oldpeer)
pending_q<-lo_final_quality_gate(bundle,with_peer,
 file.path(work,"missing_approvals.csv"),file.path(work,"pending_peer"),scope_decisions)
stopifnot(pending_q$new_below_basic_peer_targets==0L,
 pending_q$active_missing==3L,
 pending_q$primary_peer_gate=="NOT_REQUIRED_BY_CURRENT_SCOPE")
scope_decisions$status[1L]<-"APPROVED"
scope_decisions$decision_date[1L]<-"2026-10-14"
scope_decisions$user_evidence[1L]<-"SYNTHETIC TEST ONLY: A01 yes"
approved_q<-lo_final_quality_gate(bundle,with_peer,
 file.path(work,"missing_approvals.csv"),file.path(work,"chosen_peer"),scope_decisions)
stopifnot(approved_q$new_below_basic_peer_targets==3L,
 approved_q$active_missing==6L,approved_q$primary_peer_gate=="HOLD",
 approved_q$scientific_freeze=="HOLD")
expanded<-rbind(with_peer,lo_scoped_low_peer_tasks(with_peer,scope_decisions))
expanded_q<-lo_final_quality_gate(bundle,expanded,
 file.path(work,"missing_approvals.csv"),file.path(work,"expanded_peer"),scope_decisions)
stopifnot(expanded_q$new_below_basic_peer_targets==3L,expanded_q$active_missing==6L)
# The same verified absence rule applies to low peers. It leaves the target
# count intact and cannot silently require an impossible result at finalize.
low<-lo_scoped_low_peer_tasks(with_peer,scope_decisions)
low_cells<-lo_grid_from_tasks(low)[c('cell_id','target_contract_sha256')];low_cells$reason<-'Synthetic verified empty source'
writeLines('synthetic peer absence',proof)
jsonlite::write_json(list(status='SOURCE_UNAVAILABLE_VERIFIED',cells=low_cells,
 evidence_files=data.frame(path=proof,sha256=digest::digest(file=proof,algo='sha256'))),cert,auto_unbox=TRUE)
low_cells$evidence_path<-cert;low_cells$evidence_sha256<-digest::digest(file=cert,algo='sha256')
write.csv(low_cells,absence_file,row.names=FALSE)
peer_absence<-lo_final_quality_gate(bundle,expanded,file.path(work,'missing_approvals.csv'),file.path(work,'peer_absence'),scope_decisions)
stopifnot(peer_absence$scope_contracts==nrow(expanded),peer_absence$new_below_basic_peer_targets==3L,
 peer_absence$documented_unavailable_low_peers==3L,peer_absence$active_missing==3L,
 peer_absence$primary_peer_gate=='DOCUMENTED_UNAVAILABLE',peer_absence$scientific_freeze=='HOLD')
unlink(absence_file)
candidate<-lo_fixed_produce(bundle,p3,tasks,
      file.path(work,"production"),native_run=FALSE)
stopifnot(candidate$native_execution=="PREVIEW_ONLY",
 candidate$scientific_release=="NOT_AUTOMATICALLY_VALIDATED")
Sys.setenv(LO_REPO_ROOT=normalizePath("."))
held<-lo_fixed_produce(bundle,p3,tasks,file.path(work,"held_production"),
 native_run=TRUE,grid=lo_grid_from_tasks(tasks))
stopifnot(held$native_execution=="NO_APPROVED_COMPUTE_CELLS")
# A complete synthetic approval has zero missing rows and must still check
# exact target/source/design identity before becoming review-eligible.
fixture<-lo_grid_from_tasks(tasks)
fixture$status<-"SCIENTIFICALLY_VALIDATED"
fixture$estimate<-490;fixture$standard_error<-3;fixture$n_unweighted<-500
fixture$sample_id<-"synthetic_sample";fixture$method_version<-"synthetic_method"
fixture$input_fingerprint<-fixture$code_fingerprint<-fixture$result_hash<-
 fixture$source_edition_sha256<-paste(rep("a",64),collapse="")
fixture$weight_design<-"synthetic_weights";fixture$pv_rule<-"synthetic_PVs"
fixture$variance_rule<-"synthetic_replicates"
source_fixture<-file.path(work,"synthetic_source.txt");writeLines("source-free test",source_fixture)
fixture$source_path<-source_fixture
fixture$source_edition_sha256<-digest::digest(file=source_fixture,algo="sha256")
cert_fixture<-file.path(work,"synthetic_result_certificate.json")
jsonlite::write_json(list(status="SCIENTIFICALLY_VALIDATED",cells=fixture,
 evidence_files=data.frame(path=source_fixture,sha256=fixture$source_edition_sha256)),cert_fixture,auto_unbox=TRUE,digits=16)
fixture$certification_path<-cert_fixture
fixture$certification_sha256<-digest::digest(file=cert_fixture,algo="sha256")
write.csv(fixture,file.path(work,"complete_approvals.csv"),row.names=FALSE)
source('06_pipeline/LO_PAPER_GATE_EVIDENCE.R')
paper_gates<-data.frame(requirement_id=sprintf('Q%02d',1:8),status='PASS')
stopifnot(inherits(try(lo_paper_gate_evidence(paper_gates,tasks,file.path(work,'complete_approvals.csv')),silent=TRUE),'try-error'))
target<-lo_grid_from_tasks(tasks)[c('cell_id','target_contract_sha256')];target<-target[order(target$cell_id),];rownames(target)<-NULL
paper_gates$evidence_path<-file.path(work,paste0(paper_gates$requirement_id,'.json'))
for(i in seq_len(nrow(paper_gates)))jsonlite::write_json(list(status='PASS',requirement_id=paper_gates$requirement_id[i],
 target_sha256=digest::digest(target,algo='sha256'),approval_sha256=digest::digest(file=file.path(work,'complete_approvals.csv'),algo='sha256'),
 assessment='Synthetic evidence test only; no real scientific approval',
 evidence_files=data.frame(path=source_fixture,sha256=digest::digest(file=source_fixture,algo='sha256'))),paper_gates$evidence_path[i],auto_unbox=TRUE)
paper_gates$evidence_sha256<-vapply(paper_gates$evidence_path,function(p)digest::digest(file=p,algo='sha256'),character(1))
write.csv(paper_gates,file.path(work,'SCIENTIFIC_PAPER_GATES.csv'),row.names=FALSE)
complete<-lo_final_quality_gate(bundle,tasks,file.path(work,"complete_approvals.csv"),
 file.path(work,"complete_quality"))
stopifnot(complete$active_missing==0L,
 complete$scientific_freeze=="ELIGIBLE_FOR_INDEPENDENT_REVIEW",
 complete$publication_authorized=="NO_RIGHTS_AND_REPLICATION_REVIEW_PENDING")
policy<-jsonlite::fromJSON('06_pipeline/review_20261013/PAPER_QA_CURRENT.json')$requirements
stopifnot(inherits(try(lo_final_quality_gate(bundle,tasks,file.path(work,'complete_approvals.csv'),file.path(work,'stale_policy'),paper_policy=policy),silent=TRUE),'try-error'))
for(i in seq_len(nrow(paper_gates))) {
 p<-paper_gates$evidence_path[i];cert<-jsonlite::fromJSON(p);cert$policy_sha256<-digest::digest(policy,algo='sha256')
 jsonlite::write_json(cert,p,auto_unbox=TRUE);paper_gates$evidence_sha256[i]<-digest::digest(file=p,algo='sha256')
}
write.csv(paper_gates,file.path(work,'SCIENTIFIC_PAPER_GATES.csv'),row.names=FALSE)
current_policy<-lo_final_quality_gate(bundle,tasks,file.path(work,'complete_approvals.csv'),file.path(work,'current_policy'),paper_policy=policy)
stopifnot(current_policy$paper_gates_pass==8L)
writeLines("changed source",source_fixture)
stopifnot(inherits(try(lo_final_quality_gate(bundle,tasks,
 file.path(work,"complete_approvals.csv"),file.path(work,"changed_source")),silent=TRUE),"try-error"))
writeLines("source-free test",source_fixture)
fixture$target_contract_sha256[1]<-paste(rep("b",64),collapse="")
write.csv(fixture,file.path(work,"complete_approvals.csv"),row.names=FALSE)
stopifnot(inherits(try(lo_final_quality_gate(bundle,tasks,
 file.path(work,"complete_approvals.csv"),file.path(work,"wrong_target")),silent=TRUE),
 "try-error"))
write.csv(data.frame(cell_id="m1",status="SCIENTIFICALLY_VALIDATED",
 estimate=490,standard_error=3,n_unweighted=5000,sample_id="pisa",
 input_fingerprint=paste(rep("a",64),collapse=""),
 code_fingerprint=paste(rep("b",64),collapse=""),
 result_hash=paste(rep("c",64),collapse="")),
 file.path(work,"approved.csv"),row.names=FALSE)
approved<-read.csv(file.path(work,"approved.csv"),stringsAsFactors=FALSE)
dash<-lo_dashboard_export_from_grid(bundle,tasks,approved,
            file.path(work,"dashboard"))
stopifnot(dash$mapped==1L,dash$unmapped==0L)
# Status must distinguish an empty approved queue from unfinished science,
# detect a changed selection/grid, and never mutate the audit or history.
source("06_pipeline/LO_FIXED_CONTROLLER.R",encoding="UTF-8")
source("06_pipeline/LO_RUN_CONFIG.R",encoding="UTF-8")
status_state<-file.path(work,"read_only_status");dir.create(status_state)
status_grid<-data.frame(cell_id=c("done","absent","pending"),status=c(
  "SCIENTIFICALLY_VALIDATED","UNAVAILABLE_VERIFIED_SOURCE_FIELDS","TARGET_NOT_YET_ADJUDICATED"))
status_grid_path<-file.path(status_state,"PRIVATE_MASTER_GRID.csv")
write.csv(status_grid,status_grid_path,row.names=FALSE)
status_cfg<-lo_run_config("nld_only","")
config_path<-file.path(work,"status_config.json")
jsonlite::write_json(status_cfg,config_path,auto_unbox=TRUE)
prior_config<-Sys.getenv("LO_RUN_CONFIG",unset=NA_character_);Sys.setenv(LO_RUN_CONFIG=config_path)
jsonlite::write_json(list(configuration=status_cfg,
  sha256=list(run_configuration=lo_run_config_hash(status_cfg)),
  grid_sha256=digest::digest(file=status_grid_path,algo="sha256")),
  file.path(status_state,"FIXED_INPUT_MANIFEST.json"),auto_unbox=TRUE)
status_paths<-list.files(status_state,full.names=TRUE)
before_status<-vapply(status_paths,function(p)digest::digest(file=p,algo="sha256"),character(1))
current_status<-lo_fixed_status_summary(".",status_state,"nld_only")
stopifnot(current_status$targets==3L,current_status$validated==1L,
 current_status$unavailable==1L,current_status$remaining==1L,current_status$approved_compute_cells==0L,
 current_status$configuration=="MATCH",current_status$grid=="MATCH",
 current_status$scientific_readiness=="NOT_ESTABLISHED_BY_STATUS",
 identical(status_paths,list.files(status_state,full.names=TRUE)),
 identical(before_status,vapply(status_paths,function(p)digest::digest(file=p,algo="sha256"),character(1))))
status_cfg$selection$years<-"2022";jsonlite::write_json(status_cfg,config_path,auto_unbox=TRUE)
stopifnot(lo_fixed_status_summary(".",status_state,"nld_only")$configuration=="CHANGED_REAUDIT_REQUIRED")
status_grid$status[3]<-"SCIENTIFICALLY_VALIDATED";write.csv(status_grid,status_grid_path,row.names=FALSE)
stopifnot(lo_fixed_status_summary(".",status_state,"nld_only")$grid=="CHANGED_REAUDIT_REQUIRED")
if(is.na(prior_config))Sys.unsetenv("LO_RUN_CONFIG")else Sys.setenv(LO_RUN_CONFIG=prior_config)
unlink(work,recursive=TRUE)
cat("PASS historical scope fixtures, scientific gates, no-compute preview and dashboard mapping\n")

