source("06_pipeline/LO_FIXED_COMPARATOR.R",encoding="UTF-8")
Sys.setenv(LO_SYNTHETIC_REFERENCE_TEST="YES")
on.exit <- NULL
members<-c("NLD",sprintf("X%02d",1:19))
scope<-list(selected=c("NLD","Z99"),comparator=members)
years<-c("2022","2025")
tasks<-do.call(rbind,lapply(members,function(country)
 do.call(rbind,lapply(years,function(year)data.frame(
 metric_key=paste(country,year),country=country,survey="PISA",
 year=year,domain="reading",module="core",stat="mean",group="total",
 definition="total",peer_definition="",threshold="",unit="score_points",
 calculation_policy="",stringsAsFactors=FALSE)))))
grid<-data.frame(cell_id=tasks$metric_key,
 estimate=ifelse(tasks$country=="NLD",900,
   as.numeric(sub("^X","",tasks$country))+400),
 status="SCIENTIFICALLY_VALIDATED",stringsAsFactors=FALSE)
ref<-data.frame(reference="OECD_GDP_PPP_GE_CZE_2024",
 series_id="PISA|reading|core|mean|total|total|||score_points|",
 years="2022;2025",
 eligible_members=paste(c(members,"CZE"),collapse=";"))
out<-tempfile("lo_reference_")
z<-lo_fixed_reference_grid(tasks,grid,ref,scope,out)
d<-read.csv(file.path(out,"PRIVATE_FIXED_COMPARATOR_POINTS.csv"))
nld<-d[d$focus_country=="NLD",]
stopifnot(all(nld$status=="FIXED_PANEL_COMPLETE_POINT_ONLY"),
 all(nld$n_countries==19L),
 all(abs(nld$point_mean-410)<1e-10),
 all(nld$standard_error_not_plotted),
 all(d$n_countries[d$focus_country=="Z99"]==20L))
# Missing one country-year invalidates the entire common trend line.
grid$status[grid$cell_id=="X01 2022"]<-"ARCHIVE_CANDIDATE_FOUND_NOT_VALIDATED"
out2<-tempfile("lo_ref_hold_")
z2<-lo_fixed_reference_grid(tasks,grid,ref,scope,out2)
stopifnot(z2$complete_point_rows==0L,z2$held_rows==4L)
unlink(c(out,out2),recursive=TRUE)
cat("PASS fixed comparator excludes focus, equal weights, complete panel, no SE\n")
