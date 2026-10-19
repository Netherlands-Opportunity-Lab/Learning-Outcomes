# Real aggregate probes for Q06. Membership is certified for every exported
# view; these probes independently exercise averages, ranks and dependencies.
lo_reference_review <- function(repo,audit,out) {
  source(file.path(repo,'06_pipeline/LO_BALANCED_MEMBERSHIP.R'),local=environment())
  source(file.path(repo,'06_pipeline/LO_COUNTRY_REGISTRY.R'),local=environment())
  source(file.path(repo,'06_pipeline/LO_COUNTRY_RANKS.R'),local=environment())
  sha<-function(p)digest::digest(file=p,algo='sha256')
  file<-file.path(audit,'BALANCED_REFERENCE_EXPORT.json')
  export<-jsonlite::fromJSON(file,simplifyVector=FALSE)
  if(is.null(export$figure_registry_sha256)||
     sha(file.path(audit,'FIGURES.json'))!=export$figure_registry_sha256)
    stop('REFERENCE_REVIEW_CHANGED_FIGURE_REGISTRY')
  available<-read.csv(file.path(audit,'BALANCE_AVAILABLE.csv'),colClasses='character',na.strings=character())
  checked<-lo_balance_validated(available)
  if(sha(file.path(audit,'BALANCE_AVAILABLE.csv'))!=export$mapping_evidence$available_sha256)
    stop('REFERENCE_REVIEW_CHANGED_INPUT')
  dictionary<-unlist(export$key_dictionary);rows<-list();ranks<-list();parents<-list();counts<-list()
  rank_policy<-file.path(repo,'06_pipeline/review_20261013/RANK_PRODUCT_CONTRACT.json')
  rank_rules<-jsonlite::fromJSON(rank_policy,simplifyVector=FALSE)$computation$outcome_rank_rules
  if(is.null(rank_rules))stop('REFERENCE_REVIEW_RANK_RULES_MISSING')
  for(v in export$views) {
    opts<-v$options
    counts[[length(counts)+1L]]<-data.frame(country=v$focus,figure_id=v$figure_id,status=v$status,
      eligible_countries=paste(vapply(Filter(function(x)isTRUE(x$eligible),opts),function(x)x$country,character(1)),collapse=';'),
      default_countries=paste(unlist(v$default_members),collapse=';'),
      missing_focus_cells=if(is.null(v$missing_core_cells)&&is.null(v$missing_view_points))0L else
        sum(unlist(c(v$missing_core_cells,v$missing_view_points))))
    if(v$focus!='NLD'||!grepl('^(TR_MEAN|GP_SES_GAP|EN_PERFORMANCE_PEER_HIGH)_',v$figure_id)||
       v$status!='BALANCED_REFERENCE_AVAILABLE')next
    keys<-dictionary[unlist(v$required_keys)]
    req<-checked[checked$country=='NLD'&checked$balance_key%in%keys,,drop=FALSE]
    plot<-checked$balance_key[match(unlist(v$view_cell_ids),checked$cell_id)]
    if(!setequal(lo_balance_key(req),keys)||anyNA(plot))stop('REFERENCE_REVIEW_FULL_ANCHOR')
    eligible<-vapply(Filter(function(x)isTRUE(x$eligible),opts),function(x)x$country,character(1))
    for(selection in c('DEFAULT_RICH','ALL_ELIGIBLE')) {
      selected<-if(selection=='DEFAULT_RICH')unlist(v$default_members)else eligible
      if(!length(selected))next
      # The full figure requirements already contain its unchanged core years
      # and every jointly compared group. Unrelated figures/countries cannot
      # affect this derivation. Retain ALL required keys and the whole selected
      # universe, then exercise the same admission/average/rank functions.
      selected_cells<-checked[checked$country%in%c('NLD',selected)&checked$balance_key%in%keys,,drop=FALSE]
      derived<-lo_dashboard_reference_points(selected_cells,req,selected,'NLD')$points
      derived<-derived[derived$balance_key%in%plot,,drop=FALSE]
      if(nrow(derived)!=length(unique(plot)))stop('REFERENCE_REVIEW_TRUNCATED_PLOT')
      for(k in seq_len(nrow(derived))) {
        z<-selected_cells[selected_cells$country%in%selected & selected_cells$balance_key==derived$balance_key[k],]
        if(nrow(z)!=length(selected)||abs(sum(z$estimate/length(selected))-derived$estimate[k])>1e-10)
          stop('REFERENCE_REVIEW_COUNTRY_WEIGHTING')
        parents[[length(parents)+1L]]<-data.frame(figure_id=v$figure_id,selection=selection,
          balance_key=derived$balance_key[k],country=z$country,cell_id=z$cell_id,
          result_hash=z$result_hash,verification_id=z$verification_id,weight=1/length(selected))
      }
      derived$figure_id<-v$figure_id;derived$selection<-selection;rows[[length(rows)+1L]]<-derived
      # Rank only approved dashboard rank measures, using the same explicit
      # direction/transform as the retained display. Peer means are tested
      # above; the UI does not offer peer ranks.
      if(grepl('^(TR_MEAN|GP_SES_GAP)_',v$figure_id)) {
        rule<-rank_rules[[if(startsWith(v$figure_id,'TR_MEAN_'))'mean_score'else'gap']]
        rank<-lo_country_rank_series(selected_cells,req,plot,selected,'NLD',rule$direction,
          sort(selected)[1],transform=rule$transform)
        stopifnot(!rank$reference_group_plotted,!rank$group_rank_produced,
          all(rank$rows$n_ranked==length(selected)+1L))
        z<-rank$rows;z$figure_id<-v$figure_id;z$selection<-selection;ranks[[length(ranks)+1L]]<-z
      }
      cat('REFERENCE_NUMERICAL_PROBE ',v$figure_id,' ',selection,' ',nrow(selected_cells),' exact cells\n',sep='');flush.console()
    }
  }
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  files<-c(REFERENCE_BY_VIEW='REFERENCE_BY_VIEW.csv',REFERENCE_NUMERICAL_PROBES='REFERENCE_NUMERICAL_PROBES.csv',
    RANK_NUMERICAL_PROBES='RANK_NUMERICAL_PROBES.csv',REFERENCE_DEPENDENCIES='REFERENCE_DEPENDENCIES.csv')
  for(n in names(files))write.csv(switch(n,REFERENCE_BY_VIEW=do.call(rbind,counts),
    REFERENCE_NUMERICAL_PROBES=do.call(rbind,rows),RANK_NUMERICAL_PROBES=do.call(rbind,ranks),
    REFERENCE_DEPENDENCIES=do.call(rbind,parents)),file.path(out,files[[n]]),row.names=FALSE,na='')
  jsonlite::write_json(list(status='FULL_ANCHORS_AND_ACTUAL_MEAN_RANK_DERIVATIONS_VERIFIED',
    views=length(counts),probe_views=length(rows),policy=export$policy,
    mapping_review_sha256=sha(file.path(audit,'BALANCE_MAPPING_REVIEW.json')),
    reference_export_sha256=sha(file),admitted_countries=sum(vapply(export$admission,function(x)isTRUE(x$dashboard_eligible),logical(1))),
    figure_registry_sha256=export$figure_registry_sha256,
    rank_rule_policy_sha256=sha(rank_policy),
    code_sha256=as.list(vapply(c('LO_REFERENCE_REVIEW.R','LO_COUNTRY_RANKS.R','LO_BALANCED_MEMBERSHIP.R',
      'LO_DASHBOARD_REFERENCE_EXPORT.R'),function(n)sha(file.path(repo,'06_pipeline',n)),character(1))),
    output_sha256=as.list(vapply(files,function(n)sha(file.path(out,n)),character(1))),
    no_pupil_recalculation=TRUE,benchmark_or_rank_ci=FALSE),file.path(out,'REFERENCE_REVIEW.json'),
    pretty=TRUE,auto_unbox=TRUE,digits=17)
}
