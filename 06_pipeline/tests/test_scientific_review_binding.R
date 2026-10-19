source('06_pipeline/MASTER_ESTIMATION_GRID.R')
source('06_pipeline/LO_BALANCED_MEMBERSHIP.R')
source('06_pipeline/LO_SCIENTIFIC_REVIEW_BINDING.R')
source('06_pipeline/LO_PAPER_GATE_EVIDENCE.R')
w<-tempfile('scientific_binding_');dir.create(w)
repo<-file.path(w,'repo');root<-file.path(w,'root');state<-file.path(w,'state')
for(p in c(file.path(repo,'06_pipeline/review_20261013'),file.path(root,'master_reconciliation'),
  file.path(root,'scientific_review_20261019/Q06_mapping_final'),state))dir.create(p,recursive=TRUE)
file.copy('06_pipeline/LO_ATOMIC_CHECKPOINT.R',file.path(repo,'06_pipeline/LO_ATOMIC_CHECKPOINT.R'))
file.copy('06_pipeline/review_20261013/PAPER_QA_CURRENT.json',file.path(repo,'06_pipeline/review_20261013/PAPER_QA_CURRENT.json'))
sha<-function(p)digest::digest(file=p,algo='sha256')
tasks<-data.frame(metric_key='NLD|PISA|2025|reading|core|mean|total|total|||score_points|',
 country='NLD',survey='PISA',year='2025',domain='reading',module='core',stat='mean',group='total',
 definition='total',peer_definition='',threshold='',contract_figure_id='TR_MEAN_age15_reading',
 unit='score_points',calculation_policy='')
target<-lo_grid_from_tasks(tasks)[c('cell_id','target_contract_sha256')]
contracts<-file.path(root,'scientific_review_20261019/targets.csv');write.csv(target,contracts,row.names=FALSE)
approval<-file.path(root,'master_reconciliation/SCIENTIFICALLY_VALIDATED_GRID_CELLS.csv')
write.csv(data.frame(cell_id=tasks$metric_key,estimate=500),approval,row.names=FALSE)
proof<-file.path(root,'review.txt');writeLines('Synthetic reviewed evidence for receipt regression',proof)
binding<-file.path(repo,'review_policy.txt');writeLines('policy version one',binding)
map<-as.data.frame(setNames(rep(list('none'),length(lo_balance_columns())),lo_balance_columns()))
map$year<-'2025';map$cell_id<-tasks$metric_key;map$result_hash<-'synthetic-result'
write.csv(map,file.path(root,'scientific_review_20261019/Q06_mapping_final/BALANCE_AVAILABLE.csv'),row.names=FALSE)
z<-list(schema_version=1L,status='REVIEWED_SCIENTIFIC_BASIS_WITH_EXPLICIT_LIMITATIONS',
 approval_sha256=sha(approval),target_contracts_path=contracts,target_contracts_sha256=sha(contracts),
 runtime_bindings=data.frame(path='review_policy.txt',sha256=sha(binding)),
 reviews=data.frame(requirement_id=sprintf('Q%02d',1:8),assessment='Synthetic meaningful fixture proof',
   applicability='APPLICABLE_REVIEWED_WITH_QUALIFICATIONS',report_path=proof,report_sha256=sha(proof)),
 evidence_files=data.frame(path=proof,sha256=sha(proof)))
manifest<-file.path(root,'scientific_review_20261019/SCIENTIFIC_REVIEW_MANIFEST.json')
jsonlite::write_json(z,manifest,auto_unbox=TRUE)
first<-lo_scientific_review_install(repo,root,tasks,approval,state)
times<-file.info(first$evidence_path)$mtime
again<-lo_scientific_review_install(repo,root,tasks,approval,state)
stopifnot(identical(first$evidence_sha256,again$evidence_sha256),identical(times,file.info(again$evidence_path)$mtime))
policy<-jsonlite::fromJSON(file.path(repo,'06_pipeline/review_20261013/PAPER_QA_CURRENT.json'))$requirements
stopifnot(length(lo_paper_gate_evidence(first,tasks,approval,digest::digest(policy,algo='sha256'),repo))==8L)
bad<-tasks;bad$unit<-'changed'
stopifnot(inherits(try(lo_scientific_review_install(repo,root,bad,approval,state),silent=TRUE),'try-error'))
writeLines('changed policy',binding)
stopifnot(inherits(try(lo_paper_gate_evidence(first,tasks,approval,repo=repo),silent=TRUE),'try-error'))
writeLines('policy version one',binding)
writeLines('tampered scientific evidence',proof)
stopifnot(inherits(try(lo_scientific_review_install(repo,root,tasks,approval,state),silent=TRUE),'try-error'))
writeLines('Synthetic reviewed evidence for receipt regression',proof)
write.csv(data.frame(cell_id=tasks$metric_key,estimate=501),approval,row.names=FALSE)
stopifnot(inherits(try(lo_scientific_review_install(repo,root,tasks,approval,state),silent=TRUE),'try-error'))
unlink(w,recursive=TRUE)
cat('PASS immutable Q receipts, exact second-run reuse, changed policy/source/target/result rejection\n')
