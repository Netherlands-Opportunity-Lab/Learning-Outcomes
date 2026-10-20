# Portable form of the actual raw-input check used for the October calibration.
# Independent of the author's extraction routine: pupil sets, weights and every
# calibration item must match the official public-use files byte-for-value.
lo_cobreros_raw_closure <- function(repo,author,root) {
  out<-file.path(root,'cobreros_four')
  sha<-function(p)digest::digest(file=p,algo='sha256')
  prep_path<-file.path(out,'PREPARATION_MANIFEST.json')
  prep<-jsonlite::fromJSON(prep_path)
  stopifnot(prep$status=='CALIBRATION_PREPARED_REQUIRES_RAW_INPUT_AND_NLD_ESTIMATE_VERIFICATION',
    prep$model_parameter_max_absolute_difference$discrimination<1e-8,
    prep$model_parameter_max_absolute_difference$steps<1e-8)
  manifest_path<-file.path(root,'international/SOURCE_RUN_MANIFEST.csv')
  manifest<-read.csv(manifest_path,colClasses='character',na.strings=character())
  verifier<-file.path(repo,'06_pipeline/LO_COBREROS_RAW_CLOSURE.R')
  proofs<-list()
  for(year in c(2015L,2018L,2022L,2025L)) {
    source<-unique(manifest[manifest$survey=='PISA'&as.integer(manifest$year)==year,c('raw_path','raw_sha256')])
    stopifnot(nrow(source)==1L,sha(source$raw_path)==source$raw_sha256)
    extract<-file.path(author,'data/extract',paste0('stu_',year,'.parquet'))
    extract_sha<-sha(extract)
    receipt<-file.path(out,paste0('RAW_EXTRACT_PARITY_',year,'.json'))
    key<-list(raw_sha256=source$raw_sha256,extract_sha256=extract_sha,verifier_sha256=sha(verifier))
    if(file.exists(receipt)) {
      old<-jsonlite::fromJSON(receipt)
      if(!identical(old[names(key)],key)||old$status!='RAW_EXTRACT_ALL_CALIBRATION_FIELDS_EXACT')
        stop('COBREROS_RAW_CLOSURE_CHANGED_INPUT')
      proofs[[as.character(year)]]<-old
      next
    }
    fields<-if(year<=2018L)c(sprintf('st011q%02dta',c(2,4,5,6,9)),
      sprintf('st012q%02dta',1:3),sprintf('st012q%02dna',6:9),'books6')else
      c(sprintf('st250q%02dja',c(1,2,3,5)),sprintf('st251q%02dja',c(1,3,6,7)),
        sprintf('st254q%02dja',1:5),'st255q01ja')
    fields<-c('cnt','cntstuid','w_fstuwt','hisei','hisced',if(year!=2015L)'paredint',fields)
    original<-toupper(fields);original[fields=='books6']<-'ST013Q01TA'
    header<-names(haven::read_sav(source$raw_path,n_max=0))
    source_names<-header[match(c('OECD',original),toupper(header))]
    stopifnot(!anyNA(source_names))
    raw<-haven::read_sav(source$raw_path,col_select=tidyselect::all_of(source_names))
    names(raw)<-toupper(names(raw))
    raw<-raw[!is.na(raw$OECD)&as.numeric(raw$OECD)==1,]
    ext<-as.data.frame(arrow::read_parquet(extract,col_select=tidyselect::all_of(fields)))
    rid<-paste(raw$CNT,raw$CNTSTUID);eid<-paste(ext$cnt,ext$cntstuid)
    stopifnot(!anyDuplicated(rid),!anyDuplicated(eid),setequal(rid,eid))
    raw<-raw[match(eid,rid),]
    checks<-data.frame(field=fields,original=original,exact=FALSE)
    for(i in seq_along(fields)) {
      a<-raw[[original[i]]];b<-ext[[fields[i]]]
      checks$exact[i]<-if(fields[i]=='cnt')identical(as.character(a),as.character(b))else
        identical(as.numeric(a),as.numeric(b))
    }
    if(!all(checks$exact))stop('RAW_CALIBRATION_EXTRACT_MISMATCH: ',year)
    proof<-c(list(status='RAW_EXTRACT_ALL_CALIBRATION_FIELDS_EXACT',year=year,
      n=nrow(ext),exact_pupil_set=TRUE,columns=checks),key)
    jsonlite::write_json(proof,receipt,auto_unbox=TRUE,pretty=TRUE,digits=17)
    proofs[[as.character(year)]]<-proof
    rm(raw,ext);gc(FALSE)
  }
  closure_path<-file.path(out,'RAW_INPUT_CLOSURE.json')
  jsonlite::write_json(list(status='FOUR_WAVE_RAW_INPUT_PARITY_PASS',waves=proofs),
    closure_path,auto_unbox=TRUE,pretty=TRUE,digits=17)
  score_path<-file.path(out,prep$output_filename)
  stopifnot(sha(score_path)==prep$output_sha256)
  evidence<-c(prep_path,closure_path,file.path(out,'irt13_model.rds'),
    file.path(repo,'06_pipeline/LO_COBREROS_PREPARE.R'),verifier,manifest_path)
  certificate<-list(status='CHOSEN_CALIBRATION_RAW_SOURCE_AND_AUTHOR_PARAMETER_PARITY_VERIFIED',
    author_commit=prep$author_commit,
    protocol='R four-wave 13-item, senate country-wave weights, WLE min8, regression imputation seed20252022',
    calibration_country_count=34L,calibration_n=prep$n,foreign_result_production=FALSE,
    max_parameter_difference=prep$model_parameter_max_absolute_difference,
    national_quartiles='R seed7 tie-breaking in original source order; cut points recalculated for each BRR replicate',
    evidence_files=data.frame(path=evidence,sha256=vapply(evidence,sha,character(1))),
    score_file_sha256=sha(score_path),
    not_certified='Global paper/release, linking uncertainty, actual classes')
  destination<-file.path(out,'CALIBRATION_CERTIFICATE.json')
  if(file.exists(destination)) {
    stopifnot(identical(jsonlite::fromJSON(destination,simplifyVector=FALSE),
      jsonlite::fromJSON(jsonlite::toJSON(certificate,auto_unbox=TRUE,digits=17),simplifyVector=FALSE)))
  }else jsonlite::write_json(certificate,destination,auto_unbox=TRUE,pretty=TRUE,digits=17)
  invisible(certificate)
}
