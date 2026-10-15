# Reuse certified scalars across run scopes without re-estimating pupil data.
# The destination keeps original producer/input identities and receipt history.
lo_scope_result_reuse <- function(repo,root,scope,grid) {
  source(file.path(repo,'06_pipeline/LO_COMPACT_GRID_STORE.R'))
  needed<-grid[grid$status=='SCIENTIFICALLY_VALIDATED',]
  con<-lo_compact_open(file.path(root,'FIXED_PRODUCTION_V1',scope,'compact'));on.exit(lo_compact_close(con))
  have<-DBI::dbGetQuery(con,'SELECT cell_id FROM grid')$cell_id
  needed<-needed[!needed$cell_id%in%have,];copied<-0L
  for(other in setdiff(c('nld_only','nld_plus_19','all_required'),scope)) {
    if(!nrow(needed))break
    path<-file.path(root,'FIXED_PRODUCTION_V1',other,'compact','COMPACT_MASTER_GRID.sqlite')
    if(!file.exists(path))next
    source_db<-DBI::dbConnect(RSQLite::SQLite(),path,flags=RSQLite::SQLITE_RO)
    tryCatch({
      d<-DBI::dbGetQuery(source_db,'SELECT * FROM grid');d<-d[d$cell_id%in%needed$cell_id,]
      if(nrow(d)) {
        a<-needed[match(d$cell_id,needed$cell_id),]
        stopifnot(all(d$input_fingerprint==a$input_fingerprint),all(d$producer_fingerprint==a$code_fingerprint),
          all(abs(d$estimate-as.numeric(a$estimate))<1e-10),all(abs(d$standard_error-as.numeric(a$standard_error))<1e-10),all(d$n_unweighted==as.numeric(a$n_unweighted)))
        DBI::dbWithTransaction(con,{
          lo_compact_put(con,d,transaction=FALSE)
          for(table in intersect(c('execution_receipts','measured_execution_receipts','derivation_receipts'),DBI::dbListTables(source_db))) {
            receipt<-DBI::dbGetQuery(source_db,paste('SELECT * FROM',table));receipt<-receipt[receipt$cell_id%in%d$cell_id,]
            if(!table%in%DBI::dbListTables(con))DBI::dbWriteTable(con,table,receipt[FALSE,])
            existing<-DBI::dbReadTable(con,table);receipt<-receipt[!receipt$cell_id%in%existing$cell_id,]
            if(nrow(receipt))DBI::dbWriteTable(con,table,receipt,append=TRUE)
          }
        })
        copied<-copied+nrow(d);needed<-needed[!needed$cell_id%in%d$cell_id,]
      }
    },finally=DBI::dbDisconnect(source_db))
  }
  if(nrow(needed))stop('CERTIFIED_RESULT_HAS_NO_VERIFIED_COMPACT_COPY: ',needed$cell_id[1])
  cat('CERTIFIED_SCOPE_REUSE',copied,'rows; no pupil recalculation\n');invisible(copied)
}
