source('06_pipeline/tests/test_balanced_membership.R')
source('06_pipeline/LO_COUNTRY_RANKS.R')
required_full<-unique(rbind(required,all_core[all_core$country=='NLD',lo_balance_columns()]))
plot_keys<-lo_balance_key(required)
r<-lo_country_rank_series(all_data,required_full,plot_keys,c('AAA','BBB'),'NLD','largest_first','BBB')
stopifnot(nrow(r$rows)==12L,all(r$rows$rank[r$rows$country=='NLD']==1),
  all(r$rows$rank[r$rows$country=='BBB']==2),all(r$rows$n_ranked==3),
  !r$reference_group_plotted,!r$group_rank_produced,!any(c('se','standard_error')%in%names(r$rows)),
  identical(r$reference_members,c('AAA','BBB')))
stopifnot(identical(r,lo_country_rank_series(all_data,required_full,rev(plot_keys),c('BBB','AAA'),'NLD','largest_first','BBB')))
# Direction is recorded, not silently inferred from a signed gap.
s<-lo_country_rank_series(all_data,required_full,plot_keys,c('AAA','BBB'),'NLD','smallest_first')
stopifnot(all(s$rows$rank==3),all(s$rows$direction=='smallest_first'))
tie<-all_data;tie$estimate[tie$country=='BBB'&tie$split_dimension=='gender']<-900
z<-lo_country_rank_series(tie,required_full,plot_keys,c('AAA','BBB'),'NLD','largest_first','BBB')
stopifnot(all(z$rows$rank==1.5))
# The same rounded label is not an exact tie; parent changes change provenance.
tie$estimate[tie$country=='BBB'&tie$split_dimension=='gender']<-899.99999
z<-lo_country_rank_series(tie,required_full,plot_keys,c('AAA','BBB'),'NLD','largest_first','BBB')
stopifnot(all(z$rows$rank[z$rows$country=='NLD']==1),
  !identical(z$rows$parent_set_sha256,r$rows$parent_set_sha256))
stopifnot(fails(lo_country_rank_series(all_data,required_full,plot_keys,'AAA','NLD','largest_first','BBB')),
  fails(lo_country_rank_series(all_data,required_full,plot_keys,character(),'NLD','largest_first')),
  fails(lo_country_rank_series(all_data,required_full,plot_keys,c('NLD','AAA'),'NLD','largest_first')),
  fails(lo_country_rank_series(all_data,required_full,'invented_key','AAA','NLD','largest_first')),
  fails(lo_country_rank_series(all_data,required_full,plot_keys,'AAA','NLD','higher_is_better')))
missing<-all_data[!(all_data$country=='BBB'&all_data$year=='2018'&all_data$split_group=='boy'),]
stopifnot(fails(lo_country_rank_series(missing,required_full,plot_keys,c('AAA','BBB'),'NLD','largest_first')))
# A signed gap is ordered by explicit magnitude, matching the retained UI.
gap<-all_data
gap$estimate[gap$country=='NLD'&gap$split_dimension=='gender']<--20
gap$estimate[gap$country=='AAA'&gap$split_dimension=='gender']<-10
gap$estimate[gap$country=='BBB'&gap$split_dimension=='gender']<-20
z<-lo_country_rank_series(gap,required_full,plot_keys,c('AAA','BBB'),'NLD',
  'smallest_first','BBB',transform='absolute')
stopifnot(all(z$rows$rank==2.5),all(z$rows$source_estimate[z$rows$country=='NLD']==-20),
  all(z$rows$transform=='absolute'),
  fails(lo_country_rank_series(gap,required_full,plot_keys,'AAA','NLD','smallest_first',transform='round')))
policy<-jsonlite::fromJSON('06_pipeline/review_20261013/RANK_PRODUCT_CONTRACT.json')$computation$outcome_rank_rules
js<-paste(readLines('05_publication/preview_overlay/assets/explorer.mjs',warn=FALSE),collapse='\n')
for(measure in names(policy)) {
  rule<-policy[[measure]]
  direction<-if(rule$direction=='largest_first')'descending'else'ascending'
  needle<-paste0(measure,":{direction:'",direction,"',transform:'",rule$transform,"'}")
  stopifnot(grepl(needle,js,fixed=TRUE))
}
cat('PASS country-only ranks, exact transformed ties, UI-policy parity, full panel and no group rank\n')
