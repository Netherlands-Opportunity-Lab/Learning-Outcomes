# Exact approved-cell execution. No directory-wide cache search or implicit work.
# Real method/source certification remains a prerequisite; output is a candidate.
lo_exact_sha <- function(path) {
  if(length(path)!=1L || is.na(path) || !file.exists(path) || dir.exists(path))
    stop("EXACT_SOURCE_MISSING")
  digest::digest(file=path,algo="sha256")
}
lo_exact_assert_sha <- function(path,expected,label) {
  if(!grepl("^[a-f0-9]{64}$",expected) || !identical(lo_exact_sha(path),expected))
    stop("EXACT_CHANGED_",label)
}
lo_exact_producer_files <- function(repo,bundle) c(
  file.path(bundle,"engine",c("V11.R","BACKEND.R","REPAIRS.R","EXTENSIONS.R","engine.R","store.R")),
  file.path(bundle,"code",c("LO04_CACHE.R","LO04_COMMON.R")),
  file.path(repo,"06_pipeline",c("LO_COMPACT_RECOMPUTE.R","LO_EXACT_DISPATCH.R","LO_PRODUCTION_SPACE.R",
    "LO_EXACT_ESTIMATORS.R","LO_APPROVED_EXTENSIONS.R","LO_SCOPE_DECISIONS.R","LO_EXACT_BOOT.R","LO_SOURCE_REPAIR.R","LO_PROCESS_LOCK.R","LO_GENDER_POOL_POLICY.R")))
lo_exact_code_sha <- function(repo,bundle) digest::digest(
  unname(vapply(lo_exact_producer_files(repo,bundle),lo_exact_sha,character(1))),algo="sha256")

lo_exact_prepare <- function(tasks,grid,scope_info,decisions) {
  need<-c("cell_id","status","target_contract_sha256")
  if(!all(need%in%names(grid)) || anyDuplicated(grid$cell_id))stop("EXACT_INVALID_GRID")
  if(anyDuplicated(tasks$metric_key))stop("EXACT_DUPLICATE_TASK")
  work<-grid[grid$status=="COMPUTE_REQUIRED_AFTER_METHOD_GATE",,drop=FALSE]
  if(!nrow(work))return(list(tasks=tasks[FALSE,,drop=FALSE],grid=work))
  i<-match(work$cell_id,tasks$metric_key)
  if(anyNA(i))stop("EXACT_UNCONTRACTED_CELL")
  q<-tasks[i,,drop=FALSE]
  if(any(!q$country%in%scope_info$selected))stop("EXACT_COUNTRY_OUTSIDE_SCOPE")
  if(any(!q$metric_key%in%lo_scope_active_tasks(q,decisions)$metric_key))
    stop("EXACT_CELL_EXCLUDED_BY_USER_SCOPE")
  family<-sub("_age.*$","",q$contract_figure_id)
  if(any(family=="TR_BASIC"))stop("EXACT_DROPPED_COMPLEMENT")
  if(any(family=="GP_SES_HIGH") && !lo_scope_is_approved(decisions,"A02"))stop("EXACT_PENDING_A02")
  if(any(q$module=="peer_below_basic") && !lo_scope_is_approved(decisions,"A01"))stop("EXACT_PENDING_A01")
  if(any(family=="EN_PERFORMANCE_PEER" & q$module!="peer_below_basic") &&
     !lo_scope_is_approved(decisions,"A03"))stop("EXACT_PENDING_A03")
  target<-lo_grid_from_tasks(q)
  if(anyNA(work$target_contract_sha256) ||
     !identical(as.character(target$target_contract_sha256),as.character(work$target_contract_sha256)))
    stop("EXACT_TARGET_CONTRACT_CHANGED")
  required<-c("source_path","source_edition_sha256","input_fingerprint","code_fingerprint",
    "sample_id","method_version","weight_design","pv_rule","variance_rule",
    "certification_path","certification_sha256")
  if(!all(required%in%names(work)) || anyNA(work[required]) ||
     any(vapply(work[required],function(x)any(!nzchar(trimws(as.character(x)))),logical(1))))
    stop("EXACT_INCOMPLETE_SOURCE_METHOD_CERTIFICATE")
  list(tasks=q,grid=work)
}

lo_exact_verify_certificate <- function(g,q,code_sha) {
  if(any(g$code_fingerprint!=code_sha))stop("EXACT_CHANGED_PRODUCER")
  lo_exact_assert_sha(g$certification_path[1],g$certification_sha256[1],"CERTIFICATE")
  cert<-jsonlite::fromJSON(g$certification_path[1],simplifyVector=TRUE)
  fields<-c("sample_id","method_version","weight_design","pv_rule","variance_rule",
            "source_edition_sha256","input_fingerprint","code_fingerprint")
  if(!identical(cert$status,"METHOD_SAMPLE_INPUT_CERTIFIED") ||
     !all(fields%in%names(cert)) || !all(q$metric_key%in%cert$cell_ids))
    stop("EXACT_CERTIFICATE_NOT_FOR_TASKS")
  for(k in fields)if(length(cert[[k]])!=1L || any(g[[k]]!=cert[[k]]))
    stop("EXACT_CERTIFICATE_MISMATCH_",k)
  if(is.null(cert$evidence_files) || !nrow(cert$evidence_files) ||
     !all(c("path","sha256")%in%names(cert$evidence_files)))
    stop("EXACT_CERTIFICATE_WITHOUT_EVIDENCE")
  for(i in seq_len(nrow(cert$evidence_files)))
    lo_exact_assert_sha(cert$evidence_files$path[i],cert$evidence_files$sha256[i],"METHOD_EVIDENCE")
  lo_exact_assert_sha(g$source_path[1],g$source_edition_sha256[1],"SOURCE_EDITION")
  if(any(grepl('PEER_PV_FRAME_N_TARGET_COUNTS_V1',g$method_version,fixed=TRUE))) {
    if(!identical(cert$sample_count_rule,'ANALYTIC_PEER_FRAME_WITH_SEPARATE_PV_TARGET_COUNTS')||
       is.null(cert$sample_count_evidence_path)||is.null(cert$sample_count_evidence_sha256))
      stop('EXACT_PEER_COUNT_RULE_NOT_CERTIFIED')
    lo_exact_assert_sha(cert$sample_count_evidence_path,cert$sample_count_evidence_sha256,'PEER_COUNTS')
  }
  invisible(TRUE)
}

lo_exact_dispatch <- function(repo,bundle,scope_info,tasks,grid,out,backend=NULL,max_units=Inf) {
  decisions<-lo_read_scope_decisions(repo)
  work<-lo_exact_prepare(tasks,grid,scope_info,decisions)
  q<-work$tasks;g<-work$grid
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  summary<-data.frame(required_active_cells=nrow(q),source_units_visited=0L,
    new_rows_written=0L,reused_rows=0L,holds_this_attempt=0L,compute_units_attempted=0L,
    status="NO_APPROVED_COMPUTE_CELLS",stringsAsFactors=FALSE)
  if(!nrow(q))return(summary)
  source(file.path(repo,"06_pipeline","LO_COUNTRY_REGISTRY.R"),local=environment())
  lo_country_production_approval(repo,unique(q$country),scope_info$dashboard)
  # Tests inject a source-free backend; normal callers always use pinned code.
  code_sha<-if(is.null(backend))lo_exact_code_sha(repo,bundle) else backend$code_sha
  source(file.path(repo,"06_pipeline","LO_PROCESS_LOCK.R"),local=environment())
  lock<-lo_process_lock(file.path(out,".EXACT_WRITER.lck"),file.path(out,".EXACT_WRITER"))
  on.exit(lo_process_unlock(lock),add=TRUE)
  con<-lo_compact_open(out);on.exit(lo_compact_close(con),add=TRUE)
  DBI::dbExecute(con,paste0("CREATE TABLE IF NOT EXISTS execution_receipts (",
    "cell_id TEXT NOT NULL, execution_sha TEXT NOT NULL, result_sha TEXT NOT NULL, ",
    "PRIMARY KEY(cell_id,execution_sha))"))
  grouping<-cbind(g[c("survey","country","year",
    "source_path","sample_id","input_fingerprint","code_fingerprint","method_version",
    "weight_design","pv_rule","variance_rule","certification_sha256")],
    q[c("module","domain","definition","peer_definition","threshold")])
  groups<-split(seq_len(nrow(q)),do.call(paste,c(grouping,sep="|")))
  events<-list();started<-FALSE
  for(ix in groups) {
    block<-q[ix,,drop=FALSE];certified<-g[ix,,drop=FALSE]
    reusable<-rep(FALSE,nrow(block))
    summary$source_units_visited<-summary$source_units_visited+1L
    attempt<-tryCatch({
      lo_exact_verify_certificate(certified,block,code_sha)
      execution<-vapply(seq_len(nrow(certified)),function(i)digest::digest(
        as.list(certified[i,c("target_contract_sha256","source_edition_sha256",
          "input_fingerprint","code_fingerprint","sample_id","method_version",
          "weight_design","pv_rule","variance_rule","certification_sha256")]),
        algo="sha256"),character(1))
      reusable<-vapply(seq_along(ix),function(i) {
        receipt<-DBI::dbGetQuery(con,"SELECT result_sha FROM execution_receipts WHERE cell_id=? AND execution_sha=?",
          params=list(block$metric_key[i],execution[i]))
        current<-DBI::dbGetQuery(con,"SELECT * FROM grid WHERE cell_id=?",params=list(block$metric_key[i]))
        nrow(receipt)==1L && nrow(current)==1L &&
          current$status=="COMPUTED_PENDING_VALIDATION" &&
          identical(receipt$result_sha[[1]],digest::digest(current,algo="sha256"))
      },logical(1))
      summary$reused_rows<-summary$reused_rows+sum(reusable)
      if(all(reusable) || summary$compute_units_attempted>=max_units)
        return_value<-if(all(reusable))"REUSED_EXACT_RECEIPT" else "DEFERRED_BATCH_LIMIT"
      else {
        # The limit applies to missing work, not already completed blocks.
        # Otherwise repeated bounded runs can get stuck on the first receipt.
        summary$compute_units_attempted<-summary$compute_units_attempted+1L
        if(is.null(backend) && !started) {
          for(p in c("LO_APPROVED_EXTENSIONS.R","LO_EXACT_ESTIMATORS.R","LO_EXACT_BOOT.R","LO_SOURCE_REPAIR.R","LO_GENDER_POOL_POLICY.R"))
            source(file.path(repo,"06_pipeline",p),local=environment())
          for(p in c("LO04_COMMON.R","LO04_CACHE.R"))source(file.path(bundle,"code",p),local=environment())
          for(p in c("REPAIRS.R","EXTENSIONS.R","store.R","engine.R"))source(file.path(bundle,"engine",p),local=environment())
          lo_exact_boot(bundle)
          started<-TRUE
        }
        if(is.null(backend)) {
          source(file.path(repo,"06_pipeline","LO_PRODUCTION_SPACE.R"),local=environment())
          lo_production_space_check(certified$certification_path[1],out)
        }
        obj<-if(is.null(backend))readRDS(certified$source_path[1]) else backend$read(certified$source_path[1])
        if(!identical(as.character(obj$meta$survey),block$survey[1]) ||
           !identical(as.character(obj$meta$year),block$year[1]) ||
           !identical(as.character(obj$meta$v9_country),block$country[1]))stop("EXACT_SOURCE_IDENTITY_MISMATCH")
        extension<-startsWith(block$module[1],"extension_")
        projection<-if(!is.null(backend))backend$projection(obj,block) else if(extension)
          lo_extension_projection(obj,block) else lo_compact_projection(obj,lo_compact_backend_tasks(block))
        if(any(certified$input_fingerprint!=projection))stop("EXACT_SCIENTIFIC_INPUT_CHANGED")
        run<-block[!reusable,,drop=FALSE]
        science<-lo_compact_backend_tasks(run)
        answer<-if(!is.null(backend))backend$estimate(obj,science) else {
          module<-run$module[1]
          if(module=="peer_below_basic")lo_compact_low_peer(obj,run)
          else if(extension || module%in%c("core","ses_national","ses_harmonized","gender"))lo_exact_selected_estimate(obj,science)
          else if(module=="migration_generation")lo_exact_generations(obj,run)
          else if(module=="migration_peer_exposure")lo_compact_migration_peers(obj,run)
          else if(module=="ses_peer_exposure" ||
                  (module=="peer_baseline"&&all(science$stat%in%c("q1_share","q4_share"))))
            lo_exact_ses_composition(obj,science)
          else get("v10_compute",envir=.GlobalEnv)(obj,science)
        }
        n<-if(!is.null(backend))backend$count(obj,science) else if(extension)
          lo_extension_count_n(obj,science) else lo_compact_count_n(obj,science)
        rows<-lo_compact_science_rows(run,answer,n,projection,code_sha,certified$method_version[1])
        if(!setequal(rows$cell_id,run$metric_key))stop("EXACT_OUTPUT_OUTSIDE_APPROVAL")
        # A result without its execution receipt must never be committed. A
        # crash or receipt-write failure rolls back the complete source block.
        DBI::dbWithTransaction(con,{
          lo_compact_put(con,rows,transaction=FALSE)
          for(i in which(!reusable)) {
            current<-DBI::dbGetQuery(con,"SELECT * FROM grid WHERE cell_id=?",params=list(block$metric_key[i]))
            if(current$status=="COMPUTED_PENDING_VALIDATION")DBI::dbExecute(con,
              "INSERT OR REPLACE INTO execution_receipts VALUES (?,?,?)",
              params=list(block$metric_key[i],execution[i],digest::digest(current,algo="sha256")))
          }
        })
        summary$new_rows_written<-summary$new_rows_written+sum(rows$status=="COMPUTED_PENDING_VALIDATION")
        summary$holds_this_attempt<-summary$holds_this_attempt+sum(rows$status!="COMPUTED_PENDING_VALIDATION")
        rm(obj);return_value<-"EXECUTED_EXACT_APPROVAL"
      }
      return_value
    },error=function(e)e)
    # Failed verification never overwrites a previously complete result.
    failed<-inherits(attempt,"error")
    if(failed)summary$holds_this_attempt<-summary$holds_this_attempt+sum(!reusable)
    events[[length(events)+1L]]<-data.frame(cell_id=block$metric_key,
      status=if(failed)"VERIFICATION_FAILED" else as.character(attempt),
      reason=if(failed)conditionMessage(attempt) else "",stringsAsFactors=FALSE)
  }
  write.csv(do.call(rbind,events),file.path(out,"PRIVATE_EXACT_EXECUTION_EVENTS.csv"),row.names=FALSE)
  summary$status<-if(summary$holds_this_attempt)"PARTIAL_WITH_REPAIRABLE_FAILURES" else
    if(summary$new_rows_written+summary$reused_rows<nrow(q))"PARTIAL_CHECKPOINT" else "EXACT_CANDIDATES_REQUIRE_SCIENCE_REVIEW"
  write.csv(summary,file.path(out,"EXACT_DISPATCH_SUMMARY.csv"),row.names=FALSE)
  summary
}
