for(p in c("MASTER_ESTIMATION_GRID.R","LO_SCOPE_DECISIONS.R","LO_COMPACT_GRID_STORE.R",
            "LO_COMPACT_RECOMPUTE.R","LO_EXACT_DISPATCH.R"))source(file.path("06_pipeline",p))
work<-tempfile("exact_dispatch_");dir.create(work)
on.exit_cleanup<-function()unlink(work,recursive=TRUE)
sha<-function(x)paste(rep(x,64),collapse="")
tasks<-data.frame(metric_key=c("chosen","not_approved","foreign"),country=c("NLD","NLD","AUT"),
 survey="PISA",year="2022",domain="reading",module="core",stat="mean",group="total",
 definition="score",peer_definition="",threshold="",unit="score_points",calculation_policy="",
 contract_figure_id="TR_MEAN_age15_reading",stringsAsFactors=FALSE)
obj<-list(data=data.frame(x=c(1,2,3)),meta=list(survey="PISA",year="2022",v9_country="NLD"))
src<-file.path(work,"canonical.rds");saveRDS(obj,src)
evidence<-file.path(work,"method.txt");writeLines("Synthetic source-free method verification",evidence)
grid<-lo_grid_from_tasks(tasks)
grid$status[1]<-"COMPUTE_REQUIRED_AFTER_METHOD_GATE"
grid$source_path[1]<-src;grid$source_edition_sha256[1]<-lo_exact_sha(src)
grid$input_fingerprint[1]<-sha("a");grid$code_fingerprint[1]<-sha("b")
grid$sample_id[1]<-"synthetic_sample";grid$method_version[1]<-"synthetic_method"
grid$weight_design[1]<-"synthetic_weights";grid$pv_rule[1]<-"synthetic_PV";grid$variance_rule[1]<-"synthetic_variance"
fields<-c("sample_id","method_version","weight_design","pv_rule","variance_rule",
 "source_edition_sha256","input_fingerprint","code_fingerprint")
cert<-c(list(status="METHOD_SAMPLE_INPUT_CERTIFIED",cell_ids="chosen"),as.list(grid[1,fields]))
cert$evidence_files<-data.frame(path=evidence,sha256=lo_exact_sha(evidence))
cert_path<-file.path(work,"certificate.json")
jsonlite::write_json(cert,cert_path,auto_unbox=TRUE)
grid$certification_path[1]<-cert_path;grid$certification_sha256[1]<-lo_exact_sha(cert_path)
calls<-new.env();calls$reads<-0L;calls$computed<-character()
backend<-list(code_sha=sha("b"),read=function(path){calls$reads<-calls$reads+1L;readRDS(path)},
 projection=function(obj,q)sha("a"),estimate=function(obj,q){calls$computed<-c(calls$computed,q$metric_key);q$estimate<-500;q$se<-2;q},
 count=function(obj,q)rep(3L,nrow(q)))
scope<-list(scope="nld_only",selected="NLD")
out<-file.path(work,"result")
a<-lo_exact_dispatch(".",work,scope,tasks,grid,out,backend)
stopifnot(a$new_rows_written==1L,a$holds_this_attempt==0L,
 identical(calls$computed,"chosen"),calls$reads==1L)
b<-lo_exact_dispatch(".",work,scope,tasks,grid,out,backend)
stopifnot(b$new_rows_written==0L,b$reused_rows==1L,calls$reads==1L)
# Changed raw bytes cannot reuse a receipt or execute an estimator.
saveRDS(list(changed=TRUE),src)
c<-lo_exact_dispatch(".",work,scope,tasks,grid,out,backend)
stopifnot(c$holds_this_attempt==1L,calls$reads==1L)
saveRDS(obj,src)
wrong<-grid;wrong$target_contract_sha256[1]<-sha("f")
stopifnot(inherits(try(lo_exact_dispatch(".",work,scope,tasks,wrong,out,backend),silent=TRUE),"try-error"))
bad_backend<-backend;bad_backend$code_sha<-sha("c")
d<-lo_exact_dispatch(".",work,scope,tasks,grid,out,bad_backend)
stopifnot(d$holds_this_attempt==1L,calls$reads==1L)
bad_backend<-backend;bad_backend$projection<-function(obj,q)sha("d")
e<-lo_exact_dispatch(".",work,scope,tasks,grid,file.path(work,"wrong_input"),bad_backend)
stopifnot(e$new_rows_written==0L,e$holds_this_attempt==1L)
# Estimator cannot smuggle extra result keys into the store.
bad_backend<-backend;bad_backend$estimate<-function(obj,q){q$estimate<-500;q$se<-2;rbind(q,transform(q,metric_key="unapproved"))}
f<-lo_exact_dispatch(".",work,scope,tasks,grid,file.path(work,"extra_key"),bad_backend)
stopifnot(f$new_rows_written==0L,f$holds_this_attempt==1L)
empty<-grid;empty$status<-"TARGET_NOT_YET_ADJUDICATED"
z<-lo_exact_dispatch(".",work,scope,tasks,empty,file.path(work,"empty"),backend)
stopifnot(z$status=="NO_APPROVED_COMPUTE_CELLS",z$new_rows_written==0L)
# An interrupted two-unit run resumes only its missing unit; completed work
# remains protected by the exact execution receipt, not a coarse done flag.
t2<-tasks[1:2,];t2$domain[2]<-"mathematics"
g2<-grid[rep(1,2),];g2$cell_id<-t2$metric_key
g2$target_contract_sha256<-lo_grid_from_tasks(t2)$target_contract_sha256
cert$cell_ids<-t2$metric_key
jsonlite::write_json(cert,cert_path,auto_unbox=TRUE)
g2$certification_sha256<-lo_exact_sha(cert_path)
resumed_out<-file.path(work,"resume")
r1<-lo_exact_dispatch(".",work,scope,t2,g2,resumed_out,backend,max_units=1L)
r2<-lo_exact_dispatch(".",work,scope,t2,g2,resumed_out,backend,max_units=1L)
r3<-lo_exact_dispatch(".",work,scope,t2,g2,resumed_out,backend,max_units=1L)
stopifnot(r1$new_rows_written==1L,r1$status=="PARTIAL_CHECKPOINT",
 r2$new_rows_written==1L,r2$reused_rows==1L,r3$new_rows_written==0L,r3$reused_rows==2L)
# Even a newly signed source byte hash does not make the wrong country valid.
wrong_obj<-obj;wrong_obj$meta$v9_country<-"AUT";saveRDS(wrong_obj,src)
g2$source_edition_sha256<-lo_exact_sha(src)
cert$source_edition_sha256<-lo_exact_sha(src)
jsonlite::write_json(cert,cert_path,auto_unbox=TRUE)
g2$certification_sha256<-lo_exact_sha(cert_path)
bad<-lo_exact_dispatch(".",work,scope,t2,g2,file.path(work,"wrong_identity"),backend)
stopifnot(bad$new_rows_written==0L,bad$holds_this_attempt==2L)
on.exit_cleanup()
cat("PASS exact approval dispatch, bounded read/write set, idempotence, changed source/code/input, extra output rejection\n")
