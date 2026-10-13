# Build a GUIDED-frontend figure-product candidate from independently
# validated primitive estimates. Source task and figure IDs remain immutable.
# Old high-peer results cannot fill new primary below-basic peer graphs.
lo_guided_grid_export <- function(bundle,tasks,approved,out) {
  if(!exists("lo_grid_validate_fill",mode="function"))
    stop("GUIDED_EXPORT_HOLD: load MASTER_ESTIMATION_GRID.R")
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  figures<-read.csv(file.path(bundle,"FIGURE_SERIES_CONTRACT_20261002.csv"),
      colClasses="character",stringsAsFactors=FALSE,check.names=FALSE)
  required<-c("figure_id","expected_series","survey","domain","required_years")
  if(!all(required%in%names(figures)) ||
     (nrow(figures)!=138L &&
      Sys.getenv("LO_SYNTHETIC_GUIDED_TEST")!="YES") ||
     anyDuplicated(figures$figure_id))
    stop("GUIDED_EXPORT_HOLD: source figure registry changed")
  if(!all(c("metric_key","contract_figure_id","country","survey",
            "year","domain","group","stat","definition")%in%names(tasks)) ||
      anyDuplicated(tasks$metric_key))
    stop("GUIDED_EXPORT_HOLD: source task identity changed")
  if(!nrow(approved)) {
    # A blank file with the exact locked schema can still produce an empty
    # review candidate, without pretending data have been checked.
    approved <- data.frame(cell_id=character(),estimate=numeric(),
      standard_error=numeric(),n_unweighted=integer(),
      sample_id=character(),input_fingerprint=character(),
      code_fingerprint=character(),result_hash=character(),
      method_version=character(),status=character())
  }
  if(nrow(approved)) {
    lo_grid_validate_fill(data.frame(cell_id=tasks$metric_key),approved)
  }
  matched <- match(approved$cell_id,tasks$metric_key)
  if(anyNA(matched))stop("GUIDED_EXPORT_HOLD: unknown science cell")
  source<-tasks[matched,,drop=FALSE]
  map_fig<-match(source$contract_figure_id,figures$figure_id)
  rec<-list();omissions<-list()
  omit<-function(i,reason) {
    omissions[[length(omissions)+1L]] <<- data.frame(
       cell_id=approved$cell_id[i],figure_id=source$contract_figure_id[i],
       country=source$country[i],reason=reason,stringsAsFactors=FALSE)
  }
  for(i in seq_len(nrow(approved))) {
    if(is.na(map_fig[[i]])) {
      omit(i,"NO_EXACT_FIGURE_CONTRACT_OR_DERIVED_RANK");next
    }
    f<-figures[map_fig[i],,drop=FALSE]
    id<-f$figure_id[[1]]
    family<-sub("_age.*$","",id)
    if(family=="TR_BASIC") {
      omit(i,"DERIVED_COMPLEMENT_NO_SEPARATE_CHART");next
    }
    if(family=="EN_PERFORMANCE_PEER") {
      omit(i,"OLD_HIGH_PEER_CANNOT_FILL_PRIMARY_BELOW_BASIC");next
    }
    if(family=="GP_SES_HIGH") {
      omit(i,"OPTIONAL_APPENDIX_NOT_REQUIRED_FOR_MAIN_42");next
    }
    if(family=="GP_SES_BASIC") {
      omit(i,"HOLD_BELOW_BASIC_BY_SES_COMPLEMENT_REQUIRES_DEFINED_UNIT_AND_CI")
      next
    }
    group<-as.character(source$group[i])
    expected<-strsplit(f$expected_series[[1]],";",fixed=TRUE)[[1]]
    if(!group%in%expected) {
      omit(i,"HOLD_EXPECTED_SERIES_MAPPING_NEEDS_METHOD_ADJUDICATION")
      next
    }
    if(!as.character(source$year[i])%in%
         strsplit(f$required_years[[1]],";",fixed=TRUE)[[1]]) {
      omit(i,"HOLD_SURVEY_YEAR_NOT_IN_FIGURE_CONTRACT");next
    }
    code<-as.character(source$country[i])
    if(!grepl("^[A-Z0-9]{3}$",code)) {
      omit(i,"HOLD_INVALID_COUNTRY_CODE");next
    }
    row<-data.frame(figure_id=id,country=code,
      year=as.character(source$year[i]),survey=as.character(source$survey[i]),
      domain=as.character(source$domain[i]),
      outcome_id=as.character(source$definition[i]),
      estimate=as.numeric(approved$estimate[i]),
      se=as.numeric(approved$standard_error[i]),
      n_unweighted=as.numeric(approved$n_unweighted[i]),
      scientific_status="SCIENTIFICALLY_VALIDATED",
      sample_id=as.character(approved$sample_id[i]),
      source_id=paste0("GRID:SHA256:",as.character(approved$result_hash[i])),
      input_fingerprint=as.character(approved$input_fingerprint[i]),
      code_fingerprint=as.character(approved$code_fingerprint[i]),
      result_hash=as.character(approved$result_hash[i]),
      series_id=group,series_role="focus",
      series_label_nl=group,series_label_en=group,
      split_group=group,
      comparison_fixed_panel_pass="",
      comparison_method="",comparator_n="",
      ci_low=if("ci_low"%in%names(approved))
        as.character(approved$ci_low[i]) else "",
      ci_high=if("ci_high"%in%names(approved))
        as.character(approved$ci_high[i]) else "",
      peer_denominator_verified="",
      self_exclusion_verified="",stringsAsFactors=FALSE)
    rec[[length(rec)+1L]]<-row
  }
  result<-if(length(rec))do.call(rbind,rec) else data.frame(
    figure_id=character(),country=character(),year=character(),
    survey=character(),domain=character(),outcome_id=character(),
    estimate=numeric(),se=numeric(),n_unweighted=numeric(),
    scientific_status=character(),sample_id=character(),
    source_id=character(),input_fingerprint=character(),
    code_fingerprint=character(),result_hash=character(),
    series_id=character(),series_role=character(),
    series_label_nl=character(),series_label_en=character(),
    split_group=character(),comparison_fixed_panel_pass=character(),
    comparison_method=character(),comparator_n=character(),
    ci_low=character(),ci_high=character(),
    peer_denominator_verified=character(),
    self_exclusion_verified=character(),stringsAsFactors=FALSE)
  if(nrow(result) && anyDuplicated(result[c("figure_id","country",
                                "year","series_id","series_role")]))
    stop("GUIDED_EXPORT_HOLD: multiple validated results per figure-series-wave")
  skipped<-if(length(omissions))do.call(rbind,omissions) else
     data.frame(cell_id=character(),figure_id=character(),
                country=character(),reason=character())
  write.csv(result,file.path(out,"PRIVATE_GUIDED_VALIDATED_ROWS.csv"),
            row.names=FALSE,na="")
  write.csv(skipped,file.path(out,"PRIVATE_GUIDED_MAPPING_HOLDS.csv"),
            row.names=FALSE)
  stats<-data.frame(validated_input_cells=nrow(approved),
    guided_focus_rows=nrow(result),
    mapping_holds=nrow(skipped),
    requires_new_below_basic_peer="YES",
    publication_status="PRIVATE_REVIEW_ONLY",stringsAsFactors=FALSE)
  write.csv(stats,file.path(out,"GUIDED_EXPORT_SUMMARY.csv"),row.names=FALSE)
  invisible(stats)
}
