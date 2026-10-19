# A view keeps the complete focus-country core anchor plus the union of every
# series actually compared in that figure. Unrelated appendix figures do not
# restrict its reference group. Missing focus results block that view explicitly.
lo_balance_task_views <- function(tasks) {
  required<-c('metric_key','country','survey','domain','contract_figure_id','definition','peer_definition','module')
  if(!all(required%in%names(tasks))||anyDuplicated(tasks$metric_key))stop('BALANCE_VIEW_TASK_IDENTITY')
  main<-!startsWith(tasks$module,'extension_') & !grepl('^GP_SES_HIGH_',tasks$contract_figure_id)
  t<-tasks[main,,drop=FALSE]
  variant<-ifelse(t$module=='peer_below_basic','below_basic',
    ifelse(t$module=='high_proficiency_peer_exposure'|t$module=='peer_baseline'&t$definition=='high_peer_raw_sample','high','standard'))
  # Definition and environment are user choices; all groups and years within
  # each choice are mandatory. Never derive support from finite plotted points.
  id<-paste(t$contract_figure_id,t$survey,t$definition,t$peer_definition,variant,sep='::')
  parts<-split(seq_len(nrow(t)),paste(t$country,id,sep=':::'))
  lapply(parts,function(ix)list(focus=t$country[ix[1]],view_id=id[ix[1]],
    cell_ids=sort(t$metric_key[ix])))
}

lo_balance_view_context <- function(available,candidates) {
  x<-lo_balance_validated(available)
  list(x=x,lookup=setNames(seq_len(nrow(x)),paste(x$country,x$balance_key,sep='::')),
    by_country=split(x$balance_key,x$country),
    admission=lo_support_eligibility(x,candidates)$countries)
}

lo_balance_one_view <- function(available,grid,view,focus_core_ids,candidates,rich,nld_anchor=NULL,context=NULL) {
  focus<-view$focus
  ids<-unique(c(focus_core_ids,view$cell_ids))
  i<-match(ids,grid$cell_id)
  if(anyNA(i)||any(grid$country[i]!=focus))stop('BALANCE_VIEW_UNAPPROVED_OR_OTHER_FOCUS')
  missing<-ids[grid$status[i]!='SCIENTIFICALLY_VALIDATED'|!ids%in%available$cell_id]
  if(length(missing))return(list(focus=focus,view_id=view$view_id,
    status=if(any(missing%in%focus_core_ids))'FOCUS_CORE_INCOMPLETE'else'FOCUS_VIEW_INCOMPLETE',
    missing_cells=grid[match(missing,grid$cell_id),intersect(c('cell_id','status','hold_reason'),names(grid)),drop=FALSE],
    default_members=character(),default_points=data.frame(),required_cell_ids=ids,view_cell_ids=view$cell_ids))
  core<-available[match(focus_core_ids,available$cell_id),,drop=FALSE]
  comparison<-available[match(view$cell_ids,available$cell_id),,drop=FALSE]
  required<-lo_focus_required_support(core,comparison,focus,nld_anchor)
  if(is.null(context))options<-lo_dashboard_reference_options(available,required,candidates,focus) else {
    # The context is built from the full verified input once per export, never
    # persisted or reused by timestamp. View filtering cannot relax admission.
    if(!isTRUE(context$admission$dashboard_eligible[match(focus,context$admission$country)]))
      stop('BALANCE_HOLD: focus does not satisfy certified dashboard 6x3 rule')
    keys<-sort(unique(lo_balance_key(required)))
    candidates<-sort(unique(candidates))
    missing<-lapply(candidates,function(c)setdiff(keys,context$by_country[[c]]))
    counts<-lengths(missing)
    admitted<-context$admission$dashboard_eligible[match(candidates,context$admission$country)]
    if(anyNA(admitted))stop('BALANCE_VIEW_CONTEXT_CANDIDATES_CHANGED')
    options<-data.frame(country=candidates,focus_country=focus,required_cells=length(keys),
      covered_cells=length(keys)-counts,missing_cells=counts,
      eligible=candidates!=focus & admitted & counts==0L,
      reason=ifelse(candidates==focus,'FOCUS_EXCLUDED',ifelse(!admitted,'FAIL_DASHBOARD_6x3',
        ifelse(counts>0L,'MISSING_OR_INCOMPATIBLE_REQUIRED_CELLS','FULL_BALANCED_SUPPORT'))),
      missing_keys=vapply(missing,paste,character(1),collapse=';'),dashboard_eligible=admitted)
  }
  selected<-sort(intersect(rich,options$country[options$eligible]))
  points<-data.frame()
  if(length(selected)) {
    if(is.null(context))points<-lo_dashboard_reference_points(available,required,selected,focus)$points else {
      points<-do.call(rbind,lapply(sort(unique(lo_balance_key(comparison))),function(key) {
        j<-unname(context$lookup[paste(selected,key,sep='::')])
        if(anyNA(j))stop('BALANCE_VIEW_INCOMPLETE_POINT')
        z<-context$x[j,,drop=FALSE]
        data.frame(focus_country=focus,balance_key=key,estimate=mean(z$estimate),
          n_countries=length(selected),members=paste(selected,collapse=';'),
          country_weights='EQUAL_PER_COUNTRY',source_records=paste(z$source_record_id,collapse=';'),
          verification_ids=paste(z$verification_id,collapse=';'),benchmark_se_displayed=FALSE)
      }))
    }
  }
  # Anchor rows gate membership but are not additional plotted series.
  if(nrow(points))points<-points[points$balance_key%in%lo_balance_key(comparison),,drop=FALSE]
  list(focus=focus,view_id=view$view_id,status=if(length(selected))'BALANCED_REFERENCE_AVAILABLE'else'NO_ELIGIBLE_REFERENCE',
    required_cell_ids=ids,view_cell_ids=view$cell_ids,required_keys=sort(lo_balance_key(required)),options=options,
    default_members=selected,default_points=points,focus_excluded=TRUE,
    country_weights='EQUAL_PER_COUNTRY',benchmark_uncertainty=FALSE)
}

lo_balanced_view_export <- function(repo,grid,contracts,tasks,scope_info,out,checked=new.env(parent=emptyenv())) {
  if(anyDuplicated(grid$cell_id))stop('BALANCE_VIEW_DUPLICATE_GRID')
  # Every certified result used here still needs its independently verified
  # comparison mapping. Unvalidated targets remain explicit missing view cells.
  contracts<-contracts[contracts$cell_id%in%grid$cell_id,,drop=FALSE]
  available<-lo_balance_result_adapter(grid,contracts,checked)
  anchor<-read.csv(file.path(repo,'06_pipeline/review_20261013/NLD_POLICY_CORE_YEAR_ANCHOR.csv'),colClasses='character')
  views<-lo_balance_task_views(tasks[tasks$country%in%scope_info$dashboard,,drop=FALSE])
  candidates<-scope_info$reference_candidates
  if(is.null(candidates))candidates<-scope_info$dashboard
  context<-lo_balance_view_context(available,unique(c(candidates,scope_info$dashboard)))
  products<-lapply(views,function(view) {
    core<-tasks$metric_key[tasks$country==view$focus & tasks$module=='core' & tasks$stat=='mean']
    if(!length(core))stop('BALANCE_VIEW_CORE_ANCHOR_MISSING')
    result<-lo_balance_one_view(available,grid,view,core,candidates,scope_info$comparator,anchor,context)
    result$required_years<-sort(unique(as.character(grid$year[match(view$cell_ids,grid$cell_id)])))
    result
  })
  jsonlite::write_json(list(schema_version=2L,policy='FULL_FOCUS_CORE_PLUS_JOINT_VIEW_SUPPORT_6x3',
    grid_sha256=digest::digest(grid,algo='sha256'),views=products,
    unavailable_cells=grid[grid$status!='SCIENTIFICALLY_VALIDATED',intersect(c('cell_id','country','survey','year','status','hold_reason'),names(grid)),drop=FALSE]),
    file.path(out,'BALANCED_REFERENCE_EXPORT.json'),auto_unbox=TRUE,pretty=TRUE,na='null',digits=17)
  invisible(products)
}
