# Explicit run selection: intersects the approved grid; never authorizes science.
lo_run_config <- function(scope, path=Sys.getenv("LO_RUN_CONFIG", "")) {
  cfg<-list(schema_version=1L,scope=scope,selection=list(surveys=character(),
    years=character(),domains=character(),modules=character(),countries=character(),
    stats=character(),groups=character(),definitions=character(),peer_environments=character(),cell_ids=character()),
    max_compute_units=1L)
  if(nzchar(path)) {
    if(!file.exists(path))stop("RUN_CONFIG_NOT_FOUND: ",path)
    x<-jsonlite::fromJSON(path,simplifyVector=TRUE)
    if(!is.list(x)||any(!names(x)%in%names(cfg))||!identical(x$schema_version,1L))
      stop("RUN_CONFIG_UNKNOWN_FIELD_OR_VERSION")
    if(is.null(x$scope)||!identical(x$scope,scope))stop("RUN_CONFIG_SCOPE_CONFLICT")
    if(!is.null(x$selection)) {
      if(!is.list(x$selection)||any(!names(x$selection)%in%names(cfg$selection)))
        stop("RUN_CONFIG_UNKNOWN_SELECTION")
      for(k in names(x$selection))cfg$selection[[k]]<-x$selection[[k]]
    }
    if(!is.null(x$max_compute_units))cfg$max_compute_units<-x$max_compute_units
  }
  if(!cfg$scope%in%c("nld_only","nld_plus_19","all_required"))stop("RUN_CONFIG_INVALID_SCOPE")
  for(k in names(cfg$selection)) {
    v<-cfg$selection[[k]]
    if(is.list(v)&&!length(v))v<-character()
    if(!is.character(v)||anyNA(v)||any(!nzchar(v))||anyDuplicated(v))
      stop("RUN_CONFIG_INVALID_SELECTION: ",k)
    cfg$selection[[k]]<-sort(v)
  }
  n<-cfg$max_compute_units
  if(!is.numeric(n)||length(n)!=1L||!is.finite(n)||n<1||n!=floor(n))
    stop("RUN_CONFIG_POSITIVE_INTEGER_BATCH_REQUIRED")
  cfg
}
lo_run_config_hash <- function(cfg) digest::digest(
  jsonlite::toJSON(cfg,auto_unbox=TRUE,null="null",digits=NA),algo="sha256",serialize=FALSE)
lo_run_select <- function(tasks,cfg) {
  fields<-c(surveys="survey",years="year",domains="domain",modules="module",countries="country",
    stats="stat",groups="group",definitions="definition",peer_environments="peer_definition",cell_ids="metric_key")
  keep<-rep(TRUE,nrow(tasks))
  for(k in names(fields)) {
    values<-cfg$selection[[k]]
    if(!length(values))next
    if(any(!values%in%tasks[[fields[[k]]]]))stop("RUN_CONFIG_UNKNOWN_OR_UNAPPROVED_SELECTION: ",k)
    keep<-keep & tasks[[fields[[k]]]]%in%values
  }
  if(nrow(tasks)&&!any(keep))stop("RUN_CONFIG_EMPTY_INTERSECTION")
  tasks[keep,,drop=FALSE]
}
lo_run_record <- function(repo,state,stage,cfg,outcome) {
  hash_file<-function(p)if(file.exists(p))digest::digest(file=p,algo="sha256")else "ABSENT"
  paths<-c(input="FIXED_INPUT_MANIFEST.json",grid="PRIVATE_MASTER_GRID.csv",
    plan="PRIVATE_BATCH_PLAN.csv",audit="GRID_AUDIT_SUMMARY.csv",
    production="PRODUCTION_SCOPE_STATUS.csv",status="FIXED_STAGE_STATUS.csv")
  # Full input manifest and configuration are retained, not merely their hashes.
  manifest<-file.path(state,paths[["input"]])
  inputs<-if(file.exists(manifest))jsonlite::fromJSON(manifest,simplifyVector=FALSE)else NULL
  git<-Sys.which("git")
  commit<-if(nzchar(git))tryCatch(suppressWarnings(system2(git,
    shQuote(c("-C",repo,"rev-parse","HEAD")),stdout=TRUE,stderr=FALSE)),error=function(e)character())else character()
  if(length(commit)!=1L||!grepl("^[a-f0-9]{40}$",commit))commit<-"UNAVAILABLE_USE_FILE_HASHES"
  code<-list.files(file.path(repo,"06_pipeline"),pattern="[.](R|py)$",full.names=TRUE)
  pkg<-c("jsonlite","digest","DBI","RSQLite","haven")
  versions<-setNames(vapply(pkg,function(p)if(requireNamespace(p,quietly=TRUE))
    as.character(utils::packageVersion(p))else "NOT_INSTALLED",character(1)),pkg)
  results<-data.frame(cell_id=character(),result_version_sha256=character())
  database<-file.path(state,"compact","COMPACT_MASTER_GRID.sqlite")
  if(file.exists(database)) {
    con<-DBI::dbConnect(RSQLite::SQLite(),database,flags=RSQLite::SQLITE_RO)
    rows<-tryCatch(DBI::dbGetQuery(con,"SELECT * FROM grid ORDER BY cell_id"),
      finally=DBI::dbDisconnect(con))
    selected_grid<-file.path(state,"PRIVATE_MASTER_GRID.csv")
    if(file.exists(selected_grid))rows<-rows[rows$cell_id%in%
      read.csv(selected_grid,colClasses="character",na.strings=character())$cell_id,,drop=FALSE]
    results<-data.frame(cell_id=rows$cell_id,result_version_sha256=vapply(seq_len(nrow(rows)),
      function(i){r<-rows[i,,drop=FALSE];rownames(r)<-NULL;digest::digest(r,algo="sha256")},character(1)))
  }
  record<-list(schema_version=1L,stage=stage,outcome=outcome,
    timestamp_utc=format(Sys.time(),"%Y-%m-%dT%H:%M:%OS6Z",tz="UTC"),
    configuration=cfg,configuration_sha256=lo_run_config_hash(cfg),
    git_commit=commit,code_sha256=setNames(vapply(code,hash_file,character(1)),basename(code)),
    input_manifest=inputs,artifact_sha256=setNames(vapply(file.path(state,paths),hash_file,character(1)),names(paths)),
    R_version=R.version.string,platform=R.version$platform,packages=versions,
    session_info=capture.output(sessionInfo()),scientific_release="NOT_IMPLIED_BY_RUN_SUCCESS")
  record$results<-results
  record$result_set_sha256<-digest::digest(results,algo="sha256")
  ledger<-file.path(state,"RUN_RECORDS");dir.create(ledger,showWarnings=FALSE)
  text<-jsonlite::toJSON(record,auto_unbox=TRUE,pretty=TRUE,digits=NA,null="null")
  id<-digest::digest(text,algo="sha256",serialize=FALSE)
  writeLines(text,file.path(ledger,paste0(id,".json")),useBytes=TRUE)
  invisible(id)
}
