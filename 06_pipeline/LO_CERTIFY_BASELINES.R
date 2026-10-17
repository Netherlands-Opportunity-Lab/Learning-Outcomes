lo_certify_population_baselines <- function(repo,root,scope,tasks) {
  for(f in c('MASTER_ESTIMATION_GRID.R','GRID_ARCHIVE_BATCH.R','LO_DERIVE_POPULATION_BASELINES.R','LO_COMPACT_RECOMPUTE.R','LO_COMPACT_GRID_STORE.R','LO_ATOMIC_CHECKPOINT.R'))source(file.path(repo,'06_pipeline',f))
  master<-file.path(root,'master_reconciliation');path<-file.path(master,'SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv')
  old<-read.csv(path,stringsAsFactors=FALSE,na.strings=character())
  key<-function(x)paste(x$country,x$survey,x$year,x$domain,x$threshold,sep='|')
  core<-tasks[tasks$module=='core'&tasks$stat=='total_high'&tasks$metric_key%in%old$cell_id,]
  tasks<-tasks[tasks$module!='peer_baseline'|tasks$stat!='high_share'|key(tasks)%in%key(core),]
  x<-lo_derive_population_baselines(tasks,old);if(!nrow(x$tasks))return(invisible(0L))
  stopifnot(lo_grid_verify_result_artifacts(x$parents))
  code<-file.path(repo,'06_pipeline/LO_DERIVE_POPULATION_BASELINES.R');sha<-function(p)digest::digest(file=p,algo='sha256')
  id<-digest::digest(list(x$tasks,x$parents$result_hash,sha(code)),algo='sha256')
  out<-file.path(root,'international','derived',id);dir.create(out,recursive=TRUE,showWarnings=FALSE)
  frozen<-file.path(out,'VERIFIER_DERIVATION.R');if(!file.exists(frozen))stopifnot(file.copy(code,frozen))
  x$rows$code_fingerprint<-sha(code)
  x$rows$input_fingerprint<-vapply(seq_len(nrow(x$parents)),function(i)digest::digest(x$parents[i,c('cell_id','estimate','standard_error','n_unweighted','result_hash','certification_sha256')],algo='sha256'),character(1))
  lineage<-data.frame(cell_id=x$rows$cell_id,parent_cell_id=x$parents$cell_id,parent_result_sha256=x$parents$result_hash,multiplier=100)
  write.csv(lineage,file.path(out,'EXACT_PARENT_LINEAGE.csv'),row.names=FALSE)
  rows<-do.call(rbind,lapply(seq_len(nrow(x$tasks)),function(i){q<-x$tasks[i,];z<-data.frame(metric_key=q$metric_key,estimate=x$rows$estimate[i],se=x$rows$standard_error[i]);lo_compact_science_rows(q,z,x$rows$n_unweighted[i],x$rows$input_fingerprint[i],x$rows$code_fingerprint[i],x$rows$method_version[i])}))
  con<-lo_compact_open(file.path(root,'FIXED_PRODUCTION_V1',scope,'compact'));on.exit(lo_compact_close(con))
  DBI::dbWithTransaction(con,{
    lo_compact_put(con,rows,transaction=FALSE)
    DBI::dbExecute(con,'CREATE TABLE IF NOT EXISTS derivation_receipts (cell_id TEXT PRIMARY KEY,parent_cell_id TEXT NOT NULL,parent_result_sha256 TEXT NOT NULL,multiplier REAL NOT NULL)')
    for(i in seq_len(nrow(lineage)))DBI::dbExecute(con,'INSERT OR REPLACE INTO derivation_receipts VALUES (?,?,?,?)',params=unname(as.list(lineage[i,])))
  })
  x$rows$result_hash<-vapply(x$rows$cell_id,function(id)digest::digest(DBI::dbGetQuery(con,'SELECT * FROM grid WHERE cell_id=?',params=list(id)),algo='sha256'),character(1))
  ef<-unique(c(frozen,file.path(out,'EXACT_PARENT_LINEAGE.csv'),x$parents$certification_path));cert<-file.path(out,'RESULT_CERTIFICATE.json')
  jsonlite::write_json(list(status='SCIENTIFICALLY_VALIDATED',cells=x$rows,evidence_files=data.frame(path=ef,sha256=vapply(ef,sha,character(1))),pupil_recalculations=0L,validation='Exact national core threshold and population; estimate and SE multiplied by 100, N preserved'),cert,auto_unbox=TRUE,pretty=TRUE,digits=17)
  x$rows$certification_path<-cert;x$rows$certification_sha256<-sha(cert)
  stopifnot(lo_grid_verify_result_artifacts(x$rows))
  cols<-union(names(old),names(x$rows));for(k in setdiff(cols,names(old)))old[[k]]<-'';for(k in setdiff(cols,names(x$rows)))x$rows[[k]]<-''
  lo_atomic_csv(rbind(old[cols],x$rows[cols]),path)
  cat('CERTIFIED_DERIVED_BASELINES',nrow(x$rows),'NO_PUPIL_RECALCULATION\n');invisible(nrow(x$rows))
}
