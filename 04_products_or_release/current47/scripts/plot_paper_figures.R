# Aggregate-only paper figures. No source loading, pupil computation or tests.
# All plotted values and point intervals are the existing certified display
# transform. Break lines at a missing required wave or a definition change.
args <- commandArgs(TRUE)
stopifnot(length(args)==3L)
data_dir <- normalizePath(args[1],winslash='/',mustWork=TRUE)
fonts <- normalizePath(args[2],winslash='/',mustWork=TRUE)
out <- args[3];dir.create(out,recursive=TRUE,showWarnings=FALSE)
z <- jsonlite::fromJSON(file.path(data_dir,'RESEARCH_PRODUCT_DATA.json'),simplifyVector=FALSE)
stopifnot(length(z$provenance$countries)==47L)
systemfonts::register_font(name='Oswald',plain=file.path(fonts,'font2.ttf'),
                          bold=file.path(fonts,'font3.ttf'))
library(ggplot2)
domain_labels <- c(reading='Lezen',mathematics='Rekenen/wiskunde',science='Natuurwetenschappen')
plots <- list(mean_trends='TR_MEAN_',basic_levels='TR_BELOW_',ses_levels='GP_SES_LEVELS_',
              gender_levels='GP_GENDER_LEVELS_',migration_levels='GP_MIGRATION_LEVELS_',
              peer_basic='EN_PERFORMANCE_PEER_')
ledger <- list()
for(name in names(plots)) {
  panels <- Filter(function(p) {
    yes<-startsWith(p$id,plots[[name]])
    if(name=='migration_levels')yes<-yes&&!grepl('_ANY_PARENT_ABROAD$|_BOTH_PARENTS_ABROAD$',p$id)
    if(name=='peer_basic')yes<-yes&&!startsWith(p$id,'EN_PERFORMANCE_PEER_HIGH_')&&p$peer_definition=='direct_learning_environment'
    yes
  },z$panels)
  stopifnot(length(panels)==6L)
  rows <- list();empty <- list();anchors <- list()
  panel_order <- character()
  for(p in panels) {
    # ASCII separator is stable under the locked Windows C locale as well.
    label <- paste(domain_labels[[p$domain]],if(p$age=='age10')'groep 6'else'15 jaar',sep=' - ')
    panel_order<-c(panel_order,label)
    required<-as.integer(unlist(p$years))
    # Train each facet on its full approved anchor, including years without
    # usable observations. NA y adds no zero, point, interval or line segment.
    stopifnot(length(required)>0L, !anyNA(required))
    anchors[[length(anchors)+1L]]<-data.frame(panel=label,year=required,
      estimate=NA_real_,figure_id=p$id,stringsAsFactors=FALSE)
    rr<-Filter(function(r)name=='mean_trends'||r$series_role!='comparator',p$rows)
    if(!length(rr)) {
      empty[[length(empty)+1L]]<-data.frame(panel=label,x=mean(range(required)),y=0,
        text='Geen bruikbare reeks')
      next
    }
    # Labels distinguish exact girls and Female / Other. They form separate
    # visible segments without changing the underlying series identity.
    groups<-split(rr,vapply(rr,function(r)paste(r$series_id,r$label,sep='|'),character(1)))
    for(key in names(groups)) {
      group<-groups[[key]];group<-group[order(vapply(group,function(r)r$year,numeric(1)))]
      segment<-0L;previous<-NULL
      for(r in group) {
        if(is.null(previous)||match(r$year,required)!=match(previous,required)+1L||
           identical(r$series_break_before,TRUE)||identical(r$series_break_before,'TRUE'))segment<-segment+1L
        se<-if(is.null(r$standard_error)||r$series_role=='comparator')NA_real_ else as.numeric(r$standard_error)
        rows[[length(rows)+1L]]<-data.frame(panel=label,year=r$year,estimate=r$estimate,se=se,
          label=r$label,role=r$series_role,series_id=r$series_id,segment=paste(label,key,segment),
          cell_id=if(is.null(r$cell_id))''else r$cell_id,stringsAsFactors=FALSE)
        previous<-r$year
      }
    }
  }
  d<-do.call(rbind,rows);stopifnot(nrow(d)>0,all(is.finite(d$estimate)))
  d$panel<-factor(d$panel,levels=panel_order)
  anchor_data<-do.call(rbind,anchors)
  anchor_data$panel<-factor(anchor_data$panel,levels=panel_order)
  labels<-unique(d$label)
  palette<-setNames(rep(c('#315D8A','#6A4C93','#2C807F','#9A6D00','#8B9298'),length.out=length(labels)),labels)
  palette[grepl('Vergelijkingsgroep|Landelijk',names(palette))]<-'#8B9298'
  palette[grepl('Onderste kwart',names(palette))]<-'#9A6D00'
  palette[grepl('Bovenste kwart|Meisjes',names(palette))]<-'#6A4C93'
  palette[grepl('Jongens|Nederland|Alle leerlingen',names(palette))]<-'#315D8A'
  # Match the approved semantic groups in the policy slides. In particular,
  # all pupils and pupils above basic must not silently share the same colour.
  semantic<-c(native='#315D8A',first_generation='#6A4C93',second_generation='#2C807F',
    total='#315D8A',self_below_basic='#6A4C93',self_at_or_above_basic='#2C807F')
  for(id in names(semantic))palette[unique(d$label[d$series_id==id])]<-semantic[[id]]
  g<-ggplot(d,aes(year,estimate,color=label,group=segment))+
    geom_blank(data=anchor_data,aes(x=year,y=estimate),inherit.aes=FALSE)+
    geom_line(aes(linetype=role),linewidth=.45,na.rm=TRUE)+
    geom_linerange(aes(ymin=estimate-1.96*se,ymax=estimate+1.96*se),linewidth=.27,na.rm=TRUE,show.legend=FALSE)+
    geom_point(size=1.2)+
    facet_wrap(~panel,ncol=3,scales='free')+
    scale_color_manual(values=palette,breaks=labels)+scale_linetype_manual(values=c(focus='solid',comparator='dashed'))+
    guides(linetype='none',color=guide_legend(nrow=if(length(labels)<=3)1 else 2,byrow=TRUE,
      override.aes=list(linetype=ifelse(grepl('Vergelijkingsgroep',labels),'dashed','solid'))))+
    scale_x_continuous(breaks=function(limits)pretty(limits,n=4))+
    labs(x=NULL,y=if(name%in%c('basic_levels','peer_basic'))'Percentage'else'Scorepunten',color=NULL)+
    theme_minimal(base_family='Oswald',base_size=11)+
    theme(panel.grid.minor=element_blank(),panel.grid.major.x=element_blank(),
      panel.grid.major.y=element_line(color='#D8D8D3',linewidth=.25),
      strip.text=element_text(face='bold',hjust=0,color='#17242D',size=11),
      axis.text=element_text(color='#59636A',size=8.5),axis.title=element_text(size=10),
      legend.position='bottom',legend.text=element_text(size=10),
      panel.spacing=grid::unit(1,'lines'),plot.margin=margin(10,10,5,8),
      plot.background=element_rect(fill='#FFFFFF',color=NA))
  if(length(empty)) {
    blanks<-do.call(rbind,empty);blanks$panel<-factor(blanks$panel,levels=panel_order)
    g<-g+geom_text(data=blanks,aes(x=x,y=y,label=text),inherit.aes=FALSE,family='Oswald',size=3.2,color='#59636A')
  }
  # Inspect the trained ggplot scales, not only the intended metadata.
  # This assertion catches a removed geom_blank or a truncated empty facet.
  built<-ggplot_build(g)
  axis_proof<-lapply(seq_along(panel_order),function(i) {
    layout_row<-which(as.character(built$layout$layout$panel)==panel_order[i])
    stopifnot(length(layout_row)==1L)
    scale_id<-built$layout$layout$SCALE_X[layout_row]
    observed<-built$layout$panel_scales_x[[scale_id]]$range$range
    expected<-range(anchor_data$year[anchor_data$panel==panel_order[i]])
    stopifnot(isTRUE(all.equal(as.numeric(observed),as.numeric(expected))))
    list(figure_id=panels[[i]]$id,
      required_years=as.integer(unlist(panels[[i]]$years)),
      trained_x_range=as.numeric(observed),
      missing_years=as.list(setdiff(as.integer(unlist(panels[[i]]$years)),
        d$year[d$panel==panel_order[i]])))
  })
  dest<-file.path(out,paste0(name,'.svg'))
  svglite::svglite(dest,width=10,height=5.625,system_fonts=list(sans='Oswald'))
  print(g);dev.off()
  png_dest<-file.path(out,paste0(name,'.png'))
  ragg::agg_png(png_dest,width=3000,height=1688,units='px',res=300)
  print(g);dev.off()
  write.csv(d,file.path(out,paste0(name,'_points.csv')),row.names=FALSE,na='')
  write.csv(anchor_data,file.path(out,paste0(name,'_anchors.csv')),row.names=FALSE,na='')
  ledger[[name]]<-list(figure_ids=vapply(panels,function(p)p$id,character(1)),
    svg_sha256=digest::digest(file=dest,algo='sha256'),
    png_sha256=digest::digest(file=png_dest,algo='sha256'),points=nrow(d),
    points_sha256=digest::digest(file=file.path(out,paste0(name,'_points.csv')),algo='sha256'),
    anchors_sha256=digest::digest(file=file.path(out,paste0(name,'_anchors.csv')),algo='sha256'),
    rendered_axis_proof=axis_proof,
    series_colors=as.list(palette),
    values='Existing aggregate presentation transform; no new estimates',
    intervals='Existing standard errors times 1.96; no reference intervals')
}
jsonlite::write_json(list(provenance=z$provenance,figures=ledger,
  code_sha256=digest::digest(file=sub('^--file=','',grep('^--file=',commandArgs(),value=TRUE)),algo='sha256')),
  file.path(out,'PAPER_FIGURE_MANIFEST.json'),pretty=TRUE,auto_unbox=TRUE,digits=17)
cat('AGGREGATE_PAPER_FIGURES_BUILT',length(plots),'no pupil calculation\n')
