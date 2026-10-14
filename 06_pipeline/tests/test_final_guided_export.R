source("06_pipeline/MASTER_ESTIMATION_GRID.R")
source("06_pipeline/LO_FINAL_GUIDED_EXPORT.R")
source("06_pipeline/GRID_ARCHIVE_BATCH.R")
source("06_pipeline/LO_SCOPE_DECISIONS.R")
Sys.setenv(LO_SYNTHETIC_GUIDED_TEST="YES")
work<-tempfile("guided_export_");dir.create(work)
bundle<-file.path(work,"bundle");dir.create(bundle)
f<-data.frame(figure_id=c("TR_MEAN_age15_reading",
 "EN_PERFORMANCE_PEER_age15_reading_direct_learning_environment"),
 expected_series=c("total","self_below_high;self_high"),
 survey="PISA",domain="reading",required_years="2025",
 stringsAsFactors=FALSE)
write.csv(f,file.path(bundle,"FIGURE_SERIES_CONTRACT_20261002.csv"),
          row.names=FALSE)
tasks<-data.frame(metric_key=c("a","b"),country="NLD",survey="PISA",
 year="2025",domain="reading",module="core",stat="mean",
 group=c("total","self_high"),definition="mean_score",
 contract_figure_id=f$figure_id,stringsAsFactors=FALSE)
tasks$peer_definition<-"";tasks$threshold<-"";tasks$unit<-"score_points";tasks$calculation_policy<-""
sha<-function(x)paste(rep(x,64),collapse="")
approved<-data.frame(cell_id=c("a","b"),status="SCIENTIFICALLY_VALIDATED",
 estimate=c(500,35),standard_error=c(2.4,1.1),
 n_unweighted=c(5500,5500),sample_id="NLD_PISA_2025",
 method_version="certified",input_fingerprint=sha("a"),
 code_fingerprint=sha("b"),result_hash=c(sha("c"),sha("d")))
approved$target_contract_sha256<-lo_grid_from_tasks(tasks)$target_contract_sha256
approved$source_edition_sha256<-sha("a")
approved$weight_design<-"fixture";approved$pv_rule<-"fixture";approved$variance_rule<-"fixture"
certify<-function(rows,label) {
 raw<-file.path(work,paste0(label,"_source.txt"));writeLines("SYNTHETIC source",raw)
 rows$source_path<-raw;rows$source_edition_sha256<-digest::digest(file=raw,algo="sha256")
 cert<-file.path(work,paste0(label,"_certificate.json"))
 jsonlite::write_json(list(status="SCIENTIFICALLY_VALIDATED",cells=rows),cert,auto_unbox=TRUE,digits=NA)
 rows$certification_path<-cert;rows$certification_sha256<-digest::digest(file=cert,algo="sha256")
 rows
}
approved<-certify(approved,"base")
out<-file.path(work,"out")
q<-lo_guided_grid_export(bundle,tasks,approved,out)
stopifnot(q$validated_input_cells==2L,q$guided_focus_rows==1L,
 q$mapping_holds==1L)
z<-read.csv(file.path(out,"PRIVATE_GUIDED_VALIDATED_ROWS.csv"))
stopifnot(nrow(z)==1L,z$figure_id=="TR_MEAN_age15_reading",
 z$n_unweighted==5500,z$series_id=="total")
hold<-read.csv(file.path(out,"PRIVATE_GUIDED_MAPPING_HOLDS.csv"))
stopifnot(hold$reason=="OLD_HIGH_PEER_CANNOT_FILL_PRIMARY_BELOW_BASIC")
# A separately certified BELOW-basic peer result is accepted; the old
# high-peer result remains excluded despite having numeric evidence.
peer<-tasks[2,,drop=FALSE]
peer$metric_key<-"NEW_PEER_BELOW_BASIC|NLD|PISA|2025|reading|direct|self_below_basic"
peer$module<-"peer_below_basic"
peer$stat<-"peer_share_below_basic"
peer$group<-"self_below_basic"
peer$definition<-"below_basic_exclude_self_direct_or_school"
tasks2<-rbind(tasks,peer)
approved2<-approved
for(field in c("peer_denominator_verified","self_exclusion_verified",
               "method_certification_status"))
  approved2[[field]]<-""
other<-approved2[2,,drop=FALSE]
other$cell_id<-peer$metric_key
other$target_contract_sha256<-lo_grid_from_tasks(peer)$target_contract_sha256
other$estimate<-12.5
other$standard_error<-1.2
other$result_hash<-sha("e")
for(field in c("peer_denominator_verified","self_exclusion_verified",
               "method_certification_status"))
  other[[field]]<-"PASS"
approved2<-rbind(approved2,other)
approved2<-certify(approved2,"peers")
out2<-file.path(work,"out_peer")
decisions<-lo_read_scope_decisions(".")
decisions$status<-"PENDING";decisions$decision_date<-"";decisions$user_evidence<-""
decisions$status[1]<-"APPROVED";decisions$decision_date[1]<-"2026-10-14";decisions$user_evidence[1]<-"SYNTHETIC TEST ONLY"
presult<-lo_guided_grid_export(bundle,tasks2,approved2,out2,decisions)
stopifnot(presult$guided_focus_rows==2L,presult$mapping_holds==1L)
result2<-read.csv(file.path(out2,"PRIVATE_GUIDED_VALIDATED_ROWS.csv"))
low<-result2[result2$series_id=="self_below_basic",,drop=FALSE]
stopifnot(nrow(low)==1L,low$outcome_id=="peer_share_below_basic",
          low$self_exclusion_verified=="PASS",
          low$peer_denominator_verified=="PASS")
wrong<-approved2;wrong$estimate[1]<-wrong$estimate[1]+1
stopifnot(inherits(try(lo_guided_grid_export(bundle,tasks2,wrong,file.path(work,"changed"),decisions),silent=TRUE),"try-error"))
fake_repo<-file.path(work,"repo");dir.create(file.path(fake_repo,"05_publication","preview_overlay","assets"),recursive=TRUE)
dir.create(file.path(fake_repo,"06_pipeline"))
css<-file.path(fake_repo,"05_publication","preview_overlay","assets","styles.css")
writeLines("body {color: black}",css)
h1<-lo_guided_preview_fingerprint(fake_repo,bundle,out2)
writeLines("body {color: blue}",css)
h2<-lo_guided_preview_fingerprint(fake_repo,bundle,out2)
stopifnot(h1!=h2)
writeLines("changed reference",file.path(out2,"BALANCED_REFERENCE_EXPORT.json"))
stopifnot(h2!=lo_guided_preview_fingerprint(fake_repo,bundle,out2))
unlink(work,recursive=TRUE)
cat("PASS validated guided export, fixed source IDs and high-peer exclusion\n")

