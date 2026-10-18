source("06_pipeline/MASTER_ESTIMATION_GRID.R")
source("06_pipeline/GRID_ARCHIVE_BATCH.R")
tasks <- data.frame(metric_key=c("k1","k2","k3"),
 survey="PISA",country="NLD",year="2022",domain="reading",
 module="core",stat="mean",group=c("total","girls","boys"),
 definition="score",peer_definition="",threshold="",unit="score_points",calculation_policy="",sample="NLD_2022")
g <- lo_grid_from_tasks(tasks)
sha <- function(z)paste(rep(z,64),collapse="")
candidate <- data.frame(cell_id="k1",status="SCIENTIFICALLY_VALIDATED",
 estimate=490,standard_error=3,n_unweighted=1500,
 sample_id="NLD_2022",method_version="m1",
 input_fingerprint=sha("a"),code_fingerprint=sha("b"),
 result_hash=sha("c"))
filled <- lo_grid_archive_fill(g,candidate)
stopifnot(filled$status[[1]]=="SCIENTIFICALLY_VALIDATED",
 is.na(filled$estimate[[2]]),filled$estimate[[1]]==490)
legacy<-candidate;legacy$age<-NA_character_;legacy$population_id<-''
metadata<-lo_grid_archive_fill(g,legacy)
stopifnot(metadata$age[1]=='age15',metadata$population_id[1]=='PISA_15_YEAR_OLD_TARGET',
 identical(metadata$result_hash,filled$result_hash),identical(metadata$estimate,filled$estimate))
legacy$age<-'age10'
stopifnot(inherits(try(lo_grid_archive_fill(g,legacy),silent=TRUE),'try-error'))
candidate$sample_id <- "UNRELATED_SAMPLE"
stopifnot(inherits(try(lo_grid_archive_fill(g,candidate),silent=TRUE),"try-error"))
candidate$sample_id <- "NLD_2022"
candidate$status <- "COMPUTED_PENDING_VALIDATION"
unchanged <- lo_grid_archive_fill(g,candidate)
stopifnot(all(is.na(unchanged$estimate)))
g$status[2:3] <- "COMPUTE_REQUIRED_AFTER_METHOD_GATE"
g$method_version[2:3] <- "m1"
g$input_fingerprint[2:3] <- sha("a")
g$weight_design[2:3] <- "weights1"
g$pv_rule[2:3] <- "PV10"
g$variance_rule[2:3] <- "FAYBRR"
batch <- lo_grid_batch_plan(g)
stopifnot(nrow(batch)==1L,batch$n_cells==2L)
g$pv_rule[[3]] <- ""
stopifnot(inherits(try(lo_grid_batch_plan(g),silent=TRUE),"try-error"))
cat("PASS strict archive provenance and two-cell shared-wave batch planning\n")


# Historical archives are candidates only; no estimates are invented.
cand <- lo_grid_mark_archive_candidates(lo_grid_from_tasks(tasks),c("k1","k2"),c("k2"))
stopifnot(cand$status[[1]]=="ARCHIVE_CANDIDATE_FOUND_NOT_VALIDATED",
          cand$status[[2]]=="ARCHIVE_CANDIDATE_FOUND_NOT_VALIDATED",
          cand$archive_source[[2]]=="LO02_CANDIDATE",
          all(is.na(cand$estimate)),
          nrow(lo_grid_batch_plan(cand))==0L)

# Grouped artifact verification must check every cell in each certificate,
# regardless of row order; late-row corruption must not evade the fast path.
tmp<-tempfile('grouped_certificates_');dir.create(tmp)
src<-file.path(tmp,'source.txt');writeLines('synthetic source',src)
r<-data.frame(cell_id=paste0('cell_',1:400),estimate=(1:400)/10,standard_error=2,n_unweighted=100,
 sample_id='sample',method_version='method',source_path=src,source_edition_sha256=digest::digest(file=src,algo='sha256'),
 target_contract_sha256=sha('a'),input_fingerprint=sha('b'),code_fingerprint=sha('c'),result_hash=sha('d'),
 weight_design='design',pv_rule='all_pv',variance_rule='all_replicates')
r$certification_path<-file.path(tmp,paste0('cert_',rep(1:4,each=100),'.json'))
for(p in unique(r$certification_path))jsonlite::write_json(list(status='SCIENTIFICALLY_VALIDATED',cells=r[r$certification_path==p,],
 evidence_files=data.frame(path=src,sha256=digest::digest(file=src,algo='sha256'))),p,auto_unbox=TRUE,digits=17)
r$certification_sha256<-vapply(r$certification_path,function(p)digest::digest(file=p,algo='sha256'),character(1))
lo_grid_verify_result_artifacts(r[400:1,])
for(field in c('estimate','standard_error','n_unweighted','method_version','target_contract_sha256','weight_design','pv_rule','variance_rule')) {
 bad<-r;if(is.numeric(bad[[field]]))bad[[field]][400]<-bad[[field]][400]+1 else bad[[field]][400]<-'changed'
 stopifnot(inherits(try(lo_grid_verify_result_artifacts(bad),silent=TRUE),'try-error'))
}
bad<-r;bad$cell_id[400]<-'unknown';stopifnot(inherits(try(lo_grid_verify_result_artifacts(bad),silent=TRUE),'try-error'))
writeLines('changed source',src)
stopifnot(inherits(try(lo_grid_verify_result_artifacts(r),silent=TRUE),'try-error'))
unlink(tmp,recursive=TRUE)
cat('PASS grouped certificate checks preserve every value/design/target comparison and fresh file hashes\n')

