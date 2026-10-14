# Independent, bounded verification of one PISA-2022 country source and selected
# means/tails. This checker does not call the production estimator or pooling.
# OECD PISA 2022 Technical Report, chapters 10 and 11, formula 11.12.
lo_verify_pisa2022_core <- function(raw_path, canonical_path, tasks, out) {
  stopifnot(all(tasks$survey=="PISA"),all(tasks$year=="2022"),
    length(unique(tasks$country))==1L,all(tasks$module=="core"),
    all(tasks$stat%in%c("mean","total_below","total_high")),!anyDuplicated(tasks$metric_key))
  country<-unique(tasks$country)
  lower<-c(reading=407.47,mathematics=420.07,science=409.54)
  upper<-c(reading=625.61,mathematics=606.99,science=633.33)
  stopifnot(all(tasks$domain%in%names(lower)))
  for(k in seq_len(nrow(tasks)))if(tasks$stat[k]!="mean") {
    expected<-if(tasks$stat[k]=="total_below")lower[[tasks$domain[k]]] else upper[[tasks$domain[k]]]
    stopifnot(isTRUE(all.equal(as.numeric(tasks$threshold[k]),expected,tolerance=0)))
  }
  dir.create(out,recursive=TRUE,showWarnings=FALSE)
  obj<-readRDS(canonical_path);d<-obj$data
  stopifnot(identical(obj$meta$survey,"PISA"),as.character(obj$meta$year)=="2022",
    obj$meta$v9_country==country)
  # The country selector is the only global column read. All scientific fields
  # are read in contiguous country runs, never into a global pupil-data copy.
  selector<-haven::read_sav(raw_path,col_select="CNT")$CNT
  where<-which(selector==country)
  stopifnot(length(where)>0L)
  codes<-c(reading="READ",mathematics="MATH",science="SCIE")
  pvs<-unlist(lapply(unique(tasks$domain),function(k)paste0("PV",1:10,codes[[k]])))
  fields<-c("CNT","CNTSTUID","W_FSTUWT",paste0("W_FSTURWT",1:80),pvs)
  blocks<-split(where,cumsum(c(TRUE,diff(where)!=1L)))
  raw<-do.call(rbind,lapply(blocks,function(idx)haven::read_sav(raw_path,
    col_select=tidyselect::all_of(fields),skip=min(idx)-1L,n_max=length(idx))))
  stopifnot(all(raw$CNT==country),nrow(raw)==length(where),nrow(d)==nrow(raw),
    !anyDuplicated(raw$CNTSTUID),!anyDuplicated(d$SOURCE_STUDENT_ID))
  i<-match(as.character(d$SOURCE_STUDENT_ID),as.character(raw$CNTSTUID))
  stopifnot(!anyNA(i));raw<-raw[i,,drop=FALSE]
  canonical<-c("W",paste0("RW",1:80),
    unlist(lapply(unique(tasks$domain),function(k)paste0("PV_",codes[[k]],"_",1:10))))
  original<-c("W_FSTUWT",paste0("W_FSTURWT",1:80),pvs)
  checks<-data.frame(canonical=canonical,original=original,equal=FALSE)
  for(j in seq_along(canonical)) {
    stopifnot(canonical[j]%in%names(d))
    a<-as.numeric(d[[canonical[j]]]);b<-as.numeric(raw[[original[j]]])
    checks$equal[j]<-identical(a,b)
  }
  stopifnot(all(checks$equal))
  w<-as.numeric(raw$W_FSTUWT);rw<-as.matrix(raw[paste0("W_FSTURWT",1:80)])
  stopifnot(all(is.finite(w)),all(w>0),all(is.finite(rw)),all(rw>=0))
  # Independent matrix-ratio calculation for every PV and every supplied weight.
  weights<-cbind(w,rw);denom<-colSums(weights)
  stopifnot(all(denom>0))
  results<-lapply(seq_len(nrow(tasks)),function(k) {
    q<-tasks[k,];pv<-paste0("PV",1:10,codes[[q$domain]])
    y<-as.matrix(raw[pv]);stopifnot(all(is.finite(y)))
    if(q$stat!="mean") {
      cut<-as.numeric(q$threshold);stopifnot(is.finite(cut))
      y<-if(q$stat=="total_below")1*(y<cut) else 1*(y>=cut)
    }
    estimates<-sweep(crossprod(y,weights),2,denom,"/")
    point_pv<-estimates[,1]
    variance_pv<-rowSums((estimates[,-1,drop=FALSE]-point_pv)^2)/20
    sampling<-mean(variance_pv)
    imputation<-(1+1/10)*sum((point_pv-mean(point_pv))^2)/9
    data.frame(cell_id=q$metric_key,estimate=mean(point_pv),
      standard_error=sqrt(sampling+imputation),n_unweighted=nrow(raw),
      sampling_variance=sampling,pv_variance=imputation)
  })
  result<-do.call(rbind,results)
  write.csv(checks,file.path(out,"RAW_CANONICAL_COLUMN_PARITY.csv"),row.names=FALSE)
  write.csv(result,file.path(out,"INDEPENDENT_CORE_RESULTS.csv"),row.names=FALSE)
  receipt<-list(status="RAW_SAMPLE_AND_SELECTED_COLUMNS_VERIFIED",survey="PISA",year=2022L,
    country=country,pupil_count=nrow(raw),exact_id_set=TRUE,columns_checked=nrow(checks),
    selected_cells=tasks$metric_key,source_sha256=digest::digest(file=raw_path,algo="sha256"),
    canonical_sha256=digest::digest(file=canonical_path,algo="sha256"),
    population="All country records in OECD student public-use file; no SES/language restriction",
    caution="PISA 2022 Netherlands sampling/nonresponse and changed testing-period cautions remain",
    method="80 supplied Fay-BRR weights, 1/20; 10 PVs; mean within-PV variance plus 1.1 between-PV variance",
    source_url="https://webfs.oecd.org/pisa2022/index.html",
    method_url="https://doi.org/10.1787/01820d6d-en",
    release_authorized=FALSE)
  jsonlite::write_json(receipt,file.path(out,"RAW_CORE_VERIFICATION.json"),auto_unbox=TRUE,pretty=TRUE,digits=16)
  result
}
