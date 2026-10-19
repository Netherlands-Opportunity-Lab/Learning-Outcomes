# A09: rank a country relative to the selected, constant comparison group.
# This aggregate-only derivation never estimates a pupil statistic, a group
# rank, or an uncertainty interval for a rank. Direction is explicit and is
# descriptive (largest/smallest value first), not a welfare judgement.
lo_country_rank_series <- function(available,required,plot_keys,selected,focus,
                                   direction,other=NULL,transform='identity') {
  if(length(direction)!=1L || !direction%in%c('largest_first','smallest_first'))
    stop('RANK_EXPLICIT_DIRECTION_REQUIRED')
  if(length(transform)!=1L || !transform%in%c('identity','absolute'))
    stop('RANK_EXPLICIT_TRANSFORM_REQUIRED')
  if(length(focus)!=1L || focus%in%selected)stop('RANK_FOCUS_NOT_REFERENCE_MEMBER')
  selected<-sort(unique(selected))
  if(!length(selected))stop('RANK_REFERENCE_GROUP_EMPTY')
  # Another displayed country belongs to the same selected universe. Adding
  # an unselected country must be an explicit checkbox change, not an invisible
  # change of the Dutch rank denominator.
  if(!is.null(other) && (length(other)!=1L || !other%in%selected))
    stop('RANK_OTHER_COUNTRY_MUST_BELONG_TO_SELECTED_REFERENCE')
  keys<-sort(unique(plot_keys));required_keys<-lo_balance_key(required)
  if(!length(keys)||!all(keys%in%required_keys))stop('RANK_UNAPPROVED_OR_EMPTY_PLOT_KEYS')
  options<-lo_dashboard_reference_options(available,required,selected,focus)
  if(!all(options$eligible))stop('RANK_INCOMPLETE_OR_INCOMPATIBLE_REFERENCE')
  x<-lo_balance_validated(available)
  universe<-sort(c(focus,selected));display<-c(focus,other)
  rows<-list();parents<-list()
  for(key in keys) {
    z<-x[x$balance_key==key & x$country%in%universe,,drop=FALSE]
    z<-z[match(universe,z$country),,drop=FALSE]
    if(nrow(z)!=length(universe)||anyNA(z$country))stop('RANK_INCOMPLETE_CONSTANT_UNIVERSE')
    values<-if(transform=='absolute')abs(z$estimate)else z$estimate
    ranked<-rank(if(direction=='largest_first')-values else values,ties.method='average')
    # Exact stored doubles determine ties. Display rounding never changes ranks.
    ids<-data.frame(country=z$country,result_hash=z$source_record_id,
      verification_id=z$verification_id,estimate=z$estimate,stringsAsFactors=FALSE)
    parents[[key]]<-ids
    parent_hash<-digest::digest(ids,algo='sha256')
    for(country in display) {
      j<-match(country,z$country)
      rows[[length(rows)+1L]]<-data.frame(country=country,year=z$year[j],balance_key=key,
        rank=ranked[j],source_estimate=z$estimate[j],n_ranked=length(universe),direction=direction,
        transform=transform,ties='AVERAGE_EXACT_STORED_VALUES_AFTER_EXPLICIT_TRANSFORM',
        reference_members=paste(selected,collapse=';'),ranked_members=paste(universe,collapse=';'),
        parent_set_sha256=parent_hash,own_result_hash=z$source_record_id[j],
        uncertainty_status='DESCRIPTIVE_POINT_RANK_NO_RANK_CI',stringsAsFactors=FALSE)
    }
  }
  list(schema_version=1L,approval_id='A09',focus=focus,other=other,
    reference_group_plotted=FALSE,group_rank_produced=FALSE,
    full_required_keys=sort(unique(required_keys)),reference_members=selected,
    rows=do.call(rbind,rows),parents=parents,
    limitations='Point ranks do not establish significant differences between countries.')
}
