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
cat('PASS country-only ranks, exact ties, explicit direction, unchanged full panel, provenance and no group rank\n')
