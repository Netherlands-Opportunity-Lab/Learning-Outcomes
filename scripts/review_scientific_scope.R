# Read-only aggregate/source-identity review; not another production runner.
# Rscript scripts/review_scientific_scope.R <repo> <private-root> <source-bundle>
args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)==3L)
repo<-normalizePath(args[1],winslash='/');root<-normalizePath(args[2],winslash='/')
bundle<-normalizePath(args[3],winslash='/')
work<-file.path(root,'scientific_review_20261019')
read<-function(p)read.csv(p,colClasses='character',na.strings=character(),check.names=FALSE)
sha<-function(p)digest::digest(file=p,algo='sha256')
for(n in c('LO_BALANCED_MEMBERSHIP.R','LO_COUNTRY_REGISTRY.R','LO_SCOPE_DECISIONS.R','LO_PRODUCT_TRACE.R'))
  source(file.path(repo,'06_pipeline',n))
tasks<-read(file.path(work,'snapshot/product_export/PRIVATE_TASKS.csv'))
gp<-file.path(work,'REVIEWED_MASTER_GRID.csv')
if(!file.exists(gp))gp<-file.path(root,'FIXED_PRODUCTION_V1/all_required/PRIVATE_MASTER_GRID.csv')
grid<-read(gp)
stopifnot(setequal(tasks$metric_key,grid$cell_id))
out<-file.path(work,'product_trace');dir.create(out,showWarnings=FALSE)
trace<-lo_product_trace(repo,tasks,grid,lo_read_scope_decisions(repo),out)
stopifnot(sum(trace$product=='PAPER_REGISTERED_CLAIM')==12L)
public<-file.path(repo,'06_pipeline/review_20261013/scientific_review')
support_path<-file.path(root,'master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv')
support<-lo_read_source_support(support_path,repo)
country_path<-file.path(public,'COUNTRY_REVIEW.csv')
countries<-read(country_path)
info<-lo_support_eligibility(support,countries$country)
write.csv(info$countries,file.path(public,'VERIFIED_COUNTRY_ADMISSION.csv'),row.names=FALSE)
write.csv(info$detail,file.path(public,'VERIFIED_COUNTRY_SIX_COMBINATIONS.csv'),row.names=FALSE)
write.csv(info$detail,file.path(public,'COUNTRY_SIX_COMBINATIONS.csv'),row.names=FALSE)
countries$proposed_dashboard_admission<-info$countries$dashboard_eligible[match(countries$country,info$countries$country)]
countries$quality_note[countries$country=='AUT']<-'PISA 2009 boycott/motivation qualification: retained historical target, excluded from comparable trend support. Full focus anchor is not shortened.'
countries$quality_note[countries$country=='ESP']<-'PISA 2018 exam-timing/motivation qualification: retained historical target, excluded from comparable trend support. Full focus anchor is not shortened.'
regions<-read(file.path(public,'REGIONAL_SOURCE_IDENTITIES.csv'))
countries$entity_kind<-ifelse(countries$country%in%c('HKG','TWN'),'CONSISTENT_PARTICIPATING_EDUCATION_SYSTEM',
  ifelse(countries$country%in%regions$country & !countries$proposed_dashboard_admission,'REVIEWED_SOURCE_CODE_NOT_AUTOMATICALLY_A_COUNTRY','NATIONAL_CANDIDATE'))
write.csv(countries,country_path,row.names=FALSE)
runtime<-lo_runtime_scope(bundle,read(file.path(bundle,'engine/TASKS.csv')),'all_required',support)
anchor<-read(file.path(repo,'06_pipeline/review_20261013/NLD_POLICY_CORE_YEAR_ANCHOR.csv'))
core<-support[support$country=='NLD',]
required<-lo_focus_required_support(core,core[FALSE,],'NLD',anchor)
keys<-sort(unique(lo_balance_key(required)));source_keys<-lo_balance_key(support)
reference<-do.call(rbind,lapply(countries$country,function(country) {
  missing<-setdiff(keys,source_keys[support$country==country])
  data.frame(country=country,focus_country='NLD',required_cells=length(keys),
    covered_cells=length(keys)-length(missing),missing_cells=length(missing),
    eligible=country!='NLD' && !length(missing),missing_keys=paste(missing,collapse=';'))
}))
# This is a verified source-support audit. Q06 separately checks result support
# and derives actual reference values; source availability is not an estimate.
reference$dashboard_admitted<-info$countries$dashboard_eligible[match(reference$country,info$countries$country)]
reference$eligible<-reference$eligible & reference$dashboard_admitted
reference$rich_candidate<-reference$country%in%runtime$comparator
write.csv(reference,file.path(public,'NLD_CORE_REFERENCE_REVIEW.csv'),row.names=FALSE)
jsonlite::write_json(list(result_basis='ac9f0bdb15b5bf3fcf843f3e4f857995d182aef2',
  candidate_count=nrow(countries),eligible_count=sum(countries$proposed_dashboard_admission),
  candidate_entities_are_not_all_sovereign_countries=TRUE,
  rich_pool_unchanged=runtime$comparator,verified_support_rows=nrow(support),
  population_review_sha256=attr(support,'population_review_sha256'),
  source_support_sha256=sha(support_path),code_sha256=sha(file.path(repo,'scripts/review_scientific_scope.R')),
  source_only_not_final_result_balance=TRUE),file.path(public,'COUNTRY_REVIEW_MANIFEST.json'),pretty=TRUE,auto_unbox=TRUE)
cat('REVIEWED_PRODUCTS ',nrow(trace),'; COUNTRY_ADMISSION ',sum(countries$proposed_dashboard_admission),
  '; RICH_NLD_CORE_REFERENCE ',paste(reference$country[reference$eligible & reference$rich_candidate],collapse=';'),'\n',sep='')
