# Build a GUIDED-frontend figure-product candidate from independently
# validated primitive estimates. Source task and figure IDs remain immutable.
# Old high-peer results cannot fill new primary below-basic peer graphs.
lo_guided_grid_export <- function(bundle,tasks,approved,out,scope_decisions=NULL) {
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
    if(!exists("lo_grid_archive_fill",mode="function"))stop("GUIDED_EXPORT_EXACT_ARCHIVE_GATE_REQUIRED")
    lo_grid_archive_fill(lo_grid_from_tasks(tasks),approved,
      verify_files=TRUE)
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
      if(startsWith(source$module[i],"extension_")) {
        omit(i,"APPROVED_APPENDIX_OR_SCIENCE_EXTENSION_SEPARATE_EXPORT");next
      }
      omit(i,"NO_EXACT_FIGURE_CONTRACT_OR_DERIVED_RANK");next
    }
    f<-figures[map_fig[i],,drop=FALSE]
    id<-f$figure_id[[1]]
    family<-sub("_age.*$","",id)
    if(family=="TR_POSITION") {
      omit(i,"RANK_REQUIRES_CERTIFIED_DERIVATION_AND_EXPLICIT_FIXED_PANEL");next
    }
    if(family=="TR_BASIC") {
      omit(i,"DERIVED_COMPLEMENT_NO_SEPARATE_CHART");next
    }
    new_peer <- family=="EN_PERFORMANCE_PEER" &&
                 source$module[[i]]=="peer_below_basic" &&
                 source$stat[[i]]=="peer_share_below_basic"
    allowed <- function(id)exists("lo_scope_is_approved",mode="function") && lo_scope_is_approved(scope_decisions,id)
    if(new_peer && !allowed("A01")) { omit(i,"PENDING_A01");next }
    if(family=="EN_PERFORMANCE_PEER" && !new_peer && !allowed("A03")) {
      omit(i,"OLD_HIGH_PEER_CANNOT_FILL_PRIMARY_BELOW_BASIC");next
    }
    if(new_peer) {
      cert <- c("peer_denominator_verified","self_exclusion_verified",
                "method_certification_status")
      if(!all(cert%in%names(approved)) ||
         any(vapply(cert,function(col)!identical(
              as.character(approved[[col]][i]),"PASS"),logical(1L)))) {
        omit(i,"HOLD_NEW_PEER_METHOD_DENOMINATOR_OR_SELF_EXCLUSION");next
      }
    }
    if(family=="GP_SES_HIGH" && !allowed("A02")) {
      omit(i,"OPTIONAL_APPENDIX_NOT_REQUIRED_FOR_MAIN_42");next
    }
    value<-as.numeric(approved$estimate[i]);se<-as.numeric(approved$standard_error[i])
    low<-if("ci_low"%in%names(approved))as.character(approved$ci_low[i]) else ""
    high<-if("ci_high"%in%names(approved))as.character(approved$ci_high[i]) else ""
    derived<-FALSE
    if(family=="GP_SES_BASIC") {
      unit<-source$unit[i];stat<-source$stat[i]
      # Historical base_share is >=basic. Do not infer a unit from its value.
      if(!unit%in%c("proportion","percent") || !stat%in%c("base_share","below_share","q1_basic","q4_basic")) {
        omit(i,"BELOW_BASIC_EXACT_UNIT_OR_STAT_NOT_RECOGNIZED");next
      }
      cap<-if(unit=="proportion")1 else 100
      if(value<0||value>cap)stop("GUIDED_EXPORT_INVALID_SHARE_RANGE")
      if(stat%in%c("base_share","q1_basic","q4_basic")) {
        value<-cap-value;derived<-TRUE
        if(nzchar(low)&&nzchar(high)) { oldlow<-low;low<-as.character(cap-as.numeric(high));high<-as.character(cap-as.numeric(oldlow)) }
      }
      scale<-if(f$unit=="percent" && unit=="proportion")100 else if(f$unit==unit)1 else NA_real_
      if(!is.finite(scale))stop("GUIDED_EXPORT_UNIT_CONVERSION_NOT_SPECIFIED")
      value<-value*scale;se<-se*scale
      if(nzchar(low))low<-as.character(as.numeric(low)*scale)
      if(nzchar(high))high<-as.character(as.numeric(high)*scale)
    }
    if(family=="EN_PERFORMANCE_PEER" && !new_peer && allowed("A01"))
      id<-sub("^EN_PERFORMANCE_PEER_","EN_PERFORMANCE_PEER_HIGH_",id)
    group<-as.character(source$group[i])
    expected<-if(new_peer)
      c("total","self_below_basic","self_at_or_above_basic")
      else strsplit(f$expected_series[[1]],";",fixed=TRUE)[[1]]
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
      outcome_id=if(new_peer)"peer_share_below_basic"
         else if(family=="GP_SES_BASIC")"below_basic_by_ses" else as.character(source$definition[i]),
      estimate=value,
      se=se,
      n_unweighted=as.numeric(approved$n_unweighted[i]),
      scientific_status="SCIENTIFICALLY_VALIDATED",
      sample_id=as.character(approved$sample_id[i]),
      source_id=paste0("GRID:SHA256:",as.character(approved$result_hash[i])),
      input_fingerprint=as.character(approved$input_fingerprint[i]),
      code_fingerprint=as.character(approved$code_fingerprint[i]),
      result_hash=if(derived)digest::digest(list(parent=as.character(approved$result_hash[i]),
        transform="BELOW_BASIC_COMPLEMENT_V1",source_unit=source$unit[i],target_unit=f$unit,
        estimate=value,se=se,ci_low=low,ci_high=high),algo="sha256") else as.character(approved$result_hash[i]),
      series_id=group,series_role="focus",
      series_label_nl=group,series_label_en=group,
      split_group=group,
      comparison_fixed_panel_pass="",
      comparison_method="",comparator_n="",
      ci_low=low,ci_high=high,
      peer_denominator_verified=if(new_peer)"PASS" else "",
      self_exclusion_verified=if(new_peer)"PASS" else "",
      stringsAsFactors=FALSE)
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
  # Preserve approved appendix/science results with exact parent IDs and full
  # provenance; dashboard figure contracts cannot silently rename these rows.
  ext<-startsWith(source$module,"extension_")
  appendix<-cbind(source[ext,,drop=FALSE],approved[ext,setdiff(names(approved),names(source)),drop=FALSE])
  write.csv(appendix,file.path(out,"PRIVATE_APPROVED_EXTENSION_ROWS.csv"),row.names=FALSE,na="")
  write.csv(skipped,file.path(out,"PRIVATE_GUIDED_MAPPING_HOLDS.csv"),
            row.names=FALSE)
  stats<-data.frame(validated_input_cells=nrow(approved),
    guided_focus_rows=nrow(result),
    mapping_holds=nrow(skipped),
    requires_new_below_basic_peer=if(!is.null(scope_decisions) && lo_scope_is_approved(scope_decisions,"A01"))"YES" else "NO",
    publication_status="PRIVATE_REVIEW_ONLY",stringsAsFactors=FALSE)
  write.csv(stats,file.path(out,"GUIDED_EXPORT_SUMMARY.csv"),row.names=FALSE)
  invisible(stats)
}
# Immutable previews must change when the visible frontend or reference data
# changes, even if the scientific values remain identical.
lo_guided_preview_fingerprint <- function(repo,bundle,state) {
  frontend<-file.path(repo,"05_publication","preview_overlay")
  assets<-sort(list.files(frontend,recursive=TRUE,full.names=TRUE))
  assets<-assets[!dir.exists(assets)]
  if(!length(assets))stop("GUIDED_PREVIEW_FRONTEND_MISSING")
  files<-c(export=file.path(state,"PRIVATE_GUIDED_VALIDATED_ROWS.csv"),
    decisions=file.path(repo,"06_pipeline","SCOPE_APPROVALS.csv"),
    countries=file.path(state,"COUNTRY_SOURCE_ELIGIBILITY.csv"),
    figures=file.path(bundle,"FIGURE_SERIES_CONTRACT_20261002.csv"),
    builder=file.path(repo,"06_pipeline","LO_FINAL_GUIDED_DASHBOARD_BUILD.py"),
    references=file.path(state,"BALANCED_REFERENCE_EXPORT.json"),
    setNames(assets,paste0("frontend/",substring(assets,nchar(frontend)+2L))))
  hashes<-vapply(files,function(p)if(file.exists(p))digest::digest(file=p,algo="sha256") else "ABSENT",character(1))
  substr(digest::digest(hashes,algo="sha256"),1L,18L)
}

