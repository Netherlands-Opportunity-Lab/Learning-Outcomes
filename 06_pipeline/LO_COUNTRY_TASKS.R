# Apply the human-approved statistic contracts consistently to every admitted
# country. The immutable historical task catalogue remains provenance. It is
# not a country whitelist and cannot omit newly discovered eligible countries.
lo_country_base_tasks <- function(tasks,scope_info) {
  if(anyDuplicated(tasks$metric_key))stop('COUNTRY_TEMPLATE_DUPLICATE_CONTRACT')
  template<-tasks[tasks$country=='NLD',,drop=FALSE]
  if(!nrow(template))stop('COUNTRY_TEMPLATE_MISSING')
  support<-scope_info$source_support
  # Admission excludes corrected populations/non-comparable waves. A correction
  # must not silently shorten an admitted focus country's historical anchor.
  # Retain its reviewed target contexts; comparison eligibility remains separate.
  excluded<-attr(support,'population_exclusions')
  contexts_support<-support[c('country','survey','year')]
  if(is.data.frame(excluded)&&nrow(excluded))contexts_support<-unique(rbind(
    contexts_support,excluded[c('country','survey','year')]))
  parts<-list(template[template$country%in%scope_info$selected,,drop=FALSE])
  for(country in setdiff(scope_info$selected,'NLD')) {
    contexts<-unique(contexts_support[contexts_support$country==country,c('survey','year')])
    keys<-paste(contexts$survey,contexts$year)
    z<-template[paste(template$survey,template$year)%in%keys,,drop=FALSE]
    if(!nrow(z))stop('COUNTRY_HAS_NO_REVIEWED_CYCLE_CONTRACT: ',country)
    z$country<-country
    if(any(!startsWith(z$metric_key,'NLD|')))stop('COUNTRY_TEMPLATE_KEY_MISMATCH')
    z$metric_key<-sub('^NLD[|]',paste0(country,'|'),z$metric_key)
    parts[[length(parts)+1L]]<-z
  }
  result<-do.call(rbind,parts);rownames(result)<-NULL
  if(anyDuplicated(result$metric_key))stop('COUNTRY_EXPANSION_DUPLICATE')
  result
}
