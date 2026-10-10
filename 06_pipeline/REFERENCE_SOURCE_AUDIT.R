# Independent World Bank WDI numeric provenance for the 19-country reference.
# Never alters country memberships or releases results automatically.
lo_wdi_2024_reference_audit <- function(bundle, root) {
  if(!requireNamespace("jsonlite",quietly=TRUE) ||
     !requireNamespace("digest",quietly=TRUE))
    stop("R packages jsonlite and digest required")
  p<-file.path(bundle,"PPP_COMPARATOR_MEMBERSHIP_v2.csv")
  members<-read.csv(p,colClasses="character",stringsAsFactors=FALSE)
  stopifnot(nrow(members)==38L,
            all(c("country","strictly_above_czechia")%in%names(members)),
            "CZE"%in%members$country)
  # Exact requested WDI year/indicator; no approximate or PPP-constant variant.
  indicator<-"NY.GDP.PCAP.PP.CD"
  year<-"2024"
  url<-paste0("https://api.worldbank.org/v2/country/",
     paste(members$country,collapse=";"),"/indicator/",indicator,
     "?date=",year,"&format=json&per_page=1000")
  dir.create(root,recursive=TRUE,showWarnings=FALSE)
  rawfile<-tempfile(fileext=".json",tmpdir=root)
  on.exit(if(file.exists(rawfile))unlink(rawfile),add=TRUE)
  tryCatch(utils::download.file(url,rawfile,method="libcurl",mode="wb",
                                quiet=TRUE),error=function(e)
    stop("WDI_SOURCE_NOT_AVAILABLE: ",conditionMessage(e)))
  sha<-unname(digest::digest(file=rawfile,algo="sha256"))
  js<-jsonlite::fromJSON(rawfile,simplifyVector=TRUE)
  if(!is.list(js)||length(js)!=2L||!is.data.frame(js[[2L]]))
    stop("WDI_INVALID_JSON_RESPONSE")
  d<-js[[2L]]
  if(!all(c("countryiso3code","date","value")%in%names(d)))
    stop("WDI_UNEXPECTED_DATA_SCHEMA")
  d<-d[as.character(d$date)==year,,drop=FALSE]
  if(anyDuplicated(d$countryiso3code) ||
     !setequal(d$countryiso3code,members$country))
    stop("WDI_OECD38_COVERAGE_INCOMPLETE")
  v<-as.numeric(d$value[match(members$country,d$countryiso3code)])
  cze<-v[match("CZE",members$country)]
  if(length(cze)!=1L || !is.finite(cze)|| any(!is.finite(v)))
    stop("WDI_2024_MISSING_NUMERIC_VALUE")
  actual<-v>cze
  expected<-members$strictly_above_czechia=="TRUE"
  status<-ifelse(actual==expected,"MATCH","REVIEW_MEMBERSHIP_REVISED")
  snapdir<-file.path(root,"wdi_source_snapshots")
  dir.create(snapdir,recursive=TRUE,showWarnings=FALSE)
  immutable<-file.path(snapdir,paste0("WDI_",year,"_",substr(sha,1,20),".json"))
  if(!file.exists(immutable)) {
    temp<-tempfile(tmpdir=snapdir)
    if(!file.copy(rawfile,temp))stop("Could not stage WDI source")
    if(!file.rename(temp,immutable))stop("Could not commit immutable WDI source")
  }
  if(!identical(unname(digest::digest(file=immutable,algo="sha256")),sha))
    stop("WDI_SOURCE_SNAPSHOT_SHA_MISMATCH")
  report<-data.frame(country=members$country,
    gdp_ppp_current_international_dollars_2024=v,
    czechia_value_2024=rep(cze,length(v)),
    strict_above_czechia_from_wdi=actual,
    strict_reference_from_locked_contract=expected,
    comparison=status,source_sha256=rep(sha,length(v)))
  dest<-file.path(root,"runs",paste0("reference_audit_",format(Sys.time(),"%Y%m%d_%H%M%S")))
  dir.create(dest,recursive=TRUE,showWarnings=FALSE)
  write.csv(report,file.path(dest,"REFERENCE_WDI_2024_AUDIT.csv"),row.names=FALSE)
  writeLines(c("SOURCE=World Bank World Development Indicators",
    paste0("INDICATOR=",indicator),paste0("YEAR=",year),
    paste0("SOURCE_SHA256=",sha),
    paste0("SOURCE_ACCESSED_UTC=",format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC")),
    paste0("MISMATCHED_MEMBERSHIPS=",sum(status!="MATCH")),
    "SCIENTIFIC_RELEASE=HOLD_UNTIL_PPP_VINTAGE_AND_POLICY_REVIEW"),
    file.path(dest,"REFERENCE_SOURCE_STATUS.txt"))
  cat("WDI source saved, raw SHA-256: ",sha,
      "; membership discrepancies: ",sum(status!="MATCH"),
      "; NO comparator definition changed.\n",sep="")
  invisible(list(source_sha256=sha,discrepancies=sum(status!="MATCH"),
                 status_file=file.path(dest,"REFERENCE_SOURCE_STATUS.txt")))
}
