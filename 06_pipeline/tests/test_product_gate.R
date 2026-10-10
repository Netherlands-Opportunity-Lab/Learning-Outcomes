# Synthetic survey/figure contract smoke; no pupil files or R packages needed.
source("06_pipeline/PRODUCT_SCOPE_GATE.R",encoding="UTF-8")
root <- tempfile("lo_product_gate_")
dir.create(root)
dir.create(file.path(root,"engine"))
write_gate <- function(z,name,compressed=FALSE) {
  p<-file.path(root,name)
  if(compressed) {
    con<-gzfile(p,"wt")
    write.csv(z,con,row.names=FALSE,na="")
    close(con)
  } else write.csv(z,p,row.names=FALSE,na="")
}
outcomes <- c("mean_score","p10","p50","p90","ses_mean_levels",
  "ses_score_gap","ses_basic_levels","gender_mean_levels",
  "home_language_mean_levels","migration_mean_levels","ses_peer_exposure",
  "home_language_peer_exposure","migration_peer_exposure")
n <- length(outcomes)
fields <- c("country","survey","year","domain","module","stat","group",
            "definition","peer_definition","threshold","unit","calculation_policy")
task <- data.frame(country=c(rep("NLD",n-2L),"AUS","BGR"),
 survey=rep("PISA",n),year=rep("2015",n),domain=rep("reading",n),
 module=rep("core",n),stat=paste0("test",seq_len(n)),group=rep("total",n),
 definition=rep("total",n),peer_definition=rep("",n),threshold=rep("",n),
 unit=rep("score_points",n),calculation_policy=rep("",n),
 stringsAsFactors=FALSE)
task$metric_key<-do.call(paste,c(task[fields],sep="|"))
fid <- paste0("F",seq_len(n))
task$contract_figure_id<-fid
write_gate(task,"engine/TASKS.csv")
fig <- data.frame(figure_id=c(fid,"TR_POSITION_age15_reading"),
 survey=rep("PISA",n+1L),age=rep("age15",n+1L),
 domain=rep("reading",n+1L),
 outcome=c(outcomes,"international_position_mean"),
 release_role=rep("Required",n+1L),
 comparison_default=rep("OECD_HIGH_INCOME_FY2027",n+1L))
write_gate(fig,"FIGURE_SERIES_CONTRACT_20261002.csv")
write_gate(data.frame(metric_key=task$metric_key,contract_figure_id=fid),
 "PRODUCT_FIGUUR_RESULTAAT.csv.gz",TRUE)
write_gate(data.frame(requirement_id=sprintf("Q%02d",1:8),
 action=rep("REVIEW",8)),"OPEN_PAPER_REQUIREMENTS.csv")
members<-c("NLD","CZE","AUS","AUT","BEL","CAN","CHE","DEU","DNK",
 "ESP","FIN","FRA","GBR","IRL","ISL","ITA","KOR","LUX","NOR","SWE","USA")
sig<-do.call(paste,c(task[n-1L,fields,drop=FALSE],sep="|"))
write_gate(data.frame(reference="OECD_GDP_PPP_GE_CZE_2024",
 series_id=sig,years="2015",eligible_members=paste(members,collapse=";")),
 "REFERENTIE_ASSEMBLAGE.csv.gz",TRUE)
write_gate(data.frame(country=members,
 strictly_above_czechia=ifelse(members=="CZE","FALSE","TRUE")),
 "PPP_COMPARATOR_MEMBERSHIP_v2.csv")
expected<-list(tasks=n,figures=n+1L,paper=8L,refs=1L,
 nld=n-2L,oecd19=1L,other=1L,ranks=1L)
res<-lo_product_gate(root,tempdir(),expected=expected)
stopifnot(length(res$positions)==1L,
 identical(unname(as.integer(res$counts)),c(n-2L,1L,1L)),
 file.exists(file.path(res$report_dir,"SLIDE_13_REQUIREMENT_STATUS.csv")))
# Regression: missing one metric-product link must fail closed.
write_gate(data.frame(metric_key=task$metric_key[-1L],
 contract_figure_id=fid[-1L]),"PRODUCT_FIGUUR_RESULTAAT.csv.gz",TRUE)
err<-try(lo_product_gate(root,tempdir(),expected=expected),silent=TRUE)
stopifnot(inherits(err,"try-error"))
unlink(root,recursive=TRUE)
cat("PASS product/figure mapping and deliberate loss regression\n")
