source("06_pipeline/MASTER_ESTIMATION_GRID.R",encoding="UTF-8")
task<-data.frame(metric_key=c("m1","m2"),survey="PISA",
 country="NLD",year="2022",domain="reading",module=c("core","gender"),
 stat="mean",group=c("total","girls"),definition="score",
 peer_definition="",threshold="",unit="score_points",calculation_policy="",stringsAsFactors=FALSE)
g<-lo_grid_from_tasks(task)
stopifnot(nrow(g)==2L,all(is.na(g$estimate)),all(is.na(g$standard_error)),
 all(is.na(g$n_unweighted)),!anyDuplicated(g$cell_id),
 identical(names(g),lo_grid_schema()))
stopifnot(all(g$age=='age15'),all(g$population_id=='PISA_15_YEAR_OLD_TARGET'))
primary<-transform(task,survey='PIRLS')
stopifnot(all(lo_grid_from_tasks(primary)$population_id=='IEA_INTERNATIONAL_GRADE_4'),
 all(lo_grid_from_tasks(primary)$age=='age10'))
stopifnot(inherits(try(lo_grid_from_tasks(transform(task,age='10')),silent=TRUE),'try-error'))
stopifnot(inherits(try(lo_grid_from_tasks(transform(task,contract_figure_id='TR_MEAN_age10_reading')),silent=TRUE),'try-error'))
candidate<-data.frame(cell_id="m1",estimate=490,standard_error=3,
 n_unweighted=1500,input_fingerprint=paste(rep("a",64),collapse=""),
 code_fingerprint=paste(rep("b",64),collapse=""),
 result_hash=paste(rep("c",64),collapse=""),method_version="v1",
 sample_id="PISA_NLD_2022",status="SCIENTIFICALLY_VALIDATED")
stopifnot(isTRUE(lo_grid_validate_fill(g,candidate)))
candidate$standard_error<- -3
stopifnot(inherits(try(lo_grid_validate_fill(g,candidate),silent=TRUE),"try-error"))
candidate$standard_error<-3
candidate$status<-"COMPUTED_PENDING_VALIDATION"
err<-try(lo_grid_validate_fill(g,candidate),silent=TRUE)
stopifnot(inherits(err,"try-error"))
cat("PASS grid schema, blank-first and strict scientific fill gate\n")


# New below-basic peers are independent target cells, never aliases of the
# old advanced/high-peer observations.
oldpeer <- task[1L,,drop=FALSE]
oldpeer$module <- "high_proficiency_peer_exposure"
oldpeer$stat <- "self_high"
oldpeer$group <- "self_high"
oldpeer$definition <- "high_peer_raw_sample"
oldpeer$peer_definition <- "whole_school"
oldpeer$contract_figure_id <-
   "EN_PERFORMANCE_PEER_age15_reading_whole_school"
peer <- lo_grid_new_low_peer_tasks(oldpeer)
stopifnot(nrow(peer)==3L,
   setequal(peer$group,c("total","self_below_basic",
                        "self_at_or_above_basic")),
   all(peer$threshold=="PISA_BELOW_LEVEL2"),
   all(peer$module=="peer_below_basic"),
   all(!peer$metric_key%in%oldpeer$metric_key))
target <- lo_grid_from_tasks(peer)
stopifnot(all(grepl("^[0-9a-f]{64}$",target$target_contract_sha256)),
          !anyDuplicated(target$cell_id))

