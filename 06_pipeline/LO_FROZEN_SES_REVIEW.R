# Q03/Q04/Q05/Q07: no calibration refit, no alternate two-wave or official-ESCS
# analysis. Recheck the retained author evidence and each used score projection.
lo_frozen_ses_review <- function(repo,root,grid,out) {
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  sha<-function(p)digest::digest(file=p,algo='sha256')
  calibration_path<-file.path(root,'cobreros_four/CALIBRATION_CERTIFICATE.json')
  calibration<-jsonlite::fromJSON(calibration_path)
  if(calibration$status!='CHOSEN_CALIBRATION_RAW_SOURCE_AND_AUTHOR_PARAMETER_PARITY_VERIFIED' ||
     calibration$author_commit!='1da4b26097e84e732973af672355a1c3103d5d33')stop('SES_REVIEW_CALIBRATION_IDENTITY')
  for(i in seq_len(nrow(calibration$evidence_files))) {
    e<-calibration$evidence_files[i,]
    if(!file.exists(e$path)||sha(e$path)!=e$sha256)stop('SES_REVIEW_CALIBRATION_EVIDENCE_CHANGED')
  }
  prep_path<-file.path(root,'cobreros_four/PREPARATION_MANIFEST.json')
  prep<-jsonlite::fromJSON(prep_path)
  # The author extraction fields and actual author code are pinned separately.
  for(i in seq_len(nrow(prep$input_and_code_hashes))) {
    e<-prep$input_and_code_hashes[i,]
    if(!file.exists(e$path)||sha(e$path)!=e$sha256)stop('SES_REVIEW_AUTHOR_INPUT_CHANGED')
  }
  candidates<-list.files(file.path(root,'international/ses'),pattern='^SES_[a-f0-9]+[.]json$',full.names=TRUE)
  if(!length(candidates))stop('SES_REVIEW_APPLICATION_CERTIFICATE_REQUIRED')
  applications<-setNames(lapply(candidates,jsonlite::fromJSON),vapply(candidates,sha,character(1)))
  for(application in applications) {
    if(application$author_commit!=calibration$author_commit||
       application$model_sha256!=sha(file.path(root,'cobreros_four/irt13_model.rds'))||
       application$status!='FROZEN_CHOSEN_SES_APPLIED_WITH_NLD_NUMERIC_PARITY')stop('SES_REVIEW_FROZEN_MODEL_CHANGED')
  }
  g<-grid[grid$survey=='PISA' & grid$status=='SCIENTIFICALLY_VALIDATED' &
    grid$subgroup_variable%in%c('ses_harmonized','extension_ses_gender','extension_ses_school','ses_peer_exposure') ,]
  if(any(!grepl('Cobreros_fourwave_13item_trend_comparable',g$cell_id,fixed=TRUE))||
     any(!g$year%in%c('2015','2018','2022','2025')))stop('SES_REVIEW_UNCHOSEN_CONSTRUCT')
  parts<-split(seq_len(nrow(g)),g$source_path);rows<-list()
  for(path in names(parts)) {
    z<-g[parts[[path]],];country<-unique(z$country);year<-unique(z$year)
    if(length(country)!=1L||length(year)!=1L||length(unique(z$source_edition_sha256))!=1L||sha(path)!=z$source_edition_sha256[1])stop('SES_REVIEW_RESULT_SOURCE')
    obj<-readRDS(path);d<-obj$data
    id<-obj$meta$calibration_sha256
    if(is.null(id)||!id%in%names(applications)) {
      # Early NLD sources predate the international application certificate.
      # Resolve only when all applicable certificates identify the same exact
      # immutable score bytes; never choose the newest file by modification time.
      applicable<-vapply(applications,function(a)any(a$files$country==country&a$files$year==year),logical(1))
      hashes<-unique(unlist(lapply(applications[applicable],function(a)a$files$sha256[a$files$country==country&a$files$year==year])))
      if(length(hashes)!=1L||!any(applicable))stop('SES_REVIEW_AMBIGUOUS_APPLICATION')
      id<-names(applications)[which(applicable)[1]]
    }
    application<-applications[[id]]
    f<-application$files[application$files$country==country & application$files$year==year,]
    if(nrow(f)!=1L||!file.exists(f$path)||sha(f$path)!=f$sha256)stop('SES_REVIEW_APPLICATION_OUTPUT')
    raw<-readRDS(f$path)
    if(obj$meta$ses_construct_id!='Cobreros_fourwave_13item_trend_comparable')stop('SES_REVIEW_OFFICIAL_ESCS_SUBSTITUTION')
    ids<-as.character(d$SOURCE_STUDENT_ID);at<-match(ids,as.character(raw$cntstuid))
    if(anyNA(at)||anyDuplicated(ids)||length(ids)!=nrow(raw)||anyDuplicated(raw$cntstuid))stop('SES_REVIEW_PUPIL_MAPPING')
    expected<-raw$SES[at]
    if(!identical(is.na(expected),is.na(d$SES)))stop('SES_REVIEW_SCORE_MISSINGNESS_CHANGED')
    valid<-is.finite(expected);difference<-max(abs(expected[valid]-d$SES[valid]),0)
    if(difference>1e-12||max(abs(d$W-raw$w_fstuwt[at]))>1e-10)stop('SES_REVIEW_SCORE_OR_WEIGHT_PARITY')
    w<-raw$w_fstuwt;goodw<-is.finite(w)&w>0;w[!goodw]<-0
    component<-is.finite(raw$homepos_irt)&is.finite(raw$hisei)&is.finite(raw$pared_c)
    rows[[length(rows)+1L]]<-data.frame(country=country,year=year,n=nrow(raw),
      author_calibration_member=country%in%application$calibration_countries,
      score_valid_n=sum(is.finite(raw$SES)),score_weighted_coverage=sum(w[is.finite(raw$SES)])/sum(w),
      homepos_observed_n=sum(is.finite(raw$homepos_irt)),occupation_observed_n=sum(is.finite(raw$hisei)),
      education_observed_n=sum(is.finite(raw$pared_c)),all_components_observed_n=sum(component),
      scored_with_missing_component_n=sum(is.finite(raw$SES)&!component),
      scored_with_missing_component_weight_share=sum(w[is.finite(raw$SES)&!component])/sum(w),
      min_score=min(raw$SES,na.rm=TRUE),max_score=max(raw$SES,na.rm=TRUE),
      max_canonical_score_difference=difference,source_sha256=z$source_edition_sha256[1],
      calibrated_scores_sha256=f$sha256,calibration_sha256=sha(calibration_path),
      model_sha256=application$model_sha256,application_sha256=id,
      definition='Cobreros_fourwave_13item_trend_comparable',stringsAsFactors=FALSE)
    rm(raw,obj,d);gc(FALSE)
  }
  result<-do.call(rbind,rows)
  write.csv(result,file.path(out,'FROZEN_SES_COUNTRY_WAVE_REVIEW.csv'),row.names=FALSE)
  summary<-list(status='PINNED_AUTHOR_AND_ALL_USED_CANONICAL_SCORES_VERIFIED',
    calibration_sha256=sha(calibration_path),application_sha256=unique(result$application_sha256),author_commit=calibration$author_commit,
    calibration_countries=application$calibration_countries,calibration_n=application$calibration_n,
    numerical_parameter_differences=calibration$max_parameter_difference,
    canonical_sources_checked=nrow(result),used_country_waves=nrow(unique(result[c('country','year')])),
    scored_canonical_max_difference=max(result$max_canonical_score_difference),
    extension_country_waves=nrow(unique(result[!result$author_calibration_member,c('country','year')])),
    selected_two_wave_targets=0L,official_PISA_ESCS_analysis_targets=0L,
    author_preparation_selected=prep$selected,author_preparation_excluded=prep$excluded,
    output_sha256=sha(file.path(out,'FROZEN_SES_COUNTRY_WAVE_REVIEW.csv')),
    method_limitations='Fixed calibrated item parameters and regression imputation are carried across countries. Numerical/source parity is verified; measurement invariance and ignorable missingness outside calibration are assumptions, not demonstrated findings. No unrequested refit or ESCS robustness analysis.',
    review_code_sha256=sha(file.path(repo,'06_pipeline/LO_FROZEN_SES_REVIEW.R')))
  jsonlite::write_json(summary,file.path(out,'FROZEN_SES_REVIEW.json'),auto_unbox=TRUE,pretty=TRUE,digits=17)
  invisible(summary)
}
