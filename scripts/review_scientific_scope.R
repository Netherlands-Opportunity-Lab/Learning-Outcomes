# Read-only aggregate/source-identity review; not another production runner.
# Rscript scripts/review_scientific_scope.R <repo> <private-root> <source-bundle>
args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)%in%c(3L,4L))
country_only<-length(args)==4L&&identical(args[4],'--country-only')
if(length(args)==4L&&!country_only)stop('UNKNOWN_REVIEW_OPTION')
repo<-normalizePath(args[1],winslash='/');root<-normalizePath(args[2],winslash='/')
bundle<-normalizePath(args[3],winslash='/')
work<-file.path(root,'scientific_review_20261019')
read<-function(p)read.csv(p,colClasses='character',na.strings=character(),check.names=FALSE)
sha<-function(p)digest::digest(file=p,algo='sha256')
for(n in c('LO_BALANCED_MEMBERSHIP.R','LO_COUNTRY_REGISTRY.R','LO_SCOPE_DECISIONS.R','LO_PRODUCT_TRACE.R'))
  source(file.path(repo,'06_pipeline',n))
trace<-NULL
if(!country_only) {
tasks<-read(file.path(work,'snapshot/product_export/PRIVATE_TASKS.csv'))
gp<-file.path(work,'REVIEWED_MASTER_GRID.csv')
if(!file.exists(gp))gp<-file.path(root,'FIXED_PRODUCTION_V1/all_required/PRIVATE_MASTER_GRID.csv')
grid<-read(gp)
stopifnot(setequal(tasks$metric_key,grid$cell_id))
out<-file.path(work,'product_trace');dir.create(out,showWarnings=FALSE)
trace<-lo_product_trace(repo,tasks,grid,lo_read_scope_decisions(repo),out)
stopifnot(sum(trace$product=='PAPER_REGISTERED_CLAIM')==12L)
}
public<-file.path(repo,'06_pipeline/review_20261013/scientific_review')
support_path<-file.path(root,'master_reconciliation/SOURCE_SUPPORT_CONTRACTS.csv')
support<-lo_read_source_support(support_path,repo)
country_path<-file.path(public,'COUNTRY_REVIEW.csv')
countries<-read(country_path)
impact_path<-file.path(root,'international/COMBINATION_RULE_IMPACT_20261019.json')
impact<-if(file.exists(impact_path))jsonlite::fromJSON(impact_path)else NULL
if(!is.null(impact))for(c in setdiff(impact$new_candidate_countries,countries$country)) {
  row<-countries[1,,drop=FALSE];row[1,]<-''
  row$country<-c;row$rich_candidate<-'FALSE';row$previously_produced<-'FALSE'
  row$entity_kind<-'NATIONAL_CANDIDATE'
  row$quality_note<-'Additional PISA participant absent from the former IEA-driven catalogue. Stored row indices alone do not certify released scores or comparable populations.'
  countries<-rbind(countries,row)
}
countries<-countries[order(countries$country),,drop=FALSE]
info<-lo_support_eligibility(support,countries$country)
info$detail$years<-vapply(seq_len(nrow(info$detail)),function(i) {
  z<-info$detail[i,];paste(sort(unique(support$year[support$country==z$country &
    support$survey==z$survey & support$domain==z$domain])),collapse=';')
},character(1))
write.csv(info$countries,file.path(public,'VERIFIED_COUNTRY_ADMISSION.csv'),row.names=FALSE)
# Keep the former filenames as compatible six-row-per-country inventories;
# they no longer mean all six rows must pass for country-selector admission.
write.csv(info$detail,file.path(public,'VERIFIED_COUNTRY_SIX_COMBINATIONS.csv'),row.names=FALSE)
write.csv(info$detail,file.path(public,'COUNTRY_SIX_COMBINATIONS.csv'),row.names=FALSE)
write.csv(info$detail,file.path(public,'VERIFIED_COUNTRY_COMBINATIONS.csv'),row.names=FALSE)
countries$proposed_dashboard_admission<-info$countries$dashboard_eligible[match(countries$country,info$countries$country)]
countries$admitted_combinations<-info$countries$admitted_combinations[match(countries$country,info$countries$country)]
countries$main_reason<-ifelse(countries$proposed_dashboard_admission,'AT_LEAST_ONE_VERIFIED_COMBINATION_MIN3',
  ifelse(countries$country%in%support$country,'NO_VERIFIED_COMBINATION_HAS_THREE_COMPARABLE_WAVES',
  'SOURCE_CERTIFICATION_NOT_YET_AVAILABLE'))
countries$decision<-'APPLY_USER_20261019_COMBINATION_MIN3_FIXED_VIEW_PANEL'
pending<-if(is.null(impact))character()else setdiff(impact$new_candidate_countries,support$country)
countries$main_reason[countries$country%in%pending]<-'ADDITIONAL_COMBINATION_CANDIDATE_AWAITING_SOURCE_CERTIFICATION'
countries$quality_note[countries$country=='AUT']<-'PISA 2009 boycott/motivation qualification: retained historical target, excluded from comparable trend support. Full focus anchor is not shortened.'
countries$quality_note[countries$country=='ESP']<-'PISA 2018 exam-timing/motivation qualification: retained historical target, excluded from comparable trend support. Full focus anchor is not shortened.'
regions<-read(file.path(public,'REGIONAL_SOURCE_IDENTITIES.csv'))
# An IEA regional code must not reclassify an independently national PISA
# population (e.g. Belgium or the UK). Preserve the reviewed entity identities.
countries$main_reason[countries$entity_kind=='REVIEWED_SOURCE_CODE_NOT_AUTOMATICALLY_A_COUNTRY']<-'REGIONAL_SOURCE_NOT_AUTHORIZED_AS_NATIONAL_COUNTRY'
for(c in c('CAN','POL'))countries$quality_note[countries$country==c]<-if(c=='CAN')
  'PISA and TIMSS admitted separately. PIRLS has two comparable national waves (2011;2016); regional 2001 excluded. Canadian TIMSS 2015;2019;2023 cannot cover the full Dutch 2003-2023 anchor.' else
  'PISA and grade-4 TIMSS admitted separately. PIRLS 2006;2011 and TIMSS 2011 use grade 3 and cannot extend the grade-4 anchor. Grade-4 PIRLS 2016;2021 has only two waves.'
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
# That 40-cell table is now a whole-catalogue diagnostic, NOT a per-figure gate.
per_combination<-do.call(rbind,lapply(seq_len(nrow(anchor)),function(i) {
  a<-anchor[i,];selected<-core[lo_combination_key(core)==lo_combination_key(a),,drop=FALSE]
  req<-lo_focus_required_support(core,selected,'NLD',anchor)
  k<-sort(unique(lo_balance_key(req)))
  admitted<-lo_combination_admitted(info,req,countries$country)
  do.call(rbind,lapply(seq_len(nrow(countries)),function(j) {
    country<-countries$country[j];missing<-setdiff(k,source_keys[support$country==country])
    data.frame(country=country,focus_country='NLD',survey=a$survey,age_group=a$age_group,
      domain=a$domain,required_years=a$years,required_cells=length(k),
      covered_cells=length(k)-length(missing),missing_cells=length(missing),
      combination_admitted=unname(admitted[j]),rich_candidate=country%in%runtime$comparator,
      eligible=country!='NLD' && admitted[j] && !length(missing),
      reason=if(country=='NLD')'FOCUS_EXCLUDED'else if(!admitted[j])'COMBINATION_NOT_ADMITTED'
        else if(length(missing))'MISSING_FULL_FOCUS_ANCHOR'else 'FULL_COMBINATION_CORE_SUPPORT',
      missing_keys=paste(missing,collapse=';'))
  }))
}))
write.csv(per_combination,file.path(public,'NLD_COMBINATION_REFERENCE_REVIEW.csv'),row.names=FALSE)
jsonlite::write_json(list(result_basis='ac9f0bdb15b5bf3fcf843f3e4f857995d182aef2',
  candidate_count=nrow(countries),eligible_count=sum(countries$proposed_dashboard_admission),
  candidate_entities_are_not_all_sovereign_countries=TRUE,
  rich_pool_unchanged=runtime$comparator,verified_support_rows=nrow(support),
  population_review_sha256=attr(support,'population_review_sha256'),
  source_support_sha256=sha(support_path),code_sha256=sha(file.path(repo,'scripts/review_scientific_scope.R')),
  policy='COUNTRY_AGE_DOMAIN_MIN3_FULL_FOCUS_COMBINATION_AND_JOINT_VIEW',
  user_decision_sha256=sha(file.path(repo,'06_pipeline/review_20261013/BALANCE_USER_DECISION_20261019.json')),
  admitted_combinations=sum(info$detail$combination_pass),
  additional_candidates_pending_source_certification=pending,
  inventory_screen_sha256=if(is.null(impact))NULL else sha(impact_path),
  whole_catalogue_reference_is_diagnostic_only=TRUE,
  source_only_not_final_result_balance=TRUE),file.path(public,'COUNTRY_REVIEW_MANIFEST.json'),pretty=TRUE,auto_unbox=TRUE)
cat('REVIEWED_PRODUCTS ',if(is.null(trace))'UNCHANGED_TRACE_REUSED'else nrow(trace),'; COUNTRY_ADMISSION ',sum(countries$proposed_dashboard_admission),
  '; ADMITTED_COMBINATIONS ',sum(info$detail$combination_pass),'; ADDITIONAL_CANDIDATES ',length(pending),'\n',sep='')
