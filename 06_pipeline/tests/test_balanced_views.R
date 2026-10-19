source('06_pipeline/tests/test_balanced_export.R')
source('06_pipeline/LO_BALANCED_VIEWS.R')
w<-tempfile('balance_views_');dir.create(w)
proof<-file.path(w,'review.txt');writeLines('Actual fixture comparison review',proof)
cert$evidence_files<-data.frame(path=proof,sha256=lo_exact_sha(proof))
p<-file.path(w,'cert.json');jsonlite::write_json(cert,p,auto_unbox=TRUE)
contracts$verification_path<-p;contracts$verification_sha256<-lo_exact_sha(p)
available<-lo_balance_result_adapter(g,contracts)
core_ids<-g$cell_id[g$country=='AAA' & g$split_dimension=='none']
view<-list(focus='AAA',view_id='gender',cell_ids=g$cell_id[g$country=='AAA'&g$split_dimension=='gender'])
x<-lo_balance_one_view(available,g,view,core_ids,c('AAA','BBB'),c('AAA','BBB'))
stopifnot(x$status=='BALANCED_REFERENCE_AVAILABLE',identical(x$default_members,'BBB'),
  nrow(x$default_points)==6L,length(x$required_cell_ids)==24L)
fast<-lo_balance_one_view(available,g,view,core_ids,c('AAA','BBB'),c('AAA','BBB'),
  context=lo_balance_view_context(available,c('AAA','BBB')))
stopifnot(isTRUE(all.equal(x,fast,check.attributes=FALSE)))
# A missing focus boy blocks the complete selected gender comparison, but an
# unrelated figure remains available; no shorter year set or girl-only panel.
bad<-g;bad$status[match(tail(view$cell_ids,1),bad$cell_id)]<-'SOURCE_MAPPING_REVIEW_REQUIRED'
x<-lo_balance_one_view(available,bad,view,core_ids,c('AAA','BBB'),c('AAA','BBB'))
stopifnot(x$status=='FOCUS_VIEW_INCOMPLETE',!length(x$default_members),length(x$required_cell_ids)==24L)
total<-list(focus='AAA',view_id='total',cell_ids=core_ids[1:3])
x<-lo_balance_one_view(available,bad,total,core_ids,c('AAA','BBB'),c('AAA','BBB'))
stopifnot(x$status=='BALANCED_REFERENCE_AVAILABLE',nrow(x$default_points)==3L)
# Missing a reference boy removes that country from BOTH group lines.
reference_bad<-available[!(available$country=='BBB'&available$split_group=='boy'&available$year=='2018'),]
x<-lo_balance_one_view(reference_bad,g,view,core_ids,c('AAA','BBB'),c('AAA','BBB'))
stopifnot(x$status=='NO_ELIGIBLE_REFERENCE',!length(x$default_members))
# Hiding a core year is never enough to relax membership.
bad<-g;bad$status[match(core_ids[1],bad$cell_id)]<-'UNAVAILABLE_VERIFIED_SOURCE_FIELD'
x<-lo_balance_one_view(available,bad,total,core_ids,c('AAA','BBB'),c('AAA','BBB'))
stopifnot(x$status=='FOCUS_CORE_INCOMPLETE')
unlink(w,recursive=TRUE)
cat('PASS independent joint views; unchanged full-country anchor; explicit missing focus; no silent group trimming\n')
