source("06_pipeline/LO_COMPACT_GRID_STORE.R",encoding="UTF-8")
root<-tempfile("lo_compact_store_");dir.create(root)
db<-lo_compact_open(root)
on.exit(try(lo_compact_close(db),silent=TRUE),add=TRUE)
sha<-function(c)paste(rep(c,64L),collapse="")
make_row<-function(estimate=504.1234567890123, input=sha("a"), status="COMPUTED_PENDING_VALIDATION") {
  data.frame(cell_id="NLD|PISA|2022|reading|core|mean",survey="PISA",
    country="NLD",year="2022",domain="reading",module="core",
    stat="mean",subgroup="total",definition="total",unit="score_points",
    peer_environment="",threshold="",estimate=estimate,standard_error=3.123456789,
    n_unweighted=5000L,input_fingerprint=input,
    producer_fingerprint=sha("b"),method_id="TEST_PV_REPLICATE",
    status=status,hold_reason=if(status=="HOLD")"Missing source" else "",
    stringsAsFactors=FALSE)
}
stopifnot(lo_compact_put(db,make_row())$written==1L)
stopifnot(isTRUE(lo_compact_known(db,make_row()$cell_id,sha("a"),sha("b"),"TEST_PV_REPLICATE")))
stopifnot(lo_compact_put(db,make_row())$reused==1L)
stopifnot(DBI::dbGetQuery(db,"SELECT COUNT(*) AS n FROM result_versions")$n==1L)
conflict<-try(lo_compact_put(db,make_row(506)),silent=TRUE)
stopifnot(inherits(conflict,"try-error"))
# Incomplete replay of unchanged science may not erase the completed record.
stopifnot(lo_compact_put(db,make_row(status="HOLD"))$written==0L)
# Change in input identity must not silently retain stale results as current.
stopifnot(lo_compact_put(db,make_row(status="HOLD",input=sha("c")))$written==1L)
stopifnot(!lo_compact_known(db,make_row()$cell_id,sha("a"),sha("b"),"TEST_PV_REPLICATE"))
stopifnot(lo_compact_put(db,make_row(input=sha("c")))$written==1L)
stopifnot(DBI::dbGetQuery(db,"SELECT COUNT(*) AS n FROM result_versions")$n==2L)
history<-DBI::dbGetQuery(db,"SELECT * FROM result_versions ORDER BY input_fingerprint")
stopifnot(identical(history$estimate,c(make_row()$estimate,make_row()$estimate)))
bad<-make_row();bad$n_unweighted<-NA_integer_
stopifnot(inherits(try(lo_compact_put(db,bad),silent=TRUE),"try-error"))
bad<-make_row();bad$standard_error<--1
stopifnot(inherits(try(lo_compact_put(db,bad),silent=TRUE),"try-error"))
summary<-lo_compact_export(db,root)
stopifnot(summary$rows==1L,summary$complete==1L,
  file.exists(file.path(root,"COMPACT_MASTER_GRID.sqlite")),
  file.exists(file.path(root,"COMPACT_MASTER_GRID.csv.gz")),
  file.exists(file.path(root,"COMPACT_DASHBOARD_ROUNDED.csv.gz")))
full<-read.csv(gzfile(file.path(root,"COMPACT_MASTER_GRID.csv.gz")))
display<-read.csv(gzfile(file.path(root,"COMPACT_DASHBOARD_ROUNDED.csv.gz")))
stopifnot(full$unit[1]=="score_points",abs(full$estimate[1]-504.1234567890123)<1e-9,
  display$estimate[1]==504.1,display$standard_error[1]==3.12,
  full$n_unweighted[1]==5000L,
  summary$full_csv_bytes < 20000)
stopifnot(identical(full$estimate[[1]],make_row()$estimate[[1]]),
  identical(full$standard_error[[1]],make_row()$standard_error[[1]]))
pr<-make_row(0.12345678901234567);pr$cell_id<-"proportion";pr$unit<-"proportion"
lo_compact_put(db,pr);lo_compact_export(db,root)
display<-read.csv(gzfile(file.path(root,"COMPACT_DASHBOARD_ROUNDED.csv.gz")))
stopifnot(display$unit[display$cell_id=="proportion"]=="percent",
  display$estimate[display$cell_id=="proportion"]==12.3)
lo_compact_export(db,root,selected_ids="proportion")
limited<-read.csv(gzfile(file.path(root,"COMPACT_MASTER_GRID.csv.gz")))
stopifnot(identical(limited$cell_id,"proportion"),
  DBI::dbGetQuery(db,"SELECT COUNT(*) AS n FROM grid")$n==2L)
lo_compact_close(db)
unlink(root,recursive=TRUE)
cat("PASS compact ledger: exact N, SE, fingerprint-resume, changed-source invalidation, rounded export\n")

