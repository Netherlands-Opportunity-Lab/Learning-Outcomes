# Match every displayed primitive to the exact reviewed task/result identity.
# A support table for an earlier run cannot certify newly produced rows.
lo_analysis_support_match <- function(repo,tasks,approved,review) {
  policy<-jsonlite::fromJSON(file.path(repo,'06_pipeline/review_20261013/ANALYSIS_SUPPORT_POLICY.json'))
  if(policy$minimum_pupils!=30L||policy$minimum_schools!=5L||
     !isTRUE(policy$require_known_school_for_each_target_pupil))stop('SUPPORT_UNREVIEWED_POLICY')
  if(anyDuplicated(review$cell_id))stop('SUPPORT_DUPLICATE_RESULT')
  at<-match(approved$cell_id,review$cell_id)
  if(anyNA(at))stop('SUPPORT_REVIEW_MISSING_CURRENT_RESULT')
  rows<-review[at,,drop=FALSE]
  contracts<-lo_grid_from_tasks(tasks)
  cx<-match(approved$cell_id,contracts$cell_id)
  if(anyNA(cx)||any(rows$target_contract_sha256!=contracts$target_contract_sha256[cx])||
     any(rows$result_hash!=approved$result_hash)||any(rows$source_sha256!=approved$source_edition_sha256)||
     any(rows$recorded_n!=as.numeric(approved$n_unweighted))||!all(rows$recorded_n_matches))
    stop('SUPPORT_REVIEW_RESULT_OR_CONTRACT_CHANGED')
  rows$publication_eligible<-rows$min_component_n>=policy$minimum_pupils&
    rows$min_component_school_n>=policy$minimum_schools&rows$max_missing_school_n==0
  rows$publication_restriction<-ifelse(rows$publication_eligible,'',
    ifelse(rows$max_missing_school_n>0,'QUALITY_SCHOOL_ID_NOT_OBSERVED',
      ifelse(rows$min_component_n<policy$minimum_pupils,'QUALITY_FEWER_THAN_30_TARGET_PUPILS','QUALITY_FEWER_THAN_5_TARGET_SCHOOLS')))
  rows
}

lo_analysis_support_load <- function(repo,root,tasks,approved) {
  manifest_path<-file.path(root,'scientific_review_20261019/SCIENTIFIC_REVIEW_MANIFEST.json')
  if(!file.exists(manifest_path))stop('SUPPORT_CURRENT_SCIENTIFIC_REVIEW_REQUIRED')
  manifest<-jsonlite::fromJSON(manifest_path)
  work<-manifest$review_work_directory
  if(is.null(work)||!nzchar(work))stop('SUPPORT_CURRENT_REVIEW_DIRECTORY_MISSING')
  path<-file.path(work,'Q01_ANALYSIS_SUPPORT/ANALYSIS_SUPPORT.csv')
  evidence<-manifest$evidence_files
  # Actual evidence uses paths and hashes, not a summary PASS label.
  if(!is.data.frame(evidence))stop('SUPPORT_REVIEW_EVIDENCE_MISSING')
  at<-match(normalizePath(path,winslash='/',mustWork=FALSE),gsub('\\','/',evidence$path,fixed=TRUE))
  if(is.na(at)||!file.exists(path)||digest::digest(file=path,algo='sha256')!=evidence$sha256[at])
    stop('SUPPORT_REVIEW_EVIDENCE_CHANGED')
  lo_analysis_support_match(repo,tasks,approved,read.csv(path,stringsAsFactors=FALSE,na.strings=character()))
}
