# Convert independently validated primitive grid cells to the EXISTING
# dashboard's explicit data contract. Never infer score values or unit scales.
lo_dashboard_export_from_grid <- function(bundle,tasks,approved,out) {
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  expected<-c("cell_id","estimate","standard_error","n_unweighted",
    "status","sample_id","input_fingerprint","code_fingerprint","result_hash")
  if(!all(expected%in%names(approved))||
     anyDuplicated(approved$cell_id))stop("DASHBOARD_EXPORT_HOLD: invalid grid approvals")
  ok <- approved$status=="SCIENTIFICALLY_VALIDATED"
  if(anyNA(ok)||!all(ok))stop("DASHBOARD_EXPORT_HOLD: nonvalidated values")
  ix<-match(approved$cell_id,tasks$metric_key)
  if(anyNA(ix))stop("DASHBOARD_EXPORT_HOLD: approval not in pinned input grid")
  q<-tasks[ix,,drop=FALSE]
  make<-function(mod,stat,group) {
    if(mod=="core") {
      if(stat%in%c("mean","total_below","total_high"))return(c("levels",
        switch(stat,mean="mean",total_below="low",total_high="overall_top"),"total"))
      if(stat%in%c("p10","p50","p90","p90_p10"))
        return(c("distribution",stat,"total"))
      return(NULL)
    }
    if(mod%in%c("ses_national","ses_harmonized")) {
      val<-switch(stat,q1_mean="q1_mean",q4_mean="q4_mean",
        q1_basic="q1_baseline",q4_basic="q4_baseline",
        q1_high="q1_top",q4_high="q4_top",
        score_gap_q4_minus_q1="score_gap",NULL)
      if(!is.null(val))return(c("ses",val,group))
    }
    if(mod=="gender") {
      if(stat=="mean"&&group%in%c("girl","boy"))
        return(c("gender",paste0("gender_",group,"_mean"),group))
      if(stat=="gap"&&group=="girls_minus_boys")
        return(c("gender","gender_girl_minus_boy_mean",group))
    }
    NULL
  }
  mapping <- lapply(seq_len(nrow(q)),function(i)
    make(q$module[[i]],q$stat[[i]],q$group[[i]]))
  supported <- which(lengths(mapping)==3L)
  omitted <- setdiff(seq_len(nrow(q)),supported)
  records <- if(length(supported))do.call(rbind,mapping[supported]) else
    matrix(character(),ncol=3L)
  missing <- data.frame(module=q$module[omitted],stat=q$stat[omitted],
    group=q$group[omitted],reason=rep("UNSUPPORTED_DASHBOARD_MAPPING",length(omitted)),
    stringsAsFactors=FALSE)
  write.csv(missing,file.path(out,"PRIVATE_DASHBOARD_UNMAPPED_STATS.csv"),
            row.names=FALSE)
  z <- if(length(supported))data.frame(
    cell_id=approved$cell_id[supported],country=q$country[supported],
    survey=q$survey[supported],year=q$year[supported],
    domain=q$domain[supported],family=records[,1],
    stat=records[,2],group=records[,3],
    estimate=approved$estimate[supported],
    se=approved$standard_error[supported],
    n_unweighted=approved$n_unweighted[supported],
    unit=q$unit[supported],
    variant=ifelse(q$module[supported]=="ses_harmonized",
      "harmonized",ifelse(q$survey[supported]=="PISA","official",
         ifelse(q$survey[supported]=="PIRLS" &
                q$module[supported]=="gender","official",
           ifelse(q$survey[supported]=="PIRLS","rc1","v6")))),
    sample_id=approved$sample_id[supported],
    scientific_status="SCIENTIFICALLY_VALIDATED",
    source=paste0("scientific-grid:",substr(approved$result_hash[supported],1L,12L)),
    stringsAsFactors=FALSE) else data.frame()
  if(nrow(z)) {
    z$ci_low <- if("ci_low"%in%names(approved))
      approved$ci_low[supported] else NA_real_
    z$ci_high <- if("ci_high"%in%names(approved))
      approved$ci_high[supported] else NA_real_
  }
  write.csv(z,file.path(out,"PRIVATE_DASHBOARD_VALIDATED_EXPORT.csv"),
            row.names=FALSE,na="")
  summary <- data.frame(approved_input=nrow(approved),
    mapped=nrow(z),unmapped=nrow(missing),
    final_42_country_publication="HOLD_UNTIL_QA_RANKS_AND_RIGHTS",
    stringsAsFactors=FALSE)
  write.csv(summary,file.path(out,"DASHBOARD_MAPPING_SUMMARY.csv"),
            row.names=FALSE)
  invisible(summary)
}
