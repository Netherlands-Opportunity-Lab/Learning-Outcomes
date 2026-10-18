# Export the real country selector using the existing balanced membership rules.
# Arguments: repository, frozen snapshot, comparability audit directory.
# This reads aggregates only and never changes the active R production master.
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==3L)
repo<-args[1];snapshot<-args[2];out<-args[3]
source(file.path(repo,'06_pipeline/LO_BALANCED_MEMBERSHIP.R'))
source(file.path(repo,'06_pipeline/LO_COUNTRY_REGISTRY.R'))
read<-function(p)read.csv(p,colClasses='character',na.strings=character(),check.names=FALSE)
a<-read(file.path(out,'BALANCE_AVAILABLE.csv'))
review<-jsonlite::fromJSON(file.path(out,'BALANCE_MAPPING_REVIEW.json'))
stopifnot(digest::digest(file=file.path(out,'BALANCE_AVAILABLE.csv'),algo='sha256')==review$available_sha256)
x<-lo_balance_validated(a)
all_keys<-sort(unique(x$balance_key))
core_targets<-read(file.path(out,'FOCUS_CORE_TARGETS.csv'))
stopifnot(digest::digest(file=file.path(out,'FOCUS_CORE_TARGETS.csv'),algo='sha256')==review$core_targets_sha256)
products<-read(file.path(snapshot,'public_inputs/dashboard_cells.csv'))
products_by_view<-split(products,paste(products$country,products$figure_id,sep='::'))
empty_product<-products[FALSE,,drop=FALSE]
registry<-read(file.path(snapshot,'public_inputs/COUNTRY_SOURCE_ELIGIBILITY.csv'))
countries<-registry$country[registry$dashboard_eligible=='TRUE' & registry$selected_for_production=='TRUE']
rich<-registry$country[registry$rich_candidate=='TRUE']
figures<-jsonlite::fromJSON(file.path(out,'FIGURES.json'))$figures
anchor<-read(file.path(repo,'06_pipeline/review_20261013/NLD_POLICY_CORE_YEAR_ANCHOR.csv'))
admission<-lo_dashboard_eligibility(x,countries)$countries
views<-list();n<-0L
for(focus in sort(countries)) {
 core_ids<-core_targets$cell_id[core_targets$country==focus]
 core<-x[match(core_ids,x$cell_id),,drop=FALSE]
 core_good<-length(core_ids)>0L && !anyNA(core$cell_id)
 # The existing engine evaluates the complete verified focus support once.
 # Each figure takes an exact subset of that missing-key matrix, with the
 # unchanged full core added. This avoids thousands of repeated revalidations.
 focus_rows<-x[x$country==focus,,drop=FALSE]
 full<-if(nrow(focus_rows))lo_balanced_membership(x,focus_rows,countries,focus) else NULL
 missing_index<-if(!is.null(full))setNames(strsplit(full$missing_keys,';',fixed=TRUE),full$country) else list()
 for(i in seq_len(nrow(figures))) {
  f<-figures[i,];p<-products_by_view[[paste(focus,f$figure_id,sep='::')]]
  if(is.null(p))p<-empty_product
  expected<-as.vector(outer(strsplit(f$required_years,';',fixed=TRUE)[[1]],strsplit(f$expected_series,';',fixed=TRUE)[[1]],paste,sep=':'))
  actual<-paste(p$year,p$series_id,sep=':')
  ids<-p$cell_id
  v<-list(focus=focus,figure_id=f$figure_id,view_id=paste0('PUBLIC_FIGURE::',f$figure_id),
    view_cell_ids=ids,default_members=character(),default_points=list(),
    focus_excluded=TRUE,country_weights='EQUAL_PER_COUNTRY',benchmark_uncertainty=FALSE)
  if(!core_good) {
   v$status<-'FOCUS_CORE_INCOMPLETE';v$missing_core_cells<-sum(!core_ids%in%x$cell_id)
  }else if(!setequal(expected,actual)||anyDuplicated(actual)) {
   v$status<-'FOCUS_VIEW_INCOMPLETE';v$missing_view_points<-length(setdiff(expected,actual))
  }else if(any(!ids%in%x$cell_id)) {
   v$status<-'COMPARABILITY_PENDING';v$missing_mapping_cells<-sum(!ids%in%x$cell_id)
  }else {
   comp<-x[match(ids,x$cell_id),,drop=FALSE]
   required<-lo_focus_required_support(core,comp,focus,anchor)
   keys<-sort(unique(lo_balance_key(required)))
   # Filtering to requested keys is computational only: the unmodified global
   # 6x3 admission test above still gates every candidate below.
   candidates<-sort(countries)
   missing<-lapply(candidates,function(c)sort(intersect(keys,missing_index[[c]])))
   counts<-lengths(missing)
   admitted<-admission$dashboard_eligible[match(candidates,admission$country)]
   opts<-data.frame(country=candidates,focus_country=focus,required_cells=length(keys),
      covered_cells=length(keys)-counts,missing_cells=counts,
      eligible=candidates!=focus & admitted & counts==0L,
      reason=ifelse(candidates==focus,'FOCUS_EXCLUDED',ifelse(!admitted,'FAIL_DASHBOARD_6x3',ifelse(counts>0L,'MISSING_OR_INCOMPATIBLE_REQUIRED_CELLS','FULL_BALANCED_SUPPORT'))),
      missing_keys=vapply(missing,paste,character(1),collapse=';'),dashboard_eligible=admitted)
   # Store a small example, not an O(countries x figures x missing keys) dump.
   # Full missing sets are independently recomputed from the cell dictionary.
   opts$missing_keys<-vapply(strsplit(opts$missing_keys,';',fixed=TRUE),function(k)
     paste(head(match(k[nzchar(k)],all_keys),3L),collapse=';'),character(1))
   v$options<-opts;v$required_keys<-match(keys,all_keys)
   v$default_members<-sort(intersect(rich,opts$country[opts$eligible]))
   v$status<-if(any(opts$eligible))'BALANCED_REFERENCE_AVAILABLE'else'NO_ELIGIBLE_REFERENCE'
  }
  n<-n+1L;views[[n]]<-v
 }
 cat('REFERENCE_OPTIONS',focus,'\n');flush.console()
}
# Public proof has aggregate identities and hashes, never local evidence paths.
proof_cols<-c('cell_id','country',lo_balance_columns(),'result_hash','verification_id',
              'source_certificate_sha256','result_certificate_sha256')
jsonlite::write_json(list(schema_version=3L,policy='FULL_FOCUS_CORE_PLUS_JOINT_VIEW_SUPPORT_6x3',
 dashboard_input_sha256=review$dashboard_input_sha256,mapping_evidence=review,
 key_dictionary=all_keys,cell_columns=proof_cols,cells=unname(as.matrix(a[proof_cols])),
 core_targets=core_targets,admission=admission,rich_candidates=sort(rich),views=views),
 file.path(out,'BALANCED_REFERENCE_EXPORT.json'),auto_unbox=TRUE,pretty=FALSE,na='null',digits=17)
cat('PASS reference options use existing R membership engine; no pupil recalculation\n')
