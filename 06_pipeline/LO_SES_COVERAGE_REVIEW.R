# Q01/Q05: inspect the actual canonical inputs of selected, sealed results.
# This library does not fit SES, calculate achievement results, or change scope.
# Every source and selected result is fingerprinted; persisted source summaries
# are reused only after checking source bytes, code and target/result identities.
lo_ses_coverage_review <- function(repo,grid,out) {
  source(file.path(repo,'06_pipeline/LO_IEA_BACKGROUND.R'),local=environment())
  source(file.path(repo,'06_pipeline/LO_EXACT_ESTIMATORS.R'),local=environment())
  rc2_tails_rank<-lo_iea_reference_tails
  modules<-c('ses_national','ses_harmonized','extension_ses_gender',
    'extension_home_ses','extension_ses_school','extension_ses_class')
  g<-grid[grid$subgroup_variable%in%modules & grid$status=='SCIENTIFICALLY_VALIDATED',,drop=FALSE]
  if(!nrow(g))stop('SES_REVIEW_NO_SELECTED_RESULTS')
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  cache<-file.path(out,'source_checks');dir.create(cache,showWarnings=FALSE)
  code_files<-file.path(repo,'06_pipeline',c('LO_SES_COVERAGE_REVIEW.R','LO_IEA_BACKGROUND.R','LO_EXACT_ESTIMATORS.R'))
  code<-vapply(code_files,function(p)digest::digest(file=p,algo='sha256'),character(1))
  groups<-split(seq_len(nrow(g)),g$source_path)
  rows<-list();proof<-list();hits<-0L
  for(path in names(groups)) {
    z<-g[groups[[path]],,drop=FALSE]
    expected<-unique(z$source_edition_sha256)
    if(length(expected)!=1L||!file.exists(path)||digest::digest(file=path,algo='sha256')!=expected)
      stop('SES_REVIEW_SOURCE_CHANGED')
    identity<-z[c('cell_id','target_contract_sha256','result_hash','n_unweighted')]
    identity<-identity[order(identity$cell_id),];rownames(identity)<-NULL
    key<-digest::digest(list(source=expected,code=code,targets=identity),algo='sha256')
    saved_path<-file.path(cache,paste0(key,'.rds'))
    if(file.exists(saved_path)) {
      saved<-readRDS(saved_path)
      if(!identical(saved$key,key)||!identical(saved$rows_sha256,digest::digest(saved$rows,algo='sha256')))
        stop('SES_REVIEW_CACHE_CHANGED')
      result<-saved$rows;hits<-hits+1L
    }else {
      obj<-readRDS(path);d<-obj$data
      if(!is.data.frame(d)||!'W'%in%names(d))stop('SES_REVIEW_CANONICAL_SCHEMA')
      w<-as.numeric(d$W);valid_w<-is.finite(w)&w>0
      if(!any(valid_w))stop('SES_REVIEW_NO_VALID_WEIGHT')
      w[!valid_w]<-0
      ishome<-all(z$subgroup_variable=='extension_home_ses')
      if(ishome) {
        if(!'HOME_SES_GROUP'%in%names(d)||!identical(obj$meta$home_ses_construct,'IEA_OFFICIAL_HOME_SES'))
          stop('SES_REVIEW_HOME_CONSTRUCT')
        valid<-valid_w & !is.na(d$HOME_SES_GROUP)&d$HOME_SES_GROUP%in%c('lower','middle','higher')
        tails<-NULL
      }else {
        if(!'SES'%in%names(d))stop('SES_REVIEW_SES_FIELD')
        valid<-valid_w&is.finite(d$SES)
        definition<-unique(z$ses_construct_id)
        definition<-definition[nzchar(definition)&definition!='none']
        # The immutable target uses the full construct name in its key.
        chosen<-any(grepl('Cobreros_fourwave_13item_trend_comparable',z$cell_id,fixed=TRUE))
        q<-data.frame(definition=if(chosen)'Cobreros_fourwave_13item_trend_comparable'else'books5_fractional')
        tails<-lo_exact_ses_tails(obj,q,w)
      }
      parts<-split(seq_len(nrow(z)),paste(z$country,z$survey,z$year,z$domain,z$subgroup_variable,z$subgroup_level,sep='|'))
      result<-do.call(rbind,lapply(parts,function(ix) {
        r<-z[ix[1],];module<-r$subgroup_variable;group<-r$subgroup_level
        member<-rep(1,nrow(d));sex<-rep(TRUE,nrow(d))
        if(ishome)member<-as.numeric(d$HOME_SES_GROUP==group)
        else if(module%in%c('ses_national','ses_harmonized','extension_ses_gender')) {
          if(group=='q4_minus_q1')member<-pmin(1,tails$q1+tails$q4)
          else member<-tails[[sub('_.*$','',group)]]
          if(module=='extension_ses_gender') {
            if(!'DEMO_GENDER'%in%names(d))stop('SES_REVIEW_GENDER_FIELD')
            sex<-d$DEMO_GENDER==sub('^q[14]_','',group)
          }
        }
        sex[is.na(sex)]<-FALSE;member[!is.finite(member)]<-0
        member[!valid|!sex]<-0
        if(module%in%c('extension_ses_school','extension_ses_class')) {
          unit<-if(module=='extension_ses_school')as.character(d$SCHOOL)else ifelse(is.na(d$SCHOOL)|is.na(d$CLASS),NA_character_,paste(d$SCHOOL,d$CLASS,sep='::'))
          member[is.na(unit)|!nzchar(unit)]<-0
        }
        pv<-if(r$domain=='all')character()else grep(paste0('^PV_',switch(r$domain,reading='READ',mathematics='MATH',science='SCIE'),'_[0-9]+$'),names(d),value=TRUE)
        complete<-if(length(pv))rowSums(!is.finite(as.matrix(d[pv])))==0 else rep(TRUE,nrow(d))
        # Background membership alone is not the achievement analysis sample.
        # A pupil with no score PVs retains background coverage but cannot enter
        # achievement denominators. Partially observed PV sets are rejected by
        # the source verifier before this review can consume a certified row.
        before_score_n<-sum(member>0)
        before_score_weight<-sum(w*member)
        member[!complete]<-0
        observed_n<-sum(member>0)
        declared<-as.numeric(z$n_unweighted[ix])
        data.frame(country=r$country,survey=r$survey,year=r$year,domain=r$domain,
          module=module,group=group,definition_id=if(ishome)'IEA_OFFICIAL_HOME_SES'else if(chosen)'Cobreros_fourwave_13item_trend_comparable'else'books5_fractional',
          source_sha256=expected,source_n=nrow(d),positive_weight_n=sum(valid_w),
          source_weight_sum=sum(w),ses_valid_n=sum(valid),ses_missing_n=sum(valid_w&!valid),
          ses_valid_weight_sum=sum(w[valid]),weighted_ses_coverage=sum(w[valid])/sum(w),
          group_n=observed_n,group_fractional_n=sum(member),group_weight_sum=sum(w*member),
          group_share_of_source_weight=sum(w*member)/sum(w),
          group_n_before_score_filter=before_score_n,
          group_weight_sum_before_score_filter=before_score_weight,
          group_complete_pv_n=sum(member>0&complete),required_pv_count=length(pv),
          recorded_n_min=min(declared),recorded_n_max=max(declared),
          n_matches_selected_results=all(declared==observed_n),
          cell_ids=paste(sort(z$cell_id[ix]),collapse=';'),
          result_set_sha256=digest::digest(identity,algo='sha256'),
          gender_definition=if(any(grepl('FEMALE_OR_OTHER_WHEN_UNSEPARATED',z$cell_id[ix],fixed=TRUE)))'FEMALE_OR_OTHER_WHEN_UNSEPARATED'else'EXACT_SOURCE_GENDER',
          denominator_note=if(group=='q4_minus_q1')'Union of tail members; weighted components remain in separate Q1 and Q4 rows'else if(!ishome&&!chosen)'Fractional books ties: group_n counts positive membership; group_weight_sum uses fractional membership'else'Chosen source definition and positive student weights',
          stringsAsFactors=FALSE)
      }))
      envelope<-list(key=key,rows=result,rows_sha256=digest::digest(result,algo='sha256'))
      temp<-tempfile('ses_review_',tmpdir=cache);saveRDS(envelope,temp)
      if(!file.rename(temp,saved_path))stop('SES_REVIEW_ATOMIC_CACHE_WRITE')
      rm(obj,d);gc(FALSE)
    }
    rows[[length(rows)+1L]]<-result
    proof[[length(proof)+1L]]<-data.frame(source_sha256=expected,check_key=key,
      output_sha256=digest::digest(file=saved_path,algo='sha256'),stringsAsFactors=FALSE)
  }
  all<-do.call(rbind,rows);all<-all[order(all$country,all$survey,all$year,all$domain,all$module,all$group),]
  write.csv(all,file.path(out,'SES_ANALYSIS_SAMPLE_COVERAGE.csv'),row.names=FALSE,na='')
  write.csv(do.call(rbind,proof),file.path(out,'SES_SOURCE_CHECKS.csv'),row.names=FALSE)
  bindings<-g[order(g$cell_id),c('cell_id','target_contract_sha256','result_hash','source_edition_sha256','n_unweighted')]
  write.csv(bindings,file.path(out,'SES_REVIEW_TARGET_BINDINGS.csv'),row.names=FALSE)
  summary<-list(status=if(all(all$n_matches_selected_results))'ACTUAL_SES_SAMPLE_COUNTS_VERIFIED'else'SES_SAMPLE_COUNT_DIFFERENCES_REQUIRE_REVIEW',
    selected_result_cells=nrow(g),source_files=length(groups),analysis_groups=nrow(all),
    count_mismatches=sum(!all$n_matches_selected_results),reused_source_checks=hits,
    source_rows_are_not_distinct_pupils_across_files=TRUE,
    outputs=list(coverage=digest::digest(file=file.path(out,'SES_ANALYSIS_SAMPLE_COVERAGE.csv'),algo='sha256'),
      sources=digest::digest(file=file.path(out,'SES_SOURCE_CHECKS.csv'),algo='sha256'),
      bindings=digest::digest(file=file.path(out,'SES_REVIEW_TARGET_BINDINGS.csv'),algo='sha256')),
    code_sha256=as.list(code),limitations='Coverage does not establish missing-at-random, measurement invariance or representativeness after nonresponse. PISA chosen SES may use the documented author imputation; observed components require their separate Q05 review.')
  jsonlite::write_json(summary,file.path(out,'SES_SAMPLE_REVIEW.json'),auto_unbox=TRUE,pretty=TRUE,digits=17)
  invisible(summary)
}
