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
 jsonlite::write_json(list(status="SCIENTIFICALLY_VALIDATED",cells=rows,
   evidence_files=data.frame(path=raw,sha256=digest::digest(file=raw,algo="sha256"))),cert,auto_unbox=TRUE,digits=NA)
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
other$method_version<-'SYNTHETIC_PEER_PV_FRAME_N_TARGET_COUNTS_V1'
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
stopifnot(low$n_definition=='ANALYTIC_PEER_FRAME; TARGET_N_SEPARATE_FOR_EACH_PV')
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
# Source-specific placeholders resolve only to the certified PISA construct.
lf<-f[c(1,1),,drop=FALSE];lf$figure_id<-c("GP_LANGUAGE_LEVELS_age15_reading","GP_LANGUAGE_GAP_age15_reading")
lf$expected_series<-c("source_valid_groups","source_valid_contrast")
write.csv(lf,file.path(bundle,"FIGURE_SERIES_CONTRACT_20261002.csv"),row.names=FALSE)
lt<-tasks[rep(1,4),,drop=FALSE];lt$metric_key<-paste0("lang",1:4)
lt$module<-"language_exact";lt$stat<-c("mean","mean","gap","mean")
lt$group<-c("test_language_home","other_language_home","other_minus_test","test_language_home")
lt$definition<-c(rep("same_as_assessment_language_vs_other",3),"unverified_dutch_vs_other")
lt$contract_figure_id<-lf$figure_id[c(1,1,2,1)]
la<-approved[rep(1,4),,drop=FALSE];la$cell_id<-lt$metric_key
la$target_contract_sha256<-lo_grid_from_tasks(lt)$target_contract_sha256
la$estimate<-c(500,480,-20,500);la<-certify(la,"language")
language_out<-file.path(work,"language")
language_result<-lo_guided_grid_export(bundle,lt,la,language_out)
stopifnot(language_result$guided_focus_rows==3L,language_result$mapping_holds==1L)
language_rows<-read.csv(file.path(language_out,"PRIVATE_GUIDED_VALIDATED_ROWS.csv"))
stopifnot(identical(language_rows$series_id,lt$group[1:3]),
 identical(as.numeric(language_rows$estimate),c(500,480,-20)),
 all(language_rows$outcome_id=="same_as_assessment_language_vs_other"))
language_holds<-read.csv(file.path(language_out,"PRIVATE_GUIDED_MAPPING_HOLDS.csv"))
stopifnot(language_holds$cell_id=="lang4")
# An approved appendix statistic remains available in its separate export,
# without appearing as a dashboard choice or a missing-method hold.
af<-f[1,,drop=FALSE];af$figure_id<-"GP_SES_HIGH_age15_reading";af$expected_series<-"q1"
write.csv(af,file.path(bundle,"FIGURE_SERIES_CONTRACT_20261002.csv"),row.names=FALSE)
at<-tasks[1,,drop=FALSE];at$metric_key<-"appendix_high";at$contract_figure_id<-af$figure_id
at$module<-"ses_national";at$stat<-"q1_high";at$group<-"q1"
aa<-approved[1,,drop=FALSE];aa$cell_id<-at$metric_key
aa$target_contract_sha256<-lo_grid_from_tasks(at)$target_contract_sha256;aa<-certify(aa,"appendix")
appendix_out<-file.path(work,"appendix")
appendix_result<-lo_guided_grid_export(bundle,at,aa,appendix_out,lo_read_scope_decisions("."))
stopifnot(appendix_result$guided_focus_rows==0L,appendix_result$mapping_holds==0L,
 appendix_result$separate_appendix_or_science_rows==1L,
 nrow(read.csv(file.path(appendix_out,"PRIVATE_APPROVED_EXTENSION_ROWS.csv")))==1L)
sf<-f[1,,drop=FALSE];sf$figure_id<-"EN_SES_PEER_age15_all_whole_school"
sf$domain<-"all";sf$expected_series<-"q1_target_pct_q4_peers;q4_target_pct_q1_peers"
sf$required_years<-"2015;2018;2022;2025 if SES; all PISA waves for language/migration where valid"
write.csv(sf,file.path(bundle,"FIGURE_SERIES_CONTRACT_20261002.csv"),row.names=FALSE)
st<-tasks[rep(1,3),,drop=FALSE];st$metric_key<-paste0('ses_context',1:3)
st$contract_figure_id<-sf$figure_id;st$domain<-"all";st$unit<-"percent"
st$definition<-"Cobreros_fourwave_13item_trend_comparable"
st$module<-c("ses_peer_exposure",rep("peer_baseline",2))
st$stat<-c("q1_target_pct_q4_peers","q1_share","q4_share")
st$group<-c(st$stat[1],"total","total")
sa<-approved[rep(1,3),,drop=FALSE];sa$cell_id<-st$metric_key
sa$estimate<-c(12,24.9,25.1)
sa$target_contract_sha256<-lo_grid_from_tasks(st)$target_contract_sha256
sa<-certify(sa,"ses_context");so<-file.path(work,"ses_context")
sx<-lo_guided_grid_export(bundle,st,sa,so)
sr<-read.csv(file.path(so,"PRIVATE_GUIDED_VALIDATED_ROWS.csv"))
stopifnot(sx$mapping_holds==0L,nrow(sr)==3L,
 identical(sr$series_id,c(st$stat[1],"population_q1_share","population_q4_share")),
 identical(sr$estimate,sa$estimate),identical(sr$result_hash,sa$result_hash))
mf<-sf;mf$figure_id<-"EN_MIGRATION_PEER_age10_all_whole_school";mf$survey<-"PIRLS_TIMSS"
mf$expected_series<-"source_valid_target/reference_groups";mf$required_years<-"PIRLS:2001;2006;2011;2016;2021 | TIMSS:2003;2007;2011;2015;2019;2023"
write.csv(mf,file.path(bundle,"FIGURE_SERIES_CONTRACT_20261002.csv"),row.names=FALSE)
mt<-st[rep(1,4),];mt$metric_key<-paste0('migration_context',1:4);mt$survey<-c('PIRLS','PIRLS','TIMSS','TIMSS');mt$year<-'2011'
mt$contract_figure_id<-mf$figure_id;mt$module<-'peer_baseline';mt$stat<-'reference_share';mt$group<-'total'
mt$definition<-rep(c('MIGRATION_ANY_PARENT_ABROAD','MIGRATION_BOTH_PARENTS_ABROAD'),2)
ma<-approved[rep(1,4),];ma$cell_id<-mt$metric_key;ma$target_contract_sha256<-lo_grid_from_tasks(mt)$target_contract_sha256;ma<-certify(ma,'migration_context')
mo<-file.path(work,'migration_context');mx<-lo_guided_grid_export(bundle,mt,ma,mo)
mr<-read.csv(file.path(mo,'PRIVATE_GUIDED_VALIDATED_ROWS.csv'))
stopifnot(mx$mapping_holds==0L,nrow(mr)==4L,length(unique(mr$figure_id))==4L,all(mr$series_id=='population_reference_share'),identical(mr$outcome_id,mt$definition))
unlink(work,recursive=TRUE)
cat("PASS validated guided export, fixed source IDs and high-peer exclusion\n")

