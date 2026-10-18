# Proven unavailable source cells stay in the target grid. Their absence must
# never silently shorten a comparison or be replaced by another construct.
lo_source_unavailability <- function(grid, path) {
  if(!file.exists(path))return(grid)
  x<-read.csv(path,colClasses="character",na.strings=character())
  required<-c("cell_id","target_contract_sha256","reason","evidence_path","evidence_sha256")
  if(!all(required%in%names(x))||anyDuplicated(x$cell_id)||any(!nzchar(as.matrix(x[required]))))
    stop("SOURCE_UNAVAILABILITY_INVALID_REGISTRY")
  x<-x[x$cell_id%in%grid$cell_id,,drop=FALSE]
  if(!'classification'%in%names(x))x$classification<-rep('SOURCE_UNAVAILABLE_VERIFIED',nrow(x))
  x$classification[!nzchar(x$classification)]<-'SOURCE_UNAVAILABLE_VERIFIED'
  if(any(!x$classification%in%c('SOURCE_UNAVAILABLE_VERIFIED','SOURCE_MAPPING_REVIEW_REQUIRED','ESTIMATION_UNAVAILABLE_VERIFIED')))
    stop('SOURCE_REVIEW_UNKNOWN_CLASSIFICATION')
  for(p in unique(x$evidence_path)) {
    z<-x[x$evidence_path==p,,drop=FALSE]
    if(length(unique(z$evidence_sha256))!=1L||!file.exists(p)||
       digest::digest(file=p,algo="sha256")!=z$evidence_sha256[1])stop("SOURCE_UNAVAILABILITY_EVIDENCE_CHANGED")
    cert<-jsonlite::fromJSON(p)
    if(length(unique(z$classification))!=1L||!identical(cert$status,z$classification[1])||!is.data.frame(cert$cells)||
       !all(c("cell_id","target_contract_sha256","reason")%in%names(cert$cells))||
       !is.data.frame(cert$evidence_files)||!nrow(cert$evidence_files))stop("SOURCE_UNAVAILABILITY_CERTIFICATE_INVALID")
    for(j in seq_len(nrow(cert$evidence_files))) {
      f<-cert$evidence_files[j,]
      if(!file.exists(f$path)||digest::digest(file=f$path,algo="sha256")!=f$sha256)
        stop("SOURCE_UNAVAILABILITY_PROOF_CHANGED")
    }
    i<-match(z$cell_id,cert$cells$cell_id)
    if(anyNA(i)||any(z$target_contract_sha256!=cert$cells$target_contract_sha256[i])||
       any(z$reason!=cert$cells$reason[i]))stop("SOURCE_UNAVAILABILITY_CELL_MISMATCH")
    if(z$classification[1]=='ESTIMATION_UNAVAILABLE_VERIFIED') {
      diagnostic<-cert$evidence_files$path[basename(cert$evidence_files$path)=='ANALYTIC_AVAILABILITY.csv']
      if(length(diagnostic)!=1L)stop('ESTIMATION_ABSENCE_DIAGNOSTIC_REQUIRED')
      d<-read.csv(diagnostic,colClasses='character',na.strings=character())
      fields<-c('cell_id','pv','component','n_full_target','full_weight','empty_weight_indices','reason','treatment')
      if(!all(fields%in%names(d))||!all(z$cell_id%in%d$cell_id))stop('ESTIMATION_ABSENCE_DIAGNOSTIC_INVALID')
      d<-d[d$cell_id%in%z$cell_id,,drop=FALSE]
      if(any(!d$reason%in%c('NO_OBSERVED_ANALYTIC_TARGET_IN_REQUIRED_PV','EMPTY_TARGET_IN_REQUIRED_SURVEY_REPLICATE'))||
         !all(paste(z$cell_id,z$reason)%in%paste(d$cell_id,d$reason))||
         any(d$treatment!='UNAVAILABLE_NOT_ZERO_NO_PV_OR_REPLICATE_DROPPED')||
         any(!grepl('^[0-9]+(;[0-9]+)*$',d$empty_weight_indices))||
         any(!is.finite(as.numeric(d$full_weight)))||any(as.numeric(d$full_weight)<0))stop('ESTIMATION_ABSENCE_DIAGNOSTIC_INVALID')
    }
  }
  i<-match(x$cell_id,grid$cell_id)
  if(any(x$target_contract_sha256!=grid$target_contract_sha256[i]))stop("SOURCE_UNAVAILABILITY_TARGET_CHANGED")
  if(any(grid$status[i]%in%c("SCIENTIFICALLY_VALIDATED","COMPUTE_REQUIRED","COMPUTE_REQUIRED_AFTER_METHOD_GATE")))
    stop("SOURCE_UNAVAILABILITY_CONFLICT_WITH_APPROVAL")
  grid$status[i]<-ifelse(x$classification=='SOURCE_MAPPING_REVIEW_REQUIRED',
    'HOLD_SOURCE_MAPPING_REVIEW',ifelse(x$classification=='ESTIMATION_UNAVAILABLE_VERIFIED',
      'UNAVAILABLE_VERIFIED_ANALYTIC_SAMPLE','UNAVAILABLE_VERIFIED_SOURCE_FIELD'))
  grid$hold_reason[i]<-x$reason
  grid
}
