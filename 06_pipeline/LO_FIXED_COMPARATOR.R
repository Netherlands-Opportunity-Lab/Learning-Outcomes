# Compute equal-weight comparative point lines from already validated
# country results and the *same* fixed panel across waves. No benchmark CI/SE.
lo_fixed_reference_grid <- function(tasks,grid,reference,scope_info,out) {
  if(!all(c("cell_id","estimate","status")%in%names(grid)))
    stop("REFERENCE_HOLD: missing validated grid")
  core <- c("metric_key","survey","domain","module","stat","group",
            "definition","peer_definition","threshold","unit",
            "calculation_policy","year","country")
  if(!all(core%in%names(tasks)))stop("REFERENCE_HOLD: task schema incomplete")
  if(anyDuplicated(grid$cell_id)||anyDuplicated(tasks$metric_key))
    stop("REFERENCE_HOLD: duplicate science task")
  req <- c("series_id","years","eligible_members")
  if(!all(req%in%names(reference)))stop("REFERENCE_HOLD: missing panel definitions")
  ix<-match(grid$cell_id,tasks$metric_key)
  x<-tasks[ix[!is.na(ix)],,drop=FALSE]
  g<-grid[!is.na(ix),,drop=FALSE]
  x$estimate<-suppressWarnings(as.numeric(g$estimate))
  x$science_status<-g$status
  x<-x[x$science_status=="SCIENTIFICALLY_VALIDATED" &
       is.finite(x$estimate),,drop=FALSE]
  keys<-c("survey","domain","module","stat","group","definition",
          "peer_definition","threshold","unit","calculation_policy")
  if(nrow(x))x$series_id<-do.call(paste,c(x[keys],sep="|"))
  ref<-reference[reference$reference=="OECD_GDP_PPP_GE_CZE_2024",,drop=FALSE]
  if(nrow(ref)!=300L && !identical(Sys.getenv("LO_SYNTHETIC_REFERENCE_TEST"),"YES"))
    stop("REFERENCE_HOLD: expected 300 source reference rows")
  if(anyDuplicated(ref$series_id))stop("REFERENCE_HOLD: duplicate fixed reference series")
  proposals<-list()
  for(i in seq_len(nrow(ref))) {
    series<-ref$series_id[[i]]
    years<-strsplit(ref$years[[i]],";",fixed=TRUE)[[1]]
    eligible<-strsplit(ref$eligible_members[[i]],";",fixed=TRUE)[[1]]
    # Strictly above Czechia, plus NLD when selected as a focus: no CZE.
    members<-intersect(eligible,scope_info$comparator)
    if(!setequal(members,scope_info$comparator))
      stop("REFERENCE_HOLD: comparator identity changed in original source")
    available<-if(nrow(x))x[x$series_id==series &
      x$country%in%members & x$year%in%years,,drop=FALSE] else x
    kt<-paste(available$country,available$year,sep="|")
    valid_keys<-!anyDuplicated(kt) && length(kt)==length(members)*length(years)
    fixed <- valid_keys && all(unlist(lapply(years,function(y)
        members%in%available$country[available$year==y])))
    for(focus in scope_info$selected) {
      refmembers<-setdiff(members,focus)
      # A fixed series cannot drop an unavailable country or wave without
      # explicit revision of the original reference contract.
      status<-if(fixed)"FIXED_PANEL_COMPLETE_POINT_ONLY" else
        "HOLD_MISSING_VALIDATED_COUNTRY_WAVES"
      for(year in years) {
        r<-available[available$year==year &
             available$country%in%refmembers,,drop=FALSE]
        point<-if(fixed && nrow(r)==length(refmembers))
          mean(r$estimate) else NA_real_
        proposals[[length(proposals)+1L]]<-data.frame(
          focus_country=focus,series_id=series,year=year,
          point_mean=point,n_countries=length(refmembers),
          country_weights="EQUAL_PER_COUNTRY",
          focus_excluded=!(focus%in%refmembers),
          standard_error_not_plotted="TRUE",
          status=status,stringsAsFactors=FALSE)
      }
    }
  }
  rows<-if(length(proposals))do.call(rbind,proposals) else data.frame()
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  write.csv(rows,file.path(out,"PRIVATE_FIXED_COMPARATOR_POINTS.csv"),
            row.names=FALSE,na="")
  stats<-data.frame(reference_series=nrow(ref),
    point_rows=nrow(rows),
    complete_point_rows=if(nrow(rows))sum(is.finite(rows$point_mean)) else 0L,
    held_rows=if(nrow(rows))sum(!is.finite(rows$point_mean)) else 0L,
    displayed_reference_se="NEVER",
    scientific_release="PENDING_INDEPENDENT_REVIEW",stringsAsFactors=FALSE)
  write.csv(stats,file.path(out,"FIXED_COMPARATOR_SUMMARY.csv"),row.names=FALSE)
  invisible(stats)
}
